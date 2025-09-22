/*
   IoTelos.c - Modular TelOS Architecture Coordinator
   Orchestrates Core, FFI, Morphic, Persistence, Memory, and Persona modules
   Extracted from 2687-line monolith for targeted debugging and antifragile architecture
*/

#include "IoTelos.h"
#include "IoTelosCore.h"
#include "IoTelosFFI.h"
#include "IoTelosMorphic.h"
#include "IoState.h"
#include "IoObject.h"
#include "IoSeq.h"
#include "IoCFunction.h"
#include <stdio.h>

// Main module initialization - coordinates all subsystem modules
void IoTelosInit(IoState *state, IoObject *context) {
    printf("TelOS: Initializing modular architecture...\n");
    
    // Initialize core system (coordinates all modules)
    IoTelosCore_Init(state);
    
    // Initialize Morphic module
    IoTelosMorphic_Init(state);
    
    // Get the registered Telos prototype
    printf("TelOS Init: Getting Telos prototype...\n");
    IoObject *telosProto = (IoObject *)IoTelos_proto(state);
    printf("TelOS Init: Got prototype (%p)\n", telosProto);
    
    // Expose proto on Protos namespace
    printf("TelOS Init: Getting Protos namespace...\n");
    IoObject *protos = IoObject_getSlot_(state->lobby, IoState_symbolWithCString_(state, "Protos"));
    printf("TelOS Init: Got Protos (%p)\n", protos);
    if (protos) {
        printf("TelOS Init: Setting Telos slot on Protos...\n");
        IoObject_setSlot_to_(protos, IoState_symbolWithCString_(state, "Telos"), telosProto);
        printf("TelOS Init: ✓ Telos slot set\n");
    }
    
    // Load Io-level modules now that C architecture is stable
    printf("TelOS Init: Loading Io-level modules...\n");
    
    // Load TelosCore.io which coordinates all Io module loading
    const char *candidates[] = {
        "/mnt/c/EntropicGarden/libs/Telos/io/TelosCore.io",        // WSL absolute path
        "c:/EntropicGarden/libs/Telos/io/TelosCore.io",           // Windows absolute
        "../../libs/Telos/io/TelosCore.io",                       // Relative from build/bin
        "../libs/Telos/io/TelosCore.io",                          // Relative from tools binary
        "libs/Telos/io/TelosCore.io",                             // Relative from repo root
        NULL
    };

    int loaded = 0;
    for (int i = 0; candidates[i] != NULL; i++) {
        const char *path = candidates[i];
        FILE *f = fopen(path, "r");
        if (f) {
            fclose(f);
            printf("TelOS Init: Loading core from %s...\n", path);
            IoState_doFile_(state, path);
            printf("TelOS Init: ✓ Loaded Io modules successfully\n");
            loaded = 1;
            break;
        }
    }
    
    if (!loaded) {
        printf("TelOS Init: WARNING - Could not find TelosCore.io, Morphic not available\n");
    }
    
    printf("TelOS: ✓ Modular architecture initialized - Core, FFI, Morphic, Persistence, Memory, Persona\n");
}