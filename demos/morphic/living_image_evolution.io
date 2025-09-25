#!/usr/bin/env io
/*
   Living Image Evolution Demo - Runtime System Modification
   
   This demo showcases the ultimate "Living Image" capabilities:
   - Runtime prototype modification
   - System introspection and self-modification
   - Autopoietic evolution of the Morphic system itself
   - Meta-programming with live objects
   
   Usage: Run after basic_window_demo.io for maximum effect
*/

writeln("=== TelOS Living Image Evolution Demo ===")
writeln("Demonstrating runtime system evolution and self-modification")
writeln("⚠️  Warning: This demo modifies system prototypes at runtime!")
writeln()

LivingImageEvolution := Object clone do(
    
    // Enhance the Morph prototype with new capabilities at runtime
    enhanceMorphPrototype := method(
        writeln("🧬 Evolving the Morph prototype with new capabilities...")
        
        // Add a magnetism behavior to all morphs
        Morph do(
            magnetism := 0.1
            
            attractTo := method(otherMorph, strength,
                if(otherMorph == nil, return)
                
                myPos := self position
                otherPos := otherMorph position
                
                dx := otherPos x - myPos x  
                dy := otherPos y - myPos y
                distance := (dx * dx + dy * dy) sqrt
                
                if(distance > 5,
                    force := strength / distance
                    newX := myPos x + (dx * force)
                    newY := myPos y + (dy * force)
                    
                    self setPosition(newX, newY)
                    writeln("🧲 " .. self id .. " attracted to " .. otherMorph id)
                )
            )
            
            repelFrom := method(otherMorph, strength,
                if(otherMorph == nil, return)
                
                myPos := self position
                otherPos := otherMorph position
                
                dx := myPos x - otherPos x  
                dy := myPos y - otherPos y
                distance := (dx * dx + dy * dy) sqrt
                
                if(distance > 0 and distance < 100,
                    force := strength / distance
                    newX := myPos x + (dx * force)
                    newY := myPos y + (dy * force)
                    
                    self setPosition(newX, newY)
                    writeln("⚡ " .. self id .. " repelled from " .. otherMorph id)
                )
            )
            
            // Add memory capabilities
            memory := Map clone
            
            remember := method(key, value,
                self memory atPut(key, value)
                writeln("🧠 " .. self id .. " remembered: " .. key .. " = " .. value)
            )
            
            recall := method(key,
                value := self memory at(key)
                writeln("💭 " .. self id .. " recalls: " .. key .. " = " .. value)
                value
            )
            
            // Add communication capabilities
            broadcast := method(message,
                if(Telos world == nil, return)
                
                writeln("📡 " .. self id .. " broadcasting: " .. message)
                
                Telos world submorphs foreach(otherMorph,
                    if(otherMorph != self and otherMorph hasSlot("receive"),
                        otherMorph receive(message, self)
                    )
                )
            )
            
            receive := method(message, sender,
                writeln("📨 " .. self id .. " received from " .. sender id .. ": " .. message)
                
                // Simple response behavior
                if(message beginsWithSeq("hello"),
                    sender receive("hello back!", self)
                )
            )
        )
        
        writeln("✓ Morph prototype enhanced with: magnetism, memory, communication")
    )
    
    // Create a self-evolving ecosystem of morphs
    createEcosystem := method(
        writeln("🌱 Creating self-evolving morph ecosystem...")
        
        if(Telos world == nil,
            writeln("❌ No world found! Run basic_window_demo.io first.")
            return
        )
        
        // Create different types of evolved morphs
        predator := RectangleMorph clone do(
            id := "Predator"
            setColor(0.8, 0.2, 0.2, 1)  // Red predator
            setPosition(500, 100)
            setSize(60, 40)
            
            hunt := method(
                prey := Telos world submorphs detect(morph,
                    morph id beginsWithSeq("Prey")
                )
                if(prey,
                    self attractTo(prey, 2.0)
                    self broadcast("hunting " .. prey id)
                )
            )
            
            remember("type", "predator")
            remember("energy", 100)
        )
        
        prey := CircleMorph clone do(
            id := "Prey1"
            setColor(0.2, 0.8, 0.2, 1)  // Green prey
            setPosition(200, 200)
            setRadius(25)
            
            flee := method(
                predators := Telos world submorphs select(morph,
                    morph recall("type") == "predator"
                )
                predators foreach(predator,
                    self repelFrom(predator, 3.0)
                )
                if(predators size > 0,
                    self broadcast("fleeing!")
                )
            )
            
            remember("type", "prey")
            remember("fear", 50)
        )
        
        neutral := TextMorph clone do(
            id := "Observer" 
            setText("🔬 Observing")
            setPosition(320, 240)
            setColor(1, 1, 1, 1)
            
            observe := method(
                morphCount := Telos world submorphs size
                self setText("🔬 Observing " .. morphCount .. " morphs")
                
                // Count different types
                predators := Telos world submorphs select(m, m recall("type") == "predator") size
                prey := Telos world submorphs select(m, m recall("type") == "prey") size
                
                if(predators > 0 or prey > 0,
                    self broadcast("Population: " .. predators .. " predators, " .. prey .. " prey")
                )
            )
            
            remember("type", "observer")
        )
        
        // Add them to the world
        Telos world addMorph(predator)
        Telos world addMorph(prey)
        Telos world addMorph(neutral)
        
        writeln("✓ Ecosystem created with predator, prey, and observer morphs")
        
        // Return the ecosystem for further interaction
        list(predator, prey, neutral)
    )
    
    // Demonstrate autopoietic evolution - system modifies itself
    demonstrateAutopoiesis := method(
        writeln("🌀 Demonstrating autopoietic self-modification...")
        
        // The system evolves its own evaluation capabilities
        originalEval := Lobby getSlot("doString")
        
        Lobby doString := method(code,
            writeln("🔄 Living Image evaluating: " .. code)
            result := self getSlot("originalEval") call(code)
            writeln("✅ Evaluation complete, result type: " .. result type)
            result
        )
        
        writeln("✓ System evaluation enhanced with logging")
        
        # Test the enhancement
        writeln("Testing enhanced evaluation:")
        doString("2 + 2")
        doString("Date now")
        
        # Restore original (optional)
        # Lobby doString := originalEval
    )
    
    // Meta-programming: Create new morph types at runtime
    createNewMorphType := method(typeName, behavior,
        writeln("🔨 Creating new morph type: " .. typeName)
        
        # Create a new prototype dynamically
        newType := RectangleMorph clone
        newType type := typeName
        
        # Add custom behavior
        newType do(behavior)
        
        # Register it globally
        Lobby setSlot(typeName, newType)
        
        writeln("✓ New morph type '" .. typeName .. "' created and registered globally")
        newType
    )
    
    // Run the complete living image demonstration
    runEvolutionDemo := method(
        writeln("🚀 Starting Living Image Evolution Demo...")
        writeln()
        
        writeln("Phase 1: Prototype Enhancement")
        self enhanceMorphPrototype
        writeln()
        
        writeln("Phase 2: Ecosystem Creation") 
        ecosystem := self createEcosystem
        writeln()
        
        writeln("Phase 3: Autopoietic Demonstration")
        self demonstrateAutopoiesis
        writeln()
        
        writeln("Phase 4: Meta-Programming")
        # Create a new "QuantumMorph" type
        QuantumMorph := self createNewMorphType("QuantumMorph", 
            # Define quantum behavior
            block(
                quantumState := "superposition"
                
                collapse := method(
                    self quantumState = "collapsed"
                    self setColor(Random value, Random value, Random value, 1)
                    writeln("⚛️  Quantum morph collapsed to new state")
                )
                
                tunnel := method(newX, newY,
                    writeln("🌀 Quantum tunneling to (" .. newX .. ", " .. newY .. ")")
                    self setPosition(newX, newY)
                )
            )
        )
        
        # Create an instance
        quantumMorph := QuantumMorph clone
        quantumMorph id := "QuantumMorph1"
        quantumMorph setPosition(350, 300)
        quantumMorph setSize(50, 50)
        quantumMorph setColor(1, 0, 1, 0.5)  # Purple, semi-transparent
        
        if(Telos world,
            Telos world addMorph(quantumMorph)
            writeln("✓ Quantum morph added to world")
        )
        
        writeln()
        writeln("Phase 5: Ecosystem Simulation")
        if(ecosystem,
            writeln("Running ecosystem behaviors...")
            predator := ecosystem at(0)
            prey := ecosystem at(1) 
            observer := ecosystem at(2)
            
            # Run some behaviors
            observer observe
            predator hunt
            prey flee
            quantumMorph collapse
            quantumMorph tunnel(400, 150)
        )
        
        writeln()
        writeln("🎉 Living Image Evolution Demo Complete!")
        writeln("The system has evolved itself at runtime with:")
        writeln("• Enhanced Morph prototypes with new behaviors")
        writeln("• Self-modifying ecosystem of interacting objects")
        writeln("• Autopoietic evaluation enhancement")
        writeln("• Dynamically created new morph types")
        writeln("• Live behavioral simulation")
        writeln()
        writeln("Total morphs in world: " .. Telos world submorphs size)
        writeln("All changes happened while the system was running!")
    )
)

writeln("=== Living Image Evolution Commands ===")
writeln("LivingImageEvolution runEvolutionDemo      - Run complete demonstration")
writeln("LivingImageEvolution enhanceMorphPrototype - Add new capabilities to all morphs")
writeln("LivingImageEvolution createEcosystem       - Create interacting morph ecosystem")
writeln("LivingImageEvolution demonstrateAutopoiesis - Show system self-modification")
writeln("LivingImageEvolution createNewMorphType(name, behavior) - Create new morph types")
writeln()

writeln("🌟 Try: LivingImageEvolution runEvolutionDemo")
writeln()

# Return the evolution system for interactive use
LivingImageEvolution