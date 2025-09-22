#!/usr/bin/env io

/*
=======================================================================================
  COMPREHENSIVE INTEGRATION TEST: FHRR VSA Memory + Entropy-Optimized Planning
=======================================================================================

This integration test demonstrates the complete TelOS vertical slice:
- UI: Morphic if(optimalSolution,
    do(
        writeln("🏆 OPTIMAL SOLUTION SELECTED:")
        writeln("─────────────────────────────")
        ("Persona: " .. optimalSolution persona .. " (" .. optimalSolution facet facetName .. ")") println
        ("Solution: " .. optimalSolution response exSlice(0, 250) .. "...") println
    ),
    nil
) with heartbeat and visual feedback
- FFI: FHRR/DiskANN-backed VSA Memory operations via Python synaptic bridge
- Persistence: WAL frames and JSONL logging for all operations
- Cognition: Live persona consultations with entropy-optimized planning

The test shows FHRR VSA memory feeding into entropy-guided persona cognition,
creating a complete demonstration of the TelOS neuro-symbolic intelligence system.
*/

"=== COMPREHENSIVE INTEGRATION TEST: FHRR VSA + ENTROPY PLANNING ===" println
"🧠 Testing complete TelOS vertical slice: UI + FFI + Persistence + Cognition" println

// Initialize TelOS system
writeln("Initializing TelOS with complete cognitive architecture...")

// Load core TelOS modules
doFile("libs/Telos/io/TelosCore.io")
doFile("libs/Telos/io/TelosFFI.io")
doFile("libs/Telos/io/TelosPersistence.io")
doFile("libs/Telos/io/TelosMemory.io")
doFile("libs/Telos/io/TelosPersona.io")

// Create living world for UI demonstration
world := Telos createWorld
writeln("🌍 Living Morphic world created with heartbeat")

// Enable Python synaptic bridge for FHRR VSA operations
Telos pyEval("import sys; sys.path.append('python')")
writeln("🐍 Python synaptic bridge initialized for FHRR VSA operations")

// === PHASE 1: FHRR VSA MEMORY SUBSTRATE ===
// Demonstrate FHRR operations feeding into memory system

writeln("\n🧠 PHASE 1: FHRR VSA Memory Substrate")
