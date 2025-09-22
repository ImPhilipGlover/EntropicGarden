#!/usr/bin/env io

writeln("=== Checking Morphic Availability ===")
writeln()

writeln("1. Lobby slots:")
Lobby slotNames foreach(name, writeln("  " .. name))
writeln()

writeln("2. Checking for Morphic prototypes:")
writeln("Morph available: " .. (Lobby hasSlot("Morph")))
writeln("RectangleMorph available: " .. (Lobby hasSlot("RectangleMorph")))
writeln("TelosMorphic available: " .. (Lobby hasSlot("TelosMorphic")))
writeln()

writeln("3. Checking for Telos prototype:")
writeln("Telos available: " .. (Lobby hasSlot("Telos")))
if(Lobby hasSlot("Telos"),
    writeln("Telos slots: " .. Telos slotNames)
)

writeln()
writeln("=== End Check ===")