/*
Prototypal FFI Implementation - Pure C Approach
==============================================

This implements rigorous FFI patterns while maintaining full compatibility
with Io's prototypal philosophy. Uses pure C to avoid C++ static type
system conflicts with Io's dynamic object model.

Key Principles:
1. Everything flows through message passing
2. No static hierarchies - only function dispatch
3. Explicit memory management integrated with Io GC
4. Python objects wrapped as Io CData with proper cleanup
5. Error handling through Io exception objects, not C++ exceptions

Philosophy: The FFI should be a transparent membrane, not a rigid boundary.
*/

#include "IoTelos.h"
#include "IoList.h"
#include "IoNumber.h"
#include <Python.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Forward declarations
PyObject* FFI_marshalIoObject(IoObject* io_obj);
void FFI_propagateError(IoState* state);
IoObject* FFI_handleWillFree(IoObject* self, IoObject* locals, IoMessage* m);

// =============================================================================
// Prototypal FFI State Management
// =============================================================================

typedef struct {
    PyObject* process_pool;          // ProcessPoolExecutor for GIL quarantine
    PyObject* concurrent_futures;    // concurrent.futures module
    char* venv_path;                 // Virtual environment path
    int is_initialized;              // Initialization state
    int python_initialized;          // Python interpreter state
} PrototypalFFI;

static PrototypalFFI* global_ffi = NULL;

// =============================================================================
// Memory Management - Prototypal Integration
// =============================================================================

typedef struct {
    PyObject* python_object;    // Python object reference
    IoObject* io_wrapper;       // Io wrapper object
    int gc_registered;          // GC registration state
} FFIObjectHandle;

// Create Io-managed handle for Python object
FFIObjectHandle* FFI_createHandle(IoState* state, PyObject* py_obj) {
    if (!py_obj) return NULL;
    
    FFIObjectHandle* handle = (FFIObjectHandle*)calloc(1, sizeof(FFIObjectHandle));
    if (!handle) return NULL;
    
    // Increment Python reference count
    Py_INCREF(py_obj);
    handle->python_object = py_obj;
    
    // Create Io Object wrapper
    handle->io_wrapper = IoObject_new(state);
    IoObject_setDataPointer_(handle->io_wrapper, handle);
    
    // Register with Io GC and set cleanup callback  
    IoObject_addMethod_(handle->io_wrapper, IoState_symbolWithCString_(state, "willFree"), (IoMethodFunc*)FFI_handleWillFree);
    IoState_stackRetain_(state, handle->io_wrapper);
    handle->gc_registered = 1;
    
    return handle;
}

// Cleanup callback for FFI handles
// Cleanup method for FFI handles (called by Io GC)
IoObject* FFI_handleWillFree(IoObject* self, IoObject* locals, IoMessage* m) {
    FFIObjectHandle* handle = (FFIObjectHandle*)IoObject_dataPointer(self);
    if (!handle) return IONIL(IoObject_state(self));
    
    // Release Python reference
    if (handle->python_object) {
        Py_DECREF(handle->python_object);
        handle->python_object = NULL;
    }
    
    handle->gc_registered = 0;
    free(handle);
    IoObject_setDataPointer_(self, NULL);
    
    return IONIL(IoObject_state(self));
}

// =============================================================================
// Python Virtual Environment Management
// =============================================================================

int FFI_initializePythonEnvironment(const char* venv_path) {
    if (global_ffi && global_ffi->is_initialized) {
        return 1; // Already initialized
    }
    
    if (!global_ffi) {
        global_ffi = (PrototypalFFI*)calloc(1, sizeof(PrototypalFFI));
        if (!global_ffi) return 0;
    }
    
    // Store virtual environment path
    if (venv_path) {
        global_ffi->venv_path = strdup(venv_path);
    }
    
    // Initialize Python with virtual environment
    if (!Py_IsInitialized()) {
        PyConfig config;
        PyConfig_InitIsolatedConfig(&config);
        
        if (venv_path) {
            char python_exe[512];
            snprintf(python_exe, sizeof(python_exe), "%s/bin/python", venv_path);
            
            PyStatus status = PyConfig_SetBytesString(&config, &config.executable, python_exe);
            if (PyStatus_Exception(status)) {
                printf("FFI: Failed to set Python executable: %s\n", python_exe);
                PyConfig_Clear(&config);
                return 0;
            }
        }
        
        PyStatus status = Py_InitializeFromConfig(&config);
        PyConfig_Clear(&config);
        
        if (PyStatus_Exception(status)) {
            printf("FFI: Python initialization failed\n");
            return 0;
        }
        
        global_ffi->python_initialized = 1;
    }
    
    // Initialize ProcessPoolExecutor for GIL quarantine
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    global_ffi->concurrent_futures = PyImport_ImportModule("concurrent.futures");
    if (!global_ffi->concurrent_futures) {
        PyErr_Print();
        PyGILState_Release(gstate);
        return 0;
    }
    
    PyObject* executor_class = PyObject_GetAttrString(global_ffi->concurrent_futures, "ProcessPoolExecutor");
    if (!executor_class) {
        PyErr_Print();
        PyGILState_Release(gstate);
        return 0;
    }
    
    // Create process pool with 2 workers
    PyObject* args = PyTuple_New(0);
    PyObject* kwargs = PyDict_New();
    PyDict_SetItemString(kwargs, "max_workers", PyLong_FromLong(2));
    
    global_ffi->process_pool = PyObject_Call(executor_class, args, kwargs);
    
    Py_DECREF(args);
    Py_DECREF(kwargs);
    Py_DECREF(executor_class);
    
    if (!global_ffi->process_pool) {
        PyErr_Print();
        PyGILState_Release(gstate);
        return 0;
    }
    
    PyGILState_Release(gstate);
    
    global_ffi->is_initialized = 1;
    printf("Prototypal FFI initialized with venv: %s\n", venv_path ? venv_path : "system");
    
    return 1;
}

