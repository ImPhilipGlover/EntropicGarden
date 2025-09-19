/*
   IoTelos.c - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

#include "IoTelos.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoNumber.h"
#include "IoList.h"
#include "IoSeq.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <Python.h> // FFI Pillar: Include Python C API

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
} MorphicWorld;

// Global world state
static MorphicWorld *globalWorld = NULL;
static int isPythonInitialized = 0;

// --- Helper Functions ---
void IoTelos_initPython(void) {
    if (!isPythonInitialized) {
        Py_Initialize();
        isPythonInitialized = 1;
        printf("TelOS: Python Synaptic Bridge Initialized.\n");
        // Ensure Python interpreter is finalized on exit
        atexit(Py_Finalize);
    }
}

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
			{"createWorld", IoTelos_createWorld},
			{"mainLoop", IoTelos_mainLoop},
			{"createMorph", IoTelos_createMorph},
			{"addSubmorph", IoTelos_addSubmorph},
			{"removeSubmorph", IoTelos_removeSubmorph},
			{"draw", IoTelos_draw},
			{"handleEvent", IoTelos_handleEvent},
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
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRemoveSubmorph"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_removeSubmorph, NULL, "Telos_rawRemoveSubmorph"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawDraw"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_draw, NULL, "Telos_rawDraw"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawHandleEvent"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_handleEvent, NULL, "Telos_rawHandleEvent"));
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
    FILE *wal = fopen("telos.wal", "a");
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
    globalWorld->world->submorphs = IoList_new(IOSTATE);
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

    // Simple event loop simulation
    // In a real implementation, this would handle platform events
    while (globalWorld->isRunning) {
        // Process events (stub)
        IoTelos_processEvents(self);

        // Draw world
        IoTelos_drawWorld(self);

        // Small delay to prevent busy loop
        // In real implementation: proper event loop with vsync
     printf("Telos: World heartbeat (morphs: %d)\n",
         (int)IoList_rawSize(globalWorld->world->submorphs));

        // For demo: exit after a few iterations
        static int iterations = 0;
        if (++iterations > 3) {
            globalWorld->isRunning = 0;
        }
    }

    printf("Telos: Morphic main loop completed\n");
    return self;
}

// Create a new morph (living visual object)
IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoObject *morph = IoObject_new(IOSTATE);

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

// --- Helper Functions ---

void IoTelos_drawWorld(IoTelos *self)
{
    if (!globalWorld || !globalWorld->world) return;

    printf("Telos: Drawing world (%.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);

    // Draw all submorphs
    IoList *submorphs = globalWorld->world->submorphs;
    if (submorphs) {
        int count = IoList_rawSize(submorphs);
        for (int i = 0; i < count; i++) {
            IoObject *morph = IoList_rawAt_(submorphs, i);
            IoTelos_drawMorph(self, morph);
        }
    }
}

void IoTelos_drawMorph(IoTelos *self, IoObject *morph)
{
    IoNumber *x = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(morph, IOSYMBOL("height"));

    printf("Telos: Drawing morph at (%.0f,%.0f) size %.0fx%.0f\n",
           x ? CNUMBER(x) : 0,
           y ? CNUMBER(y) : 0,
           w ? CNUMBER(w) : 0,
           h ? CNUMBER(h) : 0);
}

void IoTelos_processEvents(IoTelos *self)
{
    // Stub event processing
    // In real implementation: handle mouse, keyboard, window events
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
