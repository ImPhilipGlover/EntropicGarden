#!/usr/bin/env io
writeln("=== Direct TelosMorphic Object Test ===")

writeln("Loading TelosMorphic file directly...")
doFile("libs/Telos/io/TelosMorphic.io")

writeln("Checking if TelosMorphic object exists...")
if(TelosMorphic != nil,
    writeln("✓ TelosMorphic object found")
    writeln("TelosMorphic type: ", TelosMorphic type)
    
    if(TelosMorphic hasSlot("load"),
        writeln("✓ TelosMorphic has load method")
        writeln("Calling TelosMorphic load directly...")
        result := TelosMorphic load
        writeln("Load method returned: ", result)
    ,
        writeln("✗ TelosMorphic has no load method")
        writeln("Available TelosMorphic slots:")
        TelosMorphic slotNames foreach(slot, writeln("  - ", slot))
    )
,
    writeln("✗ TelosMorphic object is nil")
)