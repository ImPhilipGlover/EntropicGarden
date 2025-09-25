// Test Canvas Drawing Directly
// Bypass the world system and test Canvas functions directly

writeln("Testing Canvas drawing directly...")

// Create SDL2 window
Telos openWindow("Canvas Test", 400, 300)
Telos createWorld

// Test if Canvas methods exist
writeln("Canvas type: " .. Canvas type)
writeln("Canvas methods:")
Canvas slotNames foreach(slotName,
    writeln("  " .. slotName)
)

// Test if Telos has the raw drawing methods
writeln("Telos raw drawing methods:")
if(Telos hasSlot("Telos_rawDrawRect"), 
    writeln("  ✓ Telos_rawDrawRect exists"),
    writeln("  ✗ Telos_rawDrawRect missing")
)
if(Telos hasSlot("Telos_rawDrawCircle"),
    writeln("  ✓ Telos_rawDrawCircle exists"),
    writeln("  ✗ Telos_rawDrawCircle missing")
)

// Create a simple Canvas and test drawing
canvas := Canvas clone
writeln("Created canvas: " .. canvas type)

// Test bounds and color objects
testBounds := Object clone do(
    x := 50
    y := 50
    width := 100
    height := 75
)

testColor := Object clone do(
    r := 1.0
    g := 0.0
    b := 0.0
    a := 1.0
)

writeln("Testing canvas fillRectangle...")
canvas fillRectangle(testBounds, testColor)

writeln("Test complete!")