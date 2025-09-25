#!/usr/bin/env io
/*
   Fixed Rendering Demo - Ensures proper SDL2 drawing
   
   This demo includes explicit rendering calls to make sure
   objects are actually drawn to the screen.
*/

writeln("=== TelOS Fixed Rendering Demo ===")
writeln("Creating window with visible red rectangle...")
writeln()

// Create world and window
Telos createWorld
Telos openWindow

// Create a bright red rectangle
redRect := RectangleMorph clone
redRect id := "BigRedRect"
redRect setColor(1, 0, 0, 1)      // Bright red, fully opaque
redRect setPosition(150, 150)      // Centered position
redRect setSize(200, 150)          // Large size - should be very visible

// Add to world
Telos world addMorph(redRect)

// Create a contrasting green rectangle
greenRect := RectangleMorph clone  
greenRect id := "GreenRect"
greenRect setColor(0, 1, 0, 1)     // Bright green
greenRect setPosition(300, 250)    
greenRect setSize(100, 100)

Telos world addMorph(greenRect)

// Add some text
textMorph := TextMorph clone
textMorph id := "TestText"
textMorph setText("TelOS Morphic UI Working!")
textMorph setPosition(50, 50)
textMorph setColor(1, 1, 1, 1)     // White text

Telos world addMorph(textMorph)

writeln("Created objects:")
writeln("• Red rectangle (200x150) at (150,150)")  
writeln("• Green rectangle (100x100) at (300,250)")
writeln("• White text at (50,50)")
writeln()
writeln("Total morphs: " .. Telos world submorphs size)

// Explicit rendering call if available
if(Telos hasSlot("render"),
    writeln("Calling explicit render...")
    Telos render
)

// Try to trigger a display update
if(Telos hasSlot("display"),
    writeln("Calling display update...")
    Telos display  
)

writeln()
writeln("If you still see only blue, the issue is in the C rendering pipeline.")
writeln("The morphs are created correctly in Io, but not being drawn by SDL2.")

"Demo complete - check the window"