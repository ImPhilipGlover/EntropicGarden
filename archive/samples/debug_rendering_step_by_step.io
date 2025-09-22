#!/usr/bin/env io

// Debug Rendering Step-by-Step - Real Verification
// Tests each rendering component individually to identify failures

writeln("🔍 TelOS Rendering Debug - Step by Step Verification")
writeln("=" repeated(50))

// Step 1: Initialize TelOS modules
writeln("\n1️⃣ Initializing TelOS...")
Telos createWorld
world := Telos world
writeln("World object: ", world)
writeln("World morphs list: ", world morphs)

// Step 2: Test SDL2 window creation
writeln("\n2️⃣ Testing SDL2 window...")
result := Telos openWindow
writeln("openWindow result: ", result)

// Step 3: Create simple morph and inspect it
writeln("\n3️⃣ Creating and inspecting morph...")
testRect := RectangleMorph clone
writeln("Created RectangleMorph: ", testRect)
writeln("RectangleMorph proto: ", testRect proto)

// Step 4: Test morph configuration
writeln("\n4️⃣ Configuring morph...")
testRect setColor(255, 0, 0) // Red
testRect setPosition(100, 100)
testRect setSize(80, 60)
writeln("Morph color: ", testRect color)
writeln("Morph position: x=", testRect x, " y=", testRect y)
writeln("Morph size: w=", testRect width, " h=", testRect height)

// Step 5: Add morph to world and verify
writeln("\n5️⃣ Adding morph to world...")
world addMorph(testRect)
writeln("World morph count after add: ", world morphs size)
writeln("First morph in world: ", world morphs at(0))

// Step 6: Test drawing explicitly
writeln("\n6️⃣ Testing explicit draw call...")
drawResult := Telos draw
writeln("Draw result: ", drawResult)

// Step 7: Test event checking
writeln("\n7️⃣ Testing event handling...")
if(Telos hasSlot("checkEvents"),
    eventResult := Telos checkEvents
    writeln("checkEvents result: ", eventResult)
,
    writeln("❌ checkEvents method not found")
)

if(Telos hasSlot("shouldExit"),
    exitStatus := Telos shouldExit
    writeln("shouldExit status: ", exitStatus)
,
    writeln("❌ shouldExit method not found")
)

// Step 8: Manual render loop with diagnostic info
writeln("\n8️⃣ Manual render loop (5 frames)...")
framesToRender := 5
framesToRender repeat(
    i := (?0 + 1)
    writeln("Frame ", i, ":")
    
    // Check events
    if(Telos hasSlot("checkEvents"), Telos checkEvents)
    
    // Draw frame
    drawResult := Telos draw
    writeln("  Draw result: ", drawResult)
    
    // Check exit condition
    if(Telos hasSlot("shouldExit") and Telos shouldExit, 
        writeln("  Exit requested by user")
        break
    )
    
    // Wait
    Telos sleep(1000) // 1 second between frames
)

writeln("\n📋 Debug Summary:")
writeln("- World created: ", world != nil)
writeln("- SDL2 window opened: ", result != nil)
writeln("- Morph created: ", testRect != nil)
writeln("- Morph in world: ", world morphs size > 0)
writeln("- Draw method exists: ", Telos hasSlot("draw"))
writeln("- Event methods exist: checkEvents=", Telos hasSlot("checkEvents"), " shouldExit=", Telos hasSlot("shouldExit"))

writeln("\n❓ Next Steps:")
writeln("- If morphs not visible: SDL2 rendering pipeline broken")
writeln("- If can't close window: Event handling not working")
writeln("- Check C-level implementations in IoTelosMorphic.c")

0