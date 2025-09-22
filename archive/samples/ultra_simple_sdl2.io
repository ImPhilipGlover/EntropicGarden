#!/usr/bin/env io

// Ultra-Simple SDL2 Validation - No Loops, Just Draw and Exit
writeln("🎯 Ultra-Simple SDL2 Validation")

try(
    // Basic setup
    Telos createWorld
    writeln("1. World created")
    
    Telos openWindow  
    writeln("2. Window opened")
    
    // Get world reference
    world := Telos world
    writeln("3. Got world reference")
    
    // Test: Create and add a simple rectangle
    writeln("4. Creating rectangle...")
    rect := RectangleMorph clone
    if(rect == nil, 
        writeln("ERROR: Could not create RectangleMorph")
        return 1
    )
    
    writeln("5. Setting rectangle properties...")
    rect setColor(255, 0, 0)  // Red
    rect setPosition(100, 100)
    rect setSize(200, 150)
    
    writeln("6. Adding rectangle to world...")
    world addMorph(rect)
    writeln("   Morph count: ", world morphs size)
    
    // Single draw operation
    writeln("7. Drawing...")
    world heartbeat
    Telos draw
    writeln("8. Draw complete")
    
    // Save state
    writeln("9. Saving snapshot...")
    Telos saveSnapshot
    
    writeln("✅ SUCCESS: Red rectangle should be visible in window!")
    writeln("   Window: 640x480 'The Entropic Garden'")
    writeln("   Shape: Red rectangle at (100,100) size 200x150")
) catch(Exception, e,
    writeln("❌ ERROR: ", e description)
    return 1
)

writeln("🏁 Demo complete - check the SDL2 window!")
0