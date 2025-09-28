/**
 * IoTelosBridge - TELOS Synaptic Bridge Io Addon Implementation
 * 
 * This file implements the Io language bindings for the TELOS Synaptic Bridge,
 * following the architectural mandate that all Python operations must be called
 * through the bridge from Io. The implementation enforces prototypal behavior
 * and coarse-grained message passing.
 */

#include "IoTelosBridge.h"
#include "synaptic_bridge.h"
#include "IoState.h"
#include "IoNumber.h"
#include "IoSeq.h"
#include "IoList.h"
#include "IoMap.h"
#include "IoCFunction.h"
#include "IoError.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include "parson.h"

/* =============================================================================
 * Type Tags and Proto IDs
 * =============================================================================
 */

#define DATA(self) ((IoTelosBridgeData *)IoObject_dataPointer(self))
#define HANDLEDATA(self) ((IoSharedMemoryHandleData *)IoObject_dataPointer(self))

static const char *protoId = "TelosBridge";
static const char *handleProtoId = "SharedMemoryHandle";

typedef struct {
    int initialized;
    int maxWorkers;
} IoTelosBridgeData;

typedef struct {
    char *name;
    size_t offset;
    size_t size;
    void *lastMappedPointer;
} IoSharedMemoryHandleData;

static IoObject *IoTelosBridge_submitTask(IoTelosBridge *self, IoObject *locals, IoMessage *m);

static int IoTelosBridge_extractSharedMemoryHandle(
    IoTelosBridge *self,
    IoObject *arg,
    SharedMemoryHandle *out,
    int required,
    const char *label,
    IoMessage *m
) {
    IoState *state = IOSTATE;

    if (arg == NULL || arg == state->ioNil) {
        if (required) {
            IoState_error_(state, m, "%s handle is required", label);
            return -1;
        }
        return 0;
    }

    IoObject *handleProto = IoState_protoWithId_(state, handleProtoId);
    if (!IoObject_rawHasProto_(arg, handleProto)) {
        IoState_error_(state, m, "%s must be a SharedMemoryHandle", label);
        return -1;
    }

    IoSharedMemoryHandleData *handleData = HANDLEDATA(arg);
    if (handleData == NULL || handleData->name == NULL) {
        IoState_error_(state, m, "%s handle is not initialized", label);
        return -1;
    }

    out->name = handleData->name;
    out->offset = handleData->offset;
    out->size = handleData->size;
    return 1;
}

static void IoTelosBridge_seed_random(void) {
    static int seeded = 0;
    if (!seeded) {
        unsigned int seed = (unsigned int)(time(NULL) ^ clock());
        srand(seed);
        seeded = 1;
    }
}

static void IoTelosBridge_random_bytes(unsigned char *buffer, size_t length) {
    IoTelosBridge_seed_random();
    for (size_t i = 0; i < length; i++) {
        buffer[i] = (unsigned char)(rand() & 0xFF);
    }
}

static int IoTelosBridge_bytes_all_zero(const unsigned char *buffer, size_t length) {
    for (size_t i = 0; i < length; i++) {
        if (buffer[i] != 0) {
            return 0;
        }
    }
    return 1;
}

static void IoTelosBridge_bytes_to_hex(const unsigned char *buffer, size_t length, char *dest, size_t dest_size) {
    static const char hex_table[] = "0123456789abcdef";
    size_t required = length * 2 + 1;
    if (dest_size < required) {
        if (dest_size > 0) {
            dest[0] = '\0';
        }
        return;
    }

    for (size_t i = 0; i < length; i++) {
        unsigned char value = buffer[i];
        dest[i * 2] = hex_table[(value >> 4) & 0x0F];
        dest[i * 2 + 1] = hex_table[value & 0x0F];
    }
    dest[length * 2] = '\0';
}

static void IoTelosBridge_generate_traceparent(char *buffer, size_t buffer_size) {
    unsigned char trace_id_bytes[16];
    unsigned char span_id_bytes[8];

    do {
        IoTelosBridge_random_bytes(trace_id_bytes, sizeof(trace_id_bytes));
    } while (IoTelosBridge_bytes_all_zero(trace_id_bytes, sizeof(trace_id_bytes)));

    do {
        IoTelosBridge_random_bytes(span_id_bytes, sizeof(span_id_bytes));
    } while (IoTelosBridge_bytes_all_zero(span_id_bytes, sizeof(span_id_bytes)));

    char trace_id_hex[33];
    char span_id_hex[17];
    IoTelosBridge_bytes_to_hex(trace_id_bytes, sizeof(trace_id_bytes), trace_id_hex, sizeof(trace_id_hex));
    IoTelosBridge_bytes_to_hex(span_id_bytes, sizeof(span_id_bytes), span_id_hex, sizeof(span_id_hex));

    snprintf(buffer, buffer_size, "00-%s-%s-01", trace_id_hex, span_id_hex);
}

