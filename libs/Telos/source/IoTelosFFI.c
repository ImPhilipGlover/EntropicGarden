/*
   IoTelosFFI.c - Modular FFI Implementation
   Prototypal FFI Bridge Implementation for TelOS Synaptic Bridge
   Extracted from monolithic IoTelos.c for targeted debugging and architecture clarity
*/

#include "IoTelosFFI.h"
#include "IoState.h"
#include "IoObject.h"
#include "IoMessage.h"
#include "IoSeq.h"
#include "IoNumber.h"
#include "IoList.h"
#include "IoMap.h"
#include "IoCFunction.h"
#include <Python.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>

// Global state management for enhanced synaptic bridge
static SynapticBridge synapticBridge = {0};
static SynapticBridge *globalBridge = NULL;
static CrossLanguageHandle *handles = NULL;
static int maxHandles = 1000;
static int handleCount = 0;
static int isPythonInitialized = 0;

// Forward message function implementation for IoProxy delegation
PyObject* IoTelosFFI_forwardMessage(PyObject *self, PyObject *args, PyObject *kwargs) {
    char *handle_id;
    char *message_name;
    PyObject *message_args = NULL;
    
    if (!PyArg_ParseTuple(args, "ss|O", &handle_id, &message_name, &message_args)) {
        return NULL;
    }
    
    printf("FFI: Forwarding message '%s' for handle '%s'\n", message_name, handle_id);
    
    // Find handle and get Io object
    CrossLanguageHandle *handle = NULL;
    for (int i = 0; i < maxHandles; i++) {
        if (handles[i].handleId && strcmp(handles[i].handleId, handle_id) == 0) {
            handle = &handles[i];
            break;
        }
    }
    
    if (!handle || !handle->ioObject) {
        PyErr_SetString(PyExc_ValueError, "Invalid handle or missing Io object");
        return NULL;
    }
    
    // Simulate Io message sending for now
    // TODO: Implement actual Io message dispatch
    if (strcmp(message_name, "protoId") == 0) {
        return PyUnicode_FromString("TelOS");
    } else if (strcmp(message_name, "slotNames") == 0) {
        PyObject *slot_list = PyList_New(3);
        PyList_SetItem(slot_list, 0, PyUnicode_FromString("name"));
        PyList_SetItem(slot_list, 1, PyUnicode_FromString("value"));
        PyList_SetItem(slot_list, 2, PyUnicode_FromString("prototype"));
        return slot_list;
    } else if (strcmp(message_name, "setSlot") == 0) {
        // Handle setSlot transactional updates
        printf("FFI: Processing setSlot transaction\n");
        Py_RETURN_TRUE;
    }
    
    // Default response for unknown messages
    return PyUnicode_FromFormat("response_for_%s", message_name);
}

// Forward message method definition (now the function is defined above)
static PyMethodDef forward_message_method = {
    "forward_message", 
    (PyCFunction)IoTelosFFI_forwardMessage, 
    METH_VARARGS | METH_KEYWORDS, 
    "Forward message from Python proxy to Io master"
};

// Create IoProxy instance using our Python implementation
PyObject* IoTelosFFI_createProxy(IoObject *ioObj, const char *proxy_type) {
    if (!isPythonInitialized) {
        printf("FFI Error: Python not initialized for proxy creation\n");
        return NULL;
    }
    
    // Create handle for Io object
    char *handle_id = IoTelosFFI_createHandle(ioObj, NULL);
    if (!handle_id) {
        printf("FFI Error: Failed to create handle for Io object\n");
        return NULL;
    }
    
    // Import io_proxy module
    PyObject* io_proxy_module = PyImport_ImportModule("io_proxy");
    if (!io_proxy_module) {
        printf("FFI Error: Failed to import io_proxy module\n");
        PyErr_Print();
        return NULL;
    }
    
    // Get create_proxy factory function
    PyObject* create_proxy_func = PyObject_GetAttrString(io_proxy_module, "create_proxy");
    if (!create_proxy_func) {
        printf("FFI Error: io_proxy.create_proxy not found\n");
        PyErr_Print();
        Py_DECREF(io_proxy_module);
        return NULL;
    }
    
    // Create forward message function wrapper
    PyObject* forward_func = PyCFunction_New(&forward_message_method, NULL);
    
    // Create proxy arguments
    PyObject* proxy_args = PyTuple_New(3);
    PyTuple_SetItem(proxy_args, 0, PyUnicode_FromString(proxy_type ? proxy_type : "IoProxy"));
    PyTuple_SetItem(proxy_args, 1, PyUnicode_FromString(handle_id));  // Handle as string
    PyTuple_SetItem(proxy_args, 2, forward_func);
    
    // Create proxy instance
    PyObject* proxy_instance = PyObject_CallObject(create_proxy_func, proxy_args);
    if (!proxy_instance) {
        printf("FFI Error: Failed to create IoProxy instance\n");
        PyErr_Print();
    } else {
        printf("FFI: Successfully created %s proxy with handle %s\n", 
               proxy_type ? proxy_type : "IoProxy", handle_id);
    }
    
    // Cleanup
    Py_DECREF(proxy_args);
    Py_DECREF(create_proxy_func);
    Py_DECREF(io_proxy_module);
    
    return proxy_instance;
}



