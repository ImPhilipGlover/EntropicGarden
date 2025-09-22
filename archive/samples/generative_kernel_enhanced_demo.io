#!/usr/bin/env io
/*
 * Enhanced Generative Kernel Demo
 * Tests the improved forward protocol with context analysis,
 * memory integration, and sophisticated synthesis patterns
 */

writeln("=== Enhanced Generative Kernel Demo ===")

// Create world for morphic synthesis
world := Telos createWorld

writeln("\n=== Test 1: Enhanced Creation Synthesis ===")

// Test enhanced morph creation with context
rect := Telos createRectangleMorphAt(100, 150, 80, 60)
writeln("Created: ", rect describe)

// Test persona creation
persona := Telos createPersona("TestAgent", "Experiment Conductor")
writeln("Created persona: ", persona name, " - ", persona role)

// Test fractal creation
fractal := Telos createContextFractal("Enhanced generative synthesis patterns")
writeln("Created fractal: ", fractal payload)

writeln("\n=== Test 2: Enhanced Query Synthesis ===")

// Test morphic queries
morphsAtPos := Telos findMorphsAt(100, 150)
writeln("Morphs at (100,150): ", morphsAtPos size, " found")

// Test memory queries (if available)
memoryHits := Telos searchMemoryFor("synthesis", 3)
writeln("Memory search results: ", memoryHits size, " hits")

// Test persona queries
allPersonas := Telos findAllPersonas
writeln("Available personas: ", allPersonas size)

writeln("\n=== Test 3: Enhanced Action Synthesis ===")

// Test animation with parameters
animResult := Telos animateMorphs(15, 20)
writeln("Animation result: ", animResult)

// Test layout actions
layoutResult := Telos organizeRowLayout(12)
writeln("Layout result: ", layoutResult)

// Test persistence actions
saveResult := Telos saveWorldSnapshot
writeln("Save result: ", saveResult)

writeln("\n=== Test 4: Morphic Synthesis ===")

// Test morphic-specific synthesis
drawResult := Telos drawAllMorphs
writeln("Draw result: ", drawResult)

clickResult := Telos synthesizeClick(120, 160)
writeln("Click result: ", clickResult)

writeln("\n=== Test 5: Persistence Synthesis ===")

// Test WAL synthesis
walCommit := Telos walCommitSynthesized("test-frame")
writeln("WAL commit: ", walCommit)

snapshotResult := Telos snapshotCurrentState
writeln("Snapshot result: ", snapshotResult)

writeln("\n=== Test 6: Learning Placeholder Synthesis ===")

// Test unknown methods that should create learning placeholders
placeholder1 := Telos unknownMethodForLearning("arg1", "arg2")
writeln("Placeholder 1: ", placeholder1 usage)

placeholder2 := Telos anotherUnknownPattern(42, "test")
writeln("Placeholder 2: ", placeholder2 usage)

// Test repeated call to see learning
placeholder1b := Telos unknownMethodForLearning("different", "args")
writeln("Placeholder 1 (repeat): ", placeholder1b usage)

writeln("\n=== Test 7: Context-Aware Synthesis ===")

// Test that should demonstrate context analysis
complexResult := Telos executeComplexMorphicAction("transform", "rotate", 45, "blue")
writeln("Complex result: ", complexResult)

writeln("\n=== Enhanced Generative Kernel Demo Complete ===")
writeln("Check for synthesis messages and learning context above.")

// Show synthesized methods count
if(Telos hasSlot("synthesizedMethods"),
    writeln("Total synthesized methods: ", Telos synthesizedMethods size)
)

// Show learning context if available
if(Telos hasSlot("learningContext"),
    writeln("Learning context entries: ", Telos learningContext size)
)