static int IoTelosBridge_ensure_trace_context(JSON_Object *request_object) {
    if (request_object == NULL) {
        return 0;
    }

    JSON_Value *existing_value = json_object_get_value(request_object, "trace_context");
    JSON_Object *context_object = NULL;
    if (existing_value != NULL && json_value_get_type(existing_value) == JSONObject) {
        context_object = json_value_get_object(existing_value);
    }

    const char *existing_traceparent = NULL;
    if (context_object != NULL) {
        existing_traceparent = json_object_get_string(context_object, "traceparent");
    }

    if (existing_traceparent != NULL && strlen(existing_traceparent) > 0) {
        return 1;
    }

    char traceparent_buffer[64];
    IoTelosBridge_generate_traceparent(traceparent_buffer, sizeof(traceparent_buffer));

    if (context_object == NULL) {
        JSON_Value *new_value = json_value_init_object();
        if (new_value == NULL) {
            return 0;
        }
        context_object = json_value_get_object(new_value);
        if (json_object_set_value(request_object, "trace_context", new_value) != JSONSuccess) {
            json_value_free(new_value);
            return 0;
        }
    }

    if (json_object_set_string(context_object, "traceparent", traceparent_buffer) != JSONSuccess) {
        return 0;
    }

    if (!json_object_has_value(context_object, "tracestate")) {
        if (json_object_set_string(context_object, "tracestate", "") != JSONSuccess) {
            return 0;
        }
    }

    return 1;
}

/* =============================================================================
 * Helper Functions
 * =============================================================================
 */

/**
 * Convert a BridgeResult to an Io error if necessary
 */
static IoObject *IoTelosBridge_resultToIoObject(IoTelosBridge *self, IoObject *locals, BridgeResult result, IoMessage *m) {
    IoState *state = IOSTATE;
    
    if (result == BRIDGE_SUCCESS) {
        return IOTRUE(self);
    }
    
    // Get the error message from the bridge
    char errorBuffer[1024];
    bridge_get_last_error(errorBuffer, sizeof(errorBuffer));
    
    // Raise an Io exception with the error message
    IoState_error_(state, m, errorBuffer);
    
    return IONIL(self);
}

/**
 * Get an integer argument from the message at a specific index
 */
static int IoTelosBridge_getIntArg(IoMessage *m, int index, int defaultValue) {
    IoObject *arg = IoMessage_locals_valueArgAt_(m, NULL, index);
    if (ISNUMBER(arg)) {
        return (int)IoNumber_asDouble(arg);
    }
    return defaultValue;
}

static double IoTelosBridge_getDoubleArg(IoMessage *m, int index, double defaultValue) {
    IoObject *arg = IoMessage_locals_valueArgAt_(m, NULL, index);
    if (ISNUMBER(arg)) {
        return IoNumber_asDouble(arg);
    }
    return defaultValue;
}

/**
 * Get a string argument from the message at a specific index
 */
static const char *IoTelosBridge_getStringArg(IoMessage *m, int index, const char *defaultValue) {
    IoObject *arg = IoMessage_locals_valueArgAt_(m, NULL, index);
    if (ISSEQ(arg)) {
        return IoSeq_asCString(arg);
    }
    return defaultValue;
}

/* =============================================================================
 * IoTelosBridge Tag and Prototype Functions
 * =============================================================================
 */

static void IoTelosBridge_free(IoTelosBridge *self) {
    if (DATA(self)) {
        // Cleanup any bridge resources if initialized
        if (DATA(self)->initialized) {
            bridge_shutdown();
        }
        io_free(DATA(self));
    }
}

static IoTag *IoTelosBridge_newTag(void *state) {
    IoTag *tag = IoTag_newWithName_(protoId);
    IoTag_state_(tag, state);
    IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTelosBridge_free);
    IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTelosBridge_rawClone);
    return tag;
}

IoTelosBridge *IoTelosBridge_rawClone(IoTelosBridge *proto) {
    IoObject *self = IoObject_rawClonePrimitive(proto);
    IoObject_setDataPointer_(self, calloc(1, sizeof(IoTelosBridgeData)));
    
    // Copy initialization state from prototype
    DATA(self)->initialized = 0;  // New clones start uninitialized
    DATA(self)->maxWorkers = DATA(proto)->maxWorkers;
    
    return self;
}

