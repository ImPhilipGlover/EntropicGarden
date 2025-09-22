#!/usr/bin/env io
writeln("=== Module Loading System Simulation ===")

# This simulates exactly what TelosCore loadModule does for TelosMorphic

writeln("Step 1: Loading file...")
doFile("libs/Telos/io/TelosMorphic.io")

writeln("Step 2: Getting module object from Lobby...")
moduleObj := Lobby getSlot("TelosMorphic")
if(moduleObj == nil,
    writeln("✗ TelosMorphic object not found in Lobby")
    exit
,
    writeln("✓ TelosMorphic object found in Lobby")
)

writeln("Step 3: Checking for load method...")
hasLoadMethod := moduleObj hasSlot("load")
if(hasLoadMethod not,
    writeln("✗ TelosMorphic has no load method")
    writeln("Available slots:")
    moduleObj slotNames foreach(slot, writeln("  - ", slot))
    exit
,
    writeln("✓ TelosMorphic has load method")
)

writeln("Step 4: Calling load method within try-catch (as TelosCore does)...")
try(
    writeln("TelOS Core: Calling load method for TelosMorphic")
    result := moduleObj load
    writeln("TelOS Core: Load method completed for TelosMorphic")
    writeln("Load result: ", result)
    if(result == nil,
        writeln("✗ Load method returned nil")
    ,
        writeln("✓ Load method returned non-nil")
    )
,
    exception,
    writeln("✗ EXCEPTION during load method:")
    writeln("  Exception type: ", exception type)
    if(exception hasSlot("error"), writeln("  Exception error: ", exception error))
    if(exception hasSlot("caughtMessage"), writeln("  Exception caughtMessage: ", exception caughtMessage))
    writeln("  This would cause loadModule to return nil")
)