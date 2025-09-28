#include "synaptic_bridge.h"
#include <Python.h>
#include <memoryobject.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

GILGuard acquire_gil_impl(void) {
    GILGuard guard = {0, NULL};

    if (Py_IsInitialized()) {
        guard.state = (void*)PyGILState_Ensure();
        guard.active = 1;
    }

    return guard;
}

void release_gil_impl(GILGuard* guard) {
    if (guard->active) {
        PyGILState_Release((PyGILState_STATE)guard->state);
        guard->active = 0;
    }
}

/* =============================================================================
 * Global State Management
 * =============================================================================
 */

SynapticBridgeState* g_bridge_state = NULL;

BridgeResult bridge_initialize_impl(const BridgeConfig* config) {
    if (g_bridge_state != NULL) {
        set_bridge_error("Bridge already initialized");
        return BRIDGE_ERROR_ALREADY_INITIALIZED;
    }

    if (config == NULL) {
        set_bridge_error("Configuration cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Initialize Python if not already initialized
    if (!Py_IsInitialized()) {
        Py_Initialize();
        if (!Py_IsInitialized()) {
            set_bridge_error("Failed to initialize Python");
            return BRIDGE_ERROR_PYTHON_EXCEPTION;
        }
    }

    g_bridge_state = (SynapticBridgeState*)malloc(sizeof(SynapticBridgeState));
    if (g_bridge_state == NULL) {
        set_bridge_error("Failed to allocate bridge state");
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    memset(g_bridge_state, 0, sizeof(SynapticBridgeState));

    // Initialize error buffer
    g_bridge_state->error_buffer[0] = '\0';
    g_bridge_state->error_length = 0;

    // Copy configuration
    g_bridge_state->config = *config;

    // Initialize shared memory pools
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        g_bridge_state->shared_memory_pools[i] = NULL;
    }

    // Initialize VSA bindings
    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        g_bridge_state->vsa_bindings[i].handle = NULL;
        g_bridge_state->vsa_bindings[i].name[0] = '\0';
    }

    // Initialize Python worker pool
    // Acquire GIL for Python operations
    GILGuard gil = acquire_gil_impl();
    if (!gil.active) {
        set_bridge_error("Failed to acquire Python GIL during initialization");
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    // Add the telos package directory to sys.path
    PyObject* sys_module = PyImport_ImportModule("sys");
    if (sys_module == NULL) {
        set_bridge_error("Failed to import sys module during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* sys_path = PyObject_GetAttrString(sys_module, "path");
    if (sys_path == NULL) {
        Py_DECREF(sys_module);
        set_bridge_error("Failed to get sys.path during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    const char* python_path = "/mnt/c/EntropicGarden/libs/Telos";
    PyObject* python_path_obj = PyUnicode_FromString(python_path);
    if (python_path_obj == NULL) {
        Py_DECREF(sys_path);
        Py_DECREF(sys_module);
        set_bridge_error("Failed to create python path string during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    if (PyList_Append(sys_path, python_path_obj) != 0) {
        Py_DECREF(python_path_obj);
        Py_DECREF(sys_path);
        Py_DECREF(sys_module);
        set_bridge_error("Failed to append to sys.path during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    Py_DECREF(python_path_obj);
    Py_DECREF(sys_path);
    Py_DECREF(sys_module);

    // Import workers module and initialize worker pool
    PyObject* workers_module = PyImport_ImportModule("telos.python.workers");
    if (workers_module == NULL) {
        set_bridge_error("Failed to import telos.python.workers module during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    PyObject* init_func = PyObject_GetAttrString(workers_module, "initialize_workers");
    if (init_func == NULL || !PyCallable_Check(init_func)) {
        Py_DECREF(workers_module);
        set_bridge_error("Failed to get initialize_workers function during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    // Call initialize_workers with the configured number of workers
    PyObject* result = PyObject_CallFunction(init_func, "i", config->max_workers);
    Py_DECREF(init_func);
    Py_DECREF(workers_module);

    if (result == NULL) {
        set_bridge_error("initialize_workers call failed during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    // Check if initialization was successful
    int init_success = PyObject_IsTrue(result);
    Py_DECREF(result);

    if (!init_success) {
        set_bridge_error("initialize_workers returned false during initialization");
        release_gil_impl(&gil);
        free(g_bridge_state);
        g_bridge_state = NULL;
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    // Release GIL
    release_gil_impl(&gil);

    log_bridge_message(LOG_LEVEL_INFO, "Synaptic Bridge initialized successfully with %d workers", config->max_workers);
    return BRIDGE_SUCCESS;
}

BridgeResult bridge_shutdown_impl(void) {
    if (g_bridge_state == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_NOT_INITIALIZED;
    }

    log_bridge_message(LOG_LEVEL_INFO, "Shutting down Synaptic Bridge");

    // Clean up shared memory pools
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        if (g_bridge_state->shared_memory_pools[i] != NULL) {
            destroy_shared_memory_pool(g_bridge_state->shared_memory_pools[i]);
            g_bridge_state->shared_memory_pools[i] = NULL;
        }
    }

    // Clean up VSA bindings
    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        if (g_bridge_state->vsa_bindings[i].handle != NULL) {
            // Note: VSA cleanup should be handled by the binding owner
            g_bridge_state->vsa_bindings[i].handle = NULL;
            g_bridge_state->vsa_bindings[i].name[0] = '\0';
        }
    }

    free(g_bridge_state);
    g_bridge_state = NULL;

    // Finalize Python if it was initialized by the bridge
    if (Py_IsInitialized()) {
        Py_Finalize();
    }

    log_bridge_message(LOG_LEVEL_INFO, "Synaptic Bridge shutdown complete");
    return BRIDGE_SUCCESS;
}

/* =============================================================================
 * Error Handling
 * =============================================================================
 */

void set_bridge_error(const char* format, ...) {
    if (g_bridge_state == NULL) {
        return;
    }

    va_list args;
    va_start(args, format);
    vsnprintf(g_bridge_state->error_buffer, sizeof(g_bridge_state->error_buffer), format, args);
    va_end(args);

    g_bridge_state->error_length = strlen(g_bridge_state->error_buffer);
    log_bridge_message(LOG_LEVEL_ERROR, "Bridge error: %s", g_bridge_state->error_buffer);
}

const char* get_bridge_error(void) {
    if (g_bridge_state == NULL) {
        return "Bridge not initialized";
    }
    return g_bridge_state->error_buffer;
}

size_t get_bridge_error_length(void) {
    if (g_bridge_state == NULL) {
        return 0;
    }
    return g_bridge_state->error_length;
}

void clear_bridge_error(void) {
    if (g_bridge_state != NULL) {
        g_bridge_state->error_buffer[0] = '\0';
        g_bridge_state->error_length = 0;
    }
}

/* =============================================================================
 * Logging
 * =============================================================================
 */

void log_bridge_message(LogLevel level, const char* format, ...) {
    if (g_bridge_state == NULL || g_bridge_state->config.log_callback == NULL) {
        return;
    }

    va_list args;
    va_start(args, format);
    char message[1024];
    vsnprintf(message, sizeof(message), format, args);
    va_end(args);

    g_bridge_state->config.log_callback(level, message);
}

/* =============================================================================
 * JSON Task Submission
 * ============================================================================= */

BridgeResult bridge_submit_json_task_impl(
    const SharedMemoryHandle* request_handle,
    const SharedMemoryHandle* response_handle
) {
    if (g_bridge_state == NULL) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_NOT_INITIALIZED;
    }

    if (request_handle == NULL || response_handle == NULL) {
        set_bridge_error("Request and response handles cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    printf("DEBUG: Starting bridge_submit_json_task_impl\n");

    // Acquire GIL for Python operations
    GILGuard gil = acquire_gil_impl();
    if (!gil.active) {
        set_bridge_error("Failed to acquire Python GIL");
        return BRIDGE_ERROR_PYTHON_EXCEPTION;
    }

    printf("DEBUG: Acquired GIL\n");

    BridgeResult result = BRIDGE_SUCCESS;
    PyObject* request_json = NULL;
    PyObject* response_dict = NULL;
    char* response_json_str = NULL;

    do {
        printf("DEBUG: Reading JSON from shared memory\n");
        // Read JSON from request shared memory
        char* request_json_str = NULL;
        size_t request_json_len = 0;
        
        result = read_json_from_shared_memory(request_handle, &request_json_str, &request_json_len);
        if (result != BRIDGE_SUCCESS) {
            break;
        }

        printf("DEBUG: Read %zu bytes from shared memory\n", request_json_len);

        printf("DEBUG: Parsing JSON string to Python object\n");
        // Parse JSON string to Python object
        request_json = PyUnicode_FromStringAndSize(request_json_str, request_json_len);
        if (request_json == NULL) {
            printf("DEBUG: PyUnicode_FromStringAndSize failed\n");
            set_bridge_error("Failed to parse request JSON");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: JSON string created, adding python directory to sys.path\n");
        // Add the python directory to sys.path so we can import the modules
        PyObject* sys_module = PyImport_ImportModule("sys");
        if (sys_module == NULL) {
            printf("DEBUG: Failed to import sys module\n");
            set_bridge_error("Failed to import sys module");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: sys module imported, getting sys.path\n");
        PyObject* sys_path = PyObject_GetAttrString(sys_module, "path");
        if (sys_path == NULL) {
            printf("DEBUG: Failed to get sys.path\n");
            Py_DECREF(sys_module);
            set_bridge_error("Failed to get sys.path");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: sys.path obtained, creating python path string\n");
        // Add the telos package directory to sys.path so we can import telos.python.workers
        // Use Unix path format since we're on WSL
        const char* python_path = "/mnt/c/EntropicGarden/libs/Telos";
        PyObject* python_path_obj = PyUnicode_FromString(python_path);
        if (python_path_obj == NULL) {
            printf("DEBUG: Failed to create python path string\n");
            Py_DECREF(sys_path);
            Py_DECREF(sys_module);
            set_bridge_error("Failed to create python path string");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: Python path string created, appending to sys.path\n");
        if (PyList_Append(sys_path, python_path_obj) != 0) {
            printf("DEBUG: PyList_Append failed\n");
            Py_DECREF(python_path_obj);
            Py_DECREF(sys_path);
            Py_DECREF(sys_module);
            set_bridge_error("Failed to append to sys.path");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: Python path appended to sys.path, cleaning up\n");
        Py_DECREF(python_path_obj);
        Py_DECREF(sys_path);
        Py_DECREF(sys_module);

        printf("DEBUG: Importing workers module\n");
        // Import the workers module and get submit_worker_task function
        PyObject* workers_module = PyImport_ImportModule("telos.python.workers");
        if (workers_module == NULL) {
            printf("DEBUG: PyImport_ImportModule('telos.python.workers') failed\n");
            set_bridge_error("Failed to import telos.python.workers module");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: Workers module imported, getting submit_worker_task function\n");
        PyObject* submit_func = PyObject_GetAttrString(workers_module, "submit_worker_task");
        if (submit_func == NULL || !PyCallable_Check(submit_func)) {
            printf("DEBUG: PyObject_GetAttrString failed or function not callable\n");
            Py_DECREF(workers_module);
            set_bridge_error("Failed to get submit_worker_task function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: submit_worker_task function obtained, importing json module\n");
        // Convert JSON string to Python dict using json.loads
        PyObject* json_module = PyImport_ImportModule("json");
        if (json_module == NULL) {
            printf("DEBUG: Failed to import json module\n");
            Py_DECREF(submit_func);
            Py_DECREF(workers_module);
            set_bridge_error("Failed to import json module");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: JSON module imported, getting loads function\n");
        PyObject* loads_func = PyObject_GetAttrString(json_module, "loads");
        if (loads_func == NULL || !PyCallable_Check(loads_func)) {
            printf("DEBUG: Failed to get json.loads function\n");
            Py_DECREF(json_module);
            Py_DECREF(submit_func);
            Py_DECREF(workers_module);
            set_bridge_error("Failed to get json.loads function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: Calling json.loads\n");
        PyObject* request_dict = PyObject_CallFunctionObjArgs(loads_func, request_json, NULL);
        Py_DECREF(loads_func);
        Py_DECREF(json_module);

        if (request_dict == NULL) {
            printf("DEBUG: json.loads call failed\n");
            Py_DECREF(submit_func);
            Py_DECREF(workers_module);
            set_bridge_error("Failed to parse request JSON to dict");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: JSON parsed to dict, calling submit_worker_task\n");
        // Call submit_worker_task
        response_dict = PyObject_CallFunctionObjArgs(submit_func, request_dict, NULL);
        Py_DECREF(request_dict);
        Py_DECREF(submit_func);
        Py_DECREF(workers_module);

        if (response_dict == NULL) {
            printf("DEBUG: submit_worker_task call failed\n");
            set_bridge_error("submit_worker_task call failed");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        printf("DEBUG: submit_worker_task completed successfully\n");

        // Convert response dict back to JSON string
        if (json_module == NULL) {
            json_module = PyImport_ImportModule("json");
            if (json_module == NULL) {
                set_bridge_error("Failed to import json module");
                result = BRIDGE_ERROR_PYTHON_EXCEPTION;
                break;
            }
        }

        PyObject* dumps_func = PyObject_GetAttrString(json_module, "dumps");
        if (dumps_func == NULL || !PyCallable_Check(dumps_func)) {
            Py_DECREF(json_module);
            set_bridge_error("Failed to get json.dumps function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        PyObject* response_json = PyObject_CallFunctionObjArgs(dumps_func, response_dict, NULL);
        Py_DECREF(dumps_func);
        Py_DECREF(json_module);

        if (response_json == NULL) {
            set_bridge_error("Failed to serialize response to JSON");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Convert Python string to C string
        Py_ssize_t response_json_len;
        response_json_str = (char*)PyUnicode_AsUTF8AndSize(response_json, &response_json_len);
        if (response_json_str == NULL) {
            Py_DECREF(response_json);
            set_bridge_error("Failed to convert response JSON to C string");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Write response JSON to shared memory
        result = write_json_to_shared_memory(response_handle, response_json_str, response_json_len);
        Py_DECREF(response_json);

    } while (0);

    // Clean up
    if (request_json) Py_DECREF(request_json);
    if (response_dict) Py_DECREF(response_dict);

    // Release GIL
    release_gil_impl(&gil);

    return result;
}

BridgeResult bridge_ann_search_impl(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold
) {
    if (!g_bridge_state) {
        set_bridge_error("Bridge not initialized");
        return BRIDGE_ERROR_NOT_INITIALIZED;
    }

    if (!query_handle || !results_handle) {
        set_bridge_error("Invalid handles provided to bridge_ann_search_impl");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Acquire GIL for Python operations
    GILGuard gil = acquire_gil_impl();

    PyObject* json_module = NULL;
    PyObject* submit_func = NULL;
    PyObject* workers_module = NULL;
    PyObject* request_dict = NULL;
    PyObject* response_dict = NULL;
    char* request_json_str = NULL;
    char* response_json_str = NULL;
    BridgeResult result = BRIDGE_SUCCESS;

    do {
        // Read JSON request from shared memory
        result = read_json_from_shared_memory(query_handle, &request_json_str, NULL);
        if (result != BRIDGE_SUCCESS) {
            set_bridge_error("Failed to read request from shared memory");
            break;
        }

        // Import required modules
        json_module = PyImport_ImportModule("json");
        if (json_module == NULL) {
            set_bridge_error("Failed to import json module");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        workers_module = PyImport_ImportModule("telos.python.workers");
        if (workers_module == NULL) {
            set_bridge_error("Failed to import telos.workers module");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        submit_func = PyObject_GetAttrString(workers_module, "submit_worker_task");
        if (submit_func == NULL || !PyCallable_Check(submit_func)) {
            set_bridge_error("Failed to get submit_worker_task function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        PyObject* loads_func = PyObject_GetAttrString(json_module, "loads");
        if (loads_func == NULL || !PyCallable_Check(loads_func)) {
            Py_DECREF(json_module);
            Py_DECREF(submit_func);
            Py_DECREF(workers_module);
            set_bridge_error("Failed to get json.loads function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        request_dict = PyObject_CallFunctionObjArgs(loads_func, PyUnicode_FromString(request_json_str), NULL);
        Py_DECREF(loads_func);
        Py_DECREF(json_module);

        if (request_dict == NULL) {
            Py_DECREF(submit_func);
            Py_DECREF(workers_module);
            set_bridge_error("Failed to parse request JSON to dict");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Add ANN search parameters to the request
        PyObject* k_obj = PyLong_FromLong(k);
        PyObject* threshold_obj = PyFloat_FromDouble(similarity_threshold);
        PyDict_SetItemString(request_dict, "k", k_obj);
        PyDict_SetItemString(request_dict, "similarity_threshold", threshold_obj);
        PyDict_SetItemString(request_dict, "operation", PyUnicode_FromString("ann_search"));
        Py_DECREF(k_obj);
        Py_DECREF(threshold_obj);

        // Call submit_worker_task
        response_dict = PyObject_CallFunctionObjArgs(submit_func, request_dict, NULL);
        Py_DECREF(request_dict);
        Py_DECREF(submit_func);
        Py_DECREF(workers_module);

        if (response_dict == NULL) {
            set_bridge_error("submit_worker_task call failed");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Convert response dict back to JSON string
        if (json_module == NULL) {
            json_module = PyImport_ImportModule("json");
            if (json_module == NULL) {
                set_bridge_error("Failed to import json module");
                result = BRIDGE_ERROR_PYTHON_EXCEPTION;
                break;
            }
        }

        PyObject* dumps_func = PyObject_GetAttrString(json_module, "dumps");
        if (dumps_func == NULL || !PyCallable_Check(dumps_func)) {
            Py_DECREF(json_module);
            set_bridge_error("Failed to get json.dumps function");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        PyObject* response_json = PyObject_CallFunctionObjArgs(dumps_func, response_dict, NULL);
        Py_DECREF(dumps_func);
        Py_DECREF(json_module);

        if (response_json == NULL) {
            set_bridge_error("Failed to serialize response to JSON");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Convert Python string to C string
        Py_ssize_t response_json_len;
        response_json_str = (char*)PyUnicode_AsUTF8AndSize(response_json, &response_json_len);
        if (response_json_str == NULL) {
            Py_DECREF(response_json);
            set_bridge_error("Failed to convert response JSON to C string");
            result = BRIDGE_ERROR_PYTHON_EXCEPTION;
            break;
        }

        // Write response JSON to shared memory
        result = write_json_to_shared_memory(results_handle, response_json_str, response_json_len);
        Py_DECREF(response_json);

    } while (0);

    // Clean up
    if (request_json_str) free(request_json_str);
    if (request_dict) Py_DECREF(request_dict);
    if (response_dict) Py_DECREF(response_dict);

    // Release GIL
    release_gil_impl(&gil);

    return result;
}