IoTelosBridge *IoTelosBridge_new(void *state) {
    IoTelosBridge *proto = IoState_protoWithId_(state, protoId);
    return IOCLONE(proto);
}

IoTelosBridge *IoTelosBridge_proto(void *state) {
    IoMethodTable methodTable[] = {
        // Lifecycle methods
        {"initialize", IoTelosBridge_initialize},
        {"shutdown", IoTelosBridge_shutdown},
        {"status", IoTelosBridge_status},
        
        // Shared memory methods
        {"createSharedMemory", IoTelosBridge_createSharedMemory},
        {"destroySharedMemory", IoTelosBridge_destroySharedMemory},
        {"mapSharedMemory", IoTelosBridge_mapSharedMemory},
        {"unmapSharedMemory", IoTelosBridge_unmapSharedMemory},
        {"submitTask", IoTelosBridge_submitTask},
        
        // VSA and ANN methods
        {"executeVSABatch", IoTelosBridge_executeVSABatch},
        {"annSearch", IoTelosBridge_annSearch},
        {"addVector", IoTelosBridge_addVector},
        {"updateVector", IoTelosBridge_updateVector},
        {"removeVector", IoTelosBridge_removeVector},
        
        // Error handling
        {"getLastError", IoTelosBridge_getLastError},
        {"clearError", IoTelosBridge_clearError},
        
        // Utility methods
        {"ping", IoTelosBridge_ping},
        
        {NULL, NULL},
    };
    
    // Check if proto already exists
    IoTelosBridge *existing = IoState_protoWithId_(state, protoId);
    if (existing != NULL) {
        return existing;
    }
    
    IoTelosBridge *self = IoObject_new(state);
    IoObject_tag_(self, IoTelosBridge_newTag(state));
    IoObject_setDataPointer_(self, calloc(1, sizeof(IoTelosBridgeData)));
    
    // Initialize with default values
    DATA(self)->initialized = 0;
    DATA(self)->maxWorkers = 4;
    
    IoState_registerProtoWithId_(state, self, protoId);
    IoObject_addMethodTable_(self, methodTable);
    
    return self;
}

/* =============================================================================
 * Bridge Lifecycle Methods
 * =============================================================================
 */

IoObject *IoTelosBridge_initialize(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    int workers = IoTelosBridge_getIntArg(m, 0, DATA(self)->maxWorkers);
    
    if (DATA(self)->initialized) {
        // Already initialized, just return success
        return IOTRUE(self);
    }
    
    BridgeConfig config = {workers, NULL};  // max_workers, log_callback = NULL
    BridgeResult result = bridge_initialize(&config);
    
    if (result == BRIDGE_SUCCESS) {
        DATA(self)->initialized = 1;
        DATA(self)->maxWorkers = workers;
        return IOTRUE(self);
    }
    
    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_shutdown(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (DATA(self)->initialized) {
        bridge_shutdown();
        DATA(self)->initialized = 0;
    }
    return IOTRUE(self);
}

IoObject *IoTelosBridge_status(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    IoState *state = IOSTATE;
    IoMap *status = IoMap_new(state);
    
    // Add status information
    IoMap_rawAtPut(status, 
                  IOSYMBOL("initialized"), 
                  DATA(self)->initialized ? IOTRUE(self) : IOFALSE(self));
    
    IoMap_rawAtPut(status, 
                  IOSYMBOL("maxWorkers"), 
                  IONUMBER(DATA(self)->maxWorkers));
    
    // Get last error if any
    char errorBuffer[1024] = {0};
    bridge_get_last_error(errorBuffer, sizeof(errorBuffer));
    if (strlen(errorBuffer) > 0) {
        IoMap_rawAtPut(status, 
                      IOSYMBOL("lastError"), 
                      IOSEQ((unsigned char *)errorBuffer, strlen(errorBuffer)));
    } else {
        IoMap_rawAtPut(status, 
                      IOSYMBOL("lastError"), 
                      IOSYMBOL(""));
    }
    
    return status;
}

/* =============================================================================
 * Shared Memory Methods
 * =============================================================================
 */

IoObject *IoTelosBridge_createSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IONIL(self);
    }
    
    int size = IoTelosBridge_getIntArg(m, 0, 0);
    if (size <= 0) {
        IoState_error_(IOSTATE, m, "Invalid size for shared memory: %d", size);
        return IONIL(self);
    }
    
    SharedMemoryHandle handle;
    BridgeResult result = bridge_create_shared_memory(size, &handle);
    
    if (result == BRIDGE_SUCCESS) {
        return IoSharedMemoryHandle_newWithData(IOSTATE, handle.name, handle.offset, handle.size);
    }
    
    IoTelosBridge_resultToIoObject(self, locals, result, m);
    return IONIL(self);
}

