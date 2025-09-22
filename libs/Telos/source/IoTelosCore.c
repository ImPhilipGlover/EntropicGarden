/*
   IoTelosCore.c - Core System Implementation
   Fundamental TelOS object management and initialization
   Extracted from monolithic IoTelos.c for modular architecture
*/

#include "IoTelosCore.h"
#include "IoTelos.h"
#include "IoTelosFFI.h"
#include "IoState.h"
#include "IoObject.h"
#include "Collector.h"
#include "List.h"

// GC Pinning System for FFI Bridge Safety - Critical for C/Python proxy objects
static List *pinnedObjects = NULL;
#include "IoSeq.h"
#include "IoNumber.h"
#include "IoCFunction.h"
#include "IoTag.h"
#include <stdlib.h>
#include <string.h>

static const char *protoId = "Telos";

// Core TelOS prototype
static IoTelos *proto = NULL;

// --- Core Object Management ---

IoTag *IoTelos_newTag(void *state) {
    IoTag *tag = IoTag_newWithName_(protoId);
    IoTag_state_(tag, state);
    IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTelos_free);
    IoTag_markFunc_(tag, (IoTagMarkFunc *)IoTelos_mark);
    IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTelos_rawClone);  // CRITICAL: Set clone function!
    return tag;
}

IoTelos *IoTelos_proto(void *state) {
    printf("TelOS Core: Creating prototype (proto=%p)...\n", proto);
    if (!proto) {
        printf("TelOS Core: Creating new IoObject...\n");
        proto = (IoTelos *)IoObject_new(state);
        printf("TelOS Core: Setting tag...\n");
        IoObject_tag_(proto, IoTelos_newTag(state));
        printf("TelOS Core: Setting data pointer...\n");
        IoObject_setDataPointer_(proto, proto);
        
        printf("TelOS Core: Initializing Python subsystem...\n");
        // Initialize Python subsystem
        IoTelosFFI_initEnhancedPython();
        
        printf("TelOS Core: Registering prototype with state...\n");
        IoState_registerProtoWithId_(state, proto, protoId);
        
        printf("TelOS Core: Registering FFI methods...\n");
        // Register methods from all modules
        IoTelosFFI_registerMethods(state, (IoObject*)proto);
        
        printf("TelOS Core: Registering core methods...\n");
        // Core methods
        IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "protoId"),
                           IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_protoId, NULL, "protoId"));
        
        printf("TelOS Core: ✓ Prototype creation complete\n");
    } else {
        printf("TelOS Core: Using existing prototype (%p)\n", proto);
    }
    
    printf("TelOS Core: Returning prototype (%p)\n", proto);
    return proto;
}

IoTelos *IoTelos_rawClone(IoTelos *proto) {
    printf("TelOS Core: Cloning prototype (%p)...\n", proto);
    printf("TelOS Core: About to call IoObject_rawClonePrimitive...\n");
    
    // Use standard Io cloning mechanism like other objects
    IoObject *self = IoObject_rawClonePrimitive((IoObject*)proto);
    printf("TelOS Core: IoObject_rawClonePrimitive returned (%p)\n", self);
    
    if (!self) {
        printf("TelOS Core: ERROR - Clone returned NULL!\n");
        return NULL;
    }
    
    printf("TelOS Core: Clone object created, about to pin...\n");
    
    // CRITICAL: Pin the cloned object to prevent GC collection
    // This prevents the GC mismatch issue identified in architectural analysis
    IoTelos_pinObject(self);
    printf("TelOS Core: ✓ Clone completed and pinned (%p)\n", self);
    
    return (IoTelos*)self;
}

IoTelos *IoTelos_new(void *state) {
    IoTelos *proto = IoTelos_proto(state);
    return IoTelos_rawClone(proto);
}

void IoTelos_free(IoTelos *self) {
    // Clean up any TelOS-specific resources
    // Core object cleanup is handled by IoObject_free
}

// GC Pinning API - CRITICAL for FFI Bridge Integrity
// Prevents IoCollector from freeing objects held by C/Python proxies

void IoTelos_pinObject(IoObject *object) {
    if (!pinnedObjects) {
        pinnedObjects = List_new();
    }
    
    // Use Collector retain system to prevent GC of this object
    IoState *state = IoObject_state(object);
    if (state && state->collector) {
        Collector_retain_(state->collector, object);
        List_append_(pinnedObjects, object);
        printf("TelOS GC: Pinned object (%p) to prevent collection\n", object);
    }
}

void IoTelos_unpinObject(IoObject *object) {
    if (!pinnedObjects) return;
    
    // Release from Collector retain system
    IoState *state = IoObject_state(object);
    if (state && state->collector) {
        Collector_stopRetaining_(state->collector, object);
        List_remove_(pinnedObjects, object);
        printf("TelOS GC: Unpinned object (%p), now eligible for collection\n", object);
    }
}

void IoTelos_unpinAllObjects(void) {
    if (!pinnedObjects) return;
    
    printf("TelOS GC: Unpinning all objects (%d total)\n", (int)List_size(pinnedObjects));
    
    // Release all pinned objects
    LIST_FOREACH(pinnedObjects, i, object,
        IoState *state = IoObject_state((IoObject*)object);
        if (state && state->collector) {
            Collector_stopRetaining_(state->collector, object);
        }
    );
    
    List_free(pinnedObjects);
    pinnedObjects = NULL;
}

void IoTelos_mark(IoTelos *self) {
    IoObject_shouldMark(self);
}

// --- Core Methods ---

IoObject *IoTelos_protoId(IoTelos *self, IoObject *locals, IoMessage *m) {
    return IoSeq_newWithCString_(IoObject_state((IoObject*)self), protoId);
}

// --- Module Initialization ---

void IoTelosCore_Init(IoState *state) {
    printf("TelOS Core: Initializing subsystem modules...\n");
    
    // Initialize all subsystem modules
    printf("TelOS Core: Registering FFI prototype...\n");
    IoTelosFFI_registerPrototype(state);
    
    // Register the main Telos prototype
    printf("TelOS Core: Registering main prototype...\n");
    IoTelosCore_registerProto(state);
    
    printf("TelOS Core: ✓ Initialization complete\n");
}

void IoTelosCore_registerProto(IoState *state) {
    IoTelos *telosProto = IoTelos_proto(state);
    
    // Register in the Lobby
    IoObject_setSlot_to_(IoState_lobby(state), 
                        IoState_symbolWithCString_(state, protoId), 
                        telosProto);
}