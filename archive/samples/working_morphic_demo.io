#!/usr/bin/env io

// Working Morphic Demo - Using Correct Method Names
// Addresses both rendering and event handling issues

writeln("🎯 TelOS Working Morphic Demo - Corrected Methods")
writeln("=" repeated(50))

// Initialize TelOS
Telos createWorld
world := Telos world

// Open SDL2 window
Telos openWindow
writeln("✅ SDL2 window opened")

// Create test morphs
writeln("\n🎨 Creating test morphs...")
redRect := RectangleMorph clone
redRect setColor(255, 0, 0) setPosition(50, 50) setSize(100, 80)

blueRect := RectangleMorph clone  
blueRect setColor(0, 100, 255) setPosition(200, 100) setSize(80, 60)

greenRect := RectangleMorph clone
greenRect setColor(0, 255, 100) setPosition(350, 150) setSize(120, 40)

// Add morphs to world
world addMorph(redRect)
world addMorph(blueRect) 
world addMorph(greenRect)

writeln("✅ Created and added ", world morphs size, " morphs")

// Test the actual drawing method (drawWorld, not draw)
writeln("\n🖼️ Testing drawWorld method...")
if(Telos hasSlot("drawWorld"),
    Telos drawWorld
    writeln("✅ drawWorld method called successfully")
,
    writeln("❌ drawWorld method not found")
)

// Test manual render loop with proper event checking  
writeln("\n🔄 Interactive render loop...")
writeln("👆 Close the window or press ESC to exit")

frameCount := 0
shouldContinue := true

while(shouldContinue,
    frameCount = frameCount + 1
    writeln("Frame ", frameCount, " - Press ESC or close window to exit")
    
    // Check for events first
    if(Telos hasSlot("checkEvents"),
        Telos checkEvents
    ,
        writeln("  ⚠️ No checkEvents method")
        shouldContinue = false
        break
    )
    
    // Check exit condition
    if(Telos hasSlot("shouldExit"),
        exitRequested := Telos shouldExit
        if(exitRequested,
            writeln("  🚪 Exit requested - exiting loop")
            shouldContinue = false
        )
    ,
        writeln("  ⚠️ No shouldExit method - using timeout")
        if(frameCount > 20,
            shouldContinue = false
        )
    )
    
    // Draw the world
    if(Telos hasSlot("drawWorld"),
        Telos drawWorld
    )
    
    // Wait between frames
    System sleep(0.5) // 0.5 second for more responsive exit
)

writeln("\n📊 Final Status:")
writeln("- Frames rendered: ", frameCount)
writeln("- Exit reason: ", if(Telos hasSlot("shouldExit"), if(Telos shouldExit, "User requested", "Loop ended"), "Method missing"))
writeln("- Morphs in world: ", world morphs size)
writeln("- Window methods: openWindow=", Telos hasSlot("openWindow"), " drawWorld=", Telos hasSlot("drawWorld"))
writeln("- Event methods: checkEvents=", Telos hasSlot("checkEvents"), " shouldExit=", Telos hasSlot("shouldExit"))

writeln("\n❓ Expected Results:")
writeln("- If you see 3 colored rectangles: Rendering works! ✅")
writeln("- If window stays empty: C-level SDL2 rendering broken ❌")
writeln("- If can't close window: Event handling broken ❌")

// Final cleanup attempt
writeln("\n🧹 Cleanup...")
if(Telos hasSlot("closeWindow"),
    Telos closeWindow
    writeln("✅ Window closed via closeWindow method")
,
    writeln("⚠️ No closeWindow method - window may stay open")
)

0