// =============================================================================
// Data Marshalling - Pure C Implementation
// =============================================================================

// Marshal Io Number to Python float
PyObject* FFI_marshalIoNumber(IoObject* io_obj) {
    if (!ISNUMBER(io_obj)) {
        PyErr_SetString(PyExc_TypeError, "Expected Io Number");
        return NULL;
    }
    
    double value = IoNumber_asDouble(io_obj);
    return PyFloat_FromDouble(value);
}

// Marshal Python float to Io Number
IoObject* FFI_marshalPythonNumber(IoState* state, PyObject* py_obj) {
    if (!PyFloat_Check(py_obj) && !PyLong_Check(py_obj)) {
        IoState_error_(state, 0, "Expected Python number");
        return state->ioNil;
    }
    
    double value = PyFloat_AsDouble(py_obj);
    if (PyErr_Occurred()) {
        FFI_propagateError(state);
        return state->ioNil;
    }
    
    return (IoObject*)IoNumber_newWithDouble_(state, value);
}

// Marshal Io Sequence to Python string
PyObject* FFI_marshalIoSequence(IoObject* io_obj) {
    if (!ISSEQ(io_obj)) {
        PyErr_SetString(PyExc_TypeError, "Expected Io Sequence");
        return NULL;
    }
    
    const char* cstring = CSTRING(io_obj);
    return PyUnicode_FromString(cstring);
}

// Marshal Python string to Io Sequence
IoObject* FFI_marshalPythonString(IoState* state, PyObject* py_obj) {
    if (!PyUnicode_Check(py_obj)) {
        IoState_error_(state, 0, "Expected Python string");
        return state->ioNil;
    }
    
    const char* utf8_str = PyUnicode_AsUTF8(py_obj);
    if (!utf8_str) {
        FFI_propagateError(state);
        return state->ioNil;
    }
    
    return IoState_symbolWithCString_(state, utf8_str);
}

// Marshal Io List to Python list (recursive)
PyObject* FFI_marshalIoList(IoObject* io_obj) {
    if (!ISLIST(io_obj)) {
        PyErr_SetString(PyExc_TypeError, "Expected Io List");
        return NULL;
    }
    
    List* list = IoList_rawList(io_obj);
    size_t size = List_size(list);
    
    PyObject* py_list = PyList_New(size);
    if (!py_list) return NULL;
    
    for (size_t i = 0; i < size; i++) {
        IoObject* item = (IoObject*)List_at_(list, i);
        PyObject* py_item = FFI_marshalIoObject(item);  // Recursive
        
        if (!py_item) {
            Py_DECREF(py_list);
            return NULL;
        }
        
        PyList_SET_ITEM(py_list, i, py_item);  // Steals reference
    }
    
    return py_list;
}

// Master marshalling dispatcher - prototypal approach
PyObject* FFI_marshalIoObject(IoObject* io_obj) {
    if (!io_obj) {
        Py_RETURN_NONE;
    }
    
    // Use Io's type system, not C++ static typing
    if (ISNUMBER(io_obj)) {
        return FFI_marshalIoNumber(io_obj);
    } else if (ISSEQ(io_obj)) {
        return FFI_marshalIoSequence(io_obj);
    } else if (ISLIST(io_obj)) {
        return FFI_marshalIoList(io_obj);
    } else {
        // For unknown types, return a handle
        PyErr_SetString(PyExc_TypeError, "Unsupported Io type for marshalling");
        return NULL;
    }
}

// =============================================================================
// Error Propagation - Prototypal Style
// =============================================================================