IoObject *IoTelosBridge_destroySharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }
    
    IoObject *handleArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!IoObject_rawHasProto_(handleArg, IoState_protoWithId_(IOSTATE, handleProtoId))) {
        IoState_error_(IOSTATE, m, "Argument must be a SharedMemoryHandle");
        return IOFALSE(self);
    }
    
    IoSharedMemoryHandleData *handleData = HANDLEDATA(handleArg);
    SharedMemoryHandle handle = {
        .name = handleData->name,
        .offset = handleData->offset,
        .size = handleData->size
    };
    
    BridgeResult result = bridge_destroy_shared_memory(&handle);
    if (result == BRIDGE_SUCCESS) {
        if (handleData->name) {
            io_free(handleData->name);
            handleData->name = NULL;
        }
        handleData->offset = 0;
        handleData->size = 0;
        handleData->lastMappedPointer = NULL;
    }
    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_mapSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IONIL(self);
    }

    IoObject *handleArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *handleProto = IoState_protoWithId_(IOSTATE, handleProtoId);
    if (!IoObject_rawHasProto_(handleArg, handleProto)) {
        IoState_error_(IOSTATE, m, "Argument must be a SharedMemoryHandle");
        return IONIL(self);
    }

    IoSharedMemoryHandleData *handleData = HANDLEDATA(handleArg);
    SharedMemoryHandle handle = {
        .name = handleData->name,
        .offset = handleData->offset,
        .size = handleData->size
    };

    void *mappedPtr = NULL;
    BridgeResult result = bridge_map_shared_memory(&handle, &mappedPtr);
    if (result != BRIDGE_SUCCESS) {
        IoTelosBridge_resultToIoObject(self, locals, result, m);
        return IONIL(self);
    }

    handleData->lastMappedPointer = mappedPtr;

    char pointerBuffer[32];
    snprintf(pointerBuffer, sizeof(pointerBuffer), "%p", mappedPtr);

    IoSeq *pointerToken = IoSeq_newWithCString_(IOSTATE, pointerBuffer);
    return pointerToken;
}

IoObject *IoTelosBridge_unmapSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IONIL(self);
    }

    IoObject *handleArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *handleProto = IoState_protoWithId_(IOSTATE, handleProtoId);
    if (!IoObject_rawHasProto_(handleArg, handleProto)) {
        IoState_error_(IOSTATE, m, "First argument must be a SharedMemoryHandle");
        return IOFALSE(self);
    }

    IoObject *pointerArg = IoMessage_locals_valueArgAt_(m, locals, 1);
    void *mappedPtr = NULL;

    IoState *state = IOSTATE;
    if (pointerArg && pointerArg != state->ioNil) {
        if (ISSEQ(pointerArg)) {
            const char *pointerString = IoSeq_asCString(pointerArg);
            if (pointerString == NULL) {
                IoState_error_(IOSTATE, m, "Unable to decode pointer string");
                return IOFALSE(self);
            }
            mappedPtr = (void *)(uintptr_t)strtoull(pointerString, NULL, 0);
        } else if (ISNUMBER(pointerArg)) {
            mappedPtr = (void *)(uintptr_t)IoNumber_asLong(pointerArg);
        } else {
            IoState_error_(IOSTATE, m, "Pointer argument must be a Sequence or Number");
            return IOFALSE(self);
        }
    } else {
        mappedPtr = HANDLEDATA(handleArg)->lastMappedPointer;
    }

    if (mappedPtr == NULL) {
        IoState_error_(IOSTATE, m, "No mapped pointer available for unmapSharedMemory");
        return IOFALSE(self);
    }

    IoSharedMemoryHandleData *handleData = HANDLEDATA(handleArg);
    SharedMemoryHandle handle = {
        .name = handleData->name,
        .offset = handleData->offset,
        .size = handleData->size
    };

    BridgeResult result = bridge_unmap_shared_memory(&handle, mappedPtr);
    if (result != BRIDGE_SUCCESS) {
        return IoTelosBridge_resultToIoObject(self, locals, result, m);
    }

    if (mappedPtr == handleData->lastMappedPointer) {
        handleData->lastMappedPointer = NULL;
    }

    return IOTRUE(self);
}