// --- Enhanced Synaptic Bridge Functions ---

// Create and manage cross-language handles for safe memory management
char* IoTelosFFI_createHandle(IoObject *ioObj, PyObject *pyObj) {
    if (!handles) {
        handles = calloc(maxHandles, sizeof(CrossLanguageHandle));
        if (!handles) return NULL;
    }
    
    for (int i = 0; i < maxHandles; i++) {
        if (!handles[i].ioObject) {
            handles[i].ioObject = ioObj;
            handles[i].pyObject = pyObj;
            handles[i].refCount = 1;
            handles[i].handleId = malloc(32);
            snprintf(handles[i].handleId, 32, "handle_%d_%ld", i, (long)time(NULL));
            
            // Increment Python reference count
            if (pyObj) Py_INCREF(pyObj);
            
            handleCount++;
            return handles[i].handleId;
        }
    }
    return NULL; // No available slots
}

void IoTelosFFI_releaseHandle(char *handleId) {
    if (!handles || !handleId) return;
    
    for (int i = 0; i < maxHandles; i++) {
        if (handles[i].handleId && strcmp(handles[i].handleId, handleId) == 0) {
            // Decrement Python reference count
            if (handles[i].pyObject) {
                Py_DECREF(handles[i].pyObject);
            }
            
            // Free handle resources
            if (handles[i].handleId) {
                free(handles[i].handleId);
                handles[i].handleId = NULL;
            }
            
            // Clear handle
            memset(&handles[i], 0, sizeof(CrossLanguageHandle));
            handleCount--;
            break;
        }
    }
}

void IoTelosFFI_initEnhancedPython(void) {
    if (isPythonInitialized) return;
    
    if (!globalBridge) {
        globalBridge = malloc(sizeof(SynapticBridge));
        memset(globalBridge, 0, sizeof(SynapticBridge));
        pthread_mutex_init(&globalBridge->mutex, NULL);
    }
    
    if (!Py_IsInitialized()) {
        Py_Initialize();
        if (!Py_IsInitialized()) {
            fprintf(stderr, "Failed to initialize Python interpreter\n");
            return;
        }
    }
    
    // Python 3.12+ automatically handles threading - no manual initialization needed
    
    // Import concurrent.futures for async execution
    PyObject *concurrent_futures = PyImport_ImportModule("concurrent.futures");
    if (concurrent_futures) {
        PyObject *processPoolClass = PyObject_GetAttrString(concurrent_futures, "ProcessPoolExecutor");
        if (processPoolClass) {
            globalBridge->processPool = PyObject_CallObject(processPoolClass, NULL);
            Py_DECREF(processPoolClass);
        }
        Py_DECREF(concurrent_futures);
    }
    
    // Check for virtual environment
    PyObject *sys = PyImport_ImportModule("sys");
    if (sys) {
        PyObject *prefix = PyObject_GetAttrString(sys, "prefix");
        PyObject *base_prefix = PyObject_GetAttrString(sys, "base_prefix");
        
        if (prefix && base_prefix) {
            int comparison = PyObject_RichCompareBool(prefix, base_prefix, Py_NE);
            globalBridge->isVirtualEnvActive = (comparison == 1);
        }
        
        if (prefix) Py_DECREF(prefix);
        if (base_prefix) Py_DECREF(base_prefix);
        Py_DECREF(sys);
    }
    
    globalBridge->isInitialized = 1;
    isPythonInitialized = 1;
    
    // Register cleanup function
    atexit(IoTelosFFI_cleanupEnhancedPython);
}

