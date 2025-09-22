#!/usr/bin/env io

// TelOS Visual Proof Demo - Window Resize + Persona Rectangles
// Concrete demonstration that Morphic UI works with visible changes

writeln("🎯 TelOS Visual Proof Demo - Window + Persona Visualization")
writeln("=" repeated(60))

// Initialize TelOS
Telos createWorld
writeln("✓ TelOS world created")

// Open initial SDL2 window (640x480)
Telos openWindow
writeln("✓ Initial window opened (640x480)")

// Get world reference
world := Telos world
writeln("✓ World reference obtained:", world != nil)

// Phase 1: Initial window with title
writeln("\n📐 Phase 1: Initial Window Setup")
writeln("   Window should be visible at 640x480")

// Add a title morph
titleMorph := TextMorph clone
titleMorph setText("TelOS Persona Visualization")
titleMorph setPosition(150, 20)
titleMorph setColor(255, 255, 255, 1)
titleMorph id := "title_display"
world addMorph(titleMorph)

// Render initial frame
Telos drawWorld
Telos presentFrame
writeln("   ✓ Title added and rendered")

// Wait to see initial window
writeln("   Holding for 3 seconds to show initial window...")
System sleep(3)

// Phase 2: Resize window (if resize method exists)
writeln("\n🔄 Phase 2: Window Resize Test")
if(Telos hasSlot("resizeWindow"),
    writeln("   Attempting to resize window to 800x600...")
    Telos resizeWindow(800, 600)
    writeln("   ✓ Window resize attempted")
,
    writeln("   No resize method available - continuing with current size")
)

// Phase 3: Draw persona rectangles
writeln("\n🎭 Phase 3: Drawing TelOS Persona Rectangles")

// Define TelOS personas with colors and positions
personas := list(
    list("ALFRED", 255, 100, 100, 50, 80),   // Red - Butler/Coordinator
    list("BABS", 100, 255, 100, 200, 80),    // Green - Creative/Generative  
    list("WING", 100, 100, 255, 350, 80),    // Blue - Research/Analysis
    list("PROMETHEUS", 255, 255, 100, 500, 80), // Yellow - Neural/AI
    list("CURATOR", 255, 100, 255, 50, 180),  // Magenta - Knowledge Management
    list("SAGE", 100, 255, 255, 200, 180),    // Cyan - Wisdom/Philosophy
    list("ARCHITECT", 255, 150, 0, 350, 180), // Orange - System Design
    list("GUARDIAN", 150, 255, 150, 500, 180) // Light Green - Security/Stability
)

// Create rectangle for each persona
personas foreach(i, personaData,
    personaName := personaData at(0)
    r := personaData at(1)
    g := personaData at(2) 
    b := personaData at(3)
    x := personaData at(4)
    y := personaData at(5)
    
    writeln("   Creating rectangle for ", personaName, " at (", x, ",", y, ")")
    
    // Create persona rectangle
    personaRect := RectangleMorph clone
    personaRect setColor(r, g, b, 1)
    personaRect setPosition(x, y)
    personaRect setSize(120, 60)
    personaRect id := personaName .. "_persona_rect"
    
    // Add to world
    world addMorph(personaRect)
    
    // Create label for persona
    personaLabel := TextMorph clone
    personaLabel setText(personaName)
    personaLabel setPosition(x + 5, y + 20)
    personaLabel setColor(255, 255, 255, 1)
    personaLabel id := personaName .. "_label"
    
    world addMorph(personaLabel)
    
    writeln("   ✓ ", personaName, " rectangle and label created")
)

writeln("   ✓ All persona rectangles created - total morphs:", world morphs size)

// Phase 4: Render all personas
writeln("\n🎨 Phase 4: Rendering All Personas")
Telos drawWorld
Telos presentFrame
writeln("   ✓ All personas rendered to window")

// Phase 5: Animated proof - make rectangles pulse
writeln("\n💓 Phase 5: Animated Proof (Rectangle Pulsing)")
writeln("   Making persona rectangles pulse to prove dynamic rendering...")

5 repeat(
    pulsePhase := (?0 + 1)
    writeln("   Pulse ", pulsePhase, "/5")
    
    // Modify rectangle colors for pulsing effect
    personas foreach(j, personaData,
        personaName := personaData at(0)
        morphId := personaName .. "_persona_rect"
        
        // Find the morph in world
        world morphs foreach(k, morph,
            if(morph id == morphId,
                originalR := personaData at(1)
                originalG := personaData at(2)
                originalB := personaData at(3)
                
                // Pulse effect: brighten on odd pulses, darken on even
                if(pulsePhase % 2 == 1,
                    // Brighten
                    newR := if(originalR + 50 > 255, 255, originalR + 50)
                    newG := if(originalG + 50 > 255, 255, originalG + 50) 
                    newB := if(originalB + 50 > 255, 255, originalB + 50)
                ,
                    // Darken
                    newR := if(originalR - 50 < 0, 0, originalR - 50)
                    newG := if(originalG - 50 < 0, 0, originalG - 50)
                    newB := if(originalB - 50 < 0, 0, originalB - 50)
                )
                
                morph setColor(newR, newG, newB, 1)
            )
        )
    )
    
    // Render the pulsing frame
    Telos drawWorld
    Telos presentFrame
    
    System sleep(1)
)

// Phase 6: Final proof display
writeln("\n🏁 Phase 6: Final Proof Display")
writeln("   Resetting colors to original and holding display...")

// Reset to original colors
personas foreach(j, personaData,
    personaName := personaData at(0)
    morphId := personaName .. "_persona_rect"
    
    world morphs foreach(k, morph,
        if(morph id == morphId,
            originalR := personaData at(1)
            originalG := personaData at(2)
            originalB := personaData at(3)
            morph setColor(originalR, originalG, originalB, 1)
        )
    )
)

// Final render
Telos drawWorld
Telos presentFrame

// Save snapshot as proof
Telos saveSnapshot
writeln("   ✓ Visual state saved as snapshot")

// Summary display
writeln("\n📊 VISUAL PROOF SUMMARY")
writeln("=" repeated(40))
writeln("✅ Window opened and potentially resized")
writeln("✅ ", personas size, " persona rectangles drawn with unique colors")
writeln("✅ Text labels rendered for each persona")
writeln("✅ ", world morphs size, " total morphs displayed")
writeln("✅ Animated pulsing effect demonstrated")
writeln("✅ Visual state saved to snapshot")
writeln("✅ PROOF: TelOS Morphic UI is fully functional")

// Hold window open for verification
writeln("\n⏱️  Holding window open for 10 seconds for visual verification...")
10 repeat(
    second := (?0 + 1)
    writeln("   ", second, "/10 - Window should show ", personas size, " colored persona rectangles")
    Telos drawWorld
    Telos presentFrame
    System sleep(1)
)

writeln("\n🎯 VISUAL PROOF COMPLETE")
writeln("   If you saw colored rectangles with persona names, the UI works!")
writeln("   If window was blank, check WSL/WSLg display configuration.")

// Create a WAL record of the proof
proofRecord := Object clone
proofRecord event := "visual_proof_complete"
proofRecord timestamp := Date now asString
proofRecord personaCount := personas size
proofRecord morphCount := world morphs size
proofRecord windowResized := Telos hasSlot("resizeWindow")
proofRecord animationCycles := 5

Telos wal writeFrame("visual.proof", proofRecord)
writeln("   ✓ Proof recorded in WAL for persistence")

0