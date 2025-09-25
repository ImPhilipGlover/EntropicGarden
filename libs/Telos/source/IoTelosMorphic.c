/*
   IoTelosMorphic.c - Morphic UI Module Implementation
   SDL2 window management and direct manipulation interface
   Extracted from monolithic IoTelos_deprecated.c for modular architecture
*/

#include "IoTelosMorphic.h"
#include "IoTelos.h"
#include "IoState.h"
#include "IoObject.h"
#include "IoCFunction.h"
#include "IoSeq.h"
#include "IoList.h"
#include "IoNumber.h"
#include "List.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef TELOS_HAVE_SDL2
#include <SDL.h>
#endif

// Global world state
static MorphicWorld *globalWorld = NULL;

// --- Helper Function Declarations ---
#ifdef TELOS_HAVE_SDL2
void IoTelosMorphic_dispatchKeyEvent(IoObject *self, SDL_Keycode keycode, int isDown);
#endif
void IoTelosMorphic_dispatchTextInput(IoObject *self, const char *text);
#ifdef TELOS_HAVE_SDL2
void IoTelosMorphic_drawSubmorphs(SDL_Renderer *renderer, IoObject *worldObj);
#endif

// --- Core Morphic Methods ---
IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_closeWindow(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createWorld(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_mainLoop(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_displayFor(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawWorld(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_handleEvent(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_checkEvents(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_shouldExit(IoTelos *self, IoObject *locals, IoMessage *m);

// --- Raw drawing primitives ---
IoObject *IoTelos_drawRect(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawCircle(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_drawText(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_presentFrame(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_setClip(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_clearClip(IoTelos *self, IoObject *locals, IoMessage *m);

// --- Module Initialization ---

void IoTelosMorphic_Init(IoState *state) {
    printf("TelOS Morphic: Initializing SDL2 window module...\n");
    // Module initialization can register any global state here
    printf("TelOS Morphic: ✓ Initialization complete\n");
}

void IoTelosMorphic_registerMethods(IoState *state, IoObject *proto) {
    printf("TelOS Morphic: Registering Morphic methods on prototype...\n");
    
    // Register window management methods
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "openWindow"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_openWindow, NULL, "openWindow"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "closeWindow"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_closeWindow, NULL, "closeWindow"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "createWorld"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_createWorld, NULL, "createWorld"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "mainLoop"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_mainLoop, NULL, "mainLoop"));
    
    // Register raw functions used by TelosMorphic.io
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawOpenWindow"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_openWindow, NULL, "Telos_rawOpenWindow"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawCloseWindow"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_closeWindow, NULL, "Telos_rawCloseWindow"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawCreateWorld"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_createWorld, NULL, "Telos_rawCreateWorld"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawMainLoop"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_mainLoop, NULL, "Telos_rawMainLoop"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawDisplayFor"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_displayFor, NULL, "Telos_rawDisplayFor"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawDrawWorld"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_drawWorld, NULL, "Telos_rawDrawWorld"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawHandleEvent"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_handleEvent, NULL, "Telos_rawHandleEvent"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawCreateMorph"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_createMorph, NULL, "Telos_rawCreateMorph"));

    // Register additional raw draw primitives used by Io Canvas
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawDrawRect"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_drawRect, NULL, "Telos_rawDrawRect"));
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawDrawCircle"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_drawCircle, NULL, "Telos_rawDrawCircle"));
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawDrawText"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_drawText, NULL, "Telos_rawDrawText"));
    
    // Canvas presentation method
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawPresent"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_presentFrame, NULL, "Telos_rawPresent"));
    
    // Canvas clipping methods
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawSetClip"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_setClip, NULL, "Telos_rawSetClip"));
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "Telos_rawClearClip"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_clearClip, NULL, "Telos_rawClearClip"));
    
    // Register event handling methods
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "checkEvents"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_checkEvents, NULL, "checkEvents"));
    
    IoObject_setSlot_to_(proto, IoState_symbolWithCString_(state, "shouldExit"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_shouldExit, NULL, "shouldExit"));
    
    printf("TelOS Morphic: ✓ All Morphic methods registered\n");
}

// --- World Management ---

MorphicWorld *IoTelosMorphic_getGlobalWorld(void) {
    return globalWorld;
}

void IoTelosMorphic_setGlobalWorld(MorphicWorld *world) {
    globalWorld = world;
}

// --- Core Morphic Methods ---

IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    // Create world if it doesn't exist
    if (!globalWorld) {
        IoTelos_createWorld(self, locals, m);
    }
    
    // Don't create multiple windows
    if (globalWorld->sdlWindow) {
        return self;
    }
    
    // Initialize SDL2 video subsystem
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        IoState_error_(IOSTATE, m, "SDL_Init failed: %s", SDL_GetError());
        return IONIL(self);
    }
    
    // Create SDL2 window with WSLg compatibility
    globalWorld->sdlWindow = SDL_CreateWindow(
        "TelOS Living Image",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        800, 600,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    
    if (!globalWorld->sdlWindow) {
        SDL_Quit();
        IoState_error_(IOSTATE, m, "SDL_CreateWindow failed: %s", SDL_GetError());
        return IONIL(self);
    }
    
    // Create renderer with hardware acceleration
    globalWorld->sdlRenderer = SDL_CreateRenderer(
        (SDL_Window*)globalWorld->sdlWindow, -1, 
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );
    
    if (!globalWorld->sdlRenderer) {
        // Fallback to software rendering
        globalWorld->sdlRenderer = SDL_CreateRenderer(
            (SDL_Window*)globalWorld->sdlWindow, -1, 
            SDL_RENDERER_SOFTWARE
        );
    }
    
    if (!globalWorld->sdlRenderer) {
        SDL_DestroyWindow((SDL_Window*)globalWorld->sdlWindow);
        globalWorld->sdlWindow = NULL;
        SDL_Quit();
        IoState_error_(IOSTATE, m, "SDL_CreateRenderer failed: %s", SDL_GetError());
        return IONIL(self);
    }
    
    // Initial clear with dark background
    SDL_SetRenderDrawColor((SDL_Renderer*)globalWorld->sdlRenderer, 20, 30, 40, 255);
    SDL_RenderClear((SDL_Renderer*)globalWorld->sdlRenderer);
    SDL_RenderPresent((SDL_Renderer*)globalWorld->sdlRenderer);
    
    // Force window to display (critical for WSLg)
    SDL_ShowWindow((SDL_Window*)globalWorld->sdlWindow);
    SDL_RaiseWindow((SDL_Window*)globalWorld->sdlWindow);
    SDL_PumpEvents(); // Process pending window events
    
#else
    IoState_error_(IOSTATE, m, "SDL2 support not compiled in");
    return IONIL(self);
#endif
    
    return self;
}

IoObject *IoTelos_closeWindow(IoTelos *self, IoObject *locals, IoMessage *m)
{
    printf("TelOS Morphic: Closing SDL2 window...\n");
    
#ifdef TELOS_HAVE_SDL2
    if (globalWorld && globalWorld->sdlRenderer) {
        SDL_DestroyRenderer((SDL_Renderer*)globalWorld->sdlRenderer);
        globalWorld->sdlRenderer = NULL;
        printf("TelOS Morphic: ✓ SDL2 renderer destroyed\n");
    }
    
    if (globalWorld && globalWorld->sdlWindow) {
        SDL_DestroyWindow((SDL_Window*)globalWorld->sdlWindow);
        globalWorld->sdlWindow = NULL;
        printf("TelOS Morphic: ✓ SDL2 window destroyed\n");
    }
    
    SDL_Quit();
    printf("TelOS Morphic: ✓ SDL2 subsystem shut down\n");
#else
    printf("TelOS Morphic: Window closed (fallback mode)\n");
#endif
    
    return self;
}

IoObject *IoTelos_createWorld(IoTelos *self, IoObject *locals, IoMessage *m)
{
    if (globalWorld) {
        printf("TelOS Morphic: World already exists\n");
        return self;
    }

    printf("TelOS Morphic: Creating Morphic World...\n");
    
    // Allocate world structure
    globalWorld = (MorphicWorld *)calloc(1, sizeof(MorphicWorld));
    if (!globalWorld) {
        printf("TelOS Morphic: ERROR - Failed to allocate world structure\n");
        return self;
    }
    
    // Allocate root morph (the world)
    globalWorld->world = (MorphicMorph *)calloc(1, sizeof(MorphicMorph));
    if (!globalWorld->world) {
        printf("TelOS Morphic: ERROR - Failed to allocate world morph\n");
        free(globalWorld);
        globalWorld = NULL;
        return self;
    }
    
    // Initialize world morph properties
    globalWorld->world->x = 0;
    globalWorld->world->y = 0;
    globalWorld->world->width = 640;   // Match window width
    globalWorld->world->height = 480;  // Match window height
    globalWorld->world->r = 0.125;     // Dark blue-gray background
    globalWorld->world->g = 0.188;
    globalWorld->world->b = 0.251;
    globalWorld->world->a = 1.0;
    globalWorld->world->submorphs = NULL;  // No submorphs initially
    globalWorld->world->owner = NULL;      // Root has no owner
    
    globalWorld->isRunning = 0;  // Not running main loop yet
    globalWorld->ioState = IoObject_state((IoObject *)self);  // Store IoState reference
    
    // Initialize shouldExit flag to FALSE (critical for window display)
    IoState *state = IoObject_state((IoObject *)self);
    IoSymbol *shouldExitSymbol = IoState_symbolWithCString_(state, "shouldExit");
    if (shouldExitSymbol) {
        IoObject_setSlot_to_(self, shouldExitSymbol, IOFALSE(self));
        printf("TelOS Morphic: ✓ shouldExit flag initialized to FALSE\n");
    }
    
    printf("TelOS Morphic: ✓ Morphic World created (living canvas: %.0fx%.0f)\n",
           globalWorld->world->width, globalWorld->world->height);
    
    return self;
}

IoObject *IoTelos_drawWorld(IoTelos *self, IoObject *locals, IoMessage *m)
{
    if (!globalWorld) {
        printf("TelOS Morphic: No world to draw\n");
        return self;
    }
    
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld->sdlRenderer) {
        printf("TelOS Morphic: No SDL2 renderer available\n");
        return self;
    }
    
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    
    // Clear the screen with world background color
    int r = (int)(globalWorld->world->r * 255);
    int g = (int)(globalWorld->world->g * 255);
    int b = (int)(globalWorld->world->b * 255);
    int a = (int)(globalWorld->world->a * 255);
    
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
    SDL_RenderClear(renderer);
    
    printf("TelOS Morphic: Canvas ready for Io-level drawing\n");
    
    // DON'T present here - let Io-level Canvas handle drawing and presentation
    // The presentation should happen after all Canvas operations are complete
    
#else
    printf("TelOS Morphic: Drawing world (fallback mode)\n");
#endif
    
    return self;
}

IoObject *IoTelos_handleEvent(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlWindow) {
        return self;
    }
    
    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        switch (event.type) {
            case SDL_QUIT:
                printf("TelOS Morphic: Window close requested\n");
                globalWorld->isRunning = 0;
                // Set shouldExit flag on Telos object for Io access
                IoState *state = IoObject_state(self);
                IoSymbol *shouldExitSymbol = IoState_symbolWithCString_(state, "shouldExit");
                if (shouldExitSymbol) {
                    IoObject_setSlot_to_(self, shouldExitSymbol, IOTRUE(self));
                }
                break;
            case SDL_KEYDOWN:
                printf("TelOS Morphic: Key pressed: %s\n", SDL_GetKeyName(event.key.keysym.sym));
                // Check for ESC key
                if (event.key.keysym.sym == SDLK_ESCAPE) {
                    printf("TelOS Morphic: ESC key pressed - exit requested\n");
                    globalWorld->isRunning = 0;
                    // Set shouldExit flag on Telos object for Io access
                    IoState *state = IoObject_state(self);
                    IoSymbol *shouldExitSymbol = IoState_symbolWithCString_(state, "shouldExit");
                    if (shouldExitSymbol) {
                        IoObject_setSlot_to_(self, shouldExitSymbol, IOTRUE(self));
                    }
                } else {
                    // Route text input to focused morph
                    IoTelosMorphic_dispatchKeyEvent(self, event.key.keysym.sym, 1);
                }
                break;
            case SDL_TEXTINPUT:
                // Handle text input (actual characters typed)
                printf("TelOS Morphic: Text input: %s\n", event.text.text);
                IoTelosMorphic_dispatchTextInput(self, event.text.text);
                break;
            case SDL_MOUSEBUTTONDOWN:
                printf("TelOS Morphic: Mouse click at (%d, %d)\n", event.button.x, event.button.y);
                // CRITICAL: Bridge to Io-level event dispatch
                {
                    IoState *state = IoObject_state(self);
                    IoSymbol *dispatchSym = IoState_symbolWithCString_(state, "dispatchMouseEvent");
                    IoObject *xArg = IONUMBER(event.button.x);
                    IoObject *yArg = IONUMBER(event.button.y);
                    IoObject *buttonArg = IONUMBER(event.button.button);
                    IoObject *eventTypeArg = IoState_symbolWithCString_(state, "mouseDown");
                    
                    // Call: self dispatchMouseEvent("mouseDown", x, y, button)
                    IoMessage *msg = IoMessage_newWithName_label_(state, dispatchSym, dispatchSym);
                    IoMessage_addArg_(msg, eventTypeArg);
                    IoMessage_addArg_(msg, xArg);
                    IoMessage_addArg_(msg, yArg);
                    IoMessage_addArg_(msg, buttonArg);
                    
                    IoObject_perform(self, self, msg);
                }
                break;
            case SDL_MOUSEBUTTONUP:
                printf("TelOS Morphic: Mouse release at (%d, %d)\n", event.button.x, event.button.y);
                // CRITICAL: Bridge to Io-level event dispatch
                {
                    IoState *state = IoObject_state(self);
                    IoSymbol *dispatchSym = IoState_symbolWithCString_(state, "dispatchMouseEvent");
                    IoObject *xArg = IONUMBER(event.button.x);
                    IoObject *yArg = IONUMBER(event.button.y);
                    IoObject *buttonArg = IONUMBER(event.button.button);
                    IoObject *eventTypeArg = IoState_symbolWithCString_(state, "mouseUp");
                    
                    // Call: self dispatchMouseEvent("mouseUp", x, y, button)
                    IoMessage *msg = IoMessage_newWithName_label_(state, dispatchSym, dispatchSym);
                    IoMessage_addArg_(msg, eventTypeArg);
                    IoMessage_addArg_(msg, xArg);
                    IoMessage_addArg_(msg, yArg);
                    IoMessage_addArg_(msg, buttonArg);
                    
                    IoObject_perform(self, self, msg);
                }
                break;
            // Add more event types as needed
        }
    }
#endif
    
    return self;
}

IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) {
        printf("TelOS Morphic: No world/renderer for morph creation\n");
        return self;
    }
    
    // For now, draw a simple test rectangle
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    SDL_Rect rect = {100, 100, 150, 100};  // x, y, w, h
    
    SDL_SetRenderDrawColor(renderer, 255, 128, 0, 255);  // Orange rectangle
    SDL_RenderFillRect(renderer, &rect);
    
    printf("TelOS Morphic: Created test morph (orange rectangle)\n");
    
#else
    printf("TelOS Morphic: Creating morph (fallback mode)\n");
#endif
    
    return self;
}

// Helper function to extract color from Io morph object (updated for new Morph architecture)
void IoTelosMorphic_extractColor(IoObject *morph, int *r, int *g, int *b, int *a) {
    *r = *g = *b = 128; // Default gray
    *a = 255; // Opaque
    
    if (!morph) return;
    
    // Try to get color object first (new Morph architecture)
    IoObject *colorObj = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "color"));
    if (colorObj) {
        // Try to extract r, g, b, a from color object
        IoObject *rSlot = IoObject_getSlot_(colorObj, IoState_symbolWithCString_(IoObject_state(morph), "r"));
        if (rSlot && ISNUMBER(rSlot)) {
            *r = (int)(IoNumber_asDouble(rSlot) * 255.0); // Convert 0-1 to 0-255
        }
        
        IoObject *gSlot = IoObject_getSlot_(colorObj, IoState_symbolWithCString_(IoObject_state(morph), "g"));
        if (gSlot && ISNUMBER(gSlot)) {
            *g = (int)(IoNumber_asDouble(gSlot) * 255.0);
        }
        
        IoObject *bSlot = IoObject_getSlot_(colorObj, IoState_symbolWithCString_(IoObject_state(morph), "b"));
        if (bSlot && ISNUMBER(bSlot)) {
            *b = (int)(IoNumber_asDouble(bSlot) * 255.0);
        }
        
        IoObject *aSlot = IoObject_getSlot_(colorObj, IoState_symbolWithCString_(IoObject_state(morph), "a"));
        if (aSlot && ISNUMBER(aSlot)) {
            *a = (int)(IoNumber_asDouble(aSlot) * 255.0);
        }
    } else {
        // Fallback: try to get color as string for backward compatibility
        IoObject *colorSlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "color"));
        if (colorSlot && ISSEQ(colorSlot)) {
            const char *colorStr = IoSeq_asCString(colorSlot);
            if (colorStr) {
                // Parse simple color names
                if (strcmp(colorStr, "red") == 0) { *r = 255; *g = 0; *b = 0; }
                else if (strcmp(colorStr, "green") == 0) { *r = 0; *g = 255; *b = 0; }
                else if (strcmp(colorStr, "blue") == 0) { *r = 0; *g = 0; *b = 255; }
                else if (strcmp(colorStr, "yellow") == 0) { *r = 255; *g = 255; *b = 0; }
                else if (strcmp(colorStr, "magenta") == 0) { *r = 255; *g = 0; *b = 255; }
                else if (strcmp(colorStr, "cyan") == 0) { *r = 0; *g = 255; *b = 255; }
                else if (strcmp(colorStr, "white") == 0) { *r = 255; *g = 255; *b = 255; }
                else if (strcmp(colorStr, "black") == 0) { *r = 0; *g = 0; *b = 0; }
            }
        }
    }
}

