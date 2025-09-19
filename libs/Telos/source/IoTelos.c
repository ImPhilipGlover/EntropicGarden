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
}

// --- TelOS Core Functions ---

// Get Python version via FFI (Pillar 1: Synaptic Bridge)
IoObject *IoTelos_getPythonVersion(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Stub implementation - in real FFI, this would call Python C API
    // For now, return a mock version string
    printf("TelOS: Reaching into Python muscle via FFI...\n");
    return IoSeq_newWithCString_(IOSTATE, "3.11.0 (FFI Bridge Active)");
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
               IoList_rawSize(globalWorld->world->submorphs));

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
    IoObject_setSlot_to_(morph, SIOSYMBOL("x"), IONUMBER(100));
    IoObject_setSlot_to_(morph, SIOSYMBOL("y"), IONUMBER(100));
    IoObject_setSlot_to_(morph, SIOSYMBOL("width"), IONUMBER(50));
    IoObject_setSlot_to_(morph, SIOSYMBOL("height"), IONUMBER(50));
    IoObject_setSlot_to_(morph, SIOSYMBOL("color"), IoList_new(IOSTATE));

    // Initialize color as [r, g, b, a]
    IoList *color = (IoList *)IoObject_getSlot_(morph, SIOSYMBOL("color"));
    IoList_rawAppend_(color, IONUMBER(1.0)); // red
    IoList_rawAppend_(color, IONUMBER(0.0)); // green
    IoList_rawAppend_(color, IONUMBER(0.0)); // blue
    IoList_rawAppend_(color, IONUMBER(1.0)); // alpha

    // Add morph methods
    IoObject_setSlot_to_(morph, SIOSYMBOL("draw"), IoCFunction_newWithFunctionPointer_tag_name_(
        IOSTATE, IoTelos_morphDraw, NULL, "morphDraw"));
    IoObject_setSlot_to_(morph, SIOSYMBOL("containsPoint"), IoCFunction_newWithFunctionPointer_tag_name_(
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
    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, SIOSYMBOL("submorphs"));
    if (!submorphs) {
        submorphs = IoList_new(IOSTATE);
        IoObject_setSlot_to_(parentMorph, SIOSYMBOL("submorphs"), submorphs);
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

    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, SIOSYMBOL("submorphs"));
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
    IoNumber *x = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("height"));

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

    IoNumber *x = (IoNumber *)IoObject_getSlot_(self, SIOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(self, SIOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(self, SIOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(self, SIOSYMBOL("height"));

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
