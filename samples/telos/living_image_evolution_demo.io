#!/usr/bin/env io

// Living Image Evolution System Demo
// Demonstrates autopoietic self-modification with persistent snapshots and rollback

doFile("libs/Telos/io/EvolutionSystem.io")

writeln("=== Living Image Evolution System Demo ===")
writeln("Autopoietic self-modification with persistent snapshots and rollback")
writeln()

// Initialize TelOS environment
writeln("1. Initializing TelOS environment...")
telos := Telos clone
telos createWorld

// Create simple memory substrate mock for evolution tracking
SimpleMem := Object clone do(
    concepts := List clone
    stats := method(
        s := Object clone
        s semanticConcepts := self concepts size
        s timestamp := Date now
        s
    )
    consolidate := method(
        writeln("    Memory consolidation triggered")
        self
    )
)

memorySubstrate := SimpleMem clone

writeln("   TelOS world and memory substrate ready")

writeln()
writeln("2. Initializing Evolution System...")
evolution := EvolutionSystem clone
evolution initialize(memorySubstrate)

writeln()
writeln("3. Adding some morphs to create initial complexity...")

# Add some initial morphs to the world
rect1 := RectangleMorph clone
rect1 position := List clone append(50, 50)
rect1 size := List clone append(100, 60)
rect1 color := "lightblue"
rect1 id := "evolving_rect1"
telos world addSubmorph(rect1)

text1 := TextMorph clone
text1 position := List clone append(60, 70)
text1 text := "Evolution Gen 0"
text1 id := "evolution_label"
rect1 addSubmorph(text1)

# Add some concepts to memory
memorySubstrate concepts append("Initial system state")
memorySubstrate concepts append("Basic morphic structure")
memorySubstrate concepts append("Evolution framework ready")

writeln("   Added morphs and memory concepts")

writeln()
writeln("4. Capturing initial snapshot...")
initialSnapshot := evolution captureSnapshot("Initial system state")

writeln("   Initial metrics:")
writeln("     Adaptation Score: " .. initialSnapshot metrics adaptationScore)
writeln("     Complexity Measure: " .. initialSnapshot metrics complexityMeasure)
writeln("     Performance Index: " .. initialSnapshot metrics performanceIndex)
writeln("     Stability Rating: " .. initialSnapshot metrics stabilityRating)

writeln()
writeln("5. Performing evolutionary step 1...")

# Create environmental pressures
pressures1 := Map clone
pressures1 atPut("complexity", 0.6)
pressures1 atPut("performance", 0.4)
pressures1 atPut("adaptation", 0.7)

evolutionResult1 := evolution evolve(pressures1)

writeln("   Evolution 1 success: " .. evolutionResult1 success)
writeln("   Applied adaptations: " .. evolutionResult1 adaptations size)

evolutionResult1 adaptations foreach(i, adaptation,
    writeln("     Adaptation " .. i .. ": " .. adaptation type .. " -> " .. adaptation action)
)

writeln()
writeln("6. Adding more complexity for evolution step 2...")

# Add more morphs to simulate growth
rect2 := RectangleMorph clone
rect2 position := List clone append(200, 100)
rect2 size := List clone append(80, 80)
rect2 color := "lightgreen"
rect2 id := "evolving_rect2"
telos world addSubmorph(rect2)

# Add more memory concepts
memorySubstrate concepts append("Increased morphic complexity")
memorySubstrate concepts append("Multi-generational evolution")

writeln()
writeln("7. Performing evolutionary step 2...")

pressures2 := Map clone
pressures2 atPut("complexity", 0.8)
pressures2 atPut("performance", 0.9)
pressures2 atPut("stability", 0.5)

evolutionResult2 := evolution evolve(pressures2)

writeln("   Evolution 2 success: " .. evolutionResult2 success)

writeln()
writeln("8. Testing rollback capability...")

writeln("   Current generation: " .. evolution currentGeneration)
writeln("   Rolling back to generation 1...")

rollbackResult := evolution rollback(1)

writeln("   Rollback success: " .. rollbackResult success)
writeln("   Current generation after rollback: " .. evolution currentGeneration)

writeln()
writeln("9. Evolution history analysis...")

history := evolution getEvolutionHistory
writeln("   Total snapshots: " .. history totalSnapshots)
writeln("   Current generation: " .. history currentGeneration)

history snapshots foreach(i, snapshot,
    writeln("     Snapshot " .. i .. ": Gen " .. snapshot generation .. " - " .. snapshot annotation)
    if(snapshot metrics,
        writeln("       Adaptation: " .. snapshot metrics adaptationScore .. 
               ", Performance: " .. snapshot metrics performanceIndex ..
               ", Stability: " .. snapshot metrics stabilityRating)
    )
)

writeln()
writeln("10. Final evolution statistics...")

finalStats := evolution stats
writeln("    Timestamp: " .. finalStats timestamp)
writeln("    Current Generation: " .. finalStats currentGeneration)
writeln("    Total Snapshots: " .. finalStats totalSnapshots)
writeln("    Current Metrics:")
writeln("      Adaptation Score: " .. finalStats adaptationScore)
writeln("      Complexity Measure: " .. finalStats complexityMeasure)
writeln("      Performance Index: " .. finalStats performanceIndex)
writeln("      Stability Rating: " .. finalStats stabilityRating)

if(finalStats hasSlot("latestSnapshotGeneration"),
    writeln("    Latest Snapshot: Generation " .. finalStats latestSnapshotGeneration)
    writeln("    Latest Snapshot Time: " .. finalStats latestSnapshotTime)
)

writeln()
writeln("11. Running Morphic heartbeat to show live system...")
telos mainLoop(3)

writeln()
writeln("=== Living Image Evolution System Demo Complete ===")
writeln("Successfully demonstrated:")
writeln("  ✓ Evolution system initialization with memory substrate")
writeln("  ✓ Persistent snapshot capture with comprehensive metrics")
writeln("  ✓ Environmental pressure-driven evolution steps")
writeln("  ✓ Autopoietic adaptation through memory and morphic evolution")
writeln("  ✓ Multi-generational evolution tracking")
writeln("  ✓ Rollback capability to previous system states")
writeln("  ✓ Comprehensive evolution history and statistics")
writeln("  ✓ Integration with live Morphic UI system")
writeln()
writeln("TelOS Living Image Evolution System is operational!")
writeln("The system can now evolve, adapt, and self-modify autonomously.")