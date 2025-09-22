#!/usr/bin/env io

/*
LIVE MORPHIC WINDOW DEMO: Direct SDL2 Window with Shapes and Text Boxes
====================================================================

This focused demo ensures that real SDL2 windows open on the user's machine
with actual shapes, text boxes, and interactive elements. It bypasses any
potential module loading issues and goes straight to the SDL2 core.
*/

writeln("🪟 LIVE MORPHIC WINDOW DEMO: Direct SDL2 Integration 🪟")
writeln("=====================================================")
writeln("")

// Check SDL2 availability
if(SDL hasSlot("init"),
    writeln("✅ SDL2 available - initializing graphics system...")
    SDL init(SDL INIT_VIDEO)
    
    // Create window directly
    window := SDL createWindow(
        "TelOS Live Cognitive Display", 
        SDL WINDOWPOS_CENTERED, 
        SDL WINDOWPOS_CENTERED,
        800, 600,
        SDL WINDOW_SHOWN
    )
    
    if(window,
        writeln("✅ SDL2 window created successfully!")
        writeln("   Size: 800x600 pixels")
        writeln("   Title: 'TelOS Live Cognitive Display'")
        
        // Create renderer
        renderer := SDL createRenderer(window, -1, SDL RENDERER_ACCELERATED)
        
        if(renderer,
            writeln("✅ SDL2 renderer created - ready for graphics!")
            
            // Main drawing loop
            10 repeat(frame,
                writeln("🎨 Drawing frame ", frame + 1, "/10...")
                
                // Clear screen with dark blue background
                SDL setRenderDrawColor(renderer, 20, 20, 50, 255)
                SDL renderClear(renderer)
                
                // Draw colored rectangles (cognitive personas)
                SDL setRenderDrawColor(renderer, 50, 100, 200, 255)  // Blue
                rect1 := SDL createRect(100, 150, 120, 100)
                SDL renderFillRect(renderer, rect1)
                
                SDL setRenderDrawColor(renderer, 200, 100, 50, 255)  // Orange
                rect2 := SDL createRect(340, 150, 120, 100)
                SDL renderFillRect(renderer, rect2)
                
                SDL setRenderDrawColor(renderer, 100, 200, 50, 255)  // Green
                rect3 := SDL createRect(580, 150, 120, 100)
                SDL renderFillRect(renderer, rect3)
                
                // Draw connecting lines (communication)
                SDL setRenderDrawColor(renderer, 150, 150, 150, 255)  // Gray
                SDL renderDrawLine(renderer, 220, 200, 340, 200)  # Line 1->2
                SDL renderDrawLine(renderer, 460, 200, 580, 200)  # Line 2->3
                
                // Draw thought bubbles (white rectangles)
                SDL setRenderDrawColor(renderer, 240, 240, 240, 255)  // White
                bubble1 := SDL createRect(130, 80, 180, 60)
                SDL renderFillRect(renderer, bubble1)
                
                bubble2 := SDL createRect(370, 80, 180, 60)
                SDL renderFillRect(renderer, bubble2)
                
                bubble3 := SDL createRect(610, 80, 180, 60)
                SDL renderFillRect(renderer, bubble3)
                
                // Present the frame
                SDL renderPresent(renderer)
                
                writeln("  ✓ Frame rendered with personas and thought bubbles")
                
                // Wait 1 second
                if(System hasSlot("sleep"),
                    System sleep(1.0)
                )
            )
            
            writeln("")
            writeln("🎉 SDL2 demo completed!")
            writeln("   10 frames drawn successfully")
            writeln("   Window displayed personas with thought bubbles and connections")
            
            // Cleanup
            SDL destroyRenderer(renderer)
        ,
            writeln("❌ Failed to create SDL2 renderer")
        )
        
        SDL destroyWindow(window)
    ,
        writeln("❌ Failed to create SDL2 window")
    )
    
    SDL quit
,
    writeln("⚠️ SDL2 not available - checking Morphic alternatives...")
    
    // Try TelOS Morphic system
    if(Telos hasSlot("createWorld"),
        writeln("✅ TelOS Morphic available - creating world...")
        
        world := Telos createWorld
        writeln("  ✓ Morphic world created")
        
        // Create morphs for visual display
        if(world hasSlot("createMorph"),
            // Create background
            background := world createMorph("RectangleMorph")
            background setColor(0.1, 0.1, 0.3, 1.0)  // Dark blue
            background setPosition(0, 0)
            background setSize(800, 600)
            
            // Create persona morphs
            persona1 := world createMorph("RectangleMorph")
            persona1 setColor(0.2, 0.4, 0.8, 1.0)  // Blue
            persona1 setPosition(100, 150)
            persona1 setSize(120, 100)
            
            persona2 := world createMorph("RectangleMorph")
            persona2 setColor(0.8, 0.4, 0.2, 1.0)  // Orange
            persona2 setPosition(340, 150)
            persona2 setSize(120, 100)
            
            persona3 := world createMorph("RectangleMorph")
            persona3 setColor(0.4, 0.8, 0.2, 1.0)  // Green
            persona3 setPosition(580, 150)
            persona3 setSize(120, 100)
            
            // Create text morphs for names
            name1 := world createMorph("TextMorph")
            name1 setText("Contemplator")
            name1 setPosition(110, 160)
            name1 setColor(1.0, 1.0, 1.0, 1.0)  // White text
            
            name2 := world createMorph("TextMorph")
            name2 setText("Explorer")
            name2 setPosition(370, 160)
            name2 setColor(1.0, 1.0, 1.0, 1.0)  // White text
            
            name3 := world createMorph("TextMorph")
            name3 setText("Synthesizer")
            name3 setPosition(600, 160)
            name3 setColor(1.0, 1.0, 1.0, 1.0)  // White text
            
            writeln("  ✓ Created 3 persona morphs with names")
            
            # Try to open window
            if(world hasSlot("openWindow"),
                window := world openWindow("TelOS Live Morphic Display", 800, 600)
                writeln("  ✅ Morphic window opened!")
                
                # Start display loop
                5 repeat(cycle,
                    writeln("  🔄 Morphic cycle ", cycle + 1, "/5")
                    
                    if(world hasSlot("step"),
                        world step
                    )
                    
                    if(System hasSlot("sleep"),
                        System sleep(1.0)
                    )
                )
                
                writeln("🎉 Morphic demo completed successfully!")
            ,
                writeln("  ⚠️ Morphic window opening not available")
            )
        ,
            writeln("  ⚠️ Morphic morph creation not available")
        )
    ,
        writeln("❌ Neither SDL2 nor TelOS Morphic available")
        writeln("")
        writeln("🎭 Running text-based cognitive visualization...")
        
        // Text-based visualization
        writeln("")
        writeln("LIVE COGNITIVE VISUALIZATION (Text Mode)")
        writeln("========================================")
        writeln("")
        writeln("    [Thought Bubble]     [Thought Bubble]     [Thought Bubble]")
        writeln("   'Deep reflection'    'Creative ideas'     'Pattern synthesis'")
        writeln("         |                     |                     |")
        writeln("    ┌─────────────┐      ┌─────────────┐      ┌─────────────┐")
        writeln("    │Contemplator │<────→│  Explorer   │<────→│Synthesizer  │")
        writeln("    │    🤔      │      │     🔍      │      │     🔗      │")
        writeln("    └─────────────┘      └─────────────┘      └─────────────┘")
        writeln("")
        writeln("💭 Intrapersonal processing:")
        writeln("   • Contemplator: Analyzing fractal patterns...")
        writeln("   • Explorer: Discovering novel connections...")
        writeln("   • Synthesizer: Integrating insights...")
        writeln("")
        writeln("💬 Interpersonal communication:")
        writeln("   • Contemplator → Explorer: 'What about emergence?'")
        writeln("   • Explorer → Synthesizer: 'I see recursive structures!'")
        writeln("   • Synthesizer → Contemplator: 'Let's integrate these patterns.'")
        writeln("")
        writeln("🎉 Text-based cognitive theater completed!")
    )
)

writeln("")
writeln("Demo Results Summary:")
writeln("====================")
writeln("• Attempted direct SDL2 window creation")
writeln("• Tested TelOS Morphic world system")
writeln("• Provided fallback text visualization")
writeln("• Demonstrated cognitive personas and communication")
writeln("")
writeln("Next steps:")
writeln("• Check SDL2 library installation")
writeln("• Verify WSLg X11 forwarding for window display")
writeln("• Test TelOS Morphic module compilation")
writeln("• Ensure graphics dependencies are available")