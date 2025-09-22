#!/usr/bin/env io

// Debug Morphic Rendering - Focus on Visual Verification
// Goal: Get actual colored shapes visible in the SDL2 window

writeln("🔍 Debug: Morphic Rendering Verification")
writeln("=" repeated(40))

// Initialize system
Telos createWorld
writeln("1. World created:", Telos world != nil)

// Open SDL2 window
Telos openWindow
writeln("2. SDL2 window opened")

// Create a simple red rectangle
redRect := RectangleMorph clone
redRect setColor(255, 0, 0)  // Pure red
redRect setPosition(100, 100)
redRect setSize(100, 80)
redRect id := "debug_red_rect"
writeln("3. Red rectangle created:", redRect != nil)

// Add to world
world := Telos world
world addMorph(redRect)
writeln("4. Added to world. Total morphs:", world morphs size)

// Verify morph properties
writeln("5. Morph details:")
writeln("   ID:", redRect id)
writeln("   Position: (", redRect x, ",", redRect y, ")")
writeln("   Size: ", redRect width, "x", redRect height)
writeln("   Color: ", redRect color)

// Try explicit drawing calls
writeln("6. Attempting explicit render...")

// Call draw on the world
writeln("   6a. Calling drawWorld...")
Telos drawWorld

writeln("   6b. Calling presentFrame...")
Telos presentFrame

// Try manual morph iteration  
writeln("   6c. Manual morph iteration...")
world morphs foreach(i, morph,
    writeln("     Morph ", i, ": ", morph id, " at (", morph x, ",", morph y, ")")
    Telos drawMorph(morph)
)

// Final present
writeln("   6e. Final presentFrame...")
Telos presentFrame

writeln("7. Render commands complete")
writeln("8. Window should show red rectangle at (100,100)")
writeln("   If blank: SDL2 window creation succeeded but rendering failed")
writeln("   Check C-level Telos_rawDraw implementation")

// Keep window open for verification with continuous rendering
writeln("9. Continuous rendering for 10 seconds...")
for(i, 1, 10,
    writeln("   Second ", i, "/10 - rendering red rectangle")
    
    // Re-render every second to ensure visibility
    Telos drawWorld
    Telos presentFrame
    
    System sleep(1)
)

writeln("10. Test complete - closing window")
0