// Helper function to extract bounds from Io morph object (updated for new Morph architecture)
#ifdef TELOS_HAVE_SDL2
void IoTelosMorphic_extractBounds(IoObject *morph, SDL_Rect *rect) {
    rect->x = rect->y = 50; // Default position
    rect->w = rect->h = 100; // Default size
    
    if (!morph) {
        printf("TelOS Morphic: extractBounds - morph is NULL\n");
        return;
    }
    
    printf("TelOS Morphic: extractBounds - processing morph\n");
    
    // Try to get the bounds object first (new Morph architecture)
    IoObject *boundsObj = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "bounds"));
    if (boundsObj) {
        printf("TelOS Morphic: extractBounds - found bounds object\n");
        
        // Extract x, y, width, height from bounds object
        IoObject *xSlot = IoObject_getSlot_(boundsObj, IoState_symbolWithCString_(IoObject_state(morph), "x"));
        if (xSlot && ISNUMBER(xSlot)) {
            rect->x = (int)IoNumber_asDouble(xSlot);
            printf("TelOS Morphic: extractBounds - x = %d\n", rect->x);
        } else {
            printf("TelOS Morphic: extractBounds - x slot not found or not a number\n");
        }
        
        IoObject *ySlot = IoObject_getSlot_(boundsObj, IoState_symbolWithCString_(IoObject_state(morph), "y"));
        if (ySlot && ISNUMBER(ySlot)) {
            rect->y = (int)IoNumber_asDouble(ySlot);
            printf("TelOS Morphic: extractBounds - y = %d\n", rect->y);
        } else {
            printf("TelOS Morphic: extractBounds - y slot not found or not a number\n");
        }
        
        IoObject *widthSlot = IoObject_getSlot_(boundsObj, IoState_symbolWithCString_(IoObject_state(morph), "width"));
        if (widthSlot && ISNUMBER(widthSlot)) {
            rect->w = (int)IoNumber_asDouble(widthSlot);
            printf("TelOS Morphic: extractBounds - width = %d\n", rect->w);
        } else {
            printf("TelOS Morphic: extractBounds - width slot not found or not a number\n");
        }
        
        IoObject *heightSlot = IoObject_getSlot_(boundsObj, IoState_symbolWithCString_(IoObject_state(morph), "height"));
        if (heightSlot && ISNUMBER(heightSlot)) {
            rect->h = (int)IoNumber_asDouble(heightSlot);
            printf("TelOS Morphic: extractBounds - height = %d\n", rect->h);
        } else {
            printf("TelOS Morphic: extractBounds - height slot not found or not a number\n");
        }
    } else {
        printf("TelOS Morphic: extractBounds - no bounds object found, trying direct slots\n");
        
        // Fallback: try direct x, y, width, height slots for backward compatibility
        IoObject *xSlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "x"));
        if (xSlot && ISNUMBER(xSlot)) {
            rect->x = (int)IoNumber_asDouble(xSlot);
            printf("TelOS Morphic: extractBounds - direct x = %d\n", rect->x);
        }
        
        IoObject *ySlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "y"));
        if (ySlot && ISNUMBER(ySlot)) {
            rect->y = (int)IoNumber_asDouble(ySlot);
            printf("TelOS Morphic: extractBounds - direct y = %d\n", rect->y);
        }
        
        IoObject *widthSlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "width"));
        if (widthSlot && ISNUMBER(widthSlot)) {
            rect->w = (int)IoNumber_asDouble(widthSlot);
            printf("TelOS Morphic: extractBounds - direct width = %d\n", rect->w);
        }
        
        IoObject *heightSlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(IoObject_state(morph), "height"));
        if (heightSlot && ISNUMBER(heightSlot)) {
            rect->h = (int)IoNumber_asDouble(heightSlot);
            printf("TelOS Morphic: extractBounds - direct height = %d\n", rect->h);
        }
    }
    
    printf("TelOS Morphic: extractBounds - final rect: (%d,%d,%d,%d)\n", rect->x, rect->y, rect->w, rect->h);
}
#endif