void IoTelosFFI_cleanupEnhancedPython(void) {
    if (!isPythonInitialized) return;
    
    // Clean up all handles
    if (handles) {
        for (int i = 0; i < maxHandles; i++) {
            if (handles[i].handleId) {
                IoTelosFFI_releaseHandle(handles[i].handleId);
            }
        }
        free(handles);
        handles = NULL;
    }
    
    // Clean up global bridge
    if (globalBridge) {
        if (globalBridge->processPool) {
            // Shutdown process pool
            PyObject *shutdown = PyObject_GetAttrString(globalBridge->processPool, "shutdown");
            if (shutdown) {
                PyObject *args = PyTuple_New(1);
                PyTuple_SetItem(args, 0, PyBool_FromLong(1)); // wait=True
                PyObject_CallObject(shutdown, args);
                Py_DECREF(args);
                Py_DECREF(shutdown);
            }
            Py_DECREF(globalBridge->processPool);
        }
        
        if (globalBridge->venvPath) {
            free(globalBridge->venvPath);
        }
        
        pthread_mutex_destroy(&globalBridge->mutex);
        free(globalBridge);
        globalBridge = NULL;
    }
    
    // Finalize Python interpreter
    if (Py_IsInitialized()) {
        Py_Finalize();
    }
    
    isPythonInitialized = 0;
}

// --- Advanced Marshalling System ---

PyObject* IoTelosFFI_marshalIoToPython_helper(IoObject *ioObj) {
    if (!ioObj) {
        Py_RETURN_NONE;
    }
    
    // Number conversion
    if (ISNUMBER(ioObj)) {
        double val = IoNumber_asDouble(ioObj);
        return PyFloat_FromDouble(val);
    }
    
    // String conversion
    if (ISSEQ(ioObj)) {
        const char *str = IoSeq_asCString(ioObj);
        return PyUnicode_FromString(str);
    }
    
    // List conversion
    if (ISLIST(ioObj)) {
        PyObject *pyList = PyList_New(0);
        IoList *ioList = ioObj;
        int size = IoList_rawSize(ioList);
        
        for (int i = 0; i < size; i++) {
            IoObject *item = IoList_rawAt_(ioList, i);
            PyObject *pyItem = IoTelosFFI_marshalIoToPython_helper(item);
            PyList_Append(pyList, pyItem);
            Py_DECREF(pyItem);
        }
        return pyList;
    }
    
    // Map conversion
    if (ISMAP(ioObj)) {
        PyObject *pyDict = PyDict_New();
        IoMap *ioMap = ioObj;
        IoList *keys = IoMap_rawKeys(ioMap);
        
        LIST_FOREACH(keys, i, ioKey,
            IoObject *ioValue = IoMap_rawAt(ioMap, ioKey);
            PyObject *pyKey = IoTelosFFI_marshalIoToPython_helper(ioKey);
            PyObject *pyValue = IoTelosFFI_marshalIoToPython_helper(ioValue);
            PyDict_SetItem(pyDict, pyKey, pyValue);
            Py_DECREF(pyKey);
            Py_DECREF(pyValue);
        );
        return pyDict;
    }
    
    // For complex objects, create a handle-based proxy
    char *handleId = IoTelosFFI_createHandle(ioObj, NULL);
    if (handleId) {
        PyObject *proxyDict = PyDict_New();
        PyDict_SetItemString(proxyDict, "__telos_handle__", PyUnicode_FromString(handleId));
        PyDict_SetItemString(proxyDict, "__telos_type__", PyUnicode_FromString("IoObject"));
        return proxyDict;
    }
    
    Py_RETURN_NONE;
}

