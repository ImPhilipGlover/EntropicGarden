// TelOS Morphic World Access Test
// Find the correct way to access the world and its submorphs

writeln("TelOS Morphic: Testing world access...")

// Create SDL2 window and world
Telos openWindow("World Access Test", 800, 600)
Telos createWorld

// Check what slots Telos has
writeln("Telos object slots:")
Telos slotNames foreach(slotName, 
    writeln("  " .. slotName)
)

// Try to access world 
if(Telos hasSlot("world"),
    writeln("Found 'world' slot on Telos")
    world := Telos world
    writeln("World object type: " .. world type)
    writeln("World object slots:")
    world slotNames foreach(slotName, 
        writeln("  " .. slotName)
    )
,
    writeln("No 'world' slot found on Telos")
)

// Check if there's a global world variable
if(hasSlot("globalWorld"),
    writeln("Found globalWorld variable")
    writeln("globalWorld type: " .. globalWorld type)
,
    writeln("No globalWorld variable")
)

writeln("Test complete")