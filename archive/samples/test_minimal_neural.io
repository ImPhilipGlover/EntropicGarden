#!/usr/bin/env io

// Minimal Neural Backend Test
// ===========================
// 
// Direct test of neural backend without loading full IoTelos

// Minimal FFI setup
Telos := Object clone

Telos initializeFFI := method(
    writeln("Initializing minimal FFI...")
    "initialized"
)

Telos loadModule := method(moduleName,
    writeln("Loading module: ", moduleName)
    Object clone
)

Telos callFunction := method(moduleObj, functionName, args,
    writeln("Calling function: ", functionName, " with args: ", args)
    
    if(functionName == "neural_self_test",
        return true
    )
    
    if(functionName == "neural_generate_vector",
        // Mock return a list of 10 numbers
        result := List clone
        10 repeat(result append(1.0))
        return result
    )
    
    if(functionName == "neural_encode_text",
        // Mock return a list of 10 numbers
        result := List clone
        10 repeat(result append(0.5))
        return result
    )
    
    if(functionName == "neural_add_memory",
        return 1  // Mock memory index
    )
    
    if(functionName == "neural_search",
        // Mock search results
        result1 := Object clone
        result1 text := "mock result"
        result1 score := 0.8
        result1 index := 0
        return list(result1)
    )
    
    if(functionName == "neural_bind",
        // Mock bind result
        result := List clone
        10 repeat(result append(0.7))
        return result
    )
    
    if(functionName == "neural_bundle",
        // Mock bundle result  
        result := List clone
        10 repeat(result append(0.6))
        return result
    )
    
    nil
)

// Load neural backend with prototypal patterns
doFile("libs/Telos/io/NeuralBackend.io")

writeln("=== Minimal Neural Backend Test ===")

// Test 1: Vector generation
writeln("Testing vector generation...")
try(
    vector := NeuralVector generateFromSeed("test")
    writeln("✓ Vector generated: ", vector hasSlot("vectorData"))
) catch(Exception,
    writeln("✗ Vector generation failed: ", Exception message)
)

// Test 2: Text encoding
writeln("Testing text encoding...")
try(
    encoded := NeuralTextEncoder encodeText("hello world")
    writeln("✓ Text encoded: ", encoded hasSlot("vectorData"))
) catch(Exception,
    writeln("✗ Text encoding failed: ", Exception message)
)

// Test 3: Memory operations  
writeln("Testing memory operations...")
try(
    index := NeuralMemoryDatabase addMemory("test memory")
    writeln("✓ Memory added with index: ", index)
    
    results := NeuralMemoryDatabase searchMemory("test", 1)
    writeln("✓ Search results: ", results size, " items")
) catch(Exception,
    writeln("✗ Memory operations failed: ", Exception message)
)

writeln("=== Test Complete ===")