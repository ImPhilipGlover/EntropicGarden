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
#include "IoMap.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <Python.h> // FFI Pillar: Include Python C API
#include <sys/stat.h>
#include <errno.h>
#ifdef TELOS_HAVE_SDL2
#include <SDL.h>
#endif

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

// Forward declaration for Ollama bridge
IoObject *IoTelos_ollamaGenerate(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for generic Python eval
IoObject *IoTelos_pyEval(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for simple logger
IoObject *IoTelos_logAppend(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declarations for RAG skeleton
IoObject *IoTelos_ragIndex(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_ragQuery(IoTelos *self, IoObject *locals, IoMessage *m);
// Forward declaration for addMorphToWorld no-op hook
IoObject *IoTelos_addMorphToWorld(IoTelos *self, IoObject *locals, IoMessage *m);

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
            {"logAppend", IoTelos_logAppend},
            {"ragIndex", IoTelos_ragIndex},
            {"ragQuery", IoTelos_ragQuery},
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

    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawPyEval"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_pyEval, NULL, "Telos_rawPyEval"));

    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawLogAppend"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_logAppend, NULL, "Telos_rawLogAppend"));

    // RAG skeleton bridge
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRagIndex"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ragIndex, NULL, "Telos_rawRagIndex"));
    IoObject_setSlot_to_(telosProto, IoState_symbolWithCString_(state, "Telos_rawRagQuery"),
                         IoCFunction_newWithFunctionPointer_tag_name_(state, (IoUserFunction *)IoTelos_ragQuery, NULL, "Telos_rawRagQuery"));

    // Autoload Io-level TelOS layer (IoTelos.io)
    // Try a few likely paths to support both WSL and native Windows dev layouts
    {
        const char *candidates[] = {
            "/mnt/c/EntropicGarden/libs/Telos/io/IoTelos.io",              // WSL absolute path
            "c:/EntropicGarden/libs/Telos/io/IoTelos.io",                   // Windows absolute (forward slashes)
            "c\\\\EntropicGarden\\\\libs\\\\Telos\\\\io\\\\IoTelos.io", // Windows absolute (escaped backslashes for C string)
            "../../libs/Telos/io/IoTelos.io",                                // Relative from build/bin
            "../libs/Telos/io/IoTelos.io",                                  // Relative from tools binary (alt)
            "libs/Telos/io/IoTelos.io",                                     // Relative from repo root
            "TelOS/io/IoTelos.io",                                          // Backup location path
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
                printf("TelOS: Loaded Io layer from %s\n", path);
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
        result = IoSeq_newWithCString_(IOSTATE, "[OLLAMA_ERROR] request failed");
    }

    return result;
}

// --- Generic Python Eval ---
// Io signature: Telos_rawPyEval(code) -> string result or empty string
IoObject *IoTelos_pyEval(IoTelos *self, IoObject *locals, IoMessage *m)
{
    IoSeq *codeSeq = (IoSeq *)IoMessage_locals_valueArgAt_(m, locals, 0);
    const char *code = codeSeq ? IoSeq_asCString(codeSeq) : NULL;
    if (!code) {
        return IoSeq_newWithCString_(IOSTATE, "");
    }

    IoTelos_initPython();
    IoObject *result = NULL;
    PyGILState_STATE gstate = PyGILState_Ensure();

    PyObject *globals = PyDict_New();
    PyObject *localsDict = globals ? globals : PyDict_New();
    if (globals && localsDict) {
        PyDict_SetItemString(globals, "__builtins__", PyEval_GetBuiltins());

        // Try eval first
        PyObject *pyRes = PyRun_StringFlags(code, Py_eval_input, globals, localsDict, NULL);
        if (pyRes) {
            PyObject *s = PyObject_Str(pyRes);
            if (s && PyUnicode_Check(s)) {
                const char *cstr = PyUnicode_AsUTF8(s);
                if (cstr) {
                    result = IoSeq_newWithCString_(IOSTATE, cstr);
                }
            }
            Py_XDECREF(s);
            Py_DECREF(pyRes);
        } else {
            // Clear the error and attempt exec (statements)
            PyErr_Clear();
            PyObject *pyExec = PyRun_StringFlags(code, Py_file_input, globals, localsDict, NULL);
            if (pyExec) {
                Py_DECREF(pyExec);
                result = IoSeq_newWithCString_(IOSTATE, "");
            } else {
                // Return error string
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
                result = IoSeq_newWithCString_(IOSTATE, err);
                Py_XDECREF(ptype); Py_XDECREF(pvalue); Py_XDECREF(ptrace);
            }
        }
    }

    Py_XDECREF(globals);
    if (localsDict && localsDict != globals) Py_XDECREF(localsDict);
    PyGILState_Release(gstate);

    if (!result) {
        result = IoSeq_newWithCString_(IOSTATE, "");
    }
    return result;
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
        return IoSeq_newWithCString_(IOSTATE, "");
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
                    result = IoSeq_newWithData_length_(IOSTATE, (const unsigned char *)cstr, (size_t)size);
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
        result = IoSeq_newWithCString_(IOSTATE, "");
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
