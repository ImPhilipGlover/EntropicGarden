#!/usr/bin/env io
/*
 * Test prototypal TelOS implementation
 */

writeln("=== Testing Prototypal TelOS ===")

// Test immediate availability of Telos slots
writeln("Telos type: " .. Telos type)
writeln("Telos walPath: " .. Telos walPath)
writeln("Telos morphs size: " .. Telos morphs size)

// Test morph creation without initialization
writeln("\n=== Testing Prototypal Morph Creation ===")
rect := RectangleMorph clone
writeln("Rectangle created with id: " .. rect id)
writeln("Rectangle position: (" .. rect x .. "," .. rect y .. ")")
writeln("Rectangle color: " .. rect color asString)

text := TextMorph clone  
writeln("Text created with id: " .. text id)
writeln("Text content: " .. text text)
writeln("Text font size: " .. text fontSize)

// Test fractal prototypes
writeln("\n=== Testing Prototypal Fractals ===")
context := ContextFractal clone
writeln("Context fractal id: " .. context id)
writeln("Context payload: " .. context payload)

concept := ConceptFractal clone
writeln("Concept fractal id: " .. concept id)
writeln("Concept summary: " .. concept summary)

writeln("\n=== Prototypal Test Complete ===")
writeln("All prototypes immediately usable without initialization!")