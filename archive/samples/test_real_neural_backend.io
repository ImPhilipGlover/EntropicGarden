#!/usr/bin/env io

// Real Neural Backend Test
// ========================
// 
// Test with actual FFI calls to neural_backend.py

// Minimal setup - IoTelos.io loads automatically from C
writeln("=== Real Neural Backend Test ===")

// Test FFI initialization
writeln("1. Initializing FFI...")
Telos initializeFFI()
writeln("FFI initialized")

// Test neural backend self-test
writeln("2. Running neural backend self-test...")
try(
    module := Telos loadModule("neural_backend")
    result := Telos callFunction(module, "neural_self_test", list())
    writeln("Self-test result: ", result)
    
    if(result == true,
        writeln("✓ Neural backend self-test PASSED")
    ,
        writeln("✗ Neural backend self-test FAILED")
    )
) catch(Exception,
    writeln("✗ Exception: ", Exception message)
)

// Test vector generation
writeln("3. Testing vector generation...")
try(
    module := Telos loadModule("neural_backend")
    vector := Telos callFunction(module, "neural_generate_vector", list("test_seed", 50))
    writeln("Generated vector size: ", vector size)
    writeln("First few values: ", vector at(0), ", ", vector at(1), ", ", vector at(2))
) catch(Exception,
    writeln("✗ Exception: ", Exception message)
)

// Test text encoding
writeln("4. Testing text encoding...")
try(
    module := Telos loadModule("neural_backend")
    encoded := Telos callFunction(module, "neural_encode_text", list("hello neural world"))
    writeln("Encoded text vector size: ", encoded size)
    writeln("First few values: ", encoded at(0), ", ", encoded at(1), ", ", encoded at(2))
) catch(Exception,
    writeln("✗ Exception: ", Exception message)
)

// Test memory operations
writeln("5. Testing memory operations...")
try(
    module := Telos loadModule("neural_backend")
    
    // Add some memory entries
    idx1 := Telos callFunction(module, "neural_add_memory", list("neural computation example"))
    idx2 := Telos callFunction(module, "neural_add_memory", list("vector similarity testing"))
    idx3 := Telos callFunction(module, "neural_add_memory", list("completely different topic"))
    
    writeln("Added memory entries at indices: ", idx1, ", ", idx2, ", ", idx3)
    
    // Search memory
    results := Telos callFunction(module, "neural_search", list("neural vector", 2))
    writeln("Search results count: ", results size)
    
    results foreach(i, result,
        writeln("Result ", i, ": text='", result text, "', score=", result score)
    )
    
) catch(Exception,
    writeln("✗ Exception: ", Exception message)
)

writeln("=== Test Complete ===")