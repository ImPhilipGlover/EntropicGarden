#!/usr/bin/env io

//metadoc TelosRenderingProof category TelOS
//metadoc TelosRenderingProof description Proof that morph rendering bridge works - creates visible colored rectangles

// Initialize TelOS system
Telos

// ========== VISUAL PROOF DEMO ==========
// This demo proves that the C-level morph rendering bridge works
// by creating colored rectangles for each persona and displaying them

TelosRenderingProof := Object clone do(
    name := "TelOS Rendering Bridge Proof"
    
    // Create and configure the world
    setupWorld := method(
        writeln("=== Setting up Morphic World ===")
        
        // Create world and open window
        Telos createWorld
        Telos openWindow
        
        // Create personas with distinct colors and positions
        personas := List clone
        
        // ALFRED - Red rectangle (top-left)
        alfred := RectangleMorph clone
        alfred x := 50
        alfred y := 50
        alfred width := 100
        alfred height := 60
        alfred color := "red"
        personas append(alfred)
        writeln("Created ALFRED morph: red rectangle at (50,50) size 100x60")
        
        // BABS - Green rectangle (top-center)
        babs := RectangleMorph clone
        babs x := 200
        babs y := 50
        babs width := 100
        babs height := 60
        babs color := "green"
        personas append(babs)
        writeln("Created BABS morph: green rectangle at (200,50) size 100x60")
        
        // WING - Blue rectangle (top-right)
        wing := RectangleMorph clone
        wing x := 350
        wing y := 50
        wing width := 100
        wing height := 60
        wing color := "blue"
        personas append(wing)
        writeln("Created WING morph: blue rectangle at (350,50) size 100x60")
        
        // PROMETHEUS - Yellow rectangle (bottom-left)
        prometheus := RectangleMorph clone
        prometheus x := 50
        prometheus y := 200
        prometheus width := 100
        prometheus height := 60
        prometheus color := "yellow"
        personas append(prometheus)
        writeln("Created PROMETHEUS morph: yellow rectangle at (50,200) size 100x60")
        
        // CURATOR - Magenta rectangle (bottom-center)
        curator := RectangleMorph clone
        curator x := 200
        curator y := 200
        curator width := 100
        curator height := 60
        curator color := "magenta"
        personas append(curator)
        writeln("Created CURATOR morph: magenta rectangle at (200,200) size 100x60")
        
        // SAGE - Cyan rectangle (bottom-right)
        sage := RectangleMorph clone
        sage x := 350
        sage y := 200
        sage width := 100
        sage height := 60
        sage color := "cyan"
        personas append(sage)
        writeln("Created SAGE morph: cyan rectangle at (350,200) size 100x60")
        
        // Add all personas to world - ensure world exists first
        if(Telos world == nil,
            writeln("ERROR: Telos world is nil - creating world failed")
            return nil
        )
        
        // Initialize submorphs list if not present
        if(Telos world hasSlot("submorphs") not,
            Telos world submorphs := List clone
            writeln("Created submorphs list on world")
        )
        
        // Add all personas to world
        Telos world submorphs = personas
        writeln("Added " .. personas size .. " persona morphs to world submorphs")
        writeln("World now has " .. Telos world submorphs size .. " submorphs")
        
        // Return the personas for animation
        return personas
    )
    
    // Render test frames
    renderTest := method(personas,
        writeln("\n=== Testing Morph Rendering Bridge ===")
        
        // Render 10 frames to test the bridge
        for(frame, 1, 10,
            writeln("Rendering frame " .. frame .. "/10...")
            
            // Call the C-level draw function that should now render our morphs
            Telos drawWorld
            
            // Small delay between frames
            System sleep(0.1)
        )
        
        writeln("✓ Completed 10 test frames")
        writeln("\nIf the morph bridge works correctly, you should see:")
        writeln("- 6 colored rectangles arranged in a 3x2 grid")
        writeln("- Red (ALFRED), Green (BABS), Blue (WING) on top row")
        writeln("- Yellow (PROMETHEUS), Magenta (CURATOR), Cyan (SAGE) on bottom row")
        writeln("- Window should remain open showing the rendered morphs")
    )
    
    // Run the complete test
    run := method(
        writeln("Starting TelOS Rendering Bridge Proof...")
        writeln("This test verifies that Io morphs are rendered by C SDL2 code")
        
        // Setup world and create morphs
        personas := setupWorld
        
        // Test the rendering bridge
        renderTest(personas)
        
        writeln("\n=== RENDERING BRIDGE TEST COMPLETE ===")
        writeln("Check the SDL2 window to see if colored rectangles are visible")
        writeln("Press Ctrl+C to close the window when done")
        writeln("")
        
        // Keep window open for manual inspection
        writeln("Window will stay open for visual inspection...")
        writeln("Press ESC key or close window to exit gracefully")
        
        // Interactive loop with exit detection
        exitLoop := false
        frameCount := 0
        
        while(exitLoop not,
            // Check for events (ESC key or window close)
            Telos checkEvents
            
            // Render frame
            Telos drawWorld
            frameCount = frameCount + 1
            
            // Check exit status
            if(Telos shouldExit,
                exitLoop = true
                writeln("Exit requested - closing gracefully...")
            )
                
            // Safety timeout after 1000 frames (500 seconds)
            if(frameCount > 1000,
                exitLoop = true
                writeln("Safety timeout reached - closing demo...")
            )
            
            System sleep(0.5)
        )
        
        // Clean shutdown
        Telos closeWindow
        writeln("Demo complete - window closed after " .. frameCount .. " frames")
    )
)

// Execute the rendering proof
TelosRenderingProof run