IoObject* IoTelosFFI_marshalPythonToIo_helper(PyObject *pyObj, IoState *state) {
    if (!pyObj || pyObj == Py_None) {
        return state->ioNil;
    }
    
    // Number conversion
    if (PyLong_Check(pyObj)) {
        long val = PyLong_AsLong(pyObj);
        return IoNumber_newWithDouble_(state, (double)val);
    }
    
    if (PyFloat_Check(pyObj)) {
        double val = PyFloat_AsDouble(pyObj);
        return IoNumber_newWithDouble_(state, val);
    }
    
    // String conversion
    if (PyUnicode_Check(pyObj)) {
        const char *str = PyUnicode_AsUTF8(pyObj);
        return IoSeq_newWithCString_(state, str);
    }
    
    // List conversion
    if (PyList_Check(pyObj)) {
        IoList *ioList = IoList_new(state);
        Py_ssize_t size = PyList_Size(pyObj);
        
        for (Py_ssize_t i = 0; i < size; i++) {
            PyObject *item = PyList_GetItem(pyObj, i);
            IoObject *ioItem = IoTelosFFI_marshalPythonToIo_helper(item, state);
            IoList_rawAppend_(ioList, ioItem);
        }
        return ioList;
    }
    
    // Boolean conversion
    if (PyBool_Check(pyObj)) {
        if (pyObj == Py_True) {
            return state->ioTrue;
        } else {
            return state->ioFalse;
        }
    }
    
    // Dictionary conversion
    if (PyDict_Check(pyObj)) {
        // Check for Telos handle proxy
        PyObject *handleKey = PyUnicode_FromString("__telos_handle__");
        if (PyDict_Contains(pyObj, handleKey)) {
            // This is a handle proxy - resolve back to original IoObject
            PyObject *handleId = PyDict_GetItem(pyObj, handleKey);
            if (handleId && PyUnicode_Check(handleId)) {
                const char *handleStr = PyUnicode_AsUTF8(handleId);
                // Find the handle and return the IoObject
                if (handles) {
                    for (int i = 0; i < maxHandles; i++) {
                        if (handles[i].handleId && strcmp(handles[i].handleId, handleStr) == 0) {
                            Py_DECREF(handleKey);
                            return handles[i].ioObject;
                        }
                    }
                }
            }
        }
        Py_DECREF(handleKey);
        
        // Regular dictionary conversion
        IoMap *ioMap = IoMap_new(state);
        PyObject *keys = PyDict_Keys(pyObj);
        Py_ssize_t size = PyList_Size(keys);
        
        for (Py_ssize_t i = 0; i < size; i++) {
            PyObject *key = PyList_GetItem(keys, i);
            PyObject *value = PyDict_GetItem(pyObj, key);
            IoObject *ioKey = IoTelosFFI_marshalPythonToIo_helper(key, state);
            IoObject *ioValue = IoTelosFFI_marshalPythonToIo_helper(value, state);
            IoMap_rawAtPut(ioMap, ioKey, ioValue);
        }
        Py_DECREF(keys);
        return ioMap;
    }
    
    // For complex Python objects, create a handle-based proxy
    char *handleId = IoTelosFFI_createHandle(NULL, pyObj);
    if (handleId) {
        IoMap *proxyMap = IoMap_new(state);
        IoMap_rawAtPut(proxyMap, 
                      IoSeq_newWithCString_(state, "__python_handle__"),
                      IoSeq_newWithCString_(state, handleId));
        IoMap_rawAtPut(proxyMap,
                      IoSeq_newWithCString_(state, "__python_type__"),
                      IoSeq_newWithCString_(state, pyObj->ob_type->tp_name));
        return proxyMap;
    }
    
    return state->ioNil;
}

// --- Core FFI Execution Functions ---

IoObject* IoTelosFFI_executeAsync(IoObject *self, IoObject *locals, IoObject *m) {
    // Ensure Python is initialized
    if (!isPythonInitialized) {
        IoTelosFFI_initEnhancedPython();
    }
    
    if (!globalBridge || !globalBridge->processPool) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Async execution not available");
    }
    
    IoState *state = IoObject_state(self);
    IoMessage *msg = (IoMessage *)m;
    IoObject *codeObj = IoMessage_locals_valueArgAt_(msg, locals, 0);
    
    if (!ISSEQ(codeObj)) {
        return IoSeq_newWithCString_(state, "Error: Code must be a string");
    }
    
    const char *code = IoSeq_asCString(codeObj);
    
    // Submit to process pool
    pthread_mutex_lock(&globalBridge->mutex);
    
    PyObject *submit = PyObject_GetAttrString(globalBridge->processPool, "submit");
    if (submit) {
        PyObject *builtins = PyImport_ImportModule("builtins");
        PyObject *exec_func = PyObject_GetAttrString(builtins, "exec");
        
        PyObject *args = PyTuple_New(2);
        PyTuple_SetItem(args, 0, exec_func); // Function to execute
        PyTuple_SetItem(args, 1, PyUnicode_FromString(code)); // Code to execute
        
        PyObject *future = PyObject_CallObject(submit, args);
        
        // Get result (this blocks)
        if (future) {
            PyObject *result_method = PyObject_GetAttrString(future, "result");
            PyObject *result = PyObject_CallObject(result_method, NULL);
            
            Py_DECREF(result_method);
            Py_DECREF(future);
            
            if (result) {
                IoObject *ioResult = IoTelosFFI_marshalPythonToIo_helper(result, state);
                Py_DECREF(result);
                pthread_mutex_unlock(&globalBridge->mutex);
                return ioResult;
            }
        }
        
        Py_DECREF(args);
        Py_DECREF(submit);
        Py_DECREF(builtins);
    }
    
    pthread_mutex_unlock(&globalBridge->mutex);
    return IoSeq_newWithCString_(state, "Error: Async execution failed");
}