// Helper function to dispatch key events to focused Io morph
#ifdef TELOS_HAVE_SDL2
void IoTelosMorphic_dispatchKeyEvent(IoObject *self, SDL_Keycode keycode, int isDown) {
    if (!globalWorld || !globalWorld->ioState) return;
    
    IoState *state = (IoState *)globalWorld->ioState;
    
    // Get the focused morph from Telos object
    IoSymbol *focusedMorphSym = IoState_symbolWithCString_(state, "focusedMorph");
    IoObject *focusedMorph = IoObject_getSlot_(self, focusedMorphSym);
    
    if (!focusedMorph || focusedMorph == IONIL(self)) {
        // No focused morph, ignore key event
        printf("TelOS Morphic: No focused morph for key event\n");
        return;
    }
    
    // Convert SDL keycode to string representation
    const char *keyName = SDL_GetKeyName(keycode);
    if (!keyName || strlen(keyName) == 0) {
        keyName = "unknown";
    }
    
    // Create Io string for key name
    IoObject *keyNameObj = IoSeq_newWithCString_(state, keyName);
    IoObject *isDownObj = isDown ? IOTRUE(self) : IOFALSE(self);
    
    // Call keyDown or keyUp method on focused morph
    IoSymbol *methodName = isDown ? 
        IoState_symbolWithCString_(state, "keyDown") : 
        IoState_symbolWithCString_(state, "keyUp");
    
    if (IoObject_getSlot_(focusedMorph, methodName)) {
        IoMessage *msg = IoMessage_newWithName_label_(state, methodName, methodName);
        IoMessage_addArg_(msg, keyNameObj);
        IoObject_perform(focusedMorph, focusedMorph, msg);
    }
}
#endif

