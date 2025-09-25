#!/usr/bin/env io
/*
   Simple Diagnostic Demo - Minimal Test for SDL2 Rendering
   
   This creates just a basic window to test if the rendering pipeline works
   without complex demos that might hang.
*/

writeln("=== TelOS Morphic Diagnostic Test ===")
writeln("Testing basic SDL2 functionality...")
writeln()

// Check if Telos is available
if(Telos == nil,
    writeln("❌ Telos prototype not found!")
    exit
)

writeln("✓ Telos prototype available")

// Test basic world creation
writeln("Creating world...")
Telos createWorld
if(Telos world == nil,
    writeln("❌ World creation failed!")
    exit
)
writeln("✓ World created successfully")

// Test window opening  
writeln("Opening SDL2 window...")
Telos openWindow
writeln("✓ Window opening command completed")

// Check if we have morphs available
if(RectangleMorph == nil,
    writeln("❌ RectangleMorph not available!")
    exit  
)
writeln("✓ RectangleMorph available")

// Create ONE simple red rectangle
writeln("Creating single red rectangle...")
rect := RectangleMorph clone
rect id := "TestRect"
rect setColor(1, 0, 0, 1)    // Red
rect setPosition(200, 200)   // Center
rect setSize(100, 100)       // Square

writeln("Adding rectangle to world...")
Telos world addMorph(rect)

writeln("✅ Diagnostic test complete!")
writeln("You should see a red square in the SDL2 window.")
writeln("Total morphs in world: " .. Telos world submorphs size)

// Return test results
"Diagnostic complete"