/* =============================================================================
 * VSA and ANN Methods (Stubs for Phase 1)
 * =============================================================================
 */

IoObject *IoTelosBridge_executeVSABatch(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }

    const char *operationName = IoTelosBridge_getStringArg(m, 0, NULL);
    if (operationName == NULL) {
        IoState_error_(IOSTATE, m, "executeVSABatch requires an operation name string");
        return IOFALSE(self);
    }

    SharedMemoryHandle inputHandle = {0};
    SharedMemoryHandle outputHandle = {0};

    int inputStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 1),
        &inputHandle,
        1,
        "inputHandle",
        m
    );
    if (inputStatus < 0) {
        return IOFALSE(self);
    }

    int outputStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 2),
        &outputHandle,
        1,
        "outputHandle",
        m
    );
    if (outputStatus < 0) {
        return IOFALSE(self);
    }

    int batchCount = IoTelosBridge_getIntArg(m, 3, 0);
    if (batchCount <= 0) {
        IoState_error_(IOSTATE, m, "executeVSABatch requires a positive batch size");
        return IOFALSE(self);
    }

    BridgeResult result = bridge_execute_vsa_batch(
        operationName,
        &inputHandle,
        &outputHandle,
        (size_t)batchCount
    );

    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_annSearch(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }

    SharedMemoryHandle queryHandle = {0};
    SharedMemoryHandle resultsHandle = {0};

    int queryStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 0),
        &queryHandle,
        1,
        "queryHandle",
        m
    );
    if (queryStatus < 0) {
        return IOFALSE(self);
    }

    int resultsStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 2),
        &resultsHandle,
        1,
        "resultsHandle",
        m
    );
    if (resultsStatus < 0) {
        return IOFALSE(self);
    }

    int k = IoTelosBridge_getIntArg(m, 1, 0);
    if (k <= 0) {
        IoState_error_(IOSTATE, m, "annSearch requires k to be positive");
        return IOFALSE(self);
    }

    double threshold = IoTelosBridge_getDoubleArg(m, 3, 0.0);

    BridgeResult result = bridge_ann_search(
        &queryHandle,
        k,
        &resultsHandle,
        threshold
    );

    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_addVector(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }

    int64_t vectorId = (int64_t)IoTelosBridge_getIntArg(m, 0, -1);
    if (vectorId < 0) {
        IoState_error_(IOSTATE, m, "addVector requires a non-negative vectorId");
        return IOFALSE(self);
    }

    SharedMemoryHandle vectorHandle = {0};
    int handleStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 1),
        &vectorHandle,
        1,
        "vectorHandle",
        m
    );
    if (handleStatus < 0) {
        return IOFALSE(self);
    }

    const char *indexName = IoTelosBridge_getStringArg(m, 2, NULL);
    if (indexName == NULL) {
        IoState_error_(IOSTATE, m, "addVector requires an index name");
        return IOFALSE(self);
    }

    BridgeResult result = bridge_add_vector(vectorId, &vectorHandle, indexName);
    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_updateVector(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }

    int64_t vectorId = (int64_t)IoTelosBridge_getIntArg(m, 0, -1);
    if (vectorId < 0) {
        IoState_error_(IOSTATE, m, "updateVector requires a non-negative vectorId");
        return IOFALSE(self);
    }

    SharedMemoryHandle vectorHandle = {0};
    int handleStatus = IoTelosBridge_extractSharedMemoryHandle(
        self,
        IoMessage_locals_valueArgAt_(m, locals, 1),
        &vectorHandle,
        1,
        "vectorHandle",
        m
    );
    if (handleStatus < 0) {
        return IOFALSE(self);
    }

    const char *indexName = IoTelosBridge_getStringArg(m, 2, NULL);
    if (indexName == NULL) {
        IoState_error_(IOSTATE, m, "updateVector requires an index name");
        return IOFALSE(self);
    }

    BridgeResult result = bridge_update_vector(vectorId, &vectorHandle, indexName);
    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

IoObject *IoTelosBridge_removeVector(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IOFALSE(self);
    }

    int64_t vectorId = (int64_t)IoTelosBridge_getIntArg(m, 0, -1);
    if (vectorId < 0) {
        IoState_error_(IOSTATE, m, "removeVector requires a non-negative vectorId");
        return IOFALSE(self);
    }

    const char *indexName = IoTelosBridge_getStringArg(m, 1, NULL);
    if (indexName == NULL) {
        IoState_error_(IOSTATE, m, "removeVector requires an index name");
        return IOFALSE(self);
    }

    BridgeResult result = bridge_remove_vector(vectorId, indexName);
    return IoTelosBridge_resultToIoObject(self, locals, result, m);
}

