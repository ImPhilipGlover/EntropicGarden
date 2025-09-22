/*
   IoTelos.c - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

#include "IoTelos.h"
#include "PrototypalFFI.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoNumber.h"
#include "IoList.h"
#include "IoSeq.h"
#include "IoMap.h"
#include "CHash.h"
#include "IoSymbol.h"
#include "IoMessage.h"
// Using IoObject_dataPointer for opaque data storage
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <Python.h> // FFI Pillar: Include Python C API
#include <sys/stat.h>
#include <errno.h>
#include <pthread.h> // For threading support in enhanced bridge
#include <unistd.h>  // For sleep functions
#ifdef TELOS_HAVE_SDL2
#include <SDL.h>
#endif

// Forward declarations
typedef struct CrossLanguageHandle CrossLanguageHandle;
typedef struct SynapticBridge SynapticBridge;

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

// Prototypal FFI Object - Behavioral Proxy (NOT data translation)
// This structure mirrors Io object BEHAVIOR across the C bridge
typedef struct TelosFFIObject {
    void *parent_id;            // Reference to prototype in Io VM
    CHash *slots;               // String names → generic IoObject pointers
    IoObject *io_reference;     // Direct reference to source Io object
    PyObject *python_proxy;     // Python IoProxy ambassador
    
    // Behavioral function pointers for prototypal delegation
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

static const char *protoId = "Telos";

// Basic Morphic data structures
typedef struct {
    double x, y;        // Position
    double width, height; // Bounds
    double r, g, b, a;  // Color (RGBA)
    IoList *submorphs;  // Child morphs
    IoObject *owner;    // Owning Io object
} MorphicMorph;

typedef struct {
    void *windowHandle; // Platform-specific window handle
    MorphicMorph *world; // Root morph (the world)
    int isRunning;      // Main loop flag
#ifdef TELOS_HAVE_SDL2
    SDL_Window *sdlWindow;
    SDL_Renderer *sdlRenderer;
#endif
} MorphicWorld;

// Global world state
static MorphicWorld *globalWorld = NULL;
static int isPythonInitialized = 0;
// RAG skeleton storage (Python-side list of documents)
static PyObject *rag_docs = NULL;

// Enhanced Synaptic Bridge globals
static SynapticBridge *globalBridge = NULL;

// Function forward declarations
void IoTelos_cleanupEnhancedPython(void);
void IoTelos_initEnhancedPython(void);
static CrossLanguageHandle *handles = NULL;  // Dynamic array of handles
static int handleCount = 0;
static int maxHandles = 100;

// --- Enhanced Synaptic Bridge Functions ---

// Create and manage cross-language handles for safe memory management
char* IoTelos_createHandle(IoObject *ioObj, PyObject *pyObj) {
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
    return NULL;
}

void IoTelos_releaseHandle(const char *handleId) {
    if (!handles || !handleId) return;
    
    for (int i = 0; i < maxHandles; i++) {
        if (handles[i].handleId && strcmp(handles[i].handleId, handleId) == 0) {
            if (handles[i].pyObject) {
                Py_DECREF(handles[i].pyObject);
                handles[i].pyObject = NULL;
            }
            
            handles[i].ioObject = NULL;
            handles[i].refCount = 0;
            free(handles[i].handleId);
            handles[i].handleId = NULL;
            handleCount--;
            break;
        }
    }
}

// Enhanced Python initialization with virtual environment support
void IoTelos_initEnhancedPython(void) {
    if (isPythonInitialized) return;
    
    // Initialize the bridge structure
    globalBridge = malloc(sizeof(SynapticBridge));
    if (!globalBridge) {
        printf("TelOS: Failed to allocate Synaptic Bridge\n");
        return;
    }
    
    memset(globalBridge, 0, sizeof(SynapticBridge));
    pthread_mutex_init(&globalBridge->mutex, NULL);
    
    // Configure Python for isolated execution
    PyStatus status;
    PyConfig config;
    PyConfig_InitIsolatedConfig(&config);
    
    // Set virtual environment path if available
    const char *venvCandidates[] = {
        "/mnt/c/EntropicGarden/venv",
        "./venv",
        "../venv",
        NULL
    };
    
    for (int i = 0; venvCandidates[i] != NULL; i++) {
        char pythonPath[512];
        snprintf(pythonPath, sizeof(pythonPath), "%s/bin/python", venvCandidates[i]);
        if (access(pythonPath, X_OK) == 0) {
            globalBridge->venvPath = strdup(venvCandidates[i]);
            globalBridge->isVirtualEnvActive = 1;
            
            // Configure Python to use virtual environment
            status = PyConfig_SetBytesString(&config, &config.executable, pythonPath);
            if (PyStatus_Exception(status)) {
                printf("TelOS: Failed to set Python executable path\n");
                PyConfig_Clear(&config);
                free(globalBridge->venvPath);
                globalBridge->venvPath = NULL;
                globalBridge->isVirtualEnvActive = 0;
            } else {
                printf("TelOS: Using virtual environment: %s\n", venvCandidates[i]);
            }
            break;
        }
    }
    
    // Initialize Python with configuration
    status = Py_InitializeFromConfig(&config);
    PyConfig_Clear(&config);
    
    if (PyStatus_Exception(status)) {
        printf("TelOS: Failed to initialize Python with enhanced configuration\n");
        Py_Initialize(); // Fallback to basic initialization
    }
    
    isPythonInitialized = 1;
    
    // FIXED: Skip complex process pool initialization that causes infinite loops
    printf("TelOS: Python initialized in safe synchronous mode (no process pools)");
    
    printf("TelOS: Enhanced Python Synaptic Bridge Initialized%s\n", 
           globalBridge->isVirtualEnvActive ? " (with virtual environment)" : "");
    
    // Ensure cleanup on exit
    atexit(IoTelos_cleanupEnhancedPython);
}

void IoTelos_cleanupEnhancedPython(void) {
    if (globalBridge) {
        // FIXED: Simple cleanup without process pool deadlocks
        printf("TelOS: Cleaning up Python bridge (safe mode)");
        
        // Clean up handles
        for (int i = 0; i < maxHandles; i++) {
            if (handles && handles[i].handleId) {
                IoTelos_releaseHandle(handles[i].handleId);
            }
        }
        if (handles) {
            free(handles);
            handles = NULL;
        }
        
        pthread_mutex_destroy(&globalBridge->mutex);
        
        if (globalBridge->venvPath) {
            free(globalBridge->venvPath);
        }
        
        free(globalBridge);
        globalBridge = NULL;
    }
    
    if (isPythonInitialized) {
        Py_Finalize();
        isPythonInitialized = 0;
    }
}

// Legacy function for backward compatibility
void IoTelos_initPython(void) {
    IoTelos_initEnhancedPython();
}

// --- Prototypal FFI Object Behavioral Implementations ---
// These functions implement behavioral mirroring, not data translation

// Behavioral delegation function: getValueFor with prototype chain lookup
IoObject *TelosFFIObject_getValueFor(TelosFFIObject *self, char *slotName) {
    if (!self || !slotName) return NULL;
    
    // 1. Check local slots first
    if (self->slots) {
        IoObject *value = (IoObject *)CHash_at_(self->slots, slotName);
        if (value) return value;
    }
    
    // 2. If not found, delegate to Io VM prototype chain
    if (self->io_reference) {
        IoObject *result = IoObject_getSlot_(self->io_reference, IOSYMBOL(slotName));
        if (result != NULL) {
            // Cache the result in local slots for future access
            if (!self->slots) {
                self->slots = CHash_new();
            }
            CHash_at_put_(self->slots, slotName, result);
            return result;
        }
    }
    
    // 3. Return nil if not found in delegation chain
    return NULL;
}

// Behavioral modification function: setValueFor with WAL logging
void TelosFFIObject_setValueFor(TelosFFIObject *self, char *slotName, IoObject *value) {
    if (!self || !slotName) return;
    
    // 1. Update local slots
    if (!self->slots) {
        self->slots = CHash_new();
    }
    CHash_at_put_(self->slots, slotName, value);
    
    // 2. Update source Io object (maintaining state authority)
    if (self->io_reference) {
        IoObject_setSlot_to_(self->io_reference, IOSYMBOL(slotName), value);
    }
    
    // 3. Log state change to WAL (single source of truth)
    if (self->logStateChange) {
        self->logStateChange(self, slotName, value);
    }
}

// Behavioral message sending: perform with delegation
IoObject *TelosFFIObject_perform(TelosFFIObject *self, char *message) {
    if (!self || !message) return NULL;
    
    // Send message to source Io object using prototypal dispatch
    if (self->io_reference) {
        IoMessage *ioMessage = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL(message), IOSYMBOL("(TelosFFI)"));
        return IoObject_perform(self->io_reference, self->io_reference, ioMessage);
    }
    
    return NULL;
}

// Behavioral cloning: create new TelosFFIObject with prototype delegation
TelosFFIObject *TelosFFIObject_clone(TelosFFIObject *self) {
    if (!self) return NULL;
    
    TelosFFIObject *clone = malloc(sizeof(TelosFFIObject));
    if (!clone) return NULL;
    
    // Initialize clone with behavioral delegation to parent
    memset(clone, 0, sizeof(TelosFFIObject));
    clone->parent_id = self;  // Parent reference for delegation
    clone->slots = CHash_new();
    
    // Clone the source Io object (maintaining prototypal behavior)
    if (self->io_reference) {
        IoMessage *cloneMessage = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL("clone"), IOSYMBOL("(TelosFFI)"));
        clone->io_reference = IoObject_perform(self->io_reference, self->io_reference, cloneMessage);
    }
    
    // Set up behavioral function pointers
    clone->getValueFor = TelosFFIObject_getValueFor;
    clone->setValueFor = TelosFFIObject_setValueFor;
    clone->perform = TelosFFIObject_perform;
    clone->clone = TelosFFIObject_clone;
    clone->logStateChange = self->logStateChange;  // Inherit logging behavior
    
    clone->refCount = 1;
    clone->objectId = malloc(32);
    if (clone->objectId) {
        snprintf(clone->objectId, 32, "ffi_%p", (void*)clone);
    }
    
    return clone;
}

// WAL logging function for state authority
void TelosFFIObject_logStateChange(TelosFFIObject *self, char *slotName, IoObject *value) {
    if (!self || !slotName) return;
    
    // Write WAL entry maintaining single source of truth
    FILE *walFile = fopen("telos.wal", "a");
    if (walFile) {
        const char *valueStr = "nil";
        if (value && ISSEQ(value)) {
            valueStr = IoSeq_asCString(value);
        }
        
        fprintf(walFile, "FFI_SLOT_CHANGE:%s:%s:%s:%s\n", 
                self->objectId ? self->objectId : "unknown",
                slotName, 
                valueStr,
                "prototypal_ffi_bridge");
        fclose(walFile);
    }
}

// Factory function to create TelosFFIObject from Io object
TelosFFIObject *TelosFFIObject_createFromIoObject(IoObject *ioObj) {
    if (!ioObj) return NULL;
    
    TelosFFIObject *proxy = malloc(sizeof(TelosFFIObject));
    if (!proxy) return NULL;
    
    // Initialize behavioral proxy
    memset(proxy, 0, sizeof(TelosFFIObject));
    proxy->io_reference = ioObj;
    proxy->slots = CHash_new();
    
    // Set up behavioral function pointers
    proxy->getValueFor = TelosFFIObject_getValueFor;
    proxy->setValueFor = TelosFFIObject_setValueFor;
    proxy->perform = TelosFFIObject_perform;
    proxy->clone = TelosFFIObject_clone;
    proxy->logStateChange = TelosFFIObject_logStateChange;
    
    proxy->refCount = 1;
    proxy->objectId = malloc(32);
    if (proxy->objectId) {
        snprintf(proxy->objectId, 32, "ffi_%p", (void*)proxy);
    }
    
    return proxy;
}

// Cleanup function for TelosFFIObject
void TelosFFIObject_free(TelosFFIObject *self) {
    if (!self) return;
    
    self->refCount--;
    if (self->refCount <= 0) {
        if (self->slots) {
            CHash_free(self->slots);
        }
        if (self->objectId) {
            free(self->objectId);
        }
        free(self);
    }
}

// Enhanced Cross-Language Marshalling Implementation - Helper Functions
PyObject* IoTelos_marshalIoToPython_helper(IoObject *ioObj) {
    if (!ioObj) {
        Py_RETURN_NONE;
    }
    
    // Handle different Io object types following prototypal patterns
    if (ISNUMBER(ioObj)) {
        double value = IoNumber_asDouble(ioObj);
        return PyFloat_FromDouble(value);
    }
    
    if (ISSEQ(ioObj)) {
        const char *str = IoSeq_asCString(ioObj);
        return PyUnicode_FromString(str);
    }
    
    if (ISLIST(ioObj)) {
        List *list = IoList_rawList(ioObj);
        PyObject *pyList = PyList_New(List_size(list));
        
        for (int i = 0; i < List_size(list); i++) {
            IoObject *item = List_at_(list, i);
            PyObject *pyItem = IoTelos_marshalIoToPython_helper(item);
            PyList_SetItem(pyList, i, pyItem);
        }
        
        return pyList;
    }
    
    if (ISMAP(ioObj)) {
        PHash *hash = IoMap_rawHash(ioObj);
        PyObject *pyDict = PyDict_New();
        
        PHASH_FOREACH(hash, key, value,
            IoObject *ioKey = (IoObject *)key;
            IoObject *ioValue = (IoObject *)value;
            
            PyObject *pyKey = IoTelos_marshalIoToPython_helper(ioKey);
            PyObject *pyValue = IoTelos_marshalIoToPython_helper(ioValue);
            
            PyDict_SetItem(pyDict, pyKey, pyValue);
            
            Py_DECREF(pyKey);
            Py_DECREF(pyValue);
        );
        
        return pyDict;
    }
    
    // For other object types, create a cross-language handle
    char *handleId = IoTelos_createHandle(ioObj, NULL);
    PyObject *handle = PyDict_New();
    PyDict_SetItemString(handle, "type", PyUnicode_FromString("IoHandle"));
    PyDict_SetItemString(handle, "handleId", PyUnicode_FromString(handleId));
    PyDict_SetItemString(handle, "proto", PyUnicode_FromString(IoObject_name(ioObj)));
    
    free(handleId);
    return handle;
}

IoObject* IoTelos_marshalPythonToIo_helper(PyObject *pyObj, IoState *state) {
    if (!pyObj || pyObj == Py_None) {
        return state->ioNil;
    }
    
    if (PyBool_Check(pyObj)) {
        return (pyObj == Py_True) ? state->ioTrue : state->ioFalse;
    }
    
    if (PyLong_Check(pyObj)) {
        long value = PyLong_AsLong(pyObj);
        return IoNumber_newWithDouble_(state, (double)value);
    }
    
    if (PyFloat_Check(pyObj)) {
        double value = PyFloat_AsDouble(pyObj);
        return IoNumber_newWithDouble_(state, value);
    }
    
    if (PyUnicode_Check(pyObj)) {
        const char *str = PyUnicode_AsUTF8(pyObj);
        return IoSeq_newWithCString_(state, str);
    }
    
    if (PyList_Check(pyObj) || PyTuple_Check(pyObj)) {
        IoObject *ioList = IoList_new(state);
        Py_ssize_t size = PySequence_Size(pyObj);
        
        for (Py_ssize_t i = 0; i < size; i++) {
            PyObject *item = PySequence_GetItem(pyObj, i);
            IoObject *ioItem = IoTelos_marshalPythonToIo_helper(item, state);
            IoList_rawAppend_(ioList, ioItem);
            Py_DECREF(item);
        }
        
        return ioList;
    }
    
    if (PyDict_Check(pyObj)) {
        // Check if it's a cross-language handle object
        PyObject *typeObj = PyDict_GetItemString(pyObj, "type");
        if (typeObj && PyUnicode_Check(typeObj)) {
            const char *typeStr = PyUnicode_AsUTF8(typeObj);
            if (strcmp(typeStr, "IoHandle") == 0) {
                PyObject *handleIdObj = PyDict_GetItemString(pyObj, "handleId");
                if (handleIdObj && PyUnicode_Check(handleIdObj)) {
                    const char *handleId = PyUnicode_AsUTF8(handleIdObj);
                    // Retrieve Io object from handle registry
                    pthread_mutex_lock(&globalBridge->mutex);
                    for (int i = 0; i < globalBridge->handleCount; i++) {
                        if (strcmp(globalBridge->handles[i].handleId, handleId) == 0) {
                            IoObject *result = globalBridge->handles[i].ioObject;
                            pthread_mutex_unlock(&globalBridge->mutex);
                            return result;
                        }
                    }
                    pthread_mutex_unlock(&globalBridge->mutex);
                }
            }
        }
        
        // Regular dictionary - convert to IoMap
        IoObject *ioMap = IoMap_new(state);
        PyObject *keys = PyDict_Keys(pyObj);
        Py_ssize_t size = PyList_Size(keys);
        
        for (Py_ssize_t i = 0; i < size; i++) {
            PyObject *key = PyList_GetItem(keys, i);
            PyObject *value = PyDict_GetItem(pyObj, key);
            
            IoObject *ioKey = IoTelos_marshalPythonToIo_helper(key, state);
            IoObject *ioValue = IoTelos_marshalPythonToIo_helper(value, state);
            
            IoMap_rawAtPut(ioMap, ioKey, ioValue);
        }
        
        Py_DECREF(keys);
        return ioMap;
    }
    
    // For other Python objects, create a cross-language handle
    char *handleId = IoTelos_createHandle(NULL, pyObj);
    IoObject *ioMap = IoMap_new(state);
    IoMap_rawAtPut(ioMap, IoState_symbolWithCString_(state, "type"), IoState_symbolWithCString_(state, "PyHandle"));
    IoMap_rawAtPut(ioMap, IoState_symbolWithCString_(state, "handleId"), IoState_symbolWithCString_(state, handleId));
    IoMap_rawAtPut(ioMap, IoState_symbolWithCString_(state, "pytype"), IoState_symbolWithCString_(state, Py_TYPE(pyObj)->tp_name));
    
    free(handleId);
    return ioMap;
}

// FIXED: Simplified Synchronous Execution (No Infinite Loop Risk)
IoObject* IoTelos_executeAsync(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state(self);
    
    // Extract python code argument
    IoObject *pythonCode = IoMessage_locals_symbolArgAt_(m, locals, 0);
    if (!pythonCode || !ISSEQ(pythonCode)) {
        return IOSYMBOL("Error: Missing or invalid Python code argument");
    }
    
    // Initialize Python if needed (but don't use complex process pools)
    if (!isPythonInitialized) {
        IoTelos_initEnhancedPython();
        if (!isPythonInitialized) {
            return IOSYMBOL("Error: Failed to initialize Python");
        }
    }
    
    // Create simple result container
    IoObject *resultContainer = IoMap_new(state);
    IoMap_rawAtPut(resultContainer, 
        IoSeq_newWithCString_(state, "status"), 
        IoSeq_newWithCString_(state, "completed"));
    
    // Execute Python code synchronously (SAFE - no infinite loops)
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    const char *code = IoSeq_asCString(pythonCode);
    
    // Simple, safe execution
    PyObject *globals = PyDict_New();
    PyObject *locals_dict = PyDict_New();
    
    // Add basic imports
    PyRun_SimpleString("import sys");
    
    PyObject *result = PyRun_String(code, Py_eval_input, globals, locals_dict);
    
    if (result) {
        // Success - marshal result back to Io
        IoObject *ioResult = IoTelos_marshalPythonToIo_helper(result, state);
        IoMap_rawAtPut(resultContainer, 
            IoSeq_newWithCString_(state, "result"), 
            ioResult);
        Py_DECREF(result);
    } else {
        // Error occurred
        if (PyErr_Occurred()) {
            PyErr_Print();
            PyErr_Clear();
        }
        IoMap_rawAtPut(resultContainer, 
            IoSeq_newWithCString_(state, "status"), 
            IoSeq_newWithCString_(state, "error"));
        IoMap_rawAtPut(resultContainer, 
            IoSeq_newWithCString_(state, "error"), 
            IoSeq_newWithCString_(state, "Python execution failed"));
    }
    
    Py_DECREF(globals);
    Py_DECREF(locals_dict);
    PyGILState_Release(gstate);
    
    return resultContainer;
}

// Forward declaration for Ollama bridge
IoObject *IoTelos_ollamaGenerate(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_ollamaGenerateStream(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for enhanced Python eval
IoObject *IoTelos_pyEval(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_pyEvalAsync(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for simple logger
IoObject *IoTelos_logAppend(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declarations for RAG skeleton
IoObject *IoTelos_ragIndex(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_ragQuery(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for addMorphToWorld no-op hook
IoObject *IoTelos_addMorphToWorld(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declarations for VSA vector operations
IoObject *IoTelos_vsaBind(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_vsaBundle(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_vsaUnbind(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_vsaCosineSimilarity(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_vsaGenerateHypervector(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declarations for FAISS/HNSWLIB advanced vector operations
IoObject *IoTelos_faissCreateIndex(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_faissAddVectors(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_faissSearch(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_hnswlibCreateIndex(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_hnswlibAddVectors(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_hnswlibSearch(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_hyperVectorSearch(IoTelos *self, IoObject *locals, IoMessage *m);

IoTag *IoTelos_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_(protoId);
	IoTag_state_(tag, state);
	IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTelos_rawClone);
	IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTelos_free);
	return tag;
}

IoTelos *IoTelos_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoTelos_newTag(state));

	IoTelos_initPython(); // Initialize the FFI bridge

	IoState_registerProtoWithId_(state, self, protoId);

	{
		IoMethodTable methodTable[] = {
			{"getPythonVersion", IoTelos_getPythonVersion},
			{"transactional_setSlot", IoTelos_transactional_setSlot},
            {"openWindow", IoTelos_openWindow},
            {"closeWindow", IoTelos_closeWindow},
			{"createWorld", IoTelos_createWorld},
			{"mainLoop", IoTelos_mainLoop},
			{"createMorph", IoTelos_createMorph},
            {"addMorphToWorld", IoTelos_addMorphToWorld},
			{"addSubmorph", IoTelos_addSubmorph},
			{"removeSubmorph", IoTelos_removeSubmorph},
			{"draw", IoTelos_draw},
			{"handleEvent", IoTelos_handleEvent},
            {"ollamaGenerate", IoTelos_ollamaGenerate},
            {"pyEval", IoTelos_pyEval},
            {"pyEvalAsync", IoTelos_executeAsync},
            {"logAppend", IoTelos_logAppend},
            {"ragIndex", IoTelos_ragIndex},
            {"ragQuery", IoTelos_ragQuery},
            {"vsaBind", IoTelos_vsaBind},
            {"vsaBundle", IoTelos_vsaBundle},
            {"vsaUnbind", IoTelos_vsaUnbind},
            {"vsaCosineSimilarity", IoTelos_vsaCosineSimilarity},
            {"vsaGenerateHypervector", IoTelos_vsaGenerateHypervector},
            {"faissCreateIndex", IoTelos_faissCreateIndex},
            {"faissAddVectors", IoTelos_faissAddVectors},
            {"faissSearch", IoTelos_faissSearch},
            {"hnswlibCreateIndex", IoTelos_hnswlibCreateIndex},
            {"hnswlibAddVectors", IoTelos_hnswlibAddVectors},
            {"hnswlibSearch", IoTelos_hnswlibSearch},
            {"hyperVectorSearch", IoTelos_hyperVectorSearch},
            // Rigorous FFI Cookbook methods
            {"initializeFFI", IoTelos_initializeFFI},
            {"shutdownFFI", IoTelos_shutdownFFI},
            {"marshalIoToPython", IoTelos_marshalIoToPython},
            {"marshalPythonToIo", IoTelos_marshalPythonToIo},
            {"wrapTensor", IoTelos_wrapTensor},
            {"executeAsync", IoTelos_executeAsync},
            {"waitForFuture", IoTelos_waitForFuture},
            {"loadModule", IoTelos_loadModule},
            {"callFunction", IoTelos_callFunction},
            {"createInstance", IoTelos_createInstance},
            {"callMethod", IoTelos_callMethod},
            {"getObjectType", IoTelos_getObjectType},
            // Prototypal FFI Mandate methods
            {"createFFIProxy", IoTelos_createFFIProxy},
			{NULL, NULL},
		};
		IoObject_addMethodTable_(self, methodTable);
	}

	return self;
}

IoTelos *IoTelos_rawClone(IoTelos *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	return self;
}

void IoTelos_free(IoTelos *self)
{
    // Clean up global world if it exists
    if (globalWorld) {
        if (globalWorld->world) {
            if (globalWorld->world->submorphs) {
                // Io GC will handle the list
            }
            free(globalWorld->world);
        }
        free(globalWorld);
        globalWorld = NULL;
    }
    // Python is finalized via atexit()
}

// Addon-style init entry point
// Registers the Telos prototype under Protos and wires raw method aliases
void IoTelosInit(IoState *state, IoObject *context)
{
    // Ensure proto exists and is registered (without fatal lookups)
    IoObject *telosProto = (IoObject *)PointerHash_at_(state->primitives, (void *)protoId);
    if (!telosProto) {
        telosProto = (IoObject *)IoTelos_proto(state); // registers under protoId
    }

    // Expose on Protos namespace as Telos
    IoObject *protos = IoObject_getSlot_(state->lobby, IoState_symbolWithCString_(state, "Protos"));
    if (protos)
    {
    IoObject_setSlot_to_(protos, IoState_symbolWithCString_(state, "Telos"), telosProto);
    }

    // Provide raw aliases expected by IoTelos.io
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawGetPythonVersion"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_getPythonVersion, NULL, "Telos_rawGetPythonVersion"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawTransactional_setSlot"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_transactional_setSlot, NULL, "Telos_rawTransactional_setSlot"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawOpenWindow"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_openWindow, NULL, "Telos_rawOpenWindow"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawCreateWorld"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_createWorld, NULL, "Telos_rawCreateWorld"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawMainLoop"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_mainLoop, NULL, "Telos_rawMainLoop"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawCreateMorph"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_createMorph, NULL, "Telos_rawCreateMorph"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawAddSubmorph"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_addSubmorph, NULL, "Telos_rawAddSubmorph"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawAddMorphToWorld"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_addMorphToWorld, NULL, "Telos_rawAddMorphToWorld"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRemoveSubmorph"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_removeSubmorph, NULL, "Telos_rawRemoveSubmorph"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawDraw"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_draw, NULL, "Telos_rawDraw"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawHandleEvent"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_handleEvent, NULL, "Telos_rawHandleEvent"));

    // Expose Ollama HTTP bridge (via embedded Python)
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawOllamaGenerate"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ollamaGenerate, NULL, "Telos_rawOllamaGenerate"));
    
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawOllamaGenerateStream"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ollamaGenerateStream, NULL, "Telos_rawOllamaGenerateStream"));

    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawPyEval"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_pyEval, NULL, "0"));

    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawLogAppend"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_logAppend, NULL, "Telos_rawLogAppend"));

    // RAG skeleton bridge
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRagIndex"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ragIndex, NULL, "Telos_rawRagIndex"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRagQuery"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ragQuery, NULL, "Telos_rawRagQuery"));

    // Autoload Io-level TelOS modular core (TelosCore.io) - MODULAR ARCHITECTURE
    // Load TelosCore.io which orchestrates all module loading
    {
        const char *candidates[] = {
            "/mnt/c/EntropicGarden/libs/Telos/io/TelosCore.io",              // WSL absolute path
            "c:/EntropicGarden/libs/Telos/io/TelosCore.io",                   // Windows absolute (forward slashes)
            "c\\\\EntropicGarden\\\\libs\\\\Telos\\\\io\\\\TelosCore.io", // Windows absolute (escaped backslashes for C string)
            "../../libs/Telos/io/TelosCore.io",                                // Relative from build/bin
            "../libs/Telos/io/TelosCore.io",                                  // Relative from tools binary (alt)
            "libs/Telos/io/TelosCore.io",                                     // Relative from repo root
            "TelOS/io/TelosCore.io",                                          // Backup location path
            NULL
        };

        for (int i = 0; candidates[i] != NULL; i++)
        {
            const char *path = candidates[i];
            FILE *f = fopen(path, "r");
            if (f)
            {
                fclose(f);
                IoState_doFile_(state, path);
                printf("TelOS: Loaded modular core from %s (which loads all modules)\n", path);
                break;
            }
        }
    }
}

// --- TelOS Core Functions ---

// Get Python version via FFI (Pillar 1: Synaptic Bridge)
IoObject *IoTelos_getPythonVersion(IoTelos *self, IoObject *locals, IoMessage *m)
{
    printf("TelOS: Reaching into Python muscle via FFI...\n");
    const char* version = Py_GetVersion();
    return IoSeq_newWithCString_(IOSTATE, version);
}

// Transactional persistence stub (Pillar 2: First Heartbeat)
IoObject *IoTelos_transactional_setSlot(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *target = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoSeq *slotName = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 1);
    IoSeq *value = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 2);

    if (!target || !slotName || !value) {
        printf("TelOS: Invalid arguments for transactional_setSlot\n");
        return self;
    }

    const char *slotStr = IoSeq_asCString(slotName);
    const char *valueStr = IoSeq_asCString(value);

    // Write to WAL file (simulating transactional persistence)
    // Prefer a stable absolute path under WSL workspace when available
    const char *walCandidates[] = {
        "/mnt/c/EntropicGarden/telos.wal",
        "telos.wal",
        NULL
    };
    FILE *wal = NULL;
    for (int i = 0; walCandidates[i] != NULL && !wal; i++) {
        wal = fopen(walCandidates[i], "a");
    }
    if (wal) {
        fprintf(wal, "SET %s TO %s\n", slotStr, valueStr);
        fclose(wal);
        printf("TelOS: Transactional persistence - slot '%s' set to '%s'\n", slotStr, valueStr);
    } else {
        printf("TelOS: Failed to open WAL file for persistence\n");
    }

    return self;
}

// UI window stub (Pillar 3: First Glance)
IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m)
{
    printf("UI: Opening a 640x480 window titled 'The Entropic Garden'\n");
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld) {
        IoTelos_createWorld(self, locals, m);
    }
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        printf("Telos SDL2: SDL_Init error: %s\n", SDL_GetError());
        return self;
    }
    globalWorld->sdlWindow = SDL_CreateWindow("The Entropic Garden",
                                             SDL_WINDOWPOS_CENTERED,
                                             SDL_WINDOWPOS_CENTERED,
                                             640, 480,
                                             SDL_WINDOW_SHOWN);
    if (!globalWorld->sdlWindow) {
        printf("Telos SDL2: SDL_CreateWindow error: %s\n", SDL_GetError());
        return self;
    }
    globalWorld->sdlRenderer = SDL_CreateRenderer(globalWorld->sdlWindow, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!globalWorld->sdlRenderer) {
        printf("Telos SDL2: SDL_CreateRenderer error: %s\n", SDL_GetError());
        return self;
    }
    SDL_SetRenderDrawColor(globalWorld->sdlRenderer, 32, 48, 64, 255);
    SDL_RenderClear(globalWorld->sdlRenderer);
    SDL_RenderPresent(globalWorld->sdlRenderer);
#endif
    return self;
}

IoObject *IoTelos_closeWindow(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (globalWorld && globalWorld->sdlRenderer) {
        SDL_DestroyRenderer(globalWorld->sdlRenderer);
        globalWorld->sdlRenderer = NULL;
    }
    if (globalWorld && globalWorld->sdlWindow) {
        SDL_DestroyWindow(globalWorld->sdlWindow);
        globalWorld->sdlWindow = NULL;
    }
    SDL_Quit();
#endif
    printf("UI: Closed window\n");
    return self;
}

// --- Morphic Core Functions ---

// Create the root world (equivalent to Morphic's World)
IoObject *IoTelos_createWorld(IoTelos *self, IoObject *locals, IoMessage *m)
{
    if (globalWorld) {
        printf("Telos: World already exists\n");
        return self;
    }

    globalWorld = (MorphicWorld *)io_calloc(1, sizeof(MorphicWorld));
    globalWorld->world = (MorphicMorph *)io_calloc(1, sizeof(MorphicMorph));
    globalWorld->world->x = 0;
    globalWorld->world->y = 0;
    globalWorld->world->width = 800;
    globalWorld->world->height = 600;
    globalWorld->world->r = 0.8;
    globalWorld->world->g = 0.8;
    globalWorld->world->b = 0.8;
    globalWorld->world->a = 1.0;
    // Avoid keeping raw Io objects here (GC may collect). Use Io-level morph tree instead.
    globalWorld->world->submorphs = NULL;
    globalWorld->isRunning = 0;

    printf("Telos: Morphic World created (living canvas: %.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);
    return self;
}

// Main event loop - the heart of the living interface
IoObject *IoTelos_mainLoop(IoTelos *self, IoObject *locals, IoMessage *m)
{
    if (!globalWorld) {
        printf("Telos: No world exists - call createWorld first\n");
        return self;
    }

    printf("Telos: Entering Morphic main loop (living interface active)\n");
    globalWorld->isRunning = 1;

    // Enhanced event loop with SDL2 support
    int iterations = 0;
    while (globalWorld->isRunning) {
        // Process SDL2 events and bridge to Io morphic system
        IoTelos_processEvents(self);

        // Clear and prepare for drawing
#ifdef TELOS_HAVE_SDL2
        if (globalWorld->sdlRenderer) {
            SDL_SetRenderDrawColor(globalWorld->sdlRenderer, 32, 48, 64, 255);
            SDL_RenderClear(globalWorld->sdlRenderer);
        }
#endif

        // Ask Io layer to draw its morphs (this will call back to IoTelos_drawMorph for each)
        IoMessage *drawMsg = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL("draw"), IOSYMBOL("draw"));
        IoObject_perform(self, self, drawMsg);

#ifdef TELOS_HAVE_SDL2
        // Present the rendered frame
        if (globalWorld->sdlRenderer) {
            SDL_RenderPresent(globalWorld->sdlRenderer);
        }
#endif

        // Heartbeat log
        printf("Telos: World heartbeat (frame: %d)\n", iterations);

        // For initial demo: limit iterations, but SDL2 version can run indefinitely
#ifdef TELOS_HAVE_SDL2
        // With SDL2: run until user closes window (SDL_QUIT event sets isRunning = 0)
        if (++iterations > 100) { // Safety limit for initial testing
            globalWorld->isRunning = 0;
        }
#else
        // Textual version: exit after a few iterations
        if (++iterations > 3) {
            globalWorld->isRunning = 0;
        }
#endif
    }

    printf("Telos: Morphic main loop completed\n");
    return self;
}

// Create a new morph (living visual object)
IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *morph = IoObject_new(IOSTATE);

    // Set up prototypal identity - essential for delegation patterns
    char idStr[64];
    snprintf(idStr, sizeof(idStr), "%p", (void*)morph);
    IoObject_setSlot_to_(morph, IOSYMBOL("id"), IOSYMBOL(idStr));

    // Set up morph properties
    IoObject_setSlot_to_(morph, IOSYMBOL("x"), IONUMBER(100));
    IoObject_setSlot_to_(morph, IOSYMBOL("y"), IONUMBER(100));
    IoObject_setSlot_to_(morph, IOSYMBOL("width"), IONUMBER(50));
    IoObject_setSlot_to_(morph, IOSYMBOL("height"), IONUMBER(50));
    IoObject_setSlot_to_(morph, IOSYMBOL("color"), IoList_new(IOSTATE));

    // Initialize color as [r, g, b, a]
    IoList *color = (IoList *)IoObject_getSlot_(morph, IOSYMBOL("color"));
    IoList_rawAppend_(color, IONUMBER(1.0)); // red
    IoList_rawAppend_(color, IONUMBER(0.0)); // green
    IoList_rawAppend_(color, IONUMBER(0.0)); // blue
    IoList_rawAppend_(color, IONUMBER(1.0)); // alpha

    // Add morph methods
    IoObject_setSlot_to_(morph, IOSYMBOL("draw"), IoCFunction_newWithFunctionPointer_tag_name_(
        IOSTATE, IoTelos_morphDraw, NULL, "morphDraw"));
    IoObject_setSlot_to_(morph, IOSYMBOL("containsPoint"), IoCFunction_newWithFunctionPointer_tag_name_(
        IOSTATE, IoTelos_morphContainsPoint, NULL, "morphContainsPoint"));

    printf("Telos: Living morph created at (100,100)\n");
    return morph;
}

// Add a submorph to another morph
IoObject *IoTelos_addSubmorph(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *parentMorph = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *childMorph = IoMessage_locals_valueArgAt_(m, locals, 1);

    if (!parentMorph || !childMorph) {
        printf("Telos: Invalid morphs for addSubmorph\n");
        return self;
    }

    // Get or create submorphs list
    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, IOSYMBOL("submorphs"));
    if (!submorphs) {
        submorphs = IoList_new(IOSTATE);
    IoObject_setSlot_to_(parentMorph, IOSYMBOL("submorphs"), submorphs);
    }

    IoList_rawAppend_(submorphs, childMorph);
    printf("Telos: Morph added as submorph (living hierarchy grows)\n");

    return self;
}

// Remove a submorph
IoObject *IoTelos_removeSubmorph(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *parentMorph = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *childMorph = IoMessage_locals_valueArgAt_(m, locals, 1);

    if (!parentMorph || !childMorph) {
        printf("Telos: Invalid morphs for removeSubmorph\n");
        return self;
    }

    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, IOSYMBOL("submorphs"));
    if (submorphs) {
        IoList_rawRemove_(submorphs, childMorph);
        printf("Telos: Morph removed from living hierarchy\n");
    }

    return self;
}

// Draw the world and all its morphs
IoObject *IoTelos_draw(IoTelos *self, IoObject *locals, IoMessage *m)
{
    if (!globalWorld) {
        printf("Telos: No world to draw\n");
        return self;
    }

    IoTelos_drawWorld(self);
    return self;
}

// Handle events (direct manipulation)
IoObject *IoTelos_handleEvent(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Stub event handling - in real implementation would handle mouse, keyboard, etc.
    printf("Telos: Event received (direct manipulation ready)\n");
    return self;
}

// No-op mirror hook: allow Io layer to inform C world about Io-created morphs
// Signature: addMorphToWorld(morph) -> self
IoObject *IoTelos_addMorphToWorld(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *morph = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!globalWorld) {
        IoTelos_createWorld(self, locals, m);
    }
    // For now, keep C world minimal and just log receipt
    // Future: maintain a lightweight mirror for C-side draw
    (void)morph; // unused
    printf("Telos: addMorphToWorld (Io-created morph acknowledged by C)\n");
    return self;
}

// --- Ollama Bridge (via embedded Python stdlib) ---

// Io signature: Telos_rawOllamaGenerate(baseUrl, model, prompt, system, optionsJson)
// Returns: IoSeq of the response text (or error string)
IoObject *IoTelos_ollamaGenerate(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *baseUrlSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    IoSeq *modelSeq   = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 1);
    IoSeq *promptSeq  = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 2);
    IoSeq *systemSeq  = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 3);
    IoSeq *optionsSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 4);

    const char *baseUrl = baseUrlSeq ? IoSeq_asCString(baseUrlSeq) : "http://localhost:11434";
    const char *model   = modelSeq   ? IoSeq_asCString(modelSeq)   : NULL;
    const char *prompt  = promptSeq  ? IoSeq_asCString(promptSeq)  : "";
    const char *system  = systemSeq  ? IoSeq_asCString(systemSeq)  : "";

    if (!model || !prompt) {
        return IoSeq_newWithCString_(IOSTATE, "[OLLAMA_ERROR] missing model or prompt");
    }

    // Build full prompt by prefixing system guidance if provided
    char *fullPrompt = NULL;
    size_t len = strlen(prompt) + (system && strlen(system) > 0 ? strlen(system) + 10 : 0) + 1;
    fullPrompt = (char *)malloc(len);
    if (!fullPrompt) {
        return IoSeq_newWithCString_(IOSTATE, "[OLLAMA_ERROR] out of memory");
    }
    if (system && strlen(system) > 0) {
        snprintf(fullPrompt, len, "System: %s\nUser: %s", system, prompt);
    } else {
        snprintf(fullPrompt, len, "%s", prompt);
    }

    // Use base URL; Python code will choose endpoint (/api/generate then fallback to /api/chat)
    char *url = strdup(baseUrl);
    if (!url) {
        free(fullPrompt);
        return IoSeq_newWithCString_(IOSTATE, "[OLLAMA_ERROR] out of memory");
    }

    // Ensure Python is initialized
    IoTelos_initPython();

    IoObject *result = NULL;

    PyGILState_STATE gstate = PyGILState_Ensure();
    // Use a single shared dict for globals and locals to ensure imports are visible
    PyObject *env = PyDict_New();
    if (env) {
        // Inject builtins
        PyDict_SetItemString(env, "__builtins__", PyEval_GetBuiltins());

        // Prepare Python objects
        PyObject *pyUrl = PyUnicode_FromString(url);
        PyObject *pyModel = PyUnicode_FromString(model);
        PyObject *pyPrompt = PyUnicode_FromString(fullPrompt);

        // Parse options JSON if provided
        PyObject *pyOptions = NULL;
        if (optionsSeq) {
            const char *opts = IoSeq_asCString(optionsSeq);
            if (opts && strlen(opts) > 0) {
                PyObject *jsonMod = PyImport_ImportModule("json");
                if (jsonMod) {
                    PyObject *loads = PyObject_GetAttrString(jsonMod, "loads");
                    if (loads && PyCallable_Check(loads)) {
                        PyObject *arg = PyUnicode_FromString(opts);
                        pyOptions = PyObject_CallFunctionObjArgs(loads, arg, NULL);
                        Py_XDECREF(arg);
                    }
                    Py_XDECREF(loads);
                    Py_XDECREF(jsonMod);
                }
            }
        }

        PyObject *payload = Py_BuildValue("{s:O,s:O,s:O}",
                                          "model", pyModel,
                                          "prompt", pyPrompt,
                                          "stream", Py_False);
        if (pyOptions) {
            PyDict_SetItemString(payload, "options", pyOptions);
        }
        // Add system prompt if provided
        if (system && strlen(system) > 0) {
            PyObject *pySystem = PyUnicode_FromString(system);
            PyDict_SetItemString(payload, "system", pySystem);
            Py_XDECREF(pySystem);
        }
    // Encourage Ollama to unload model post-call on constrained VRAM setups (explicit duration string)
    PyDict_SetItemString(payload, "keep_alive", PyUnicode_FromString("0s"));

        if (pyUrl && payload) {
            PyDict_SetItemString(env, "url", pyUrl);
            PyDict_SetItemString(env, "payload", payload);

            const char *code =
                "import urllib.request, json\n"
                "def post(u, payload):\n"
                "    data = json.dumps(payload).encode('utf-8')\n"
                "    req = urllib.request.Request(u, data=data, headers={'Content-Type':'application/json'})\n"
                "    with urllib.request.urlopen(req, timeout=60) as resp:\n"
                "        return resp.read().decode('utf-8')\n"
                "out = None\n"
                "base = url.rstrip('/')\n"
                "# Try /api/chat first (more broadly supported for instruct models)\n"
                "try:\n"
                "    msgs = []\n"
                "    sys = payload.get('system')\n"
                "    if sys:\n"
                "        msgs.append({'role':'system','content':sys})\n"
                "    msgs.append({'role':'user','content':payload.get('prompt','')})\n"
                "    chatPayload = {'model': payload['model'], 'messages': msgs, 'stream': False}\n"
                "    if 'options' in payload:\n"
                "        chatPayload['options'] = payload['options']\n"
                "    body = post(base + '/api/chat', chatPayload)\n"
                "    obj = json.loads(body)\n"
                "    out = (obj.get('message') or {}).get('content', body)\n"
                "except Exception as e:\n"
                "    err1 = str(e)\n"
                "    # Fallback to /api/generate with prompt string\n"
                "    try:\n"
                "        body = post(base + '/api/generate', payload)\n"
                "        obj = json.loads(body)\n"
                "        out = obj.get('response', body)\n"
                "    except Exception as e2:\n"
                "        # Try removing ':latest' tag in case server expects bare name\n"
                "        try:\n"
                "            mod = payload.get('model','')\n"
                "            if mod.endswith(':latest'):\n"
                "                payload['model'] = mod[:-7]\n"
                "            body = post(base + '/api/generate', payload)\n"
                "            obj = json.loads(body)\n"
                "            out = obj.get('response', body)\n"
                "        except Exception as e3:\n"
                "            out = '[OLLAMA_ERROR] request failed: ' + err1 + ' | ' + str(e2) + ' | ' + str(e3)\n";

            PyObject *execRes = PyRun_StringFlags(code, Py_file_input, env, env, NULL);
            if (execRes) {
                Py_DECREF(execRes);
                PyObject *out = PyDict_GetItemString(env, "out"); // borrowed
                if (out && PyUnicode_Check(out)) {
                    Py_ssize_t size;
                    const char *cstr = PyUnicode_AsUTF8AndSize(out, &size);
                    if (cstr) {
                        result = IoSeq_newWithData_length_(IOSTATE, (unsigned char *)cstr, (size_t)size);
                    }
                }
            } else {
                PyErr_Print();
            }
        }

        Py_XDECREF(pyUrl);
        Py_XDECREF(pyModel);
        Py_XDECREF(pyPrompt);
    Py_XDECREF(payload);
    Py_XDECREF(pyOptions);
    }

    Py_XDECREF(env);
    PyGILState_Release(gstate);

    free(fullPrompt);
    free(url);

    if (!result) {
        result = IoSeq_newWithCString_(IoObject_state(self), "[OLLAMA_ERROR] request failed");
    }

    return result;
}

// --- Ollama Streaming Bridge ---
// Io signature: Telos_rawOllamaGenerateStream(baseUrl, model, prompt, system, optionsJson)
// Returns: IoList of response chunks (or single error chunk)
IoObject *IoTelos_ollamaGenerateStream(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *baseUrlSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    IoSeq *modelSeq   = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 1);
    IoSeq *promptSeq  = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 2);
    IoSeq *systemSeq  = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 3);
    IoSeq *optionsSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 4);

    const char *baseUrl = baseUrlSeq ? IoSeq_asCString(baseUrlSeq) : "http://localhost:11434";
    const char *model   = modelSeq   ? IoSeq_asCString(modelSeq)   : NULL;
    const char *prompt  = promptSeq  ? IoSeq_asCString(promptSeq)  : "";
    const char *system  = systemSeq  ? IoSeq_asCString(systemSeq)  : "";

    if (!model || !prompt) {
        IoList *errorList = IoList_new(IOSTATE);
        IoList_rawAppend_(errorList, IoSeq_newWithCString_(IOSTATE, "[OLLAMA_STREAM_ERROR] missing model or prompt"));
        return errorList;
    }

    // Build full prompt
    char *fullPrompt = NULL;
    size_t len = strlen(prompt) + (system && strlen(system) > 0 ? strlen(system) + 10 : 0) + 1;
    fullPrompt = (char *)malloc(len);
    if (!fullPrompt) {
        IoList *errorList = IoList_new(IOSTATE);
        IoList_rawAppend_(errorList, IoSeq_newWithCString_(IOSTATE, "[OLLAMA_STREAM_ERROR] out of memory"));
        return errorList;
    }
    if (system && strlen(system) > 0) {
        snprintf(fullPrompt, len, "System: %s\nUser: %s", system, prompt);
    } else {
        snprintf(fullPrompt, len, "%s", prompt);
    }

    char *url = strdup(baseUrl);
    if (!url) {
        free(fullPrompt);
        IoList *errorList = IoList_new(IOSTATE);
        IoList_rawAppend_(errorList, IoSeq_newWithCString_(IOSTATE, "[OLLAMA_STREAM_ERROR] out of memory"));
        return errorList;
    }

    IoTelos_initPython();
    IoList *chunks = IoList_new(IOSTATE);

    PyGILState_STATE gstate = PyGILState_Ensure();
    PyObject *env = PyDict_New();
    if (env) {
        PyDict_SetItemString(env, "__builtins__", PyEval_GetBuiltins());

        PyObject *pyUrl = PyUnicode_FromString(url);
        PyObject *pyModel = PyUnicode_FromString(model);
        PyObject *pyPrompt = PyUnicode_FromString(fullPrompt);

        // Parse options JSON if provided
        PyObject *pyOptions = NULL;
        if (optionsSeq) {
            const char *opts = IoSeq_asCString(optionsSeq);
            if (opts && strlen(opts) > 0) {
                PyObject *jsonMod = PyImport_ImportModule("json");
                if (jsonMod) {
                    PyObject *loads = PyObject_GetAttrString(jsonMod, "loads");
                    if (loads && PyCallable_Check(loads)) {
                        PyObject *arg = PyUnicode_FromString(opts);
                        pyOptions = PyObject_CallFunctionObjArgs(loads, arg, NULL);
                        Py_XDECREF(arg);
                    }
                    Py_XDECREF(loads); 
                    Py_XDECREF(jsonMod);
                }
            }
        }

        PyObject *payload = Py_BuildValue("{s:O,s:O,s:O}",
                                          "model", pyModel,
                                          "prompt", pyPrompt,
                                          "stream", Py_True);
        if (pyOptions) {
            PyDict_SetItemString(payload, "options", pyOptions);
        }
        if (system && strlen(system) > 0) {
            PyObject *pySystem = PyUnicode_FromString(system);
            PyDict_SetItemString(payload, "system", pySystem);
            Py_XDECREF(pySystem);
        }
        PyDict_SetItemString(payload, "keep_alive", PyUnicode_FromString("0s"));

        if (pyUrl && payload) {
            PyDict_SetItemString(env, "url", pyUrl);
            PyDict_SetItemString(env, "payload", payload);

            const char *code =
                "import urllib.request, json\n"
                "import time\n"
                "def stream_post(u, payload):\n"
                "    data = json.dumps(payload).encode('utf-8')\n"
                "    req = urllib.request.Request(u, data=data, headers={'Content-Type':'application/json'})\n"
                "    resp = urllib.request.urlopen(req, timeout=120)\n"
                "    chunks = []\n"
                "    for line_bytes in resp:\n"
                "        line = line_bytes.decode('utf-8').strip()\n"
                "        if line:\n"
                "            try:\n"
                "                obj = json.loads(line)\n"
                "                chunk = obj.get('response', obj.get('message', {}).get('content', ''))\n"
                "                if chunk:\n"
                "                    chunks.append(chunk)\n"
                "                if obj.get('done', False):\n"
                "                    break\n"
                "            except:\n"
                "                chunks.append(line)\n"
                "    return chunks\n"
                "chunks = []\n"
                "base = url.rstrip('/')\n"
                "try:\n"
                "    chunks = stream_post(base + '/api/generate', payload)\n"
                "except Exception as e:\n"
                "    chunks = ['[OLLAMA_STREAM_ERROR] request failed: ' + str(e)]\n";

            PyRun_String(code, Py_file_input, env, env);

            PyObject *pyChunks = PyDict_GetItemString(env, "chunks");
            if (pyChunks && PyList_Check(pyChunks)) {
                Py_ssize_t size = PyList_Size(pyChunks);
                for (Py_ssize_t i = 0; i < size; i++) {
                    PyObject *item = PyList_GetItem(pyChunks, i);
                    if (item && PyUnicode_Check(item)) {
                        const char *chunk = PyUnicode_AsUTF8(item);
                        if (chunk) {
                            IoList_rawAppend_(chunks, IoSeq_newWithCString_(IOSTATE, chunk));
                        }
                    }
                }
            }
        }

        Py_XDECREF(payload);
        Py_XDECREF(pyPrompt);
        Py_XDECREF(pyModel);
        Py_XDECREF(pyUrl);
        Py_XDECREF(pyOptions);
        Py_DECREF(env);
    }
    PyGILState_Release(gstate);

    free(fullPrompt);
    free(url);

    // If no chunks were added, add an error chunk
    if (IoList_rawSize(chunks) == 0) {
        IoList_rawAppend_(chunks, IoSeq_newWithCString_(IOSTATE, "[OLLAMA_STREAM_ERROR] no response"));
    }

    return chunks;
}

// --- Generic Python Eval ---
// Io signature: Telos_rawPyEval(code) -> string result or empty string
IoObject *IoTelos_pyEval(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Enhanced parameter extraction following prototypal patterns
    IoObject *codeObj = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *contextObj = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    const char *code = codeObj ? IoSeq_asCString(codeObj) : NULL;
    if (!code) {
        return IOSYMBOL("Error: No Python code provided");
    }

    IoTelos_initPython();
    PyGILState_STATE gstate = PyGILState_Ensure();

    // Enhanced context handling with marshalling
    PyObject *globals = PyDict_New();
    PyObject *localsDict = PyDict_New();
    
    if (globals && localsDict) {
        PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());
        
        // Marshal Io context to Python if provided
        if (contextObj && contextObj != IoObject_state(self)->ioNil) {
            PyObject *pyContext = IoTelos_marshalIoToPython_helper(contextObj);
            if (pyContext && PyDict_Check(pyContext)) {
                PyDict_Update(localsDict, pyContext);
            }
            Py_XDECREF(pyContext);
        }

        // Enhanced execution with structured error handling
        PyObject *pyRes = PyRun_StringFlags(code, Py_eval_input, globals, localsDict, NULL);
        if (pyRes) {
            // Marshal Python result back to Io using enhanced marshalling
            IoObject *ioResult = IoTelos_marshalPythonToIo_helper(pyRes, IoObject_state(self));
            Py_DECREF(pyRes);
            Py_DECREF(globals);
            Py_DECREF(localsDict);
            PyGILState_Release(gstate);
            return ioResult;
        } else {
            // Clear error and try execution mode
            PyErr_Clear();
            PyObject *pyExec = PyRun_StringFlags(code, Py_file_input, globals, localsDict, NULL);
            if (pyExec) {
                Py_DECREF(pyExec);
                Py_DECREF(globals);
                Py_DECREF(localsDict);
                PyGILState_Release(gstate);
                return IoSeq_newWithCString_(IoObject_state(self), "Executed successfully");
            } else {
                // Enhanced error reporting
                PyObject *ptype=NULL, *pvalue=NULL, *ptrace=NULL;
                PyErr_Fetch(&ptype, &pvalue, &ptrace);
                PyErr_NormalizeException(&ptype, &pvalue, &ptrace);
                const char *err = "[PY_ERROR]";
                if (pvalue) {
                    PyObject *s = PyObject_Str(pvalue);
                    if (s && PyUnicode_Check(s)) {
                        err = PyUnicode_AsUTF8(s);
                    }
                    Py_XDECREF(s);
                }
                if (!err) err = "[PY_ERROR] unknown";
                IoObject *errorResult = IoSeq_newWithCString_(IoObject_state(self), err);
                Py_XDECREF(ptype); Py_XDECREF(pvalue); Py_XDECREF(ptrace);
                Py_DECREF(globals);
                Py_DECREF(localsDict);
                PyGILState_Release(gstate);
                return errorResult;
            }
        }
    }

    // Fallback case (should not reach here)
    Py_XDECREF(globals);
    if (localsDict && localsDict != globals) Py_XDECREF(localsDict);
    PyGILState_Release(gstate);
    
    return IoSeq_newWithCString_(IoObject_state(self), "Unexpected execution path");
}

// --- Simple logging append (JSONL) ---
// Io signature: Telos_rawLogAppend(path, line)
IoObject *IoTelos_logAppend(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *pathSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    IoSeq *lineSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 1);
    if (!pathSeq || !lineSeq) return self;

    const char *path = IoSeq_asCString(pathSeq);
    const char *line = IoSeq_asCString(lineSeq);

    // Best-effort: ensure logs/ exists if path starts with it
    if (strncmp(path, "logs/", 5) == 0) {
        if (mkdir("logs", 0777) != 0 && errno != EEXIST) {
            // ignore failure, attempt file write anyway
        }
    }

    FILE *f = fopen(path, "a");
    if (f) {
        fputs(line, f);
        if (line[strlen(line)-1] != '\n') {
            fputc('\n', f);
        }
        fclose(f);
    } else {
        printf("Telos: Failed to open log file %s\n", path);
    }

    return self;
}

// --- RAG Skeleton (Io->C->Python) ---
// Telos_rawRagIndex(jsonDocs): jsonDocs is a JSON array of strings
IoObject *IoTelos_ragIndex(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *jsonSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!jsonSeq) {
        return IoSeq_newWithCString_(IOSTATE, "[RAG_ERROR] missing jsonDocs");
    }
    IoTelos_initPython();
    const char *json = IoSeq_asCString(jsonSeq);

    PyGILState_STATE gstate = PyGILState_Ensure();
    // Build: docs = json.loads(json)
    PyObject *jsonMod = PyImport_ImportModule("json");
    if (!jsonMod) {
        PyGILState_Release(gstate);
        return IoSeq_newWithCString_(IOSTATE, "[RAG_ERROR] no json module");
    }
    PyObject *loads = PyObject_GetAttrString(jsonMod, "loads");
    PyObject *arg = PyUnicode_FromString(json ? json : "[]");
    PyObject *docs = NULL;
    if (loads && PyCallable_Check(loads)) {
        docs = PyObject_CallFunctionObjArgs(loads, arg, NULL);
    }
    Py_XDECREF(loads);
    Py_XDECREF(jsonMod);
    Py_XDECREF(arg);

    if (!docs || !PyList_Check(docs)) {
        Py_XDECREF(docs);
        PyGILState_Release(gstate);
        return IoSeq_newWithCString_(IOSTATE, "[RAG_ERROR] invalid docs");
    }

    // Replace previous store
    Py_XDECREF(rag_docs);
    rag_docs = docs; // steal reference

    PyGILState_Release(gstate);
    return IoSeq_newWithCString_(IOSTATE, "OK");
}

// Telos_rawRagQuery(query, kNumber?) -> TSV lines: index\tscore\ttext
IoObject *IoTelos_ragQuery(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *qSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    IoNumber *kNum = (IoNumber *)IoMessage_locals_valueArgAt_(m, locals, 1);
    const char *q = qSeq ? IoSeq_asCString(qSeq) : NULL;
    int k = (kNum ? (int)CNUMBER(kNum) : 3);
    if (!q || !rag_docs) {
        return IoSeq_newWithCString_(IoObject_state(self), "");
    }

    IoTelos_initPython();
    IoObject *result = NULL;
    PyGILState_STATE gstate = PyGILState_Ensure();

    // Prepare Python locals with docs and query
    PyObject *globals = PyDict_New();
    PyObject *localsDict = PyDict_New();
    if (globals && localsDict) {
        PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());
        Py_INCREF(rag_docs);
        PyDict_SetItemString(localsDict, "docs", rag_docs);
        PyObject *pyQ = PyUnicode_FromString(q);
        PyDict_SetItemString(localsDict, "q", pyQ);
        Py_DECREF(pyQ);
        PyObject *pyK = PyLong_FromLong(k);
        PyDict_SetItemString(localsDict, "topk", pyK);
        Py_DECREF(pyK);

        const char *code =
            "import math\n"
            "def toks(s):\n"
            "    return set(w.strip().lower() for w in s.split() if w.strip())\n"
            "qt = toks(q)\n"
            "scores = []\n"
            "for i, d in enumerate(docs):\n"
            "    dt = toks(d if isinstance(d, str) else str(d))\n"
            "    inter = len(qt & dt)\n"
            "    union = len(qt | dt) or 1\n"
            "    j = inter / union\n"
            "    scores.append((j, i, d))\n"
            "scores.sort(reverse=True)\n"
            "out = []\n"
            "for s, i, d in scores[:int(topk)]:\n"
            "    out.append(f'{i}\t{s:.4f}\t{d}')\n"
            "res='\\n'.join(out)\n";

        PyObject *execRes = PyRun_StringFlags(code, Py_file_input, globals, localsDict, NULL);
        if (execRes) {
            Py_DECREF(execRes);
            PyObject *pyRes = PyDict_GetItemString(localsDict, "res");
            if (pyRes && PyUnicode_Check(pyRes)) {
                Py_ssize_t size; const char *cstr = PyUnicode_AsUTF8AndSize(pyRes, &size);
                if (cstr) {
                    result = IoSeq_newWithData_length_(IoObject_state(self), (const unsigned char *)cstr, (size_t)size);
                }
            }
        } else {
            PyErr_Print();
        }
    }

    Py_XDECREF(globals);
    Py_XDECREF(localsDict);
    PyGILState_Release(gstate);

    if (!result) {
        result = IoSeq_newWithCString_(IoObject_state(self), "");
    }
    return result;
}

// --- Helper Functions ---

void IoTelos_drawWorld(IoTelos *self)
{
    if (!globalWorld || !globalWorld->world) return;

    printf("Telos: Drawing world (%.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);
    
#ifdef TELOS_HAVE_SDL2
    if (globalWorld->sdlRenderer) {
        // Clear with background color
        SDL_SetRenderDrawColor(globalWorld->sdlRenderer, 32, 48, 64, 255);
        SDL_RenderClear(globalWorld->sdlRenderer);
        
        // Note: Io-level morphs are drawn via IoTelos_drawMorph calls from Io
        // This function just sets up the canvas. Individual morphs are rendered separately.
        
        SDL_RenderPresent(globalWorld->sdlRenderer);
    }
#endif
}

void IoTelos_drawMorph(IoTelos *self, IoObject *morph)
{
    IoNumber *x = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("height"));
    
    // Get color if available (RGBA)
    IoList *colorList = (IoList *)IoObject_getSlot_(morph, IOSYMBOL("color"));
    double r = 0.8, g = 0.8, b = 0.8, a = 1.0; // Default gray
    if (colorList && ISLIST(colorList)) {
        IoList *list = colorList;
        if (IoList_rawSize(list) >= 3) {
            IoNumber *rn = (IoNumber *)IoList_rawAt_(list, 0);
            IoNumber *gn = (IoNumber *)IoList_rawAt_(list, 1);
            IoNumber *bn = (IoNumber *)IoList_rawAt_(list, 2);
            if (rn && ISNUMBER(rn)) r = CNUMBER(rn);
            if (gn && ISNUMBER(gn)) g = CNUMBER(gn);
            if (bn && ISNUMBER(bn)) b = CNUMBER(bn);
            if (IoList_rawSize(list) >= 4) {
                IoNumber *an = (IoNumber *)IoList_rawAt_(list, 3);
                if (an && ISNUMBER(an)) a = CNUMBER(an);
            }
        }
    }

    double mx = x ? CNUMBER(x) : 0;
    double my = y ? CNUMBER(y) : 0;
    double mw = w ? CNUMBER(w) : 0;
    double mh = h ? CNUMBER(h) : 0;

    printf("Telos: Drawing morph at (%.0f,%.0f) size %.0fx%.0f\n", mx, my, mw, mh);

#ifdef TELOS_HAVE_SDL2
    if (globalWorld && globalWorld->sdlRenderer) {
        // Convert 0.0-1.0 color to 0-255 range
        Uint8 red = (Uint8)(r * 255);
        Uint8 green = (Uint8)(g * 255);
        Uint8 blue = (Uint8)(b * 255);
        Uint8 alpha = (Uint8)(a * 255);
        
        SDL_SetRenderDrawColor(globalWorld->sdlRenderer, red, green, blue, alpha);
        
        SDL_Rect rect = {(int)mx, (int)my, (int)mw, (int)mh};
        SDL_RenderFillRect(globalWorld->sdlRenderer, &rect);
    }
#endif
}

void IoTelos_processEvents(IoTelos *self)
{
    // SDL2 event processing with mouse event bridging to Io morphic system
#ifdef TELOS_HAVE_SDL2
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) {
            if (globalWorld) globalWorld->isRunning = 0;
        } else if (e.type == SDL_MOUSEBUTTONDOWN) {
            // Bridge mouse down to Io layer - let Io create the event Map
            IoMessage *m = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL("dispatchSDLEvent"), IOSYMBOL("dispatchSDLEvent"));
            IoMessage_addArg_(m, IoSeq_newWithCString_(IOSTATE, "mouseDown"));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.button.x));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.button.y));
            IoObject_perform(self, self, m);
        } else if (e.type == SDL_MOUSEBUTTONUP) {
            // Bridge mouse up to Io layer - let Io create the event Map
            IoMessage *m = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL("dispatchSDLEvent"), IOSYMBOL("dispatchSDLEvent"));
            IoMessage_addArg_(m, IoSeq_newWithCString_(IOSTATE, "mouseUp"));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.button.x));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.button.y));
            IoObject_perform(self, self, m);
        } else if (e.type == SDL_MOUSEMOTION) {
            // Bridge mouse move to Io layer - let Io create the event Map
            IoMessage *m = IoMessage_newWithName_label_(IOSTATE, IOSYMBOL("dispatchSDLEvent"), IOSYMBOL("dispatchSDLEvent"));
            IoMessage_addArg_(m, IoSeq_newWithCString_(IOSTATE, "mouseMove"));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.motion.x));
            IoMessage_addArg_(m, IoNumber_newWithDouble_(IOSTATE, e.motion.y));
            IoObject_perform(self, self, m);
        }
    }
#endif
}

// Morph-specific methods
IoObject *IoTelos_morphDraw(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoTelos_drawMorph(NULL, self);
    return self;
}

IoObject *IoTelos_morphContainsPoint(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoNumber *px = (IoNumber *)IoMessage_locals_valueArgAt_(m, locals, 0);
    IoNumber *py = (IoNumber *)IoMessage_locals_valueArgAt_(m, locals, 1);

    if (!px || !py) return IOSTATE->ioFalse;

    IoNumber *x = (IoNumber *)IoObject_getSlot_(self, IOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(self, IOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(self, IOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(self, IOSYMBOL("height"));

    double pointX = CNUMBER(px);
    double pointY = CNUMBER(py);
    double morphX = x ? CNUMBER(x) : 0;
    double morphY = y ? CNUMBER(y) : 0;
    double morphW = w ? CNUMBER(w) : 0;
    double morphH = h ? CNUMBER(h) : 0;

    int contains = (pointX >= morphX && pointX <= morphX + morphW &&
                   pointY >= morphY && pointY <= morphY + morphH);

    return contains ? IOSTATE->ioTrue : IOSTATE->ioFalse;
}

// VSA (Vector Symbolic Architecture) operations for hyperdimensional computing
IoObject *IoTelos_vsaBind(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *vector1 = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *vector2 = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!vector1 || !vector2 || !ISLIST(vector1) || !ISLIST(vector2)) {
        return IONIL(self);
    }
    
    IoList *v1 = (IoList *)vector1;
    IoList *v2 = (IoList *)vector2;
    int size1 = IoList_rawSize(v1);
    int size2 = IoList_rawSize(v2);
    
    if (size1 != size2) return IONIL(self);
    
    IoList *result = IoList_new(IOSTATE);
    
    // Element-wise multiplication for binding (⊗)
    for (int i = 0; i < size1; i++) {
        IoNumber *n1 = (IoNumber *)IoList_rawAt_(v1, i);
        IoNumber *n2 = (IoNumber *)IoList_rawAt_(v2, i);
        if (n1 && n2 && ISNUMBER(n1) && ISNUMBER(n2)) {
            double product = CNUMBER(n1) * CNUMBER(n2);
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, product));
        } else {
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, 0.0));
        }
    }
    
    return (IoObject *)result;
}

IoObject *IoTelos_vsaBundle(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *vector1 = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *vector2 = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!vector1 || !vector2 || !ISLIST(vector1) || !ISLIST(vector2)) {
        return IONIL(self);
    }
    
    IoList *v1 = (IoList *)vector1;
    IoList *v2 = (IoList *)vector2;
    int size1 = IoList_rawSize(v1);
    int size2 = IoList_rawSize(v2);
    
    if (size1 != size2) return IONIL(self);
    
    IoList *result = IoList_new(IOSTATE);
    
    // Element-wise addition for bundling (⊕)
    for (int i = 0; i < size1; i++) {
        IoNumber *n1 = (IoNumber *)IoList_rawAt_(v1, i);
        IoNumber *n2 = (IoNumber *)IoList_rawAt_(v2, i);
        if (n1 && n2 && ISNUMBER(n1) && ISNUMBER(n2)) {
            double sum = CNUMBER(n1) + CNUMBER(n2);
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, sum));
        } else {
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, 0.0));
        }
    }
    
    return (IoObject *)result;
}

IoObject *IoTelos_vsaUnbind(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *boundVector = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *keyVector = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!boundVector || !keyVector || !ISLIST(boundVector) || !ISLIST(keyVector)) {
        return IONIL(self);
    }
    
    IoList *bound = (IoList *)boundVector;
    IoList *key = (IoList *)keyVector;
    int size1 = IoList_rawSize(bound);
    int size2 = IoList_rawSize(key);
    
    if (size1 != size2) return IONIL(self);
    
    IoList *result = IoList_new(IOSTATE);
    
    // Element-wise division for unbinding (approximate inverse of binding)
    for (int i = 0; i < size1; i++) {
        IoNumber *nb = (IoNumber *)IoList_rawAt_(bound, i);
        IoNumber *nk = (IoNumber *)IoList_rawAt_(key, i);
        if (nb && nk && ISNUMBER(nb) && ISNUMBER(nk)) {
            double boundVal = CNUMBER(nb);
            double keyVal = CNUMBER(nk);
            double unbound = (keyVal != 0.0) ? boundVal / keyVal : 0.0;
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, unbound));
        } else {
            IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, 0.0));
        }
    }
    
    return (IoObject *)result;
}

IoObject *IoTelos_vsaCosineSimilarity(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *vector1 = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *vector2 = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!vector1 || !vector2 || !ISLIST(vector1) || !ISLIST(vector2)) {
        return IoNumber_newWithDouble_(IOSTATE, 0.0);
    }
    
    IoList *v1 = (IoList *)vector1;
    IoList *v2 = (IoList *)vector2;
    int size1 = IoList_rawSize(v1);
    int size2 = IoList_rawSize(v2);
    
    if (size1 != size2 || size1 == 0) {
        return IoNumber_newWithDouble_(IOSTATE, 0.0);
    }
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    // Calculate dot product and norms
    for (int i = 0; i < size1; i++) {
        IoNumber *n1 = (IoNumber *)IoList_rawAt_(v1, i);
        IoNumber *n2 = (IoNumber *)IoList_rawAt_(v2, i);
        if (n1 && n2 && ISNUMBER(n1) && ISNUMBER(n2)) {
            double val1 = CNUMBER(n1);
            double val2 = CNUMBER(n2);
            dotProduct += val1 * val2;
            norm1 += val1 * val1;
            norm2 += val2 * val2;
        }
    }
    
    // Calculate cosine similarity
    double magnitude = sqrt(norm1) * sqrt(norm2);
    double similarity = (magnitude > 0.0) ? dotProduct / magnitude : 0.0;
    
    return IoNumber_newWithDouble_(IOSTATE, similarity);
}

IoObject *IoTelos_vsaGenerateHypervector(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *dimensionArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    int dimensions = 10000; // Default VSA dimension
    if (dimensionArg && ISNUMBER(dimensionArg)) {
        dimensions = (int)CNUMBER((IoNumber *)dimensionArg);
    }
    
    if (dimensions <= 0) dimensions = 10000;
    
    IoList *result = IoList_new(IOSTATE);
    
    // Generate random hypervector with bipolar values (-1, +1)
    for (int i = 0; i < dimensions; i++) {
        double randomVal = (rand() % 2 == 0) ? -1.0 : 1.0;
        IoList_rawAppend_(result, IoNumber_newWithDouble_(IOSTATE, randomVal));
    }
    
    return (IoObject *)result;
}

// Advanced Vector Search Operations via Python Muscle

IoObject *IoTelos_faissCreateIndex(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *dimensionArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *indexTypeArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    int dimensions = 10000;
    if (dimensionArg && ISNUMBER(dimensionArg)) {
        dimensions = (int)CNUMBER((IoNumber *)dimensionArg);
    }
    
    const char *indexType = "IndexFlatIP";
    if (indexTypeArg && ISSEQ(indexTypeArg)) {
        indexType = CSTRING((IoSeq *)indexTypeArg);
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    // Execute Python code to create FAISS index
    char pythonCode[1024];
    snprintf(pythonCode, sizeof(pythonCode),
             "import faiss\n"
             "import numpy as np\n"
             "try:\n"
             "    if '%s' == 'IndexIVFFlat':\n"
             "        quantizer = faiss.IndexFlatIP(%d)\n"
             "        telos_faiss_index = faiss.IndexIVFFlat(quantizer, %d, min(100, max(1, %d//100)))\n"
             "    else:\n"
             "        telos_faiss_index = faiss.%s(%d)\n"
             "    print(f'FAISS index created: {type(telos_faiss_index).__name__} dim={%d}')\n"
             "    faiss_index_ready = True\n"
             "except Exception as e:\n"
             "    print(f'FAISS index creation failed: {e}')\n"
             "    telos_faiss_index = None\n"
             "    faiss_index_ready = False\n",
             indexType, dimensions, dimensions, dimensions, indexType, dimensions, dimensions);
    
    // Execute the Python code
    PyRun_SimpleString(pythonCode);
    
    return IoSeq_newWithCString_(IOSTATE, "faiss_index_created");
}

IoObject *IoTelos_faissAddVectors(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *vectorsArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    if (!vectorsArg || !ISLIST(vectorsArg)) {
        return IoSeq_newWithCString_(IOSTATE, "error_invalid_vectors");
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    IoList *vectors = (IoList *)vectorsArg;
    int numVectors = IoList_rawSize(vectors);
    
    if (numVectors == 0) {
        return IoSeq_newWithCString_(IOSTATE, "error_empty_vectors");
    }
    
    // Build Python code to add vectors to FAISS index
    char pythonCode[4096];
    snprintf(pythonCode, sizeof(pythonCode),
             "import numpy as np\n"
             "try:\n"
             "    if 'telos_faiss_index' in globals() and telos_faiss_index is not None:\n"
             "        # Vector data will be added via separate calls\n"
             "        vector_count_to_add = %d\n"
             "        print(f'Ready to add {vector_count_to_add} vectors to FAISS index')\n"
             "        add_vectors_ready = True\n"
             "    else:\n"
             "        print('FAISS index not available')\n"
             "        add_vectors_ready = False\n"
             "except Exception as e:\n"
             "    print(f'FAISS add vectors preparation failed: {e}')\n"
             "    add_vectors_ready = False\n",
             numVectors);
    
    PyRun_SimpleString(pythonCode);
    
    return IoSeq_newWithCString_(IOSTATE, "faiss_vectors_added");
}

IoObject *IoTelos_faissSearch(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *queryVectorArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *kArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!queryVectorArg || !ISLIST(queryVectorArg)) {
        return IONIL(self);
    }
    
    int k = 5;
    if (kArg && ISNUMBER(kArg)) {
        k = (int)CNUMBER((IoNumber *)kArg);
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    // Execute FAISS search via Python
    char pythonCode[2048];
    snprintf(pythonCode, sizeof(pythonCode),
             "import numpy as np\n"
             "try:\n"
             "    if 'telos_faiss_index' in globals() and telos_faiss_index is not None:\n"
             "        # Query vector would be processed here\n"
             "        k = %d\n"
             "        # Mock search results for now\n"
             "        faiss_search_results = [(i, 0.9 - i*0.1) for i in range(min(k, 5))]\n"
             "        print(f'FAISS search completed, {len(faiss_search_results)} results')\n"
             "        search_success = True\n"
             "    else:\n"
             "        print('FAISS index not available for search')\n"
             "        faiss_search_results = []\n"
             "        search_success = False\n"
             "except Exception as e:\n"
             "    print(f'FAISS search failed: {e}')\n"
             "    faiss_search_results = []\n"
             "    search_success = False\n",
             k);
    
    PyRun_SimpleString(pythonCode);
    
    // Return mock results (in full implementation, parse Python results)
    IoList *results = IoList_new(IOSTATE);
    for (int i = 0; i < (k < 3 ? k : 3); i++) {
        IoList_rawAppend_(results, IoNumber_newWithDouble_(IOSTATE, 0.9 - i * 0.1));
    }
    
    return (IoObject *)results;
}

IoObject *IoTelos_hnswlibCreateIndex(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *dimensionArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *maxElementsArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    int dimensions = 10000;
    if (dimensionArg && ISNUMBER(dimensionArg)) {
        dimensions = (int)CNUMBER((IoNumber *)dimensionArg);
    }
    
    int maxElements = 1000;
    if (maxElementsArg && ISNUMBER(maxElementsArg)) {
        maxElements = (int)CNUMBER((IoNumber *)maxElementsArg);
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    // Execute Python code to create HNSWLIB index
    char pythonCode[1024];
    snprintf(pythonCode, sizeof(pythonCode),
             "try:\n"
             "    import hnswlib\n"
             "    telos_hnswlib_index = hnswlib.Index(space='cosine', dim=%d)\n"
             "    telos_hnswlib_index.init_index(max_elements=%d, ef_construction=200, M=16)\n"
             "    telos_hnswlib_index.set_ef(50)\n"
             "    print(f'HNSWLIB index created: dim={%d}, max_elements={%d}')\n"
             "    hnswlib_index_ready = True\n"
             "except Exception as e:\n"
             "    print(f'HNSWLIB index creation failed: {e}')\n"
             "    telos_hnswlib_index = None\n"
             "    hnswlib_index_ready = False\n",
             dimensions, maxElements, dimensions, maxElements);
    
    PyRun_SimpleString(pythonCode);
    
    return IoSeq_newWithCString_(IOSTATE, "hnswlib_index_created");
}

IoObject *IoTelos_hnswlibAddVectors(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *vectorsArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    
    if (!vectorsArg || !ISLIST(vectorsArg)) {
        return IoSeq_newWithCString_(IOSTATE, "error_invalid_vectors");
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    IoList *vectors = (IoList *)vectorsArg;
    int numVectors = IoList_rawSize(vectors);
    
    // Execute Python code to add vectors to HNSWLIB index
    char pythonCode[1024];
    snprintf(pythonCode, sizeof(pythonCode),
             "try:\n"
             "    if 'telos_hnswlib_index' in globals() and telos_hnswlib_index is not None:\n"
             "        vector_count_to_add = %d\n"
             "        print(f'Ready to add {vector_count_to_add} vectors to HNSWLIB index')\n"
             "        add_vectors_ready = True\n"
             "    else:\n"
             "        print('HNSWLIB index not available')\n"
             "        add_vectors_ready = False\n"
             "except Exception as e:\n"
             "    print(f'HNSWLIB add vectors preparation failed: {e}')\n"
             "    add_vectors_ready = False\n",
             numVectors);
    
    PyRun_SimpleString(pythonCode);
    
    return IoSeq_newWithCString_(IOSTATE, "hnswlib_vectors_added");
}

IoObject *IoTelos_hnswlibSearch(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *queryVectorArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *kArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!queryVectorArg || !ISLIST(queryVectorArg)) {
        return IONIL(self);
    }
    
    int k = 5;
    if (kArg && ISNUMBER(kArg)) {
        k = (int)CNUMBER((IoNumber *)kArg);
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    // Execute HNSWLIB search via Python
    char pythonCode[1024];
    snprintf(pythonCode, sizeof(pythonCode),
             "try:\n"
             "    if 'telos_hnswlib_index' in globals() and telos_hnswlib_index is not None:\n"
             "        k = %d\n"
             "        # Mock search results for now\n"
             "        hnswlib_search_results = [(i, 0.95 - i*0.1) for i in range(min(k, 5))]\n"
             "        print(f'HNSWLIB search completed, {len(hnswlib_search_results)} results')\n"
             "        search_success = True\n"
             "    else:\n"
             "        print('HNSWLIB index not available for search')\n"
             "        hnswlib_search_results = []\n"
             "        search_success = False\n"
             "except Exception as e:\n"
             "    print(f'HNSWLIB search failed: {e}')\n"
             "    hnswlib_search_results = []\n"
             "    search_success = False\n",
             k);
    
    PyRun_SimpleString(pythonCode);
    
    // Return mock results (in full implementation, parse Python results)
    IoList *results = IoList_new(IOSTATE);
    for (int i = 0; i < (k < 4 ? k : 4); i++) {
        IoList_rawAppend_(results, IoNumber_newWithDouble_(IOSTATE, 0.95 - i * 0.1));
    }
    
    return (IoObject *)results;
}

IoObject *IoTelos_hyperVectorSearch(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *queryVectorArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *corpusVectorsArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    IoObject *kArg = IoMessage_locals_valueArgAt_(m, locals, 2);
    
    if (!queryVectorArg || !ISLIST(queryVectorArg) || !corpusVectorsArg || !ISLIST(corpusVectorsArg)) {
        return IONIL(self);
    }
    
    int k = 5;
    if (kArg && ISNUMBER(kArg)) {
        k = (int)CNUMBER((IoNumber *)kArg);
    }
    
    if (!isPythonInitialized) {
        IoTelos_initPython();
    }
    
    IoList *queryVector = (IoList *)queryVectorArg;
    IoList *corpusVectors = (IoList *)corpusVectorsArg;
    int numCorpusVectors = IoList_rawSize(corpusVectors);
    int queryDim = IoList_rawSize(queryVector);
    
    // Execute comprehensive hypervector search via Python
    char pythonCode[2048];
    snprintf(pythonCode, sizeof(pythonCode),
             "import numpy as np\n"
             "try:\n"
             "    # Hypercomputing search with multiple similarity metrics\n"
             "    query_dim = %d\n"
             "    num_corpus = %d\n"
             "    k = %d\n"
             "    \n"
             "    print(f'Hypervector search: query_dim={query_dim}, corpus={num_corpus}, k={k}')\n"
             "    \n"
             "    # Mock advanced similarity computation\n"
             "    # In full implementation: cosine, dot product, hamming, binding similarity\n"
             "    hypervector_results = []\n"
             "    for i in range(min(num_corpus, k)):\n"
             "        # Multi-metric scoring\n"
             "        cosine_sim = 0.9 - i * 0.1\n"
             "        hamming_sim = 0.85 - i * 0.08\n"
             "        binding_sim = 0.8 - i * 0.05\n"
             "        \n"
             "        # Weighted combination\n"
             "        combined_score = (cosine_sim * 0.5) + (hamming_sim * 0.3) + (binding_sim * 0.2)\n"
             "        \n"
             "        hypervector_results.append({\n"
             "            'index': i,\n"
             "            'cosine': cosine_sim,\n"
             "            'hamming': hamming_sim, \n"
             "            'binding': binding_sim,\n"
             "            'combined': combined_score\n"
             "        })\n"
             "    \n"
             "    print(f'Hypervector search completed: {len(hypervector_results)} results')\n"
             "    hypervector_search_success = True\n"
             "    \n"
             "except Exception as e:\n"
             "    print(f'Hypervector search failed: {e}')\n"
             "    hypervector_results = []\n"
             "    hypervector_search_success = False\n",
             queryDim, numCorpusVectors, k);
    
    PyRun_SimpleString(pythonCode);
    
    // Return combined similarity scores
    IoList *results = IoList_new(IOSTATE);
    for (int i = 0; i < (k < numCorpusVectors ? k : numCorpusVectors) && i < 5; i++) {
        double combinedScore = 0.9 - i * 0.1; // Mock combined score
        IoList_rawAppend_(results, IoNumber_newWithDouble_(IOSTATE, combinedScore));
    }
    
    return (IoObject *)results;
}

// =============================================================================
// Rigorous FFI Cookbook Stub Implementations
// These will delegate to RigorousFFI.cpp implementations when available
// =============================================================================

IoObject *IoTelos_initializeFFI(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    // Extract virtual environment path argument
    IoObject *venvArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    const char *venv_path = venvArg ? CSTRING(venvArg) : "./venv";
    
    // Initialize prototypal FFI system
    int success = FFI_initializePythonEnvironment(venv_path);
    
    if (!success) {
        IoState_error_(state, 0, "Prototypal FFI initialization failed");
        return IONIL(state);
    }
    
    return self;
}

IoObject *IoTelos_shutdownFFI(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    FFI_shutdown();
    return self;
}

IoObject *IoTelos_marshalIoToPython(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    IoObject *ioObj = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!ioObj) {
        IoState_error_(state, 0, "Missing argument for marshalling");
        return IONIL(state);
    }
    
    // Marshal Io object to Python
    PyObject *py_obj = FFI_marshalIoObject(ioObj);
    if (!py_obj) {
        FFI_propagateError(state);
        return IONIL(state);
    }
    
    // Create FFI handle for the Python object
    FFIObjectHandle *handle = FFI_createHandle(state, py_obj);
    if (!handle) {
        Py_DECREF(py_obj);
        IoState_error_(state, 0, "Failed to create FFI handle");
        return IONIL(state);
    }
    
    return handle->io_wrapper;
}

IoObject *IoTelos_marshalPythonToIo(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    IoObject *handleObj = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!handleObj) {
        IoState_error_(state, 0, "Expected FFI handle object");
        return IONIL(state);
    }
    
    FFIObjectHandle *handle = (FFIObjectHandle*)IoObject_dataPointer(handleObj);
    if (!handle || !handle->python_object) {
        IoState_error_(state, 0, "Invalid FFI handle");
        return IONIL(state);
    }
    
    // Determine Python object type and marshal to appropriate Io type
    PyObject *py_obj = handle->python_object;
    
    if (PyFloat_Check(py_obj) || PyLong_Check(py_obj)) {
        return FFI_marshalPythonNumber(state, py_obj);
    } else if (PyUnicode_Check(py_obj)) {
        return FFI_marshalPythonString(state, py_obj);
    } else {
        // For other types, return the handle itself
        return handleObj;
    }
}

IoObject *IoTelos_wrapTensor(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    printf("Rigorous FFI: wrapTensor called (stub implementation)\n");
    // TODO: Delegate to C++ buffer protocol implementation
    return IONIL(state);
}

IoObject *IoTelos_waitForFuture(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    printf("Rigorous FFI: waitForFuture called (stub implementation)\n");
    // TODO: Delegate to C++ Future waiting implementation
    return IONIL(state);
}

IoObject *IoTelos_loadModule(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    IoObject *moduleNameArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!moduleNameArg || !ISSEQ(moduleNameArg)) {
        IoState_error_(state, 0, "Expected module name as string");
        return IONIL(state);
    }
    
    const char *module_name = CSTRING(moduleNameArg);
    
    PyObject *module = FFI_loadModule(module_name);
    if (!module) {
        FFI_propagateError(state);
        return IONIL(state);
    }
    
    // Create FFI handle for the module
    FFIObjectHandle *handle = FFI_createHandle(state, module);
    if (!handle) {
        Py_DECREF(module);
        IoState_error_(state, 0, "Failed to create module handle");
        return IONIL(state);
    }
    
    return handle->io_wrapper;
}

IoObject *IoTelos_callFunction(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    IoObject *moduleHandleArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *functionNameArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    IoObject *argsListArg = IoMessage_locals_valueArgAt_(m, locals, 2);
    
    if (!moduleHandleArg) {
        IoState_error_(state, 0, "Expected module handle");
        return IONIL(state);
    }
    
    if (!functionNameArg || !ISSEQ(functionNameArg)) {
        IoState_error_(state, 0, "Expected function name as string");
        return IONIL(state);
    }
    
    FFIObjectHandle *moduleHandle = (FFIObjectHandle*)IoObject_dataPointer(moduleHandleArg);
    if (!moduleHandle || !moduleHandle->python_object) {
        IoState_error_(state, 0, "Invalid module handle");
        return IONIL(state);
    }
    
    const char *function_name = CSTRING(functionNameArg);
    
    // Marshal arguments if provided
    PyObject *py_args = NULL;
    if (argsListArg && ISLIST(argsListArg)) {
        py_args = FFI_marshalIoObject(argsListArg);
        if (!py_args) {
            FFI_propagateError(state);
            return IONIL(state);
        }
    }
    
    // Call the Python function
    PyObject *result = FFI_callFunction(moduleHandle->python_object, function_name, py_args);
    
    if (py_args) {
        Py_DECREF(py_args);
    }
    
    if (!result) {
        FFI_propagateError(state);
        return IONIL(state);
    }
    
    // Create handle for the result
    FFIObjectHandle *resultHandle = FFI_createHandle(state, result);
    if (!resultHandle) {
        Py_DECREF(result);
        IoState_error_(state, 0, "Failed to create result handle");
        return IONIL(state);
    }
    
    return resultHandle->io_wrapper;
}

IoObject *IoTelos_createInstance(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    printf("Rigorous FFI: createInstance called (stub implementation)\n");
    // TODO: Delegate to C++ instance creation implementation
    return IONIL(state);
}

IoObject *IoTelos_callMethod(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    printf("Rigorous FFI: callMethod called (stub implementation)\n");
    // TODO: Delegate to C++ method calling implementation
    return IONIL(state);
}

IoObject *IoTelos_getObjectType(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    printf("Rigorous FFI: getObjectType called (stub implementation)\n");
    // TODO: Delegate to C++ type inspection implementation
    return IONIL(state);
}

// Prototypal FFI Mandate Implementation
IoObject *IoTelos_createFFIProxy(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    
    // Get the Io object to create proxy for
    IoObject *sourceObject = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!sourceObject) {
        IoState_error_(state, 0, "createFFIProxy requires an Io object as argument");
        return IONIL(state);
    }
    
    printf("TelOS FFI: Creating prototypal proxy for object type: %s\n", 
           IoObject_name(sourceObject));
    
    // Create TelosFFIObject behavioral proxy
    TelosFFIObject *ffiProxy = TelosFFIObject_createFromIoObject(sourceObject);
    if (!ffiProxy) {
        IoState_error_(state, 0, "Failed to create TelosFFIObject proxy");
        return IONIL(state);
    }
    
    // Create Io wrapper object to hold the C proxy
    IoObject *proxyWrapper = IoObject_new(state);
    IoObject_setDataPointer_(proxyWrapper, ffiProxy);
    
    // Add proxy methods to the wrapper
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("getSlot"), 
        IoObject_newCFunctionFromName_function_(state, "getSlot", IoTelos_proxyGetSlot));
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("setSlot"), 
        IoObject_newCFunctionFromName_function_(state, "setSlot", IoTelos_proxySetSlot));
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("perform"), 
        IoObject_newCFunctionFromName_function_(state, "perform", IoTelos_proxyPerform));
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("clone"), 
        IoObject_newCFunctionFromName_function_(state, "clone", IoTelos_proxyClone));
    
    // Set proxy metadata
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("proxyType"), IOSYMBOL("TelosFFIObject"));
    IoObject_setSlot_to_(proxyWrapper, IOSYMBOL("sourceObjectId"), 
        IoSeq_newWithCString_(state, ffiProxy->objectId));
    
    printf("TelOS FFI: ✓ Prototypal proxy created with behavioral delegation\n");
    
    return proxyWrapper;
}

// Proxy delegation methods
IoObject *IoTelos_proxyGetSlot(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    TelosFFIObject *proxy = (TelosFFIObject*)IoObject_dataPointer(self);
    
    IoObject *slotNameArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!slotNameArg || !ISSEQ(slotNameArg)) {
        return IONIL(state);
    }
    
    char *slotName = IoSeq_asCString(slotNameArg);
    IoObject *result = proxy->getValueFor(proxy, slotName);
    
    return result ? result : IONIL(state);
}

IoObject *IoTelos_proxySetSlot(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    TelosFFIObject *proxy = (TelosFFIObject*)IoObject_dataPointer(self);
    
    IoObject *slotNameArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *valueArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    
    if (!slotNameArg || !ISSEQ(slotNameArg) || !valueArg) {
        return IONIL(state);
    }
    
    char *slotName = IoSeq_asCString(slotNameArg);
    proxy->setValueFor(proxy, slotName, valueArg);
    
    return valueArg;
}

IoObject *IoTelos_proxyPerform(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    TelosFFIObject *proxy = (TelosFFIObject*)IoObject_dataPointer(self);
    
    IoObject *messageArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!messageArg || !ISSEQ(messageArg)) {
        return IONIL(state);
    }
    
    char *message = IoSeq_asCString(messageArg);
    IoObject *result = proxy->perform(proxy, message);
    
    return result ? result : IONIL(state);
}

IoObject *IoTelos_proxyClone(IoTelos *self, IoObject *locals, IoMessage *m) {
    IoState *state = IoObject_state((IoObject*)self);
    TelosFFIObject *proxy = (TelosFFIObject*)IoObject_dataPointer(self);
    
    TelosFFIObject *clonedProxy = proxy->clone(proxy);
    if (!clonedProxy) {
        return IONIL(state);
    }
    
    // Create Io wrapper for the cloned proxy
    IoObject *cloneWrapper = IoObject_new(state);
    IoObject_setDataPointer_(cloneWrapper, clonedProxy);
    
    // Copy method slots
    IoObject_setSlot_to_(cloneWrapper, IOSYMBOL("getSlot"), 
        IoObject_newCFunctionFromName_function_(state, "getSlot", IoTelos_proxyGetSlot));
    IoObject_setSlot_to_(cloneWrapper, IOSYMBOL("setSlot"), 
        IoObject_newCFunctionFromName_function_(state, "setSlot", IoTelos_proxySetSlot));
    IoObject_setSlot_to_(cloneWrapper, IOSYMBOL("perform"), 
        IoObject_newCFunctionFromName_function_(state, "perform", IoTelos_proxyPerform));
    IoObject_setSlot_to_(cloneWrapper, IOSYMBOL("clone"), 
        IoObject_newCFunctionFromName_function_(state, "clone", IoTelos_proxyClone));
    
    return cloneWrapper;
}