void FFI_propagateError(IoState* state) {
    if (!PyErr_Occurred()) return;
    
    PyObject *type, *value, *traceback;
    PyErr_Fetch(&type, &value, &traceback);
    
    // Create error message
    char error_msg[1024] = "Python error: ";
    
    if (value) {
        PyObject* str_value = PyObject_Str(value);
        if (str_value) {
            const char* msg = PyUnicode_AsUTF8(str_value);
            if (msg) {
                strncat(error_msg, msg, sizeof(error_msg) - strlen(error_msg) - 1);
            }
            Py_DECREF(str_value);
        }
    }
    
    // Clean up Python exception state
    Py_XDECREF(type);
    Py_XDECREF(value);
    Py_XDECREF(traceback);
    
    // Raise Io exception - prototypal error handling
    IoState_error_(state, 0, "%s", error_msg);
}

// =============================================================================
// Async Execution with GIL Quarantine
// =============================================================================

typedef struct {
    char* function_name;
    PyObject* arguments;
    PyObject* future;
} AsyncExecution;

PyObject* FFI_executeAsync(const char* function_name, PyObject* args) {
    if (!global_ffi || !global_ffi->is_initialized) {
        PyErr_SetString(PyExc_RuntimeError, "FFI not initialized");
        return NULL;
    }
    
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    // Submit to process pool
    PyObject* submit_method = PyObject_GetAttrString(global_ffi->process_pool, "submit");
    if (!submit_method) {
        PyGILState_Release(gstate);
        return NULL;
    }
    
    PyObject* func_name = PyUnicode_FromString(function_name);
    PyObject* submit_args = PyTuple_New(2);
    PyTuple_SET_ITEM(submit_args, 0, func_name);  // Steals reference
    PyTuple_SET_ITEM(submit_args, 1, args);       // Steals reference
    
    PyObject* future = PyObject_CallObject(submit_method, submit_args);
    
    Py_DECREF(submit_method);
    Py_DECREF(submit_args);
    
    PyGILState_Release(gstate);
    
    return future;
}

// =============================================================================
// Module Loading and Function Calling
// =============================================================================

PyObject* FFI_loadModule(const char* module_name) {
    if (!module_name) return NULL;
    
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    PyObject* module = PyImport_ImportModule(module_name);
    if (!module) {
        PyErr_Print();
    }
    
    PyGILState_Release(gstate);
    
    return module;
}

PyObject* FFI_callFunction(PyObject* module, const char* function_name, PyObject* args) {
    if (!module || !function_name) return NULL;
    
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    PyObject* function = PyObject_GetAttrString(module, function_name);
    if (!function) {
        PyGILState_Release(gstate);
        return NULL;
    }
    
    // Convert args to tuple if it's a list
    PyObject* args_tuple = NULL;
    if (args) {
        if (PyList_Check(args)) {
            args_tuple = PyList_AsTuple(args);
        } else if (PyTuple_Check(args)) {
            args_tuple = args;
            Py_INCREF(args_tuple);
        } else {
            // Single argument, wrap in tuple
            args_tuple = PyTuple_New(1);
            PyTuple_SET_ITEM(args_tuple, 0, args);
            Py_INCREF(args);
        }
    }
    
    PyObject* result = PyObject_CallObject(function, args_tuple);
    
    if (args_tuple && args_tuple != args) {
        Py_DECREF(args_tuple);
    }
    
    Py_DECREF(function);
    PyGILState_Release(gstate);
    
    return result;
}

// =============================================================================
// Cleanup and Shutdown
// =============================================================================

void FFI_shutdown() {
    if (!global_ffi) return;
    
    if (global_ffi->process_pool) {
        PyGILState_STATE gstate = PyGILState_Ensure();
        
        // Shutdown process pool
        PyObject* shutdown_method = PyObject_GetAttrString(global_ffi->process_pool, "shutdown");
        if (shutdown_method) {
            PyObject* args = PyTuple_New(0);
            PyObject* kwargs = PyDict_New();
            PyDict_SetItemString(kwargs, "wait", Py_True);
            
            PyObject_Call(shutdown_method, args, kwargs);
            
            Py_DECREF(args);
            Py_DECREF(kwargs);
            Py_DECREF(shutdown_method);
        }
        
        Py_DECREF(global_ffi->process_pool);
        global_ffi->process_pool = NULL;
        
        PyGILState_Release(gstate);
    }
    
    if (global_ffi->concurrent_futures) {
        Py_DECREF(global_ffi->concurrent_futures);
        global_ffi->concurrent_futures = NULL;
    }
    
    if (global_ffi->venv_path) {
        free(global_ffi->venv_path);
        global_ffi->venv_path = NULL;
    }
    
    if (global_ffi->python_initialized) {
        Py_Finalize();
        global_ffi->python_initialized = 0;
    }
    
    free(global_ffi);
    global_ffi = NULL;
    
    printf("Prototypal FFI shutdown complete\n");
}