/* =============================================================================
 * Error Handling Methods
 * =============================================================================
 */

IoObject *IoTelosBridge_getLastError(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    char errorBuffer[1024] = {0};
    bridge_get_last_error(errorBuffer, sizeof(errorBuffer));
    
    if (strlen(errorBuffer) > 0) {
        return IOSEQ((unsigned char *)errorBuffer, strlen(errorBuffer));
    }
    
    return IOSYMBOL("");
}

IoObject *IoTelosBridge_clearError(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    bridge_clear_error();
    return IOTRUE(self);
}

/* =============================================================================
 * Utility Methods
 * =============================================================================
 */

IoObject *IoTelosBridge_ping(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IONIL(self);
    }
    
    const char *message = IoTelosBridge_getStringArg(m, 0, "ping");
    
    // Create a response map
    IoState *state = IOSTATE;
    IoMap *response = IoMap_new(state);
    
    IoMap_rawAtPut(response, IOSYMBOL("success"), IOTRUE(self));
    IoMap_rawAtPut(response, IOSYMBOL("request"), IOSEQ((unsigned char *)message, strlen(message)));
    IoMap_rawAtPut(response, IOSYMBOL("response"), IOSYMBOL("pong"));
    
    return response;
}

/* =============================================================================
 * IoSharedMemoryHandle Implementation
 * =============================================================================
 */

static void IoSharedMemoryHandle_free(IoSharedMemoryHandle *self) {
    if (HANDLEDATA(self)) {
        if (HANDLEDATA(self)->name) {
            io_free(HANDLEDATA(self)->name);
        }
        io_free(HANDLEDATA(self));
    }
}

static IoObject *IoTelosBridge_jsonValueToIoObject(IoState *state, JSON_Value *value) {
    if (value == NULL) {
        return state->ioNil;
    }

    switch (json_value_get_type(value)) {
        case JSONNull:
            return state->ioNil;
        case JSONBoolean:
            return json_value_get_boolean(value) ? state->ioTrue : state->ioFalse;
        case JSONNumber:
            return (IoObject *)IoNumber_newWithDouble_(state, json_value_get_number(value));
        case JSONString:
            return (IoObject *)IoSeq_newWithCString_(state, json_value_get_string(value));
        case JSONArray: {
            JSON_Array *array = json_value_get_array(value);
            IoList *list = IoList_new(state);
            size_t count = json_array_get_count(array);
            for (size_t i = 0; i < count; i++) {
                JSON_Value *element = json_array_get_value(array, i);
                IoObject *ioElement = IoTelosBridge_jsonValueToIoObject(state, element);
                if (ioElement == NULL) {
                    ioElement = state->ioNil;
                }
                IoList_rawAppend_(list, ioElement);
            }
            return (IoObject *)list;
        }
        case JSONObject: {
            JSON_Object *object = json_value_get_object(value);
            IoMap *map = IoMap_new(state);
            size_t count = json_object_get_count(object);
            for (size_t i = 0; i < count; i++) {
                const char *key = json_object_get_name(object, i);
                JSON_Value *entryValue = json_object_get_value_at(object, i);
                IoObject *ioValue = IoTelosBridge_jsonValueToIoObject(state, entryValue);
                if (ioValue == NULL) {
                    ioValue = state->ioNil;
                }
                IoSymbol *keySymbol = IoState_symbolWithCString_(state, key ? key : "");
                IoMap_rawAtPut(map, keySymbol, ioValue);
            }
            return (IoObject *)map;
        }
        case JSONError:
        default:
            return state->ioNil;
    }
}