// Helper function to dispatch text input to focused Io morph
void IoTelosMorphic_dispatchTextInput(IoObject *self, const char *text) {
    if (!globalWorld || !globalWorld->ioState || !text) return;
    
    IoState *state = (IoState *)globalWorld->ioState;
    
    // Get the focused morph from Telos object
    IoSymbol *focusedMorphSym = IoState_symbolWithCString_(state, "focusedMorph");
    IoObject *focusedMorph = IoObject_getSlot_(self, focusedMorphSym);
    
    if (!focusedMorph || focusedMorph == IONIL(self)) {
        // No focused morph, ignore text input
        printf("TelOS Morphic: No focused morph for text input\n");
        return;
    }
    
    // Create Io string for text
    IoObject *textObj = IoSeq_newWithCString_(state, text);
    
    // Call textInput method on focused morph
    IoSymbol *methodName = IoState_symbolWithCString_(state, "textInput");
    
    if (IoObject_getSlot_(focusedMorph, methodName) != IONIL(focusedMorph)) {
        IoMessage *msg = IoMessage_newWithName_label_(state, methodName, methodName);
        IoMessage_addArg_(msg, textObj);
        IoObject_perform(focusedMorph, focusedMorph, msg);
    }
}

// Helper function to recursively draw all submorphs
#ifdef TELOS_HAVE_SDL2
void IoTelosMorphic_drawSubmorphs(SDL_Renderer *renderer, IoObject *worldObj) {
    if (!renderer || !worldObj) {
        printf("TelOS Morphic: drawSubmorphs - renderer or worldObj is NULL\n");
        return;
    }
    
    IoState *state = IoObject_state(worldObj);
    printf("TelOS Morphic: drawSubmorphs - starting with world object\n");
    
    // Get the world bounds and color
    SDL_Rect worldRect = {0, 0, 800, 600}; // Default window size
    int r = 128, g = 160, b = 192, a = 255; // Default background color
    
    // Try to get backgroundColor from world
    IoObject *bgColor = IoObject_getSlot_(worldObj, IoState_symbolWithCString_(state, "backgroundColor"));
    if (bgColor) {
        IoTelosMorphic_extractColor(bgColor, &r, &g, &b, &a);
        printf("TelOS Morphic: drawSubmorphs - extracted world background color: %d,%d,%d,%d\n", r, g, b, a);
    } else {
        printf("TelOS Morphic: drawSubmorphs - no backgroundColor found, using default\n");
    }
    
    // Draw world background
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
    SDL_RenderFillRect(renderer, &worldRect);
    printf("TelOS Morphic: drawSubmorphs - drew world background\n");
    
    // Get submorphs list from Io world object
    IoObject *submorphs = IoObject_getSlot_(worldObj, IoState_symbolWithCString_(state, "submorphs"));
    if (submorphs && ISLIST(submorphs)) {
        int count = IoList_rawSize(submorphs);
        printf("TelOS Morphic: drawSubmorphs - found %d submorphs\n", count);
        
        for (int i = 0; i < count; i++) {
            IoObject *morph = IoList_rawAt_(submorphs, i);
            if (morph) {
                printf("TelOS Morphic: drawSubmorphs - processing morph %d\n", i);
                
                // Extract bounds and color from Io morph
                SDL_Rect morphRect;
                IoTelosMorphic_extractBounds(morph, &morphRect);
                
                int mr = 200, mg = 200, mb = 200, ma = 255; // Default morph color
                IoTelosMorphic_extractColor(morph, &mr, &mg, &mb, &ma);
                printf("TelOS Morphic: drawSubmorphs - extracted morph color: %d,%d,%d,%d\n", mr, mg, mb, ma);
                
                // Draw the morph
                SDL_SetRenderDrawColor(renderer, mr, mg, mb, ma);
                SDL_RenderFillRect(renderer, &morphRect);
                printf("TelOS Morphic: drawSubmorphs - drew morph fill rect\n");
                
                // Draw border
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255); // Black border
                SDL_RenderDrawRect(renderer, &morphRect);
                printf("TelOS Morphic: drawSubmorphs - drew morph border\n");
                
                // Get morph type for debugging
                IoObject *typeSlot = IoObject_getSlot_(morph, IoState_symbolWithCString_(state, "type"));
                if (typeSlot && ISSEQ(typeSlot)) {
                    const char *typeStr = IoSeq_asCString(typeSlot);
                    printf("TelOS Morphic: drawSubmorphs - completed morph %s at (%d,%d,%d,%d)\n", 
                           typeStr, morphRect.x, morphRect.y, morphRect.w, morphRect.h);
                } else {
                    printf("TelOS Morphic: drawSubmorphs - completed morph (no type) at (%d,%d,%d,%d)\n", 
                           morphRect.x, morphRect.y, morphRect.w, morphRect.h);
                }
            } else {
                printf("TelOS Morphic: drawSubmorphs - morph %d is NULL\n", i);
            }
        }
    } else {
        printf("TelOS Morphic: drawSubmorphs - no submorphs list found or not a list\n");
    }
    
    printf("TelOS Morphic: drawSubmorphs - completed\n");
}
#endif

