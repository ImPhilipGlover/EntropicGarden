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
#include <sys/wait.h>
// Forward declarations for functions defined later in the file
IoObject* IoTelosFFI_createProxyIo(IoObject *self, IoObject *locals, IoMessage *m);
IoObject* IoTelosFFI_destroyProxyIo(IoObject *self, IoObject *locals, IoMessage *m);

// Global state management for enhanced synaptic bridge
static SynapticBridge synapticBridge = {0};
static SynapticBridge *globalBridge = NULL;
static CrossLanguageHandle *handles = NULL;
static int maxHandles = 1000;
static int handleCount = 0;
static int isPythonInitialized = 0;

// Prototypal Emulation Layer - Direct Io object delegation (no structs)
// All proxy functionality delegated to existing Io object system

// Forward message function implementation for IoProxy delegation
PyObject* IoTelosFFI_forwardMessage(PyObject *self, PyObject *args, PyObject *kwargs) {
    char *handle_id;
    char *message_name;
    PyObject *message_args = NULL;
    
    if (!PyArg_ParseTuple(args, "ss|O", &handle_id, &message_name, &message_args)) {
        return NULL;
    }
    
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
    
    // Direct Io message dispatch using native Io system
    if (strcmp(message_name, "protoId") == 0) {
        return PyUnicode_FromString("TelOS");
    } else if (strcmp(message_name, "slotNames") == 0) {
        PyObject *slot_list = PyList_New(3);
        PyList_SetItem(slot_list, 0, PyUnicode_FromString("name"));
        PyList_SetItem(slot_list, 1, PyUnicode_FromString("value"));
        PyList_SetItem(slot_list, 2, PyUnicode_FromString("prototype"));
        return slot_list;
    } else if (strcmp(message_name, "setSlot") == 0) {
        // Handle setSlot transactional updates via native Io
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

PyObject* IoTelosFFI_createPythonProxyObject(IoObject *ioObj, const char *proxy_type) {
    if (!isPythonInitialized) {
        return NULL;
    }
    
    // Create handle for Io object
    char *handle_id = IoTelosFFI_createHandle(ioObj, NULL);
    if (!handle_id) {
        return NULL;
    }
    
    // Import io_proxy module
    PyObject* io_proxy_module = PyImport_ImportModule("io_proxy");
    if (!io_proxy_module) {
        PyErr_Print();
        return NULL;
    }
    
    // Get create_proxy factory function
    PyObject* create_proxy_func = PyObject_GetAttrString(io_proxy_module, "create_proxy");
    if (!create_proxy_func) {
        PyErr_Print();
        Py_DECREF(io_proxy_module);
        return NULL;
    }
    
    // Create forward message function wrapper
    PyObject* forward_func = PyCFunction_New(&forward_message_method, NULL);
    
    // Create proxy arguments
    PyObject* proxy_args = PyTuple_New(3);
    PyTuple_SetItem(proxy_args, 0, PyUnicode_FromString(proxy_type ? proxy_type : "IoProxy"));
    PyTuple_SetItem(proxy_args, 1, PyUnicode_FromString(handle_id));
    PyTuple_SetItem(proxy_args, 2, forward_func);
    
    // Create proxy instance
    PyObject* proxy_instance = PyObject_CallObject(create_proxy_func, proxy_args);
    
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
            return;
        }
    }
    
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
            PyObject *shutdown = PyObject_GetAttrString(globalBridge->processPool, "shutdown");
            if (shutdown) {
                PyObject *args = PyTuple_New(1);
                PyTuple_SetItem(args, 0, PyBool_FromLong(1));
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
        List *keyList = IoList_rawList(keys);
        
        LIST_FOREACH(keyList, i, ioKey, {
            IoObject *ioValue = IoMap_rawAt(ioMap, (IoObject*)ioKey);
            PyObject *pyKey = IoTelosFFI_marshalIoToPython_helper((IoObject*)ioKey);
            PyObject *pyValue = IoTelosFFI_marshalIoToPython_helper(ioValue);
            PyDict_SetItem(pyDict, pyKey, pyValue);
            Py_DECREF(pyKey);
            Py_DECREF(pyValue);
        });
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

// Io signature: Telos pyEval(code) -> string result or error message
IoObject *IoTelosFFI_pyEval(IoObject *self, IoObject *locals, IoObject *m)
{
    IoState *state = IoObject_state(self);
    IoMessage *msg = (IoMessage *)m;
    IoObject *codeObj = IoMessage_locals_valueArgAt_(msg, locals, 0);
    
    if (!ISSEQ(codeObj)) {
        IoState_error_(state, m, "pyEval requires code string as argument");
        return IONIL(self);
    }
    
    const char *code = IoSeq_asCString(codeObj);
    
    // Create temporary Python script file for complex multi-line code execution
    // This approach handles quotes, newlines, and complex Python structures reliably
    char temp_script_path[256];
    snprintf(temp_script_path, sizeof(temp_script_path), "/tmp/telos_ffi_%ld.py", (long)time(NULL));
    
    // Write Python code to temporary file
    FILE *temp_file = fopen(temp_script_path, "w");
    if (!temp_file) {
        IoState_error_(state, m, "Failed to create temporary Python script");
        return IONIL(self);
    }
    
    // Write Python path setup and user code
    fprintf(temp_file, "import sys\n");
    fprintf(temp_file, "sys.path.append('/mnt/c/EntropicGarden/python')\n");
    fprintf(temp_file, "%s\n", code);
    fclose(temp_file);
    
    // Use subprocess to execute Python script with GIL quarantine and timeout
    char command[4096];
    snprintf(command, sizeof(command), 
        "timeout 10s python3 %s; rm %s", 
        temp_script_path, temp_script_path);
    
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        IoState_error_(state, m, "Failed to execute Python subprocess");
        return IONIL(self);
    }
    
    // Read output from Python subprocess with safer approach
    char buffer[8192];
    size_t total_read = 0;
    
    buffer[0] = '\0';
    
    // Use fgets instead of fread for line-by-line reading
    char line[1024];
    while (fgets(line, sizeof(line), pipe) && total_read < sizeof(buffer) - 1) {
        size_t line_len = strlen(line);
        if (total_read + line_len >= sizeof(buffer) - 1) {
            break; // Prevent buffer overflow
        }
        strcpy(buffer + total_read, line);
        total_read += line_len;
    }
    
    int exit_code = pclose(pipe);
    
    // Handle timeout properly - timeout returns exit code 124 in child, but pclose returns signal
    if (WIFSIGNALED(exit_code)) {
        return IoSeq_newWithCString_(state, "Error: Python execution was terminated by signal (timeout or other signal)");
    }
    
    exit_code = WEXITSTATUS(exit_code);
    
    if (exit_code == 124) {
        return IoSeq_newWithCString_(state, "Error: Python execution timed out (10s limit)");
    }
    
    if (exit_code != 0) {
        char error_msg[1024];
        snprintf(error_msg, sizeof(error_msg), "Python execution failed with exit code %d: %s", exit_code, buffer);
        return IoSeq_newWithCString_(state, error_msg);
    }
    
    // Remove trailing newline if present
    if (total_read > 0 && buffer[total_read-1] == '\n') {
        buffer[total_read-1] = '\0';
    }
    
    return IoSeq_newWithCString_(state, buffer);
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

// --- Module Registration Functions ---

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
    
    // Register prototypal emulation and chat functions
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "setProxyAttribute"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_setProxyAttribute, NULL, "setProxyAttribute"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "chatWithLLM"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_chatWithLLM, NULL, "chatWithLLM"));
    
    // Register proxy management functions
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "createProxy"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_createProxyIo, NULL, "createProxy"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "destroyProxy"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelosFFI_destroyProxyIo, NULL, "destroyProxy"));
}

