#!/usr/bin/env io
writeln("=== Sequential Module Loading Test ===")

writeln("Loading modules in system order...")

writeln("\n--- Step 1: Loading TelosPersistence ---")
doFile("libs/Telos/io/TelosPersistence.io")
persistenceObj := Lobby getSlot("TelosPersistence")
if(persistenceObj != nil and persistenceObj hasSlot("load"),
    writeln("Calling TelosPersistence load...")
    persistenceResult := persistenceObj load
    writeln("TelosPersistence load result: ", persistenceResult != nil)
)

writeln("\n--- Step 2: Loading TelosFFI ---")
doFile("libs/Telos/io/TelosFFI.io")
ffiObj := Lobby getSlot("TelosFFI")
if(ffiObj != nil and ffiObj hasSlot("load"),
    writeln("Calling TelosFFI load...")
    ffiResult := ffiObj load  
    writeln("TelosFFI load result: ", ffiResult != nil)
)

writeln("\n--- Step 3: Loading TelosMorphic (after others) ---")
doFile("libs/Telos/io/TelosMorphic.io")
morphicObj := Lobby getSlot("TelosMorphic")
if(morphicObj != nil and morphicObj hasSlot("load"),
    writeln("Calling TelosMorphic load...")
    try(
        morphicResult := morphicObj load
        writeln("TelosMorphic load result: ", morphicResult != nil)
        writeln("✓ TelosMorphic loaded successfully in sequence")
    ,
        exception,
        writeln("✗ EXCEPTION during TelosMorphic load in sequence:")
        writeln("  Exception type: ", exception type)
        if(exception hasSlot("error"), writeln("  Exception error: ", exception error))
    )
,
    writeln("✗ TelosMorphic object not found or no load method")
)