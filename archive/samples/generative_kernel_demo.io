#!/usr/bin/env io

/*
Generative Kernel Demo - Test the forward protocol that enables dynamic behavior synthesis
This demonstrates how TelOS can grow new capabilities when encountering unfamiliar requests
*/

writeln("=== TelOS Generative Kernel Demo ===")
writeln("Testing dynamic behavior synthesis through the forward protocol...")
writeln()

// Initialize the living world
Telos createWorld
Telos verbose = true

// Create some initial morphs
rect1 := Telos createMorph("RectangleMorph")
rect1 moveTo(50, 50)
rect1 setColor(1, 0, 0, 1)

text1 := Telos createMorph("TextMorph") 
text1 moveTo(200, 100)
text1 setText("Generative Test")

writeln("=== Initial World State ===")
Telos captureScreenshot

writeln()
writeln("=== Testing Creation Synthesis ===")

// Test creating unknown objects through forward
persona := Telos createPersona("TestPersona")
writeln("Created persona: " .. persona asString)

unknownMorph := Telos createCustomMorph("magic", "sparkly")
writeln("Created unknown morph: " .. unknownMorph asString)

writeln()
writeln("=== Testing Query Synthesis ===")

// Test querying for things that don't exist
morphList := Telos findAllMorphsInRegion(0, 0, 100, 100)
writeln("Found morphs: " .. morphList asString)

worldInfo := Telos getWorldStatus()
writeln("World info: " .. worldInfo asString)

writeln()
writeln("=== Testing Action Synthesis ===")

// Test unknown actions
result := Telos animateAllMorphs("bounce")
writeln("Animation result: " .. result)

// Test morph-specific synthesis
rect1 becomeMagical()
writeln("Rectangle became: " .. rect1 asString)

rect1 growLarger()
writeln("Rectangle after growth")

writeln()
writeln("=== Testing World Synthesis ===")

if(Telos world != nil,
    // Test world-level synthesis
    Telos world spawnRandomMorphs(3)
    writeln("World after spawning:")
    Telos captureScreenshot
    
    writeln()
    writeln("Testing world organization:")
    Telos world organizeLayout()
    Telos captureScreenshot
)

writeln()
writeln("=== Testing Placeholder Methods ===")

// These should create dynamic methods for future use
result1 := Telos mysteriousFunction("param1", "param2")
writeln("Mysterious function result: " .. result1)

result2 := Telos calculateQuantumFlux(42)
writeln("Quantum flux result: " .. result2)

writeln()
writeln("=== Final State ===")

// WAL integrity
Telos mark("generative.demo.complete", Map clone atPut("tests", "synthesis"))

writeln("WAL entries written, testing complete")
writeln("=== Generative Kernel Demo Complete ===")