IoObject *IoTelos_checkEvents(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Process events and update shouldExit flag if needed
    IoTelos_handleEvent(self, locals, m);
    return self;
}

IoObject *IoTelos_shouldExit(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Return the current shouldExit status safely
    IoState *state = IoObject_state(self);
    
    // Create the symbol safely
    IoSymbol *shouldExitSymbol = IoState_symbolWithCString_(state, "shouldExit");
    if (!shouldExitSymbol) {
        printf("TelOS Morphic: Failed to create shouldExit symbol\n");
        return IOFALSE(self);
    }
    
    // Get the slot safely
    IoObject *shouldExitSlot = IoObject_getSlot_(self, shouldExitSymbol);
    if (shouldExitSlot && ISTRUE(shouldExitSlot)) {
        printf("TelOS Morphic: shouldExit is TRUE\n");
        return IOTRUE(self);
    }
    
    printf("TelOS Morphic: shouldExit is FALSE or not set\n");
    return IOFALSE(self);
}

IoObject *IoTelos_mainLoop(IoTelos *self, IoObject *locals, IoMessage *m)
{
    printf("TelOS Morphic: Starting main event loop...\n");
    
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlWindow) {
        printf("TelOS Morphic: No window available for main loop\n");
        return self;
    }
    
    globalWorld->isRunning = 1;
    
    printf("TelOS Morphic: WARNING - This is a BLOCKING main loop!\n");
    printf("TelOS Morphic: The loop will run until the window is closed.\n");
    
    while (globalWorld->isRunning) {
        // Handle events
        IoTelos_handleEvent(self, locals, m);
        
        // Draw world
        IoTelos_drawWorld(self, locals, m);
        
        // Small delay to prevent 100% CPU usage
        SDL_Delay(16);  // ~60 FPS
    }
    
    printf("TelOS Morphic: Main loop ended\n");
    
