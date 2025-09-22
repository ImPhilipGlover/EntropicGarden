/*
   IoTelosFFI.h - Modular FFI Interface Header
   Extracted from monolithic IoTelos.c for targeted debugging and architecture clarity
*/

#ifndef IOTELOS_FFI_H
#define IOTELOS_FFI_H

#include "IoState.h"
#include "IoObject.h"
#include "IoMessage.h"
#include "CHash.h"
#include <Python.h>
#include <pthread.h>

// IoTelos type definition
typedef IoObject IoTelos;

// Forward declarations
typedef struct CrossLanguageHandle CrossLanguageHandle;
typedef struct SynapticBridge SynapticBridge;
typedef struct TelosFFIObject TelosFFIObject;

// Enhanced marshalling structures
typedef struct CrossLanguageHandle {
    IoObject *ioObject;
    PyObject *pyObject;
    int refCount;
    char *handleId;
} CrossLanguageHandle;

// Enhanced Synaptic Bridge structures
typedef struct SynapticBridge {
    PyObject *processPool;      // concurrent.futures.ProcessPoolExecutor
    PyObject *asyncExecutor;    // Async execution handler
    pthread_mutex_t mutex;      // Thread safety for Python calls
    int isVirtualEnvActive;     // Virtual environment status
    char *venvPath;             // Path to virtual environment
    int isInitialized;          // Bridge initialization status
    int handleCount;            // Number of active handles
    CrossLanguageHandle *handles; // Handle registry
} SynapticBridge;

// Prototypal FFI Object - Behavioral Proxy with function pointers for dynamic dispatch
typedef struct TelosFFIObject {
    void *parent_id;            // Reference to prototype in Io VM
    CHash *slots;               // String names → generic IoObject pointers
    IoObject *io_reference;     // Direct reference to source Io object
    PyObject *python_proxy;     // Python IoProxy ambassador
    
    // Behavioral function pointers for prototypal delegation - UvmObject pattern
    IoObject *(*getValueFor)(struct TelosFFIObject *self, char *slotName);
    void (*setValueFor)(struct TelosFFIObject *self, char *slotName, IoObject *value);
    IoObject *(*perform)(struct TelosFFIObject *self, char *message);
    struct TelosFFIObject *(*clone)(struct TelosFFIObject *self);
    
    // WAL logging for state authority
    void (*logStateChange)(struct TelosFFIObject *self, char *slotName, IoObject *value);
    
    // Reference counting for memory management
    int refCount;
    char *objectId;             // Unique identifier for cross-layer tracking
} TelosFFIObject;

// FFI Bridge Management Functions
void IoTelosFFI_initEnhancedPython(void);
void IoTelosFFI_cleanupEnhancedPython(void);
char* IoTelosFFI_createHandle(IoObject *ioObj, PyObject *pyObj);
void IoTelosFFI_releaseHandle(char *handleId);

// Marshalling Functions (Bidirectional Object Conversion)
PyObject* IoTelosFFI_marshalIoToPython_helper(IoObject *ioObj);
IoObject* IoTelosFFI_marshalPythonToIo_helper(PyObject *pyObj, IoState *state);
IoObject* IoTelosFFI_marshalIoToPython(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject* IoTelosFFI_marshalPythonToIo(IoTelos *self, IoObject *locals, IoMessage *m);

// Core FFI Execution Functions  
IoObject* IoTelosFFI_pyEval(IoObject *self, IoObject *locals, IoObject *m);
IoObject* IoTelosFFI_executeAsync(IoObject *self, IoObject *locals, IoObject *m);

// Marshalling Functions (Bidirectional Object Conversion)
IoObject* IoTelosFFI_marshalIoToPython(IoObject *self, IoObject *locals, IoObject *m);
IoObject* IoTelosFFI_marshalPythonToIo(IoObject *self, IoObject *locals, IoObject *m);

// Prototypal FFI Object Management (following UvmObject behavioral pattern)
TelosFFIObject* TelosFFIObject_create(IoObject *ioRef);
void TelosFFIObject_destroy(TelosFFIObject *self);
IoObject* TelosFFIObject_getValueFor(TelosFFIObject *self, char *slotName);
void TelosFFIObject_setValueFor(TelosFFIObject *self, char *slotName, IoObject *value);
IoObject* TelosFFIObject_perform(TelosFFIObject *self, char *message);
TelosFFIObject* TelosFFIObject_clone(TelosFFIObject *self);
void TelosFFIObject_logStateChange(TelosFFIObject *self, char *slotName, IoObject *value);

// Module Registration Functions
void IoTelosFFI_registerPrototype(IoState *state);
void IoTelosFFI_registerMethods(IoState *state, IoObject *telosProto);

// IoProxy Integration Functions
PyObject* IoTelosFFI_forwardMessage(PyObject *self, PyObject *args, PyObject *kwargs);
PyObject* IoTelosFFI_createPythonProxyObject(IoObject *ioObj, const char *proxy_type);

// Prototypal Emulation Layer - Complete Implementation
typedef struct TelosProxyObject TelosProxyObject;  // Forward declaration
void IoTelosFFI_initPrototypalEmulation(void);
TelosProxyObject* IoTelosFFI_createProxy(IoObject *ioObject);
PyObject* IoTelosFFI_createPythonProxy(TelosProxyObject *proxy);
void IoTelosFFI_destroyProxy(TelosProxyObject *proxy);

// Transactional State Updates - WAL Consistency
IoObject* IoTelosFFI_setProxyAttribute(IoObject *self, IoObject *locals, IoMessage *m);

// Enhanced LLM Chat Integration
IoObject* IoTelosFFI_chatWithLLM(IoObject *self, IoObject *locals, IoMessage *m);

#endif // IOTELOS_FFI_H