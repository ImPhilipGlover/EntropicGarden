#!/usr/bin/env io

/*
Neural Backend Integration Test
==============================

This test validates that the FFI can successfully call the Python neural
computation backend and demonstrates the basic VSA operations.
*/

"TelOS Neural Backend Integration Test" println
"=" repeated(40) println

// Initialize Telos
Telos createWorld

// Test basic FFI functionality with neural backend
"Testing FFI call to neural backend..." println

try(
    // Test Python path and module loading
    result := Telos ffi callFunction("sys", "version", list())
    "✓ Python FFI working: " .. result println
,
    "✗ Python FFI failed" println
    return
)

// Test neural backend module loading
try(
    initResult := Telos ffi loadModule("sys")  // Load a standard module first
    "✓ Module loading works" println
,
    "✗ Module loading failed" println
    return
)

// Test our neural backend functions
try(
    // Simple vector operations
    v1 := list(1, 0, 1, 0, 1)
    v2 := list(0, 1, 0, 1, 0)
    
    "Testing neural bind operation..." println
    bindResult := Telos ffi callFunction("telos_neural_backend", "neural_bind", list(v1, v2))
    if(bindResult,
        "✓ Neural bind operation successful: " .. bindResult size .. " dimensions" println,
        "✗ Neural bind operation failed" println
    )
    
    "Testing neural bundle operation..." println
    bundleResult := Telos ffi callFunction("telos_neural_backend", "neural_bundle", list(list(v1, v2)))
    if(bundleResult,
        "✓ Neural bundle operation successful: " .. bundleResult size .. " dimensions" println,
        "✗ Neural bundle operation failed" println
    )
    
    "Testing text encoding..." println
    textResult := Telos ffi callFunction("telos_neural_backend", "neural_encode_text", list("test text"))
    if(textResult,
        "✓ Neural text encoding successful: " .. textResult size .. " dimensions" println,
        "✗ Neural text encoding failed" println
    )
,
    "✗ Neural backend function calls failed" println
)

"Neural backend integration test complete!" println