static IoObject *IoTelosBridge_submitTask(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    if (!DATA(self)->initialized) {
        IoState_error_(IOSTATE, m, "Bridge not initialized. Call initialize() first.");
        return IONIL(self);
    }

    IoObject *requestArg = IoMessage_locals_valueArgAt_(m, locals, 0);
    if (!ISSEQ(requestArg)) {
        IoState_error_(IOSTATE, m, "submitTask expects a Sequence containing JSON payload");
        return IONIL(self);
    }

    const char *requestJson = IoSeq_asCString(requestArg);
    if (requestJson == NULL) {
        IoState_error_(IOSTATE, m, "Unable to extract UTF-8 from request payload");
        return IONIL(self);
    }

    JSON_Value *request_root = json_parse_string(requestJson);
    if (request_root == NULL || json_value_get_type(request_root) != JSONObject) {
        if (request_root != NULL) {
            json_value_free(request_root);
        }
        IoState_error_(IOSTATE, m, "submitTask payload must be a JSON object");
        return IONIL(self);
    }

    JSON_Object *request_object = json_value_get_object(request_root);
    if (!IoTelosBridge_ensure_trace_context(request_object)) {
        json_value_free(request_root);
        IoState_error_(IOSTATE, m, "Failed to prepare trace context for request");
        return IONIL(self);
    }

    char *serialized_request = json_serialize_to_string(request_root);
    json_value_free(request_root);
    if (serialized_request == NULL) {
        IoState_error_(IOSTATE, m, "Unable to serialize request payload with trace context");
        return IONIL(self);
    }

    const char *finalRequestJson = serialized_request;

    size_t requestLength = strlen(finalRequestJson);
    size_t requestSize = requestLength + 1;
    if (requestSize < 64) {
        requestSize = 64;
    }

    size_t responseSize = (size_t)IoTelosBridge_getIntArg(m, 1, 4096);
    if (responseSize < 256) {
        responseSize = 256;
    }

    SharedMemoryHandle requestHandle = {0};
    SharedMemoryHandle responseHandle = {0};
    BridgeResult bridgeStatus = bridge_create_shared_memory(requestSize, &requestHandle);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    void *requestPtr = NULL;
    bridgeStatus = bridge_map_shared_memory(&requestHandle, &requestPtr);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    if (requestHandle.size < requestLength + 1) {
        bridge_unmap_shared_memory(&requestHandle, requestPtr);
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        IoState_error_(IOSTATE, m, "Request shared memory truncated");
        return IONIL(self);
    }

    memcpy(requestPtr, finalRequestJson, requestLength);
    ((char *)requestPtr)[requestLength] = '\0';
    if (requestHandle.size > requestLength + 1) {
        memset(((char *)requestPtr) + requestLength + 1, 0, requestHandle.size - (requestLength + 1));
    }

    bridgeStatus = bridge_unmap_shared_memory(&requestHandle, requestPtr);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    bridgeStatus = bridge_create_shared_memory(responseSize, &responseHandle);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    bridgeStatus = bridge_submit_json_task(&requestHandle, &responseHandle);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        bridge_destroy_shared_memory(&responseHandle);
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    void *responsePtr = NULL;
    bridgeStatus = bridge_map_shared_memory(&responseHandle, &responsePtr);
    if (bridgeStatus != BRIDGE_SUCCESS) {
        bridge_destroy_shared_memory(&responseHandle);
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        return IoTelosBridge_resultToIoObject(self, locals, bridgeStatus, m);
    }

    IoState *state = IOSTATE;
    const char *responseJson = (const char *)responsePtr;
    size_t maxLen = responseHandle.size;
    size_t actualLen = strnlen(responseJson, maxLen);

    IoObject *resultObject = NULL;

    if (actualLen == maxLen) {
        bridge_unmap_shared_memory(&responseHandle, responsePtr);
        bridge_destroy_shared_memory(&responseHandle);
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        IoState_error_(state, m, "Response JSON was not null-terminated");
        return IONIL(self);
    }

    JSON_Value *root = json_parse_string(responseJson);
    if (root == NULL) {
        bridge_unmap_shared_memory(&responseHandle, responsePtr);
        bridge_destroy_shared_memory(&responseHandle);
        bridge_destroy_shared_memory(&requestHandle);
        json_free_serialized_string(serialized_request);
        IoState_error_(state, m, "Failed to parse JSON response");
        return IONIL(self);
    }

    resultObject = IoTelosBridge_jsonValueToIoObject(state, root);
    json_value_free(root);

    bridge_unmap_shared_memory(&responseHandle, responsePtr);
    bridge_destroy_shared_memory(&responseHandle);
    bridge_destroy_shared_memory(&requestHandle);

    json_free_serialized_string(serialized_request);

    if (resultObject == NULL) {
        return state->ioNil;
    }

    return resultObject;
}

