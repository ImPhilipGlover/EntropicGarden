#!/usr/bin/env io

writeln("=== Manual TelosMorphic.io Load Test ===")
writeln()

writeln("1. Before loading - checking Lobby:")
writeln("Morph available: " .. (Lobby hasSlot("Morph")))
writeln("RectangleMorph available: " .. (Lobby hasSlot("RectangleMorph")))
writeln()

writeln("2. Attempting to load TelosMorphic.io manually...")
try(
    doFile("libs/Telos/io/TelosMorphic.io")
    writeln("✓ TelosMorphic.io loaded successfully")
) catch(Exception,
    writeln("✗ Failed to load TelosMorphic.io: " .. Exception description)
    try(
        doFile("/mnt/c/EntropicGarden/libs/Telos/io/TelosMorphic.io")
        writeln("✓ TelosMorphic.io loaded via absolute path")
    ) catch(Exception,
        writeln("✗ Failed absolute path too: " .. Exception description)
    )
)

writeln()
writeln("3. After loading attempt - checking Lobby:")
writeln("Morph available: " .. (Lobby hasSlot("Morph")))
writeln("RectangleMorph available: " .. (Lobby hasSlot("RectangleMorph")))
writeln("TelosMorphic available: " .. (Lobby hasSlot("TelosMorphic")))

if(Lobby hasSlot("TelosMorphic"),
    writeln("TelosMorphic slots: " .. TelosMorphic slotNames)
)

writeln()
writeln("=== End Test ===")