#else
    printf("TelOS Morphic: Main loop (fallback mode)\n");
#endif
    
    return self;
}

IoObject *IoTelos_displayFor(IoTelos *self, IoObject *locals, IoMessage *m)
{
    printf("TelOS Morphic: Starting displayFor timed event loop...\n");
    
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlWindow) {
        printf("TelOS Morphic: No window available for displayFor\n");
        return self;
    }
    
    // Get duration argument (in seconds)
    double duration = 0.0; // Default to perpetual
    if (IoMessage_argCount(m) > 0) {
        IoObject *durationArg = IoMessage_locals_valueArgAt_(m, locals, 0);
        if (durationArg && ISNUMBER(durationArg)) {
            duration = IoNumber_asDouble(durationArg);
        }
    }
    
    // Support perpetual mode: 0 or -1 means run until manually closed
    int isPerpetual = (duration <= 0.0);
    
    printf("TelOS Morphic: displayFor duration: %s\n", 
           isPerpetual ? "perpetual" : "timed");
    
    globalWorld->isRunning = 1;
    
    if (isPerpetual) {
        printf("TelOS Morphic: WARNING - This is a BLOCKING perpetual display!\n");
        printf("TelOS Morphic: The loop will run until the window is closed.\n");
    } else {
        printf("TelOS Morphic: Display will run for %.1f seconds\n", duration);
    }
    
    // Track start time for timed display
    Uint32 startTime = SDL_GetTicks();
    Uint32 durationMs = (Uint32)(duration * 1000.0);
    
    while (globalWorld->isRunning) {
        // Handle events
        IoTelos_handleEvent(self, locals, m);
        
        // Draw world
        IoTelos_drawWorld(self, locals, m);
        
        // Check if timed display should exit
        if (!isPerpetual) {
            Uint32 currentTime = SDL_GetTicks();
            if (currentTime - startTime >= durationMs) {
                printf("TelOS Morphic: Display duration expired (%.1f seconds)\n", duration);
                globalWorld->isRunning = 0;
                break;
            }
        }
        
        // Small delay to prevent 100% CPU usage
        SDL_Delay(16);  // ~60 FPS
    }
    
    printf("TelOS Morphic: displayFor loop ended\n");
    