IoSharedMemoryHandle *IoSharedMemoryHandle_rawClone(IoSharedMemoryHandle *proto) {
    IoObject *self = IoObject_rawClonePrimitive(proto);
    IoObject_setDataPointer_(self, calloc(1, sizeof(IoSharedMemoryHandleData)));
    
    // Copy data from prototype
    if (HANDLEDATA(proto)->name) {
        size_t nameLen = strlen(HANDLEDATA(proto)->name);
        HANDLEDATA(self)->name = io_malloc(nameLen + 1);
        strcpy(HANDLEDATA(self)->name, HANDLEDATA(proto)->name);
    }
    HANDLEDATA(self)->offset = HANDLEDATA(proto)->offset;
    HANDLEDATA(self)->size = HANDLEDATA(proto)->size;
    HANDLEDATA(self)->lastMappedPointer = NULL;
    
    return self;
}

static IoTag *IoSharedMemoryHandle_newTag(void *state) {
    IoTag *tag = IoTag_newWithName_(handleProtoId);
    IoTag_state_(tag, state);
    IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoSharedMemoryHandle_free);
    IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoSharedMemoryHandle_rawClone);
    return tag;
}

IoSharedMemoryHandle *IoSharedMemoryHandle_new(void *state) {
    IoSharedMemoryHandle *proto = IoState_protoWithId_(state, handleProtoId);
    return IOCLONE(proto);
}

IoSharedMemoryHandle *IoSharedMemoryHandle_newWithData(void *state, 
                                                        const char *name, 
                                                        size_t offset, 
                                                        size_t size) {
    IoSharedMemoryHandle *self = IoSharedMemoryHandle_new(state);
    
    if (name) {
        size_t nameLen = strlen(name);
        HANDLEDATA(self)->name = io_malloc(nameLen + 1);
        strcpy(HANDLEDATA(self)->name, name);
    }
    HANDLEDATA(self)->offset = offset;
    HANDLEDATA(self)->size = size;
    HANDLEDATA(self)->lastMappedPointer = NULL;
    
    return self;
}

IoSharedMemoryHandle *IoSharedMemoryHandle_proto(void *state) {
    IoMethodTable methodTable[] = {
        {"name", IoSharedMemoryHandle_name},
        {"offset", IoSharedMemoryHandle_offset},
        {"size", IoSharedMemoryHandle_size},
        {NULL, NULL},
    };
    
    // Check if proto already exists
    IoSharedMemoryHandle *existing = IoState_protoWithId_(state, handleProtoId);
    if (existing != NULL) {
        return existing;
    }
    
    IoSharedMemoryHandle *self = IoObject_new(state);
    IoObject_tag_(self, IoSharedMemoryHandle_newTag(state));
    IoObject_setDataPointer_(self, calloc(1, sizeof(IoSharedMemoryHandleData)));
    
    IoState_registerProtoWithId_(state, self, handleProtoId);
    IoObject_addMethodTable_(self, methodTable);
    
    return self;
}

/* =============================================================================
 * IoSharedMemoryHandle Methods
 * =============================================================================
 */

IoObject *IoSharedMemoryHandle_name(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m) {
    if (HANDLEDATA(self)->name) {
        return IOSEQ((unsigned char *)HANDLEDATA(self)->name, strlen(HANDLEDATA(self)->name));
    }
    return IOSYMBOL("");
}

IoObject *IoSharedMemoryHandle_offset(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m) {
    return IONUMBER(HANDLEDATA(self)->offset);
}

IoObject *IoSharedMemoryHandle_size(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m) {
    return IONUMBER(HANDLEDATA(self)->size);
}

/* =============================================================================
 * Addon Initialization Function
 * =============================================================================
 */

/**
 * This function is called when the addon is loaded to register the prototypes.
 * It should be called from the main IoVM initialization.
 */
void IoTelosBridge_registerAllProtos(void *state) {
    // Register the main TelosBridge prototype
    IoTelosBridge_proto(state);
    
    // Register the SharedMemoryHandle prototype
    IoSharedMemoryHandle_proto(state);
}

void IoTelosBridgeInit(IoObject *context) {
    IoState *state = IoObject_state(context);

    if (!state) {
        return;
    }

    IoTelosBridge_registerAllProtos(state);

    IoObject *bridgeProto = IoState_protoWithId_(state, "TelosBridge");
    IoObject *handleProto = IoState_protoWithId_(state, "SharedMemoryHandle");

    if (bridgeProto) {
        IoObject_setSlot_to_(context,
                             IoState_symbolWithCString_(state, "TelosBridge"),
                             bridgeProto);
    }

    if (handleProto) {
        IoObject_setSlot_to_(context,
                             IoState_symbolWithCString_(state, "SharedMemoryHandle"),
                             handleProto);
    }
}