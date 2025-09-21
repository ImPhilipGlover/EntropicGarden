#!/usr/bin/env io

// Debug Neural Backend Issues
// ===========================
// 
// Simplest possible test to isolate the segfault

doFile("libs/Telos/io/IoTelos.io")

writeln("=== Debug Neural Backend Test ===")

// Initialize FFI
writeln("1. Initializing FFI...")
Telos initializeFFI()
writeln("FFI initialized")

// Load neural module
writeln("2. Loading neural_backend module...")
neuralModule := Telos loadModule("neural_backend")
writeln("Module loaded: ", neuralModule)

// Test simple function call
writeln("3. Testing neural_generate_vector...")
try(
    result := Telos callFunction(neuralModule, "neural_generate_vector", list("test", 10))
    writeln("Result: ", result)
    writeln("Result type: ", result type)
    writeln("Result size: ", result size)
) catch(Exception,
    writeln("Exception: ", Exception message)
)

writeln("=== Test Complete ===")