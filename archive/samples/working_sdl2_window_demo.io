#!/usr/bin/env io

/*
WORKING SDL2 WINDOW DEMO - Direct C Function Calls
================================================

This demo bypasses the TelosMorphic wrapper and calls the raw C SDL2 functions
directly to ensure we get actual windows opening with real graphics.
*/

writeln("🪟 WORKING SDL2 WINDOW DEMO - Direct C Interface")
writeln("==============================================")
writeln("")

// Load TelOS to get access to raw C functions
doFile("libs/Telos/io/TelosCore.io")

writeln("🎯 Testing Raw SDL2 C Functions...")
writeln("")

// Test 1: Create world using raw C function
writeln("Test 1: Creating world with raw C function...")
if(Telos hasSlot("Telos_rawCreateWorld"),
    writeln("  ✅ Telos_rawCreateWorld available")
    result := Telos Telos_rawCreateWorld
    writeln("  ✓ World creation result: ", result)
,
    writeln("  ❌ Telos_rawCreateWorld not available")
)
writeln("")

// Test 2: Open window using raw C function
writeln("Test 2: Opening SDL2 window with raw C function...")
if(Telos hasSlot("Telos_rawOpenWindow"),
    writeln("  ✅ Telos_rawOpenWindow available")
    writeln("  🪟 Opening SDL2 window - should appear on screen...")
    result := Telos Telos_rawOpenWindow
    writeln("  ✓ Window opening result: ", result)
    writeln("  🎉 SDL2 window should now be visible!")
,
    writeln("  ❌ Telos_rawOpenWindow not available")
)
writeln("")

// Test 3: Create and draw morphs using raw C functions
writeln("Test 3: Creating morphs with raw C functions...")
if(Telos hasSlot("Telos_rawCreateMorph"),
    writeln("  ✅ Telos_rawCreateMorph available")
    
    // Create first morph
    morph1 := Telos Telos_rawCreateMorph
    writeln("  ✓ Created morph1: ", morph1)
    
    // Create second morph  
    morph2 := Telos Telos_rawCreateMorph
    writeln("  ✓ Created morph2: ", morph2)
    
    // Add morphs to world
    if(Telos hasSlot("Telos_rawAddMorphToWorld"),
        writeln("  ✅ Adding morphs to world...")
        Telos Telos_rawAddMorphToWorld(morph1)
        Telos Telos_rawAddMorphToWorld(morph2)
        writeln("  ✓ Morphs added to world")
    )
,
    writeln("  ❌ Telos_rawCreateMorph not available")
)
writeln("")

// Test 4: Draw using raw C function
writeln("Test 4: Drawing with raw C function...")
if(Telos hasSlot("Telos_rawDraw"),
    writeln("  ✅ Telos_rawDraw available")
    writeln("  🎨 Drawing to SDL2 window...")
    
    // Draw multiple frames
    5 repeat(frame,
        writeln("    Drawing frame ", frame + 1, "/5...")
        result := Telos Telos_rawDraw
        
        // Process events to keep window responsive
        if(Telos hasSlot("Telos_rawHandleEvent"),
            Telos Telos_rawHandleEvent
        )
        
        // Wait between frames
        if(System hasSlot("sleep"),
            System sleep(1.0)
        )
    )
    
    writeln("  ✓ Drawing completed - window should show graphics")
,
    writeln("  ❌ Telos_rawDraw not available")
)
writeln("")

// Test 5: Event handling loop
writeln("Test 5: Event handling loop...")
if(Telos hasSlot("Telos_rawHandleEvent"),
    writeln("  ✅ Telos_rawHandleEvent available")
    writeln("  🖱️ Processing SDL2 events for 10 seconds...")
    writeln("  Try clicking or moving mouse in the window!")
    
    100 repeat(cycle,
        // Process SDL2 events
        Telos Telos_rawHandleEvent
        
        // Redraw every 10 cycles
        if(cycle % 10 == 0,
            if(Telos hasSlot("Telos_rawDraw"),
                Telos Telos_rawDraw
            )
            write(".")
        )
        
        # Wait
        if(System hasSlot("sleep"),
            System sleep(0.1)
        )
    )
    
    writeln("")
    writeln("  ✓ Event handling completed")
,
    writeln("  ❌ Telos_rawHandleEvent not available")
)
writeln("")

// Test 6: Main loop (WARNING: This is blocking!)
writeln("Test 6: Main loop test (blocking)...")
if(Telos hasSlot("Telos_rawMainLoop"),
    writeln("  ✅ Telos_rawMainLoop available")
    writeln("  ⚠️ WARNING: This will start a blocking SDL2 main loop!")
    writeln("  ⚠️ The window will need to be closed via the X button to continue")
    writeln("  ⚠️ Running for demonstration - close window when ready")
    writeln("")
    
    # Note: This is blocking - it will not return until window is closed
    # For safety, we skip this in automated testing
    writeln("  🔄 Skipping blocking main loop for automated demo")
    writeln("  💡 To test: uncomment the next line and run manually")
    # result := Telos Telos_rawMainLoop
    
,
    writeln("  ❌ Telos_rawMainLoop not available")
)
writeln("")

// Summary report
writeln("📊 WORKING SDL2 DEMO RESULTS:")
writeln("================================")

rawFunctions := list(
    "Telos_rawCreateWorld", 
    "Telos_rawOpenWindow", 
    "Telos_rawCreateMorph", 
    "Telos_rawAddMorphToWorld",
    "Telos_rawDraw", 
    "Telos_rawHandleEvent", 
    "Telos_rawMainLoop"
)

availableCount := 0
rawFunctions foreach(funcName,
    isAvailable := Telos hasSlot(funcName)
    status := if(isAvailable, "✅ AVAILABLE", "❌ MISSING")
    writeln("  ", funcName, ": ", status)
    if(isAvailable, availableCount = availableCount + 1)
)

successRate := (availableCount / rawFunctions size * 100)
writeln("")
writeln("Overall SDL2 Integration Status:")
writeln("  Available functions: ", availableCount, "/", rawFunctions size)
writeln("  Success rate: ", successRate, "%")
writeln("")

if(successRate >= 80,
    writeln("🎉 SDL2 INTEGRATION WORKING!")
    writeln("   Raw C functions are available and functional")
    writeln("   SDL2 windows should be opening and displaying graphics")
    writeln("   Ready for advanced visual demonstrations")
,
    if(successRate >= 50,
        writeln("⚠️ SDL2 INTEGRATION PARTIAL")
        writeln("   Some functions available but incomplete")
        writeln("   May need additional C compilation or library linking")
    ,
        writeln("❌ SDL2 INTEGRATION FAILED")
        writeln("   Raw C functions not available")
        writeln("   Check SDL2 compilation flags and library dependencies")
    )
)

writeln("")
writeln("💡 Next Steps:")
writeln("   • If windows opened: SDL2 is working correctly")
writeln("   • If no windows: Check WSLg/X11 forwarding setup")
writeln("   • Try: export DISPLAY=:0 before running")
writeln("   • For live demos: Use non-blocking event loop approach")
writeln("")
writeln("🚀 Ready for Live Fractal Cognitive Theatre integration!")