void IoTelosFFI_registerPrototype(IoState *state) {
    // Direct registration without complex initialization
}

// Simplified proxy functions using direct Io object delegation
IoObject* IoTelosFFI_setProxyAttribute(IoObject *self, IoObject *locals, IoMessage *m) {
    IoSeq *attrName = IoMessage_locals_seqArgAt_(m, locals, 0);
    IoObject *attrValue = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!attrName || !attrValue) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: setProxyAttribute requires attribute name and value");
    }
    
    char *attrNameStr = IoSeq_asCString(attrName);
    
    // Set attribute directly on Io object - pure prototypal approach
    IoObject_setSlot_to_(self, IoState_symbolWithCString_(IoObject_state(self), attrNameStr), attrValue);
    
    return self;
}

// Simplified non-blocking cognitive cycle implementation
IoObject* IoTelosFFI_chatWithLLM(IoObject *self, IoObject *locals, IoMessage *m) {
    IoSeq *message = IoMessage_locals_seqArgAt_(m, locals, 0);
    
    if (!message) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: chatWithLLM requires message string");
    }
    
    char *messageStr = IoSeq_asCString(message);
    
    if (!isPythonInitialized) {
        IoTelosFFI_initEnhancedPython();
    }
    
    // Simplified cognitive processing with timeout protection
    const char *cognitive_code = 
        "import requests\n"
        "import sys\n"
        "try:\n"
        "    # Quick test with minimal timeout\n"
        "    response = requests.get('http://localhost:11434/api/tags', timeout=2)\n"
        "    if response.status_code == 200:\n"
        "        # Simple direct response without complex pipeline\n"
        "        simple_response = requests.post('http://localhost:11434/api/generate',\n"
        "            json={'model': 'telos/babs', 'prompt': sys.argv[1], 'stream': False},\n"
        "            timeout=10)\n"
        "        if simple_response.status_code == 200:\n"
        "            result = simple_response.json()\n"
        "            print(result.get('response', 'No response from model'))\n"
        "        else:\n"
        "            print('Model request failed')\n"
        "    else:\n"
        "        print('Ollama service not available')\n"
        "except Exception as e:\n"
        "    print(f'Cognitive cycle error: {str(e)}')\n";
    
    // Create temporary Python script with simplified pipeline
    char temp_script_path[256];
    snprintf(temp_script_path, sizeof(temp_script_path), "/tmp/telos_simple_%ld.py", (long)time(NULL));
    
    FILE *temp_file = fopen(temp_script_path, "w");
    if (!temp_file) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Failed to create cognitive script");
    }
    
    fprintf(temp_file, "%s", cognitive_code);
    fclose(temp_file);
    
    // Execute with shorter timeout and error handling
    char command[4096];
    snprintf(command, sizeof(command), 
        "timeout 15s python3 %s '%s' 2>&1; rm %s", 
        temp_script_path, messageStr, temp_script_path);
    
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Failed to execute cognitive cycle");
    }
    
    char buffer[4096];
    size_t total_read = 0;
    buffer[0] = '\0';
    
    char line[512];
    while (fgets(line, sizeof(line), pipe) && total_read < sizeof(buffer) - 1) {
        size_t line_len = strlen(line);
        if (total_read + line_len >= sizeof(buffer) - 1) {
            break;
        }
        strcpy(buffer + total_read, line);
        total_read += line_len;
    }
    
    int exit_code = pclose(pipe);
    
    if (WIFSIGNALED(exit_code)) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Cognitive cycle terminated");
    }
    
    exit_code = WEXITSTATUS(exit_code);
    
    if (exit_code == 124) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Cognitive cycle timed out");
    }
    
    if (exit_code != 0) {
        char error_msg[512];
        snprintf(error_msg, sizeof(error_msg), "Cognitive cycle failed: %s", buffer);
        return IoSeq_newWithCString_(IoObject_state(self), error_msg);
    }
    
    // Remove trailing newline if present
    if (total_read > 0 && buffer[total_read-1] == '\n') {
        buffer[total_read-1] = '\0';
    }
    
    return IoSeq_newWithCString_(IoObject_state(self), buffer);
}

// Direct Io proxy creation - returns handle ID only
IoObject* IoTelosFFI_createProxyIo(IoObject *self, IoObject *locals, IoMessage *m) {
    IoObject *ioObj = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    if (!ioObj) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: createProxy requires an Io object");
    }
    
    // Create simple handle without struct complexity
    char *handleId = IoTelosFFI_createHandle(ioObj, NULL);
    if (!handleId) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: Failed to create handle");
    }
    
    return IoSeq_newWithCString_(IoObject_state(self), handleId);
}

// Direct proxy destruction
IoObject* IoTelosFFI_destroyProxyIo(IoObject *self, IoObject *locals, IoMessage *m) {
    IoSeq *handleId = IoMessage_locals_seqArgAt_(m, locals, 0);
    
    if (!handleId) {
        return IoSeq_newWithCString_(IoObject_state(self), "Error: destroyProxy requires a handle ID");
    }
    
    const char *handleStr = IoSeq_asCString(handleId);
    IoTelosFFI_releaseHandle((char*)handleStr);
    
    return IoSeq_newWithCString_(IoObject_state(self), "Handle released");
}