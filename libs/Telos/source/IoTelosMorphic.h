/*
   IoTelosMorphic.h - Morphic UI Module Header
   SDL2 window management and direct manipulation interface
   Extracted from monolithic architecture for modular design
*/

#ifndef IOTELOMORPHIC_DEFINED
#define IOTELOMORPHIC_DEFINED 1

#include "IoObject.h"
#include "IoState.h"
#include "IoMessage.h"

#ifdef __cplusplus
extern "C" {
#endif

// Forward declarations
typedef IoObject IoTelos;

#ifdef TELOS_HAVE_SDL2
#include <SDL.h>
#else
// Forward declarations for when SDL2 is not available
typedef struct SDL_Renderer SDL_Renderer;
typedef struct SDL_Rect SDL_Rect;
#endif

// Morphic data structures
typedef struct {
    double x, y;        // Position
    double width, height; // Bounds
    double r, g, b, a;  // Color (RGBA)
    void *submorphs;    // Child morphs (IoList)
    void *owner;        // Owning Io object
} MorphicMorph;

typedef struct {
    void *windowHandle; // Platform-specific window handle
    MorphicMorph *world; // Root morph (the world)
    int isRunning;      // Main loop flag
    void *ioState;      // IoState* for accessing Io objects
#ifdef TELOS_HAVE_SDL2
    void *sdlWindow;    // SDL_Window*
    void *sdlRenderer;  // SDL_Renderer*
#endif
} MorphicWorld;

// Module initialization
void IoTelosMorphic_Init(IoState *state);
void IoTelosMorphic_registerMethods(IoState *state, IoObject *proto);

// Core Morphic methods
IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_closeWindow(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createWorld(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_mainLoop(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawWorld(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_handleEvent(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_checkEvents(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_shouldExit(IoTelos *self, IoObject *locals, IoMessage *m);

// Additional raw drawing primitives to align with Io-level Canvas
IoObject *IoTelos_drawRect(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawCircle(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawText(IoTelos *self, IoObject *locals, IoMessage *m);

// World management
MorphicWorld *IoTelosMorphic_getGlobalWorld(void);
void IoTelosMorphic_setGlobalWorld(MorphicWorld *world);

// Morph rendering helpers
void IoTelosMorphic_drawSubmorphs(SDL_Renderer *renderer, MorphicMorph *worldMorph);
void IoTelosMorphic_extractColor(IoObject *morph, int *r, int *g, int *b, int *a);
void IoTelosMorphic_extractBounds(IoObject *morph, SDL_Rect *rect);

#ifdef __cplusplus
}
#endif
#endif