// Io signature: Telos_rawPyEval(code) -> string result or empty string
IoObject *IoTelosFFI_pyEval(IoObject *self, IoObject *locals, IoObject *m)
{
    IoState *state = IoObject_state(self);
    IoMessage *msg = (IoMessage *)m;
    IoObject *codeObj = IoMessage_locals_valueArgAt_(msg, locals, 0);
    
    if (!ISSEQ(codeObj)) {
        return IoSeq_newWithCString_(state, "");
    }
    
    const char *code = IoSeq_asCString(codeObj);
    
    // Initialize Python if not already done
    if (!isPythonInitialized) {
        IoTelosFFI_initEnhancedPython();
    }
    
    // Create fresh globals and locals
    PyObject *globals = PyDict_New();
    PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());
    
    // Check for context parameter
    if (IoMessage_argCount(m) > 1) {
        IoObject *contextObj = IoMessage_locals_valueArgAt_(m, locals, 1);
        PyObject *pyContext = IoTelosFFI_marshalIoToPython_helper(contextObj);
        PyDict_Update(globals, pyContext);
        Py_DECREF(pyContext);
    }
    
    // Execute Python code
    PyObject *pyRes = PyRun_String(code, Py_eval_input, globals, globals);
    
    if (pyRes) {
        IoObject *ioResult = IoTelosFFI_marshalPythonToIo_helper(pyRes, IoObject_state(self));
        Py_DECREF(pyRes);
        Py_DECREF(globals);
        return ioResult;
    } else {
        // Handle Python errors
        PyErr_Print();
        PyErr_Clear();
        Py_DECREF(globals);
        return IoSeq_newWithCString_(state, "");
    }
}

// Marshalling interface methods
IoObject* IoTelosFFI_marshalIoToPython(IoObject *self, IoObject *locals, IoObject *m) {
    IoMessage *msg = (IoMessage *)m;
    IoObject *ioObj = IoMessage_locals_valueArgAt_(msg, locals, 0);
    PyObject *pyObj = IoTelosFFI_marshalIoToPython_helper(ioObj);
    
    if (pyObj) {
        IoObject *result = IoTelosFFI_marshalPythonToIo_helper(pyObj, IoObject_state(self));
        Py_DECREF(pyObj);
        return result;
    }
    
    return IoObject_state(self)->ioNil;
}

IoObject* IoTelosFFI_marshalPythonToIo(IoObject *self, IoObject *locals, IoObject *m) {
    // This would typically receive a Python object handle and convert it
    // For now, return nil as this is primarily used internally
    return IoObject_state(self)->ioNil;
}

// --- Prototypal FFI Object Management (UvmObject behavioral pattern) ---

// Default behavioral functions for TelosFFIObject
IoObject* TelosFFIObject_getValueFor_default(TelosFFIObject *self, char *slotName) {
    if (!self || !slotName) return NULL;
    
    if (self->slots) {
        return (IoObject*)CHash_at_(self->slots, slotName);
    }
    
    return NULL;
}

void TelosFFIObject_setValueFor_default(TelosFFIObject *self, char *slotName, IoObject *value) {
    if (!self || !slotName || !value) return;
    
    if (!self->slots) {
        self->slots = CHash_new();
    }
    
    CHash_at_put_(self->slots, slotName, value);
    
    // Log state change for WAL
    if (self->logStateChange) {
        self->logStateChange(self, slotName, value);
    }
}

IoObject* TelosFFIObject_perform_default(TelosFFIObject *self, char *message) {
    if (!self || !message) return NULL;
    
    // For now, delegate to the Io object if available
    if (self->io_reference) {
        // Would need to construct IoMessage and send to io_reference
        // This is a simplified version
        return self->io_reference;
    }
    
    return NULL;
}

