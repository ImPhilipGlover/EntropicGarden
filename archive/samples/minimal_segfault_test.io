//! Minimal Segfault Test
//! Find the exact cause of segmentation fault

writeln("=== MINIMAL SEGFAULT TEST ===")

// Test 1: Basic TelOS access
writeln("Test 1: Basic TelOS access")
writeln("  → TelOS: " .. (Telos != nil))

// Test 2: Try to access Morphic
writeln("Test 2: Morphic access")
if(Lobby hasSlot("Morph"),
    writeln("  → Morph available: " .. Morph)
,
    writeln("  → Morph not in Lobby")
)

// Test 3: Try TelosMorphic
writeln("Test 3: TelosMorphic")
if(Lobby hasSlot("TelosMorphic"),
    writeln("  → TelosMorphic available: " .. TelosMorphic)
,
    writeln("  → TelosMorphic not in Lobby")
)

// Test 4: Try accessing Telos methods that might cause segfault
writeln("Test 4: Checking Telos methods")
if(Telos hasSlot("createWorld"),
    writeln("  → createWorld: available")
,
    writeln("  → createWorld: not available")
)

if(Telos hasSlot("openWindow"),
    writeln("  → openWindow: available")
,
    writeln("  → openWindow: not available")
)

// Test 5: Try to actually call createWorld (this might cause segfault)
writeln("Test 5: Calling createWorld...")
try(
    world := Telos createWorld
    writeln("  ✅ createWorld succeeded: " .. world)
) catch(Exception,
    writeln("  ❌ createWorld failed: " .. Exception description)
)

// Test 6: Try openWindow (this might cause segfault)
writeln("Test 6: Calling openWindow...")
try(
    Telos openWindow
    writeln("  ✅ openWindow succeeded")
) catch(Exception,
    writeln("  ❌ openWindow failed: " .. Exception description)
)

writeln("=== SEGFAULT TEST COMPLETE ===")
