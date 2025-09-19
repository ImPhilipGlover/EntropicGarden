/*
   IoTelosUI.c - Morphic UI Framework for TelOS
   Everything is a living Morph that can be directly manipulated
   */

#include "IoTelosUI.h"
#include "IoState.h"
#include "IoCFunction.h"
#include "IoNumber.h"
#include "IoList.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

static const char *protoId = "TelosUI";

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

IoTag *IoTelosUI_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_(protoId);
	IoTag_state_(tag, state);
	IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTelosUI_rawClone);
	IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTelosUI_free);
	return tag;
}

IoTelosUI *IoTelosUI_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoTelosUI_newTag(state));

	IoState_registerProtoWithId_(state, self, protoId);

	{
		IoMethodTable methodTable[] = {
			{"createWorld", IoTelosUI_createWorld},
			{"mainLoop", IoTelosUI_mainLoop},
			{"createMorph", IoTelosUI_createMorph},
			{"addSubmorph", IoTelosUI_addSubmorph},
			{"removeSubmorph", IoTelosUI_removeSubmorph},
			{"draw", IoTelosUI_draw},
			{"handleEvent", IoTelosUI_handleEvent},
			{NULL, NULL},
		};
		IoObject_addMethodTable_(self, methodTable);
	}

	return self;
}

IoTelosUI *IoTelosUI_rawClone(IoTelosUI *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	return self;
}

void IoTelosUI_free(IoTelosUI *self)
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

// --- Morphic Core Functions ---

// Create the root world (equivalent to Morphic's World)
IoObject *IoTelosUI_createWorld(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    if (globalWorld) {
        printf("TelosUI: World already exists\n");
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

    printf("TelosUI: Morphic World created (living canvas: %.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);
    return self;
}

// Main event loop - the heart of the living interface
IoObject *IoTelosUI_mainLoop(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    if (!globalWorld) {
        printf("TelosUI: No world exists - call createWorld first\n");
        return self;
    }

    printf("TelosUI: Entering Morphic main loop (living interface active)\n");
    globalWorld->isRunning = 1;

    // Simple event loop simulation
    // In a real implementation, this would handle platform events
    while (globalWorld->isRunning) {
        // Process events (stub)
        IoTelosUI_processEvents(self);

        // Draw world
        IoTelosUI_drawWorld(self);

        // Small delay to prevent busy loop
        // In real implementation: proper event loop with vsync
        printf("TelosUI: World heartbeat (morphs: %d)\n",
               IoList_rawCount(globalWorld->world->submorphs));

        // For demo: exit after a few iterations
        static int iterations = 0;
        if (++iterations > 3) {
            globalWorld->isRunning = 0;
        }
    }

    printf("TelosUI: Morphic main loop completed\n");
    return self;
}

// Create a new morph (living visual object)
IoObject *IoTelosUI_createMorph(IoTelosUI *self, IoObject *locals, IoMessage *m)
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
        IOSTATE, IoTelosUI_morphDraw, NULL, "morphDraw"));
    IoObject_setSlot_to_(morph, SIOSYMBOL("containsPoint"), IoCFunction_newWithFunctionPointer_tag_name_(
        IOSTATE, IoTelosUI_morphContainsPoint, NULL, "morphContainsPoint"));

    printf("TelosUI: Living morph created at (100,100)\n");
    return morph;
}

// Add a submorph to another morph
IoObject *IoTelosUI_addSubmorph(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    IoObject *parentMorph = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *childMorph = IoMessage_locals_valueArgAt_(m, locals, 1);

    if (!parentMorph || !childMorph) {
        printf("TelosUI: Invalid morphs for addSubmorph\n");
        return self;
    }

    // Get or create submorphs list
    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, SIOSYMBOL("submorphs"));
    if (!submorphs) {
        submorphs = IoList_new(IOSTATE);
        IoObject_setSlot_to_(parentMorph, SIOSYMBOL("submorphs"), submorphs);
    }

    IoList_rawAppend_(submorphs, childMorph);
    printf("TelosUI: Morph added as submorph (living hierarchy grows)\n");

    return self;
}

// Remove a submorph
IoObject *IoTelosUI_removeSubmorph(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    IoObject *parentMorph = IoMessage_locals_valueArgAt_(m, locals, 0);
    IoObject *childMorph = IoMessage_locals_valueArgAt_(m, locals, 1);

    if (!parentMorph || !childMorph) {
        printf("TelosUI: Invalid morphs for removeSubmorph\n");
        return self;
    }

    IoList *submorphs = (IoList *)IoObject_getSlot_(parentMorph, SIOSYMBOL("submorphs"));
    if (submorphs) {
        IoList_remove_(submorphs, childMorph);
        printf("TelosUI: Morph removed from living hierarchy\n");
    }

    return self;
}

// Draw the world and all its morphs
IoObject *IoTelosUI_draw(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    if (!globalWorld) {
        printf("TelosUI: No world to draw\n");
        return self;
    }

    IoTelosUI_drawWorld(self);
    return self;
}

// Handle events (direct manipulation)
IoObject *IoTelosUI_handleEvent(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    // Stub event handling - in real implementation would handle mouse, keyboard, etc.
    printf("TelosUI: Event received (direct manipulation ready)\n");
    return self;
}

// --- Helper Functions ---

void IoTelosUI_drawWorld(IoTelosUI *self)
{
    if (!globalWorld || !globalWorld->world) return;

    printf("TelosUI: Drawing world (%.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);

    // Draw all submorphs
    IoList *submorphs = globalWorld->world->submorphs;
    if (submorphs) {
        int count = IoList_rawCount(submorphs);
        for (int i = 0; i < count; i++) {
            IoObject *morph = IoList_rawAt_(submorphs, i);
            IoTelosUI_drawMorph(self, morph);
        }
    }
}

void IoTelosUI_drawMorph(IoTelosUI *self, IoObject *morph)
{
    IoNumber *x = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("x"));
    IoNumber *y = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("y"));
    IoNumber *w = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("width"));
    IoNumber *h = (IoNumber *)IoObject_getSlot_(morph, SIOSYMBOL("height"));

    printf("TelosUI: Drawing morph at (%.0f,%.0f) size %.0fx%.0f\n",
           x ? CNUMBER(x) : 0,
           y ? CNUMBER(y) : 0,
           w ? CNUMBER(w) : 0,
           h ? CNUMBER(h) : 0);
}

void IoTelosUI_processEvents(IoTelosUI *self)
{
    // Stub event processing
    // In real implementation: handle mouse, keyboard, window events
}

// Morph-specific methods
IoObject *IoTelosUI_morphDraw(IoObject *self, IoObject *locals, IoMessage *m)
{
    IoTelosUI_drawMorph(NULL, self);
    return self;
}

IoObject *IoTelosUI_morphContainsPoint(IoObject *self, IoObject *locals, IoMessage *m)
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
