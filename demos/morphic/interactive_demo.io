#!/usr/bin/env io
/*
   Interactive Morphic Demo - Live Object Manipulation
   
   This demo showcases advanced interaction capabilities:
   - Real-time property modification
   - Object introspection and debugging
   - Dynamic morph creation and destruction
   - Event handling demonstration
   
   Usage: First run basic_window_demo.io, then run this for interactions
*/

writeln("=== TelOS Interactive Morphic Demo ===")
writeln("This demo requires the basic window to be running first.")
writeln("If you haven't run basic_window_demo.io yet, please do that first.")
writeln()

// Check if we have a world
if(Telos world == nil,
    writeln("❌ No Morphic world found! Please run basic_window_demo.io first.")
    return("Demo requires basic window")
)

writeln("✓ Found existing Morphic world with " .. Telos world submorphs size .. " morphs")
writeln()

// Interactive demonstration functions
InteractiveMorphicDemo := Object clone do(
    
    // Animate a morph's color over time
    animateColorCycle := method(morph, duration,
        writeln("🎨 Animating color cycle for " .. morph id)
        
        // Color animation loop
        steps := 60
        for(i, 0, steps,
            hue := (i / steps) * 360
            // Convert HSV to RGB (simplified)
            r := (((hue % 120) / 120)) max(0.2)
            g := (((hue + 120) % 360) / 120) max(0.2)  
            b := (((hue + 240) % 360) / 120) max(0.2)
            
            morph setColor(r, g, b, 1)
            yield  // Let other processes run
        )
        writeln("✓ Color animation complete")
    )
    
    // Demonstrate live property inspection
    inspectMorph := method(morph,
        writeln("🔍 Inspecting morph: " .. morph id)
        writeln("   Type: " .. morph type)
        writeln("   Position: (" .. morph position x .. ", " .. morph position y .. ")")
        writeln("   Color: rgba(" .. morph color r .. ", " .. morph color g .. ", " .. morph color b .. ", " .. morph color a .. ")")
        
        if(morph hasSlot("bounds"),
            writeln("   Bounds: " .. morph bounds asString)
        )
        
        if(morph hasSlot("radius"),
            writeln("   Radius: " .. morph radius)
        )
        
        if(morph hasSlot("text"),
            writeln("   Text: \"" .. morph text .. "\"")
        )
        writeln()
    )
    
    // Create dynamic morph at runtime
    createDynamicMorph := method(x, y,
        writeln("✨ Creating dynamic morph at (" .. x .. ", " .. y .. ")")
        
        dynamicMorph := RectangleMorph clone
        dynamicMorph setColor(
            Random value,  // Random red
            Random value,  // Random green  
            Random value,  // Random blue
            0.8            // Semi-transparent
        )
        dynamicMorph setPosition(x, y)
        dynamicMorph setSize(40 + (Random value * 60), 40 + (Random value * 60))
        dynamicMorph id := "Dynamic_" .. Date now asNumber asString
        
        Telos world addMorph(dynamicMorph)
        writeln("✓ Created: " .. dynamicMorph id)
        
        dynamicMorph
    )
    
    // Demonstrate Living Image evolution
    evolveMorph := method(morph,
        writeln("🧬 Evolving morph: " .. morph id)
        
        // Add new capabilities to the morph at runtime
        morph do(
            // Add a pulse behavior
            pulse := method(
                originalSize := self bounds size clone
                
                // Pulse animation
                for(i, 0, 20,
                    scale := 1 + (0.3 * (i / 20) sin)
                    newWidth := originalSize width * scale
                    newHeight := originalSize height * scale
                    self setSize(newWidth, newHeight)
                    yield
                )
                
                // Return to original size
                self setSize(originalSize width, originalSize height)
                writeln("💗 " .. self id .. " finished pulsing")
            )
            
            // Add rotation capability  
            rotate := method(angle,
                self rotation := angle
                writeln("🌀 " .. self id .. " rotated to " .. angle .. " degrees")
            )
            
            // Add glow effect
            glow := method(intensity,
                originalAlpha := self color a
                self color a = originalAlpha + (intensity * 0.5)
                writeln("✨ " .. self id .. " glowing at intensity " .. intensity)
            )
        )
        
        writeln("✓ Morph evolved with new capabilities: pulse, rotate, glow")
        morph
    )
    
    // Run full interactive demonstration
    runDemo := method(
        writeln("🚀 Starting interactive demonstration...")
        writeln()
        
        // Get existing morphs from the world
        morphs := Telos world submorphs
        
        if(morphs size > 0,
            writeln("1. Inspecting all existing morphs...")
            morphs foreach(morph,
                if(morph hasSlot("id"),
                    self inspectMorph(morph)
                )
            )
            
            writeln("2. Creating some dynamic morphs...")
            newMorph1 := self createDynamicMorph(300, 300)
            newMorph2 := self createDynamicMorph(200, 250)
            newMorph3 := self createDynamicMorph(450, 180)
            
            writeln("3. Evolving a morph with new capabilities...")
            evolvedMorph := self evolveMorph(newMorph1)
            
            writeln("4. Demonstrating evolved capabilities...")
            evolvedMorph pulse
            evolvedMorph rotate(45)
            evolvedMorph glow(0.8)
            
            writeln("5. Color animation demonstration...")
            if(morphs size >= 2,
                self animateColorCycle(morphs at(1), 3)
            )
            
            writeln("✅ Interactive demonstration complete!")
            writeln("   Total morphs now in world: " .. Telos world submorphs size)
        ,
            writeln("❌ No morphs found in world to interact with.")
        )
    )
)

writeln("=== Available Interactive Commands ===")
writeln("InteractiveMorphicDemo runDemo           - Run full demonstration")
writeln("InteractiveMorphicDemo inspectMorph(obj) - Inspect any morph")
writeln("InteractiveMorphicDemo createDynamicMorph(x,y) - Create morph at position")
writeln("InteractiveMorphicDemo evolveMorph(obj)  - Add new capabilities to morph")
writeln("InteractiveMorphicDemo animateColorCycle(obj, duration) - Animate colors")
writeln()

writeln("Try: InteractiveMorphicDemo runDemo")
writeln()

// Return the demo object for interactive use
InteractiveMorphicDemo