#else
    printf("TelOS Morphic: displayFor (fallback mode)\n");
#endif
    
    return self;
}

// --- Raw drawing primitives to support Io Canvas ---

IoObject *IoTelos_drawRect(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) return self;
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    // Extract args: x, y, w, h, r, g, b, a
    int x = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 0));
    int y = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 1));
    int w = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 2));
    int h = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 3));
    int r = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 4)) * 255.0);
    int g = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 5)) * 255.0);
    int b = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 6)) * 255.0);
    int a = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 7)) * 255.0);
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
    SDL_Rect rect = {x, y, w, h};
    SDL_RenderFillRect(renderer, &rect);
#endif
    return self;
}

IoObject *IoTelos_drawCircle(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) return self;
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    int cx = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 0));
    int cy = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 1));
    int radius = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 2));
    int r = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 3)) * 255.0);
    int g = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 4)) * 255.0);
    int b = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 5)) * 255.0);
    int a = (int)(IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 6)) * 255.0);
    SDL_SetRenderDrawColor(renderer, r, g, b, a);
    // Simple filled circle via midpoint algorithm approximation
    for (int dy = -radius; dy <= radius; ++dy) {
        int dx = (int)sqrt(radius * radius - dy * dy);
        SDL_RenderDrawLine(renderer, cx - dx, cy + dy, cx + dx, cy + dy);
    }
#endif
    return self;
}

IoObject *IoTelos_drawText(IoTelos *self, IoObject *locals, IoMessage *m)
{
    // Placeholder: text rendering requires a font library; log and no-op
    // Args: text, x, y, r, g, b, a
    printf("TelOS Morphic: drawText placeholder invoked\n");
    return self;
}

IoObject *IoTelos_presentFrame(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) {
        printf("TelOS Morphic: No SDL2 renderer for frame presentation\n");
        return self;
    }
    
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    SDL_RenderPresent(renderer);
    printf("TelOS Morphic: Frame presented to screen\n");
#else
    printf("TelOS Morphic: presentFrame (fallback mode)\n");
#endif
    return self;
}

IoObject *IoTelos_setClip(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) return self;
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    
    // Extract clip rectangle args: x, y, width, height
    int x = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 0));
    int y = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 1));
    int w = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 2));
    int h = (int)IoNumber_asDouble(IoMessage_locals_valueArgAt_(m, locals, 3));
    
    SDL_Rect clipRect = {x, y, w, h};
    SDL_RenderSetClipRect(renderer, &clipRect);
    printf("TelOS Morphic: Set clip region to (%d,%d,%d,%d)\n", x, y, w, h);
#endif
    return self;
}

IoObject *IoTelos_clearClip(IoTelos *self, IoObject *locals, IoMessage *m)
{
#ifdef TELOS_HAVE_SDL2
    if (!globalWorld || !globalWorld->sdlRenderer) return self;
    SDL_Renderer *renderer = (SDL_Renderer*)globalWorld->sdlRenderer;
    
    SDL_RenderSetClipRect(renderer, NULL);  // NULL clears clipping
    printf("TelOS Morphic: Cleared clip region\n");
#endif
    return self;
}