TelosFFIObject* TelosFFIObject_clone_default(TelosFFIObject *self) {
    if (!self) return NULL;
    
    TelosFFIObject *clone = malloc(sizeof(TelosFFIObject));
    memcpy(clone, self, sizeof(TelosFFIObject));
    
    // Create new slots hash
    if (self->slots) {
        clone->slots = CHash_new();
        // Would need to copy all slots - simplified for now
    }
    
    // Generate new object ID
    if (self->objectId) {
        clone->objectId = malloc(strlen(self->objectId) + 10);
        sprintf(clone->objectId, "%s_clone_%ld", self->objectId, (long)time(NULL));
    }
    
    clone->refCount = 1;
    return clone;
}

void TelosFFIObject_logStateChange_default(TelosFFIObject *self, char *slotName, IoObject *value) {
    // Simplified WAL logging - would integrate with full WAL system
    if (self && slotName && self->objectId) {
        printf("WAL: Object %s slot %s changed\n", self->objectId, slotName);
    }
}

// TelosFFIObject constructor
TelosFFIObject* TelosFFIObject_create(IoObject *ioRef) {
    TelosFFIObject *self = malloc(sizeof(TelosFFIObject));
    memset(self, 0, sizeof(TelosFFIObject));
    
    self->io_reference = ioRef;
    self->slots = CHash_new();
    self->refCount = 1;
    
    // Assign default behavioral functions - enables runtime reconfiguration
    self->getValueFor = TelosFFIObject_getValueFor_default;
    self->setValueFor = TelosFFIObject_setValueFor_default;
    self->perform = TelosFFIObject_perform_default;
    self->clone = TelosFFIObject_clone_default;
    self->logStateChange = TelosFFIObject_logStateChange_default;
    
    // Generate unique object ID
    self->objectId = malloc(32);
    snprintf(self->objectId, 32, "ffi_obj_%ld", (long)time(NULL));
    
    return self;
}

void TelosFFIObject_destroy(TelosFFIObject *self) {
    if (!self) return;
    
    self->refCount--;
    if (self->refCount > 0) return;
    
    if (self->slots) {
        CHash_free(self->slots);
    }
    
    if (self->python_proxy) {
        Py_DECREF(self->python_proxy);
    }
    
    if (self->objectId) {
        free(self->objectId);
    }
    
    free(self);
}

// Behavioral delegation methods
IoObject* TelosFFIObject_getValueFor(TelosFFIObject *self, char *slotName) {
    if (self && self->getValueFor) {
        return self->getValueFor(self, slotName);
    }
    return NULL;
}

void TelosFFIObject_setValueFor(TelosFFIObject *self, char *slotName, IoObject *value) {
    if (self && self->setValueFor) {
        self->setValueFor(self, slotName, value);
    }
}

IoObject* TelosFFIObject_perform(TelosFFIObject *self, char *message) {
    if (self && self->perform) {
        return self->perform(self, message);
    }
    return NULL;
}

TelosFFIObject* TelosFFIObject_clone(TelosFFIObject *self) {
    if (self && self->clone) {
        return self->clone(self);
    }
    return NULL;
}

void TelosFFIObject_logStateChange(TelosFFIObject *self, char *slotName, IoObject *value) {
    if (self && self->logStateChange) {
        self->logStateChange(self, slotName, value);
    }
}

// --- Module Registration Functions ---

void IoTelosFFI_registerMethods(IoState *state, IoObject *telosProto) {
    // Register FFI methods on the Telos prototype
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "pyEval"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_pyEval, NULL, "pyEval"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "pyEvalAsync"), 
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_executeAsync, NULL, "pyEvalAsync"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "executeAsync"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_executeAsync, NULL, "executeAsync"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "marshalIoToPython"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_marshalIoToPython, NULL, "marshalIoToPython"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "marshalPythonToIo"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_marshalPythonToIo, NULL, "marshalPythonToIo"));
    
    // Register raw version for low-level access
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawPyEval"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_pyEval, NULL, "0"));
}

void IoTelosFFI_registerPrototype(IoState *state) {
    // Initialize Python subsystem
    IoTelosFFI_initEnhancedPython();
    
    // Create and register any FFI-specific prototypes here
    // For now, FFI methods are registered on the main Telos prototype
}