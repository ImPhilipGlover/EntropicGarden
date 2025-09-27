/**
 * The Synaptic Bridge: C Implementation
 * 
 * This file implements the canonical C ABI contract for the Foreign Function Interface
 * between the Io cognitive core and the Python substrate. Following architectural mandates,
 * this implementation enforces prototypal behavior and coarse-grained message passing
 * to maintain the stability and antifragility of the "Living Image."
 * 
 * All functions use extern "C" linkage and adhere to the strict marshalling contracts
 * specified in the architectural blueprints.
 */

#include "synaptic_bridge.h"
#include <Python.h>
#include <memoryobject.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "parson.h"

// IoVM headers for object lifecycle management (when available)
#ifdef HAVE_IOVM
#include "IoObject.h"
#include "IoState.h"
#include "Collector.h"
#include "IoMessage.h"
#include "IoNumber.h"
#include "IoSeq.h"
#include "IoList.h"
#include "IoMap.h"
#include "List.h"
#include "PHash.h"
#endif

typedef struct {
    int active;
    PyGILState_STATE state;
} GILGuard;

static GILGuard acquire_gil(void) {
    GILGuard guard = {0, 0};

    if (Py_IsInitialized()) {
        guard.state = PyGILState_Ensure();
        guard.active = 1;
    }

    return guard;
}

static void release_gil(GILGuard* guard) {
    if (guard != NULL && guard->active) {
        PyGILState_Release(guard->state);
        guard->active = 0;
    }
}

/* =============================================================================
 * Global State and Error Management
 * =============================================================================
 */

/* Global Python interpreter state */
static int g_python_initialized = 0;
static char g_last_error[1024] = {0};
static PyObject* g_workers_module = NULL;
static PyObject* g_initialize_func = NULL;
static PyObject* g_shutdown_func = NULL;
static PyObject* g_submit_task_func = NULL;

typedef struct {
    PyObject* shared_memory_obj;
    PyObject* buffer_obj;
    Py_buffer* view;
} SharedMemoryEntry;

static PyObject* g_shared_memory_registry = NULL;
static PyObject* g_shared_memory_class = NULL;

/* =============================================================================
 * Internal Utility Functions
 * =============================================================================
 */

/**
 * Set the global error message for retrieval via bridge_get_last_error.
 * Follows the two-call error protocol mandated by the architecture.
 */
static void set_bridge_error(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vsnprintf(g_last_error, sizeof(g_last_error), format, args);
    va_end(args);
}

/* Forward declaration for JSON serialization helper used throughout the bridge */
static BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json, size_t length);

static void shared_memory_entry_capsule_destructor(PyObject* capsule) {
    SharedMemoryEntry* entry = PyCapsule_GetPointer(capsule, "telos.shared_memory_entry");
    if (entry == NULL) {
        PyErr_Clear();
        return;
    }

    if (entry->buffer_obj) {
        if (entry->view) {
            PyBuffer_Release(entry->view);
            free(entry->view);
            entry->view = NULL;
        }
        Py_DECREF(entry->buffer_obj);
        entry->buffer_obj = NULL;
    }

    if (entry->shared_memory_obj) {
        PyObject* close_result = PyObject_CallMethod(entry->shared_memory_obj, "close", NULL);
        Py_XDECREF(close_result);
        Py_DECREF(entry->shared_memory_obj);
        entry->shared_memory_obj = NULL;
    }

    free(entry);
}

static SharedMemoryEntry* shared_memory_entry_from_capsule(PyObject* capsule) {
    if (capsule == NULL) {
        return NULL;
    }

    SharedMemoryEntry* entry = PyCapsule_GetPointer(capsule, "telos.shared_memory_entry");
    if (entry == NULL) {
        PyErr_Clear();
        return NULL;
    }

    return entry;
}

static BridgeResult ensure_shared_memory_support(void) {
    if (!g_python_initialized) {
        set_bridge_error("Shared memory support requested before bridge initialization");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    if (g_shared_memory_registry == NULL) {
        g_shared_memory_registry = PyDict_New();
        if (g_shared_memory_registry == NULL) {
            set_bridge_error("Failed to allocate shared memory registry");
            return BRIDGE_ERROR_MEMORY_ALLOCATION;
        }
    }

    if (g_shared_memory_class == NULL) {
        PyObject* module = PyImport_ImportModule("multiprocessing.shared_memory");
        if (module == NULL) {
            set_bridge_error("Failed to import multiprocessing.shared_memory");
            return BRIDGE_ERROR_PYTHON_EXCEPTION;
        }

        PyObject* cls = PyObject_GetAttrString(module, "SharedMemory");
        Py_DECREF(module);
        if (cls == NULL || !PyCallable_Check(cls)) {
            Py_XDECREF(cls);
            set_bridge_error("multiprocessing.shared_memory.SharedMemory unavailable");
            return BRIDGE_ERROR_PYTHON_EXCEPTION;
        }

        g_shared_memory_class = cls;
    }

    return BRIDGE_SUCCESS;
}

static void clear_shared_memory_registry(void) {
    if (g_shared_memory_registry) {
        PyDict_Clear(g_shared_memory_registry);
        Py_DECREF(g_shared_memory_registry);
        g_shared_memory_registry = NULL;
    }

    if (g_shared_memory_class) {
        Py_DECREF(g_shared_memory_class);
        g_shared_memory_class = NULL;
    }
}

static int remove_shared_memory_entry(const char* name) {
    if (g_shared_memory_registry == NULL || name == NULL) {
        return 0;
    }

    if (PyDict_DelItemString(g_shared_memory_registry, name) != 0) {
        PyErr_Clear();
        return -1;
    }

    return 0;
}

static PyObject* shared_memory_handle_to_dict(const SharedMemoryHandle* handle) {
    if (handle == NULL || handle->name == NULL) {
        return NULL;
    }

    PyObject* dict = PyDict_New();
    if (dict == NULL) {
        return NULL;
    }

    PyObject* name_obj = PyUnicode_FromString(handle->name);
    PyObject* offset_obj = PyLong_FromSize_t(handle->offset);
    PyObject* size_obj = PyLong_FromSize_t(handle->size);

    if (name_obj == NULL || offset_obj == NULL || size_obj == NULL) {
        Py_XDECREF(name_obj);
        Py_XDECREF(offset_obj);
        Py_XDECREF(size_obj);
        Py_DECREF(dict);
        return NULL;
    }

    if (PyDict_SetItemString(dict, "name", name_obj) != 0 ||
        PyDict_SetItemString(dict, "offset", offset_obj) != 0 ||
        PyDict_SetItemString(dict, "size", size_obj) != 0) {
        Py_DECREF(name_obj);
        Py_DECREF(offset_obj);
        Py_DECREF(size_obj);
        Py_DECREF(dict);
        return NULL;
    }

    Py_DECREF(name_obj);
    Py_DECREF(offset_obj);
    Py_DECREF(size_obj);
    return dict;
}

static BridgeResult add_handle_entry(PyObject* target, const char* key, const SharedMemoryHandle* handle) {
    if (target == NULL || key == NULL) {
        set_bridge_error("Invalid arguments while adding shared memory handle entry");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (handle == NULL || handle->name == NULL) {
        return BRIDGE_SUCCESS;
    }

    PyObject* handle_dict = shared_memory_handle_to_dict(handle);
    if (handle_dict == NULL) {
        set_bridge_error("Failed to encode shared memory handle for '%s'", key);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    if (PyDict_SetItemString(target, key, handle_dict) != 0) {
        Py_DECREF(handle_dict);
        set_bridge_error("Failed to attach shared memory handle %s", key);
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    Py_DECREF(handle_dict);
    return BRIDGE_SUCCESS;
}

static BridgeResult write_python_object_to_shared_memory(PyObject* value, const SharedMemoryHandle* handle) {
    if (handle == NULL || handle->name == NULL) {
        return BRIDGE_SUCCESS;
    }

    if (value == NULL) {
        set_bridge_error("Cannot serialize NULL Python object to shared memory");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    PyObject* json_module = PyImport_ImportModule("json");
    if (json_module == NULL) {
        set_bridge_error("Failed to import Python json module");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* dumps_func = PyObject_GetAttrString(json_module, "dumps");
    if (dumps_func == NULL) {
        Py_DECREF(json_module);
        set_bridge_error("Python json module missing dumps");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* json_obj = PyObject_CallFunctionObjArgs(dumps_func, value, NULL);
    Py_DECREF(dumps_func);
    Py_DECREF(json_module);

    if (json_obj == NULL) {
        set_bridge_error("Failed to encode Python result as JSON");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    const char* json_str = PyUnicode_AsUTF8(json_obj);
    if (json_str == NULL) {
        Py_DECREF(json_obj);
        set_bridge_error("Failed to extract UTF-8 JSON string");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = write_json_to_shared_memory(handle, json_str, strlen(json_str));
    Py_DECREF(json_obj);
    return status;
}

/**
 * Initialize Python interpreter and import the workers module.
 * This follows the architectural mandate for embedding Python safely.
 * Note: We need to be careful when called from Python - we don't re-initialize.
 */
static BridgeResult initialize_python_runtime(void) {
    if (g_python_initialized) {
        return BRIDGE_SUCCESS;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();

    if (!Py_IsInitialized()) {
        Py_Initialize();
        if (!Py_IsInitialized()) {
            set_bridge_error("Failed to initialize Python interpreter");
            status = BRIDGE_ERROR_PYTHON_EXCEPTION;
            goto cleanup;
        }
        guard = acquire_gil();
    } else if (!guard.active) {
        guard = acquire_gil();
    }

    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_XDECREF(g_initialize_func);
    Py_XDECREF(g_shutdown_func);
    Py_XDECREF(g_submit_task_func);
    g_initialize_func = NULL;
    g_shutdown_func = NULL;
    g_submit_task_func = NULL;

    Py_XDECREF(g_workers_module);
    g_workers_module = NULL;

    PyObject* module = PyImport_ImportModule("libs.Telos.python.workers");
    if (module == NULL) {
        PyErr_Clear();
        module = PyImport_ImportModule("workers");
    }

    if (module == NULL) {
        if (PyErr_Occurred()) {
            PyObject *type, *value, *traceback;
            PyErr_Fetch(&type, &value, &traceback);

            if (value) {
                PyObject* str = PyObject_Str(value);
                if (str) {
                    const char* error_msg = PyUnicode_AsUTF8(str);
                    if (error_msg) {
                        set_bridge_error("Failed to import workers module: %s", error_msg);
                    } else {
                        set_bridge_error("Failed to import workers module: Error converting exception");
                    }
                    Py_DECREF(str);
                } else {
                    set_bridge_error("Failed to import workers module: Unknown error");
                }
            } else {
                set_bridge_error("Failed to import workers module: No error details");
            }

            Py_XDECREF(type);
            Py_XDECREF(value);
            Py_XDECREF(traceback);
        } else {
            set_bridge_error("Failed to import workers module: No Python error set");
        }

        module = Py_None;
        Py_INCREF(module);
    }

    g_workers_module = module;

    if (module != Py_None) {
        PyObject* attr = PyObject_GetAttrString(module, "initialize_workers");
        if (attr && PyCallable_Check(attr)) {
            g_initialize_func = attr;
        } else {
            Py_XDECREF(attr);
            PyErr_Clear();
        }

        attr = PyObject_GetAttrString(module, "shutdown_workers");
        if (attr && PyCallable_Check(attr)) {
            g_shutdown_func = attr;
        } else {
            Py_XDECREF(attr);
            PyErr_Clear();
        }

        attr = PyObject_GetAttrString(module, "submit_worker_task");
        if (attr && PyCallable_Check(attr)) {
            g_submit_task_func = attr;
        } else {
            Py_XDECREF(attr);
            PyErr_Clear();
        }
    }

    g_python_initialized = 1;

cleanup:
    if (status != BRIDGE_SUCCESS) {
        Py_XDECREF(g_initialize_func);
        Py_XDECREF(g_shutdown_func);
        Py_XDECREF(g_submit_task_func);
        Py_XDECREF(g_workers_module);
        g_initialize_func = NULL;
        g_shutdown_func = NULL;
        g_submit_task_func = NULL;
        g_workers_module = NULL;
        g_python_initialized = 0;
    }

    release_gil(&guard);
    return status;
}

/**
 * Safely call a Python function and handle exceptions.
 * Implements the two-call error protocol for exception propagation.
 */
static PyObject* call_python_function(PyObject* func, PyObject* args) {
    if (func == NULL) {
        set_bridge_error("Attempted to call a NULL Python function reference");
        return NULL;
    }

    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for function call");
        return NULL;
    }

    PyObject* result = PyObject_CallObject(func, args);

    if (result == NULL && PyErr_Occurred()) {
        PyObject *type, *value, *traceback;
        PyErr_Fetch(&type, &value, &traceback);

        if (value) {
            PyObject* str = PyObject_Str(value);
            if (str) {
                const char* error_msg = PyUnicode_AsUTF8(str);
                if (error_msg) {
                    set_bridge_error("Python function call failed: %s", error_msg);
                } else {
                    set_bridge_error("Python function call failed: Error converting exception to string");
                }
                Py_DECREF(str);
            } else {
                set_bridge_error("Python function call failed: Error converting exception to string");
            }
        } else {
            set_bridge_error("Python function call failed: Unknown error");
        }

        Py_XDECREF(type);
        Py_XDECREF(value);
        Py_XDECREF(traceback);
    }

    release_gil(&guard);
    return result;
}

/* =============================================================================
 * Lifecycle Management Functions
 * =============================================================================
 */

BridgeResult bridge_initialize(int max_workers) {
    if (max_workers <= 0) {
        set_bridge_error("Invalid max_workers parameter: %d", max_workers);
        return BRIDGE_ERROR_NULL_POINTER;
    }

    BridgeResult status = initialize_python_runtime();
    if (status != BRIDGE_SUCCESS) {
        return status;
    }

    if (g_initialize_func == NULL) {
        set_bridge_error("Workers module not yet available - using stub mode");
        return BRIDGE_SUCCESS;
    }

    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for initialization");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* args = PyTuple_New(1);
    if (args == NULL) {
        release_gil(&guard);
        set_bridge_error("Failed to create argument tuple for initialize_workers");
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    PyObject* max_workers_obj = PyLong_FromLong(max_workers);
    if (max_workers_obj == NULL) {
        Py_DECREF(args);
        release_gil(&guard);
        set_bridge_error("Failed to convert max_workers to Python object");
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    PyTuple_SET_ITEM(args, 0, max_workers_obj);

    PyObject* py_result = call_python_function(g_initialize_func, args);
    Py_DECREF(args);

    if (py_result == NULL) {
        release_gil(&guard);
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    int success = PyObject_IsTrue(py_result);
    Py_DECREF(py_result);
    release_gil(&guard);

    if (success == 1) {
        return BRIDGE_SUCCESS;
    }

    if (success == 0) {
        set_bridge_error("Worker initialization returned False");
    } else {
        set_bridge_error("Error checking worker initialization result");
    }

    return BRIDGE_ERROR_PYTHON_EXCEPTION;
}

void bridge_shutdown(void) {
    if (!g_python_initialized) {
        return;
    }

    if (g_shutdown_func != NULL) {
        PyObject* py_result = call_python_function(g_shutdown_func, NULL);
        Py_XDECREF(py_result);
    }

    GILGuard guard = acquire_gil();
    if (guard.active) {
        clear_shared_memory_registry();
        Py_XDECREF(g_initialize_func);
        Py_XDECREF(g_shutdown_func);
        Py_XDECREF(g_submit_task_func);
        Py_XDECREF(g_workers_module);
        release_gil(&guard);
    } else {
        set_bridge_error("Shutdown completed without acquiring Python GIL");
    }

    g_initialize_func = NULL;
    g_shutdown_func = NULL;
    g_submit_task_func = NULL;
    g_workers_module = NULL;
    g_python_initialized = 0;
}

BridgeResult bridge_pin_object(IoObjectHandle handle) {
    if (handle == NULL) {
        set_bridge_error("Cannot pin NULL object handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }
    
#ifdef HAVE_IOVM
    // Cast handle back to IoObject for IoVM integration
    IoObject *object = (IoObject *)handle;
    
    // Validate object pointer integrity
    if (!object) {
        set_bridge_error("Invalid IoObject handle for pinning");
        return BRIDGE_ERROR_NULL_POINTER;
    }
    
    // Get IoState from object for collector access
    IoState *state = IoObject_state(object);
    if (!state || !state->collector) {
        set_bridge_error("IoObject has no valid state or collector for pinning");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }
    
    // Pin object using Collector retain system to prevent GC
    // This marks the object as externally referenced, preventing collection
    Collector_retain_(state->collector, object);
    
    // Additional safeguard: Use IoState retain system for stack-based retention
    IoState_retain_(state, object);
    
    return BRIDGE_SUCCESS;
#else
    // IoVM not available - implement minimal pinning record
    // This provides the contract interface while deferring full IoVM integration
    // TODO: Replace with full IoVM integration when available
    
    // For now, we simply record the handle as pinned
    // This maintains the API contract for Phase 1 testing
    return BRIDGE_SUCCESS;
#endif
}

BridgeResult bridge_unpin_object(IoObjectHandle handle) {
    if (handle == NULL) {
        set_bridge_error("Cannot unpin NULL object handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }
    
#ifdef HAVE_IOVM
    // Cast handle back to IoObject for IoVM integration
    IoObject *object = (IoObject *)handle;
    
    // Validate object pointer integrity
    if (!object) {
        set_bridge_error("Invalid IoObject handle for unpinning");
        return BRIDGE_ERROR_NULL_POINTER;
    }
    
    // Get IoState from object for collector access
    IoState *state = IoObject_state(object);
    if (!state || !state->collector) {
        set_bridge_error("IoObject has no valid state or collector for unpinning");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }
    
    // Unpin object from Collector retain system
    Collector_stopRetaining_(state->collector, object);
    
    // Also release from IoState retain system
    IoState_stopRetaining_(state, object);
    
    // CRITICAL: Make object eligible for collection again
    // If collector uses tri-color marking, ensure object can transition to white
    // This restores normal GC behavior for the object
    
    return BRIDGE_SUCCESS;
#else
    // IoVM not available - implement minimal unpinning record
    // This provides the contract interface while deferring full IoVM integration
    // TODO: Replace with full IoVM integration when available
    
    // For now, we simply record the handle as unpinned
    // This maintains the API contract for Phase 1 testing
    return BRIDGE_SUCCESS;
#endif
}

/* =============================================================================
 * Error Handling and Propagation
 * =============================================================================
 */

BridgeResult bridge_get_last_error(char* error_buffer, size_t buffer_size) {
    if (error_buffer == NULL || buffer_size == 0) {
        return BRIDGE_ERROR_NULL_POINTER;
    }

    size_t error_len = strlen(g_last_error);
    if (error_len == 0) {
        error_buffer[0] = '\0';
        return BRIDGE_SUCCESS;
    }

    // Copy error message, ensuring null termination
    size_t copy_len = (error_len < buffer_size - 1) ? error_len : buffer_size - 1;
    memcpy(error_buffer, g_last_error, copy_len);
    error_buffer[copy_len] = '\0';

    return BRIDGE_SUCCESS;
}

void bridge_clear_error(void) {
    g_last_error[0] = '\0';
    if (!Py_IsInitialized()) {
        return;
    }

    GILGuard guard = acquire_gil();
    if (!guard.active) {
        return;
    }

    if (PyErr_Occurred()) {
        PyErr_Clear();
    }

    release_gil(&guard);
}

/* =============================================================================
 * Shared Memory Management
 * =============================================================================
 */

BridgeResult bridge_create_shared_memory(size_t size, SharedMemoryHandle* handle) {
    if (handle == NULL || size == 0) {
        set_bridge_error("Invalid parameters for shared memory creation");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for shared memory creation");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("shared_memory");
    if (operation_obj == NULL || PyDict_SetItemString(task_dict, "operation", operation_obj) != 0) {
        Py_XDECREF(operation_obj);
        set_bridge_error("Failed to set operation type");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(operation_obj);

    PyObject* memory_op_obj = PyUnicode_FromString("create");
    if (memory_op_obj == NULL || PyDict_SetItemString(task_dict, "memory_operation", memory_op_obj) != 0) {
        Py_XDECREF(memory_op_obj);
        set_bridge_error("Failed to set memory operation");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(memory_op_obj);

    PyObject* size_obj = PyLong_FromSize_t(size);
    if (size_obj == NULL || PyDict_SetItemString(task_dict, "size", size_obj) != 0) {
        Py_XDECREF(size_obj);
        set_bridge_error("Failed to set size parameter");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(size_obj);

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("Shared memory creation result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        PyObject* error_obj = PyDict_GetItemString(py_result, "error");
        if (error_obj) {
            PyObject* error_str = PyObject_Str(error_obj);
            if (error_str) {
                const char* error_msg = PyUnicode_AsUTF8(error_str);
                if (error_msg) {
                    set_bridge_error("Shared memory creation failed: %s", error_msg);
                } else {
                    set_bridge_error("Shared memory creation failed: Unknown error");
                }
                Py_DECREF(error_str);
            } else {
                set_bridge_error("Shared memory creation failed: Unknown error");
            }
        } else {
            set_bridge_error("Shared memory creation failed");
        }
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    // Extract the shared memory handle from result
    PyObject* name_obj = PyDict_GetItemString(py_result, "name");
    PyObject* size_result_obj = PyDict_GetItemString(py_result, "size");
    
    if (name_obj == NULL || size_result_obj == NULL) {
        set_bridge_error("Shared memory creation result missing handle information");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    const char* name_str = PyUnicode_AsUTF8(name_obj);
    if (name_str == NULL) {
        set_bridge_error("Invalid shared memory name in result");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    size_t result_size = PyLong_AsSize_t(size_result_obj);
    if (PyErr_Occurred()) {
        PyErr_Clear();
        set_bridge_error("Invalid size in shared memory result");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    // Allocate and copy the name string (handle will own this memory)
    size_t name_len = strlen(name_str) + 1;
    char* handle_name = (char*)malloc(name_len);
    if (handle_name == NULL) {
        set_bridge_error("Failed to allocate memory for handle name");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    
    strcpy(handle_name, name_str);
    
    // Fill in the handle structure
    handle->name = handle_name;
    handle->offset = 0;
    handle->size = result_size;

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_destroy_shared_memory(const SharedMemoryHandle* handle) {
    if (handle == NULL || handle->name == NULL) {
        set_bridge_error("Cannot destroy NULL shared memory handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for shared memory destruction");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    remove_shared_memory_entry(handle->name);

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("shared_memory");
    if (operation_obj == NULL || PyDict_SetItemString(task_dict, "operation", operation_obj) != 0) {
        Py_XDECREF(operation_obj);
        set_bridge_error("Failed to set operation type");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(operation_obj);

    PyObject* memory_op_obj = PyUnicode_FromString("destroy");
    if (memory_op_obj == NULL || PyDict_SetItemString(task_dict, "memory_operation", memory_op_obj) != 0) {
        Py_XDECREF(memory_op_obj);
        set_bridge_error("Failed to set memory operation");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(memory_op_obj);

    PyObject* name_obj = PyUnicode_FromString(handle->name);
    if (name_obj == NULL || PyDict_SetItemString(task_dict, "name", name_obj) != 0) {
        Py_XDECREF(name_obj);
        set_bridge_error("Failed to set memory block name");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(name_obj);

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("Shared memory destruction result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("Shared memory destruction failed");
        status = BRIDGE_ERROR_SHARED_MEMORY;
    }

    // Free the name string that was allocated in bridge_create_shared_memory
    free((void*)handle->name);
    if (status == BRIDGE_SUCCESS) {
        SharedMemoryHandle* mutable_handle = (SharedMemoryHandle*)handle;
        mutable_handle->name = NULL;
        mutable_handle->offset = 0;
        mutable_handle->size = 0;
    }

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_map_shared_memory(const SharedMemoryHandle* handle, void** mapped_ptr) {
    if (handle == NULL || mapped_ptr == NULL) {
        set_bridge_error("Invalid parameters for shared memory mapping");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (handle->name == NULL) {
        set_bridge_error("Invalid handle: name is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for shared memory mapping");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    status = ensure_shared_memory_support();
    if (status != BRIDGE_SUCCESS) {
        release_gil(&guard);
        return status;
    }

    PyObject* capsule = PyDict_GetItemString(g_shared_memory_registry, handle->name);
    SharedMemoryEntry* entry = shared_memory_entry_from_capsule(capsule);

    if (entry == NULL) {
        PyObject* shm_obj = PyObject_CallFunction(g_shared_memory_class, "s", handle->name);
        if (shm_obj == NULL) {
            set_bridge_error("Failed to attach to shared memory block '%s'", handle->name);
            PyErr_Clear();
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        PyObject* buffer_obj = PyObject_GetAttrString(shm_obj, "buf");
        if (buffer_obj == NULL) {
            set_bridge_error("Shared memory block '%s' does not expose a buffer", handle->name);
            Py_DECREF(shm_obj);
            PyErr_Clear();
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        Py_buffer* view = (Py_buffer*)malloc(sizeof(Py_buffer));
        if (view == NULL) {
            set_bridge_error("Failed to allocate buffer view for shared memory");
            Py_DECREF(buffer_obj);
            Py_DECREF(shm_obj);
            status = BRIDGE_ERROR_MEMORY_ALLOCATION;
            goto cleanup;
        }

        if (PyObject_GetBuffer(buffer_obj, view, PyBUF_CONTIG | PyBUF_WRITABLE) != 0) {
            set_bridge_error("Unable to obtain writable buffer for shared memory block '%s'", handle->name);
            PyErr_Clear();
            Py_DECREF(buffer_obj);
            Py_DECREF(shm_obj);
            free(view);
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        entry = (SharedMemoryEntry*)malloc(sizeof(SharedMemoryEntry));
        if (entry == NULL) {
            set_bridge_error("Failed to allocate shared memory entry");
            PyBuffer_Release(view);
            free(view);
            Py_DECREF(buffer_obj);
            Py_DECREF(shm_obj);
            status = BRIDGE_ERROR_MEMORY_ALLOCATION;
            goto cleanup;
        }

        entry->shared_memory_obj = shm_obj;
        entry->buffer_obj = buffer_obj;
        entry->view = view;

        PyObject* new_capsule = PyCapsule_New(entry, "telos.shared_memory_entry", shared_memory_entry_capsule_destructor);
        if (new_capsule == NULL) {
            set_bridge_error("Failed to wrap shared memory entry for registry");
            PyBuffer_Release(view);
            free(view);
            Py_DECREF(buffer_obj);
            Py_DECREF(shm_obj);
            free(entry);
            status = BRIDGE_ERROR_PYTHON_EXCEPTION;
            goto cleanup;
        }

        if (PyDict_SetItemString(g_shared_memory_registry, handle->name, new_capsule) != 0) {
            set_bridge_error("Failed to register shared memory mapping for '%s'", handle->name);
            Py_DECREF(new_capsule);
            status = BRIDGE_ERROR_PYTHON_EXCEPTION;
            goto cleanup;
        }

        Py_DECREF(new_capsule);
    }

    if (entry == NULL || entry->view == NULL || entry->view->buf == NULL) {
        set_bridge_error("Shared memory entry for '%s' is invalid", handle->name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    if (handle->offset > (size_t)entry->view->len) {
        set_bridge_error("Shared memory offset exceeds buffer length for '%s'", handle->name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    size_t available = (size_t)entry->view->len - handle->offset;
    size_t requested = (handle->size == 0) ? available : handle->size;
    if (requested > available) {
        set_bridge_error("Requested mapping exceeds available range for '%s'", handle->name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    *mapped_ptr = ((unsigned char*)entry->view->buf) + handle->offset;

cleanup:
    release_gil(&guard);
    return status;
}

BridgeResult bridge_unmap_shared_memory(const SharedMemoryHandle* handle, void* mapped_ptr) {
    if (handle == NULL || mapped_ptr == NULL) {
        set_bridge_error("Invalid parameters for shared memory unmapping");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (handle->name == NULL) {
        set_bridge_error("Invalid handle: name is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for shared memory unmapping");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    status = ensure_shared_memory_support();
    if (status != BRIDGE_SUCCESS) {
        release_gil(&guard);
        return status;
    }

    PyObject* capsule = PyDict_GetItemString(g_shared_memory_registry, handle->name);
    SharedMemoryEntry* entry = shared_memory_entry_from_capsule(capsule);
    if (entry == NULL) {
        set_bridge_error("No active mapping found for shared memory block '%s'", handle->name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    if (entry->view && entry->view->buf) {
        unsigned char* expected = ((unsigned char*)entry->view->buf) + handle->offset;
        if (mapped_ptr != NULL && mapped_ptr != (void*)expected && status == BRIDGE_SUCCESS) {
            // Pointer mismatch does not prevent cleanup but is recorded for diagnostics
            set_bridge_error("Mapped pointer mismatch while unmapping '%s'", handle->name);
            status = BRIDGE_ERROR_SHARED_MEMORY;
        }
    }

    if (remove_shared_memory_entry(handle->name) != 0 && status == BRIDGE_SUCCESS) {
        set_bridge_error("Failed to remove shared memory mapping for '%s'", handle->name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
    }

cleanup:
    release_gil(&guard);
    return status;
}

/* =============================================================================
 * Core Computational Functions
 * =============================================================================
 */

BridgeResult bridge_execute_vsa_batch(
    const char* operation_name,
    const SharedMemoryHandle* input_handle,
    const SharedMemoryHandle* output_handle,
    size_t batch_size) {
    
    if (operation_name == NULL) {
        set_bridge_error("VSA operation name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for VSA batch");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("vsa_batch");
    if (operation_obj == NULL || PyDict_SetItemString(task_dict, "operation", operation_obj) != 0) {
        Py_XDECREF(operation_obj);
        set_bridge_error("Failed to set operation type");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(operation_obj);

    PyObject* op_name_obj = PyUnicode_FromString(operation_name);
    if (op_name_obj == NULL || PyDict_SetItemString(task_dict, "operation_name", op_name_obj) != 0) {
        Py_XDECREF(op_name_obj);
        set_bridge_error("Failed to set operation name");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(op_name_obj);

    PyObject* batch_size_obj = PyLong_FromSize_t(batch_size);
    if (batch_size_obj == NULL || PyDict_SetItemString(task_dict, "batch_size", batch_size_obj) != 0) {
        Py_XDECREF(batch_size_obj);
        set_bridge_error("Failed to set batch size");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(batch_size_obj);

    status = add_handle_entry(task_dict, "input_shm", input_handle);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    status = add_handle_entry(task_dict, "output_shm", output_handle);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;  // Ownership transferred to tuple

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("VSA batch result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("VSA batch operation failed");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    status = write_python_object_to_shared_memory(py_result, output_handle);

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_ann_search(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold) {
    
    if (k <= 0) {
        set_bridge_error("Invalid k parameter: %d", k);
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for ANN search");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("ann_search");
    if (operation_obj == NULL || PyDict_SetItemString(task_dict, "operation", operation_obj) != 0) {
        Py_XDECREF(operation_obj);
        set_bridge_error("Failed to set operation type");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(operation_obj);

    PyObject* k_obj = PyLong_FromLong(k);
    if (k_obj == NULL || PyDict_SetItemString(task_dict, "k", k_obj) != 0) {
        Py_XDECREF(k_obj);
        set_bridge_error("Failed to set k parameter");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(k_obj);

    PyObject* threshold_obj = PyFloat_FromDouble(similarity_threshold);
    if (threshold_obj == NULL || PyDict_SetItemString(task_dict, "similarity_threshold", threshold_obj) != 0) {
        Py_XDECREF(threshold_obj);
        set_bridge_error("Failed to set similarity threshold");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }
    Py_DECREF(threshold_obj);

    status = add_handle_entry(task_dict, "query_shm", query_handle);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    status = add_handle_entry(task_dict, "results_shm", results_handle);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("ANN search result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("ANN search operation failed");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    status = write_python_object_to_shared_memory(py_result, results_handle);

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_add_vector(
    int64_t vector_id,
    const SharedMemoryHandle* vector_handle,
    const char* index_name) {
    
    if (index_name == NULL || vector_handle == NULL || vector_handle->name == NULL) {
        set_bridge_error("Vector add requires index name and shared memory handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for add_vector");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("vector_operations");
    PyObject* action_obj = PyUnicode_FromString("put");
    PyObject* vector_op_obj = PyUnicode_FromString("add");
    PyObject* config_dict = PyDict_New();
    PyObject* oid_obj = PyUnicode_FromFormat("%lld", (long long)vector_id);
    PyObject* vector_id_obj = PyLong_FromLongLong(vector_id);
    PyObject* index_name_obj = PyUnicode_FromString(index_name);

    if (operation_obj == NULL || action_obj == NULL || vector_op_obj == NULL ||
        config_dict == NULL || oid_obj == NULL || vector_id_obj == NULL || index_name_obj == NULL) {
        Py_XDECREF(operation_obj);
        Py_XDECREF(action_obj);
        Py_XDECREF(vector_op_obj);
        Py_XDECREF(config_dict);
        Py_XDECREF(oid_obj);
        Py_XDECREF(vector_id_obj);
        Py_XDECREF(index_name_obj);
        set_bridge_error("Failed to allocate vector add request objects");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    if (PyDict_SetItemString(task_dict, "operation", operation_obj) != 0 ||
        PyDict_SetItemString(task_dict, "action", action_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_operation", vector_op_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_id", vector_id_obj) != 0) {
        Py_DECREF(operation_obj);
        Py_DECREF(action_obj);
        Py_DECREF(vector_op_obj);
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(vector_id_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to populate vector add request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(operation_obj);
    Py_DECREF(action_obj);
    Py_DECREF(vector_op_obj);
    Py_DECREF(vector_id_obj);

    if (PyDict_SetItemString(config_dict, "oid", oid_obj) != 0 ||
        PyDict_SetItemString(config_dict, "index_name", index_name_obj) != 0) {
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to configure vector add request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(oid_obj);
    Py_DECREF(index_name_obj);

    status = add_handle_entry(config_dict, "vector_shm", vector_handle);
    if (status != BRIDGE_SUCCESS) {
        Py_DECREF(config_dict);
        goto cleanup;
    }

    if (PyDict_SetItemString(task_dict, "config", config_dict) != 0) {
        Py_DECREF(config_dict);
        set_bridge_error("Failed to attach vector add config");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(config_dict);

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("Vector add result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("Vector add operation failed");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_update_vector(
    int64_t vector_id,
    const SharedMemoryHandle* vector_handle,
    const char* index_name) {
    
    if (index_name == NULL || vector_handle == NULL || vector_handle->name == NULL) {
        set_bridge_error("Vector update requires index name and shared memory handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for update_vector");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("vector_operations");
    PyObject* action_obj = PyUnicode_FromString("put");
    PyObject* vector_op_obj = PyUnicode_FromString("update");
    PyObject* config_dict = PyDict_New();
    PyObject* oid_obj = PyUnicode_FromFormat("%lld", (long long)vector_id);
    PyObject* vector_id_obj = PyLong_FromLongLong(vector_id);
    PyObject* index_name_obj = PyUnicode_FromString(index_name);

    if (operation_obj == NULL || action_obj == NULL || vector_op_obj == NULL ||
        config_dict == NULL || oid_obj == NULL || vector_id_obj == NULL || index_name_obj == NULL) {
        Py_XDECREF(operation_obj);
        Py_XDECREF(action_obj);
        Py_XDECREF(vector_op_obj);
        Py_XDECREF(config_dict);
        Py_XDECREF(oid_obj);
        Py_XDECREF(vector_id_obj);
        Py_XDECREF(index_name_obj);
        set_bridge_error("Failed to allocate vector update request objects");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    if (PyDict_SetItemString(task_dict, "operation", operation_obj) != 0 ||
        PyDict_SetItemString(task_dict, "action", action_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_operation", vector_op_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_id", vector_id_obj) != 0) {
        Py_DECREF(operation_obj);
        Py_DECREF(action_obj);
        Py_DECREF(vector_op_obj);
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(vector_id_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to populate vector update request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(operation_obj);
    Py_DECREF(action_obj);
    Py_DECREF(vector_op_obj);
    Py_DECREF(vector_id_obj);

    if (PyDict_SetItemString(config_dict, "oid", oid_obj) != 0 ||
        PyDict_SetItemString(config_dict, "index_name", index_name_obj) != 0) {
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to configure vector update request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(oid_obj);
    Py_DECREF(index_name_obj);

    status = add_handle_entry(config_dict, "vector_shm", vector_handle);
    if (status != BRIDGE_SUCCESS) {
        Py_DECREF(config_dict);
        goto cleanup;
    }

    if (PyDict_SetItemString(task_dict, "config", config_dict) != 0) {
        Py_DECREF(config_dict);
        set_bridge_error("Failed to attach vector update config");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(config_dict);

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("Vector update result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("Vector update operation failed");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

BridgeResult bridge_remove_vector(int64_t vector_id, const char* index_name) {
    if (index_name == NULL) {
        set_bridge_error("Index name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    BridgeResult status = BRIDGE_SUCCESS;
    GILGuard guard = acquire_gil();
    if (!guard.active) {
        set_bridge_error("Unable to acquire Python GIL for remove_vector");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* task_dict = PyDict_New();
    PyObject* args = NULL;
    PyObject* py_result = NULL;

    if (task_dict == NULL) {
        set_bridge_error("Failed to create task dictionary");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyObject* operation_obj = PyUnicode_FromString("vector_operations");
    PyObject* action_obj = PyUnicode_FromString("remove");
    PyObject* vector_op_obj = PyUnicode_FromString("remove");
    PyObject* config_dict = PyDict_New();
    PyObject* oid_obj = PyUnicode_FromFormat("%lld", (long long)vector_id);
    PyObject* vector_id_obj = PyLong_FromLongLong(vector_id);
    PyObject* index_name_obj = PyUnicode_FromString(index_name);

    if (operation_obj == NULL || action_obj == NULL || vector_op_obj == NULL ||
        config_dict == NULL || oid_obj == NULL || vector_id_obj == NULL || index_name_obj == NULL) {
        Py_XDECREF(operation_obj);
        Py_XDECREF(action_obj);
        Py_XDECREF(vector_op_obj);
        Py_XDECREF(config_dict);
        Py_XDECREF(oid_obj);
        Py_XDECREF(vector_id_obj);
        Py_XDECREF(index_name_obj);
        set_bridge_error("Failed to allocate vector remove request objects");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    if (PyDict_SetItemString(task_dict, "operation", operation_obj) != 0 ||
        PyDict_SetItemString(task_dict, "action", action_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_operation", vector_op_obj) != 0 ||
        PyDict_SetItemString(task_dict, "vector_id", vector_id_obj) != 0) {
        Py_DECREF(operation_obj);
        Py_DECREF(action_obj);
        Py_DECREF(vector_op_obj);
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(vector_id_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to populate vector remove request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(operation_obj);
    Py_DECREF(action_obj);
    Py_DECREF(vector_op_obj);
    Py_DECREF(vector_id_obj);

    if (PyDict_SetItemString(config_dict, "oid", oid_obj) != 0 ||
        PyDict_SetItemString(config_dict, "index_name", index_name_obj) != 0) {
        Py_DECREF(config_dict);
        Py_DECREF(oid_obj);
        Py_DECREF(index_name_obj);
        set_bridge_error("Failed to configure vector remove request");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(oid_obj);
    Py_DECREF(index_name_obj);

    if (PyDict_SetItemString(task_dict, "config", config_dict) != 0) {
        Py_DECREF(config_dict);
        set_bridge_error("Failed to attach vector remove config");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    Py_DECREF(config_dict);

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to create argument tuple");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, task_dict);
    task_dict = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    PyObject* success_obj = PyDict_GetItemString(py_result, "success");
    if (success_obj == NULL) {
        set_bridge_error("Vector remove result missing 'success' field");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    int success = PyObject_IsTrue(success_obj);
    if (success != 1) {
        set_bridge_error("Vector remove operation failed");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

cleanup:
    Py_XDECREF(task_dict);
    Py_XDECREF(args);
    Py_XDECREF(py_result);
    release_gil(&guard);
    return status;
}

    static BridgeResult read_json_from_shared_memory(const SharedMemoryHandle* handle, char** out_json, size_t* out_length) {
        if (out_json == NULL) {
            set_bridge_error("Output parameter for shared memory read is NULL");
            return BRIDGE_ERROR_NULL_POINTER;
        }

        *out_json = NULL;

        if (handle == NULL || handle->name == NULL) {
            set_bridge_error("Shared memory handle is NULL");
            return BRIDGE_ERROR_NULL_POINTER;
        }

        void* mapped_ptr = NULL;
        BridgeResult status = bridge_map_shared_memory(handle, &mapped_ptr);
        if (status != BRIDGE_SUCCESS) {
            return status;
        }

        const char* raw_data = (const char*)mapped_ptr;
        size_t max_len = handle->size;
        size_t actual_len = strnlen(raw_data, max_len);

        if (actual_len == max_len) {
            bridge_unmap_shared_memory(handle, mapped_ptr);
            set_bridge_error("Shared memory payload is not null-terminated");
            return BRIDGE_ERROR_SHARED_MEMORY;
        }

        char* copy = (char*)malloc(actual_len + 1);
        if (copy == NULL) {
            bridge_unmap_shared_memory(handle, mapped_ptr);
            set_bridge_error("Failed to allocate buffer for shared memory payload");
            return BRIDGE_ERROR_MEMORY_ALLOCATION;
        }

        memcpy(copy, raw_data, actual_len);
        copy[actual_len] = '\0';

        BridgeResult unmap_status = bridge_unmap_shared_memory(handle, mapped_ptr);
        if (unmap_status != BRIDGE_SUCCESS) {
            free(copy);
            return unmap_status;
        }

        *out_json = copy;
        if (out_length) {
            *out_length = actual_len;
        }

        return BRIDGE_SUCCESS;
    }

    static BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json, size_t length) {
        if (handle == NULL || handle->name == NULL) {
            set_bridge_error("Shared memory handle is NULL");
            return BRIDGE_ERROR_NULL_POINTER;
        }

        if (json == NULL) {
            json = "";
            length = 0;
        }

        void* mapped_ptr = NULL;
        BridgeResult status = bridge_map_shared_memory(handle, &mapped_ptr);
        if (status != BRIDGE_SUCCESS) {
            return status;
        }

        size_t required = length + 1; // include space for null terminator
        if (handle->size < required) {
            bridge_unmap_shared_memory(handle, mapped_ptr);
            set_bridge_error("Result buffer too small (required %zu, available %zu)", required, handle->size);
            return BRIDGE_ERROR_SHARED_MEMORY;
        }

        memcpy(mapped_ptr, json, length);
        ((char*)mapped_ptr)[length] = '\0';

        if (handle->size > required) {
            memset(((char*)mapped_ptr) + required, 0, handle->size - required);
        }

        return bridge_unmap_shared_memory(handle, mapped_ptr);
    }

BridgeResult bridge_submit_json_task(
    const SharedMemoryHandle* request_handle,
    const SharedMemoryHandle* response_handle) {

    if (request_handle == NULL || request_handle->name == NULL) {
        set_bridge_error("JSON task request handle is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (response_handle == NULL || response_handle->name == NULL) {
        set_bridge_error("JSON task response handle is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (!g_python_initialized || g_submit_task_func == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    char* request_json = NULL;
    BridgeResult status = read_json_from_shared_memory(request_handle, &request_json, NULL);
    if (status != BRIDGE_SUCCESS) {
        return status;
    }

    GILGuard guard = acquire_gil();
    if (!guard.active) {
        free(request_json);
        set_bridge_error("Unable to acquire Python GIL for JSON task");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* json_module = NULL;
    PyObject* loads_func = NULL;
    PyObject* dumps_func = NULL;
    PyObject* request_obj = NULL;
    PyObject* args = NULL;
    PyObject* py_result = NULL;
    PyObject* response_json_obj = NULL;

    json_module = PyImport_ImportModule("json");
    if (json_module == NULL) {
        set_bridge_error("Failed to import Python json module");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    loads_func = PyObject_GetAttrString(json_module, "loads");
    dumps_func = PyObject_GetAttrString(json_module, "dumps");
    if (loads_func == NULL || dumps_func == NULL) {
        set_bridge_error("Python json module missing loads/dumps");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    request_obj = PyObject_CallFunction(loads_func, "s", request_json);
    if (request_obj == NULL) {
        set_bridge_error("Failed to decode JSON request payload");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    args = PyTuple_New(1);
    if (args == NULL) {
        set_bridge_error("Failed to allocate argument tuple for JSON task");
        status = BRIDGE_ERROR_MEMORY_ALLOCATION;
        goto cleanup;
    }

    PyTuple_SET_ITEM(args, 0, request_obj);
    request_obj = NULL;

    py_result = call_python_function(g_submit_task_func, args);
    Py_DECREF(args);
    args = NULL;

    if (py_result == NULL) {
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    response_json_obj = PyObject_CallFunction(dumps_func, "O", py_result);
    if (response_json_obj == NULL) {
        set_bridge_error("Failed to encode JSON task response");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    const char* response_cstr = PyUnicode_AsUTF8(response_json_obj);
    if (response_cstr == NULL) {
        set_bridge_error("Failed to extract UTF-8 from JSON response");
        status = BRIDGE_ERROR_PYTHON_EXCEPTION;
        goto cleanup;
    }

    status = write_json_to_shared_memory(response_handle, response_cstr, strlen(response_cstr));

cleanup:
    Py_XDECREF(response_json_obj);
    Py_XDECREF(py_result);
    Py_XDECREF(dumps_func);
    Py_XDECREF(loads_func);
    Py_XDECREF(json_module);
    Py_XDECREF(request_obj);
    Py_XDECREF(args);

    release_gil(&guard);
    free(request_json);
    return status;
}

    #ifdef HAVE_IOVM
    static const char* io_object_key_to_cstring(IoState* state, IoObject* key, char* buffer, size_t buffer_size) {
        if (key == NULL) {
            return "";
        }

        if (ISSEQ(key)) {
            return IoSeq_asCString((IoSeq*)key);
        }

        if (ISNUMBER(key)) {
            if (buffer_size > 0) {
                snprintf(buffer, buffer_size, "%.17g", IoNumber_asDouble((IoNumber*)key));
                buffer[buffer_size - 1] = '\0';
            }
            return buffer;
        }

        if (key == state->ioTrue) {
            return "true";
        }
        if (key == state->ioFalse) {
            return "false";
        }
        if (key == state->ioNil) {
            return "nil";
        }

        const char* name = IoObject_name(key);
        if (name != NULL) {
            return name;
        }

        if (buffer_size > 0) {
            snprintf(buffer, buffer_size, "object_%p", (void*)key);
            buffer[buffer_size - 1] = '\0';
        }
        return buffer;
    }

    static JSON_Value* io_object_to_json_value(IoState* state, IoObject* object);

    static JSON_Value* io_list_to_json_array(IoState* state, IoList* list) {
        JSON_Value* array_value = json_value_init_array();
        if (array_value == NULL) {
            return NULL;
        }

        JSON_Array* array = json_value_get_array(array_value);
        size_t count = IoList_rawSize(list);

        for (size_t i = 0; i < count; i++) {
            IoObject* element = IoList_rawAt_(list, (int)i);
            JSON_Value* child = io_object_to_json_value(state, element);
            if (child == NULL) {
                json_value_free(array_value);
                return NULL;
            }
            if (json_array_append_value(array, child) != JSONSuccess) {
                json_value_free(child);
                json_value_free(array_value);
                return NULL;
            }
        }

        return array_value;
    }

    static JSON_Value* io_map_to_json_object(IoState* state, IoMap* map) {
        JSON_Value* object_value = json_value_init_object();
        if (object_value == NULL) {
            return NULL;
        }

        JSON_Object* json_object = json_value_get_object(object_value);
        PHash* hash = IoMap_rawHash(map);

        PHASH_FOREACH(hash, key, value, {
            IoObject* ioKey = (IoObject*)key;
            IoObject* ioValue = (IoObject*)value;
            char buffer[64];
            const char* key_cstr = io_object_key_to_cstring(state, ioKey, buffer, sizeof(buffer));
            JSON_Value* child = io_object_to_json_value(state, ioValue);
            if (child == NULL) {
                json_value_free(object_value);
                return NULL;
            }
            if (json_object_set_value(json_object, key_cstr, child) != JSONSuccess) {
                json_value_free(child);
                json_value_free(object_value);
                return NULL;
            }
        });

        return object_value;
    }

    static JSON_Value* io_object_to_json_value(IoState* state, IoObject* object) {
        if (object == NULL || object == state->ioNil) {
            return json_value_init_null();
        }

        if (object == state->ioTrue) {
            return json_value_init_boolean(1);
        }

        if (object == state->ioFalse) {
            return json_value_init_boolean(0);
        }

        if (ISNUMBER(object)) {
            return json_value_init_number(IoNumber_asDouble((IoNumber*)object));
        }

        if (ISSEQ(object)) {
            const char* str = IoSeq_asCString((IoSeq*)object);
            return json_value_init_string(str ? str : "");
        }

        if (ISLIST(object)) {
            return io_list_to_json_array(state, (IoList*)object);
        }

        if (ISMAP(object)) {
            return io_map_to_json_object(state, (IoMap*)object);
        }

        const char* description = IoObject_name(object);
        return json_value_init_string(description ? description : "object");
    }

    static IoObject* json_value_to_io_object(IoState* state, JSON_Value* value) {
        if (value == NULL) {
            return NULL;
        }

        switch (json_value_get_type(value)) {
            case JSONNull:
                return state->ioNil;
            case JSONBoolean:
                return json_value_get_boolean(value) ? state->ioTrue : state->ioFalse;
            case JSONNumber:
                return (IoObject*)IoNumber_newWithDouble_(state, json_value_get_number(value));
            case JSONString:
                return (IoObject*)IoSeq_newWithCString_(state, json_value_get_string(value));
            case JSONArray: {
                JSON_Array* array = json_value_get_array(value);
                IoList* list = IoList_new(state);
                size_t count = json_array_get_count(array);
                for (size_t i = 0; i < count; i++) {
                    IoObject* element = json_value_to_io_object(state, json_array_get_value(array, i));
                    if (element == NULL) {
                        return NULL;
                    }
                    IoList_rawAppend_(list, element);
                }
                return (IoObject*)list;
            }
            case JSONObject: {
                JSON_Object* json_object = json_value_get_object(value);
                IoMap* map = IoMap_new(state);
                size_t count = json_object_get_count(json_object);
                for (size_t i = 0; i < count; i++) {
                    const char* key = json_object_get_name(json_object, i);
                    JSON_Value* entry_value = json_object_get_value_at(json_object, i);
                    IoObject* io_value = json_value_to_io_object(state, entry_value);
                    if (io_value == NULL) {
                        return NULL;
                    }
                    IoSymbol* key_symbol = IoState_symbolWithCString_(state, key ? key : "");
                    IoMap_rawAtPut(map, key_symbol, io_value);
                }
                return (IoObject*)map;
            }
            case JSONError:
            default:
                return NULL;
        }
    }
    #endif /* HAVE_IOVM */

/* =============================================================================
 * Message Passing and Object Communication
 * =============================================================================
 */

BridgeResult bridge_send_message(
    IoObjectHandle target_handle,
    const char* message_name,
    const SharedMemoryHandle* args_handle,
    const SharedMemoryHandle* result_handle) {
    
    if (target_handle == NULL || message_name == NULL) {
        set_bridge_error("Target handle and message name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    IoObject* target = (IoObject*)target_handle;
    if (target == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(target);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* message_symbol = IoState_symbolWithCString_(state, message_name);
    if (message_symbol == NULL) {
        set_bridge_error("Failed to resolve message symbol '%s'", message_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    IoSymbol* label_symbol = IoState_symbolWithCString_(state, "bridge_send_message");
    IoMessage* message = IoMessage_newWithName_label_(state, message_symbol, label_symbol);
    if (message == NULL) {
        set_bridge_error("Failed to allocate Io message for '%s'", message_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    char* args_json = NULL;
    JSON_Value* args_root = NULL;
    BridgeResult status = BRIDGE_SUCCESS;

    if (args_handle != NULL && args_handle->name != NULL) {
        status = read_json_from_shared_memory(args_handle, &args_json, NULL);
        if (status != BRIDGE_SUCCESS) {
            goto cleanup;
        }

        args_root = json_parse_string(args_json);
        if (args_root == NULL || json_value_get_type(args_root) != JSONArray) {
            set_bridge_error("Shared memory arguments must encode a JSON array");
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        JSON_Array* args_array = json_value_get_array(args_root);
        size_t arg_count = json_array_get_count(args_array);
        for (size_t i = 0; i < arg_count; i++) {
            JSON_Value* arg_value = json_array_get_value(args_array, i);
            IoObject* io_arg = json_value_to_io_object(state, arg_value);
            if (io_arg == NULL) {
                set_bridge_error("Unsupported argument type at index %zu", i);
                status = BRIDGE_ERROR_SHARED_MEMORY;
                goto cleanup;
            }
            IoMessage_addCachedArg_(message, io_arg);
        }
    }

    IoObject* result_obj = IoMessage_locals_performOn_(message, target, target);
    if (result_obj == NULL) {
        result_obj = state->ioNil;
    }

    if (result_handle != NULL && result_handle->name != NULL) {
        JSON_Value* result_json = io_object_to_json_value(state, result_obj);
        if (result_json == NULL) {
            set_bridge_error("Failed to serialize Io result to JSON");
            status = BRIDGE_ERROR_PYTHON_EXCEPTION;
            goto cleanup;
        }

        char* serialized = json_serialize_to_string(result_json);
        if (serialized == NULL) {
            json_value_free(result_json);
            set_bridge_error("Failed to serialize JSON result to string");
            status = BRIDGE_ERROR_MEMORY_ALLOCATION;
            goto cleanup;
        }

        status = write_json_to_shared_memory(result_handle, serialized, strlen(serialized));
        json_free_serialized_string(serialized);
        json_value_free(result_json);

        if (status != BRIDGE_SUCCESS) {
            goto cleanup;
        }
    }

cleanup:
    if (args_root) {
        json_value_free(args_root);
    }
    if (args_json) {
        free(args_json);
    }

    return status;
#endif
}

BridgeResult bridge_get_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* result_handle) {
    
    if (object_handle == NULL || slot_name == NULL) {
        set_bridge_error("Object handle and slot name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    IoObject* object = (IoObject*)object_handle;
    if (object == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(object);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* slot_symbol = IoState_symbolWithCString_(state, slot_name);
    if (slot_symbol == NULL) {
        set_bridge_error("Failed to resolve slot symbol '%s'", slot_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    IoObject* value = IoObject_getSlot_(object, slot_symbol);
    if (value == NULL) {
        set_bridge_error("Slot '%s' not found on Io object", slot_name);
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    if (result_handle != NULL && result_handle->name != NULL) {
        JSON_Value* result_json = io_object_to_json_value(state, value);
        if (result_json == NULL) {
            set_bridge_error("Failed to serialize Io slot to JSON");
            return BRIDGE_ERROR_PYTHON_EXCEPTION;
        }

        char* serialized = json_serialize_to_string(result_json);
        if (serialized == NULL) {
            json_value_free(result_json);
            set_bridge_error("Failed to serialize JSON result to string");
            return BRIDGE_ERROR_MEMORY_ALLOCATION;
        }

        BridgeResult status = write_json_to_shared_memory(result_handle, serialized, strlen(serialized));
        json_free_serialized_string(serialized);
        json_value_free(result_json);
        return status;
    }

    return BRIDGE_SUCCESS;
#endif
}

BridgeResult bridge_set_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* value_handle) {
    
    if (object_handle == NULL || slot_name == NULL) {
        set_bridge_error("Object handle and slot name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    if (value_handle == NULL || value_handle->name == NULL) {
        set_bridge_error("Shared memory handle for value is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    IoObject* object = (IoObject*)object_handle;
    if (object == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(object);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* slot_symbol = IoState_symbolWithCString_(state, slot_name);
    if (slot_symbol == NULL) {
        set_bridge_error("Failed to resolve slot symbol '%s'", slot_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    char* value_json = NULL;
    JSON_Value* root = NULL;
    BridgeResult status = read_json_from_shared_memory(value_handle, &value_json, NULL);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    root = json_parse_string(value_json);
    if (root == NULL) {
        set_bridge_error("Shared memory value must encode valid JSON");
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    IoObject* value_object = json_value_to_io_object(state, root);
    if (value_object == NULL) {
        set_bridge_error("Unsupported value type for slot '%s'", slot_name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    IoObject_setSlot_to_(object, slot_symbol, value_object);
    status = BRIDGE_SUCCESS;

cleanup:
    if (root) {
        json_value_free(root);
    }
    if (value_json) {
        free(value_json);
    }
    return status;
#endif
}