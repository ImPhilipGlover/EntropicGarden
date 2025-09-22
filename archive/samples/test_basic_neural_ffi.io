#!/usr/bin/env io

// Simple Neural Backend FFI Test
// ==============================
// 
// Test basic FFI connection to neural_backend without complex prototypal patterns

doFile("libs/Telos/io/IoTelos.io")

// Simple test without complex prototypal patterns
testBasicNeuralFFI := method(
    writeln("=== Basic Neural FFI Test ===")
    
    // Initialize FFI
    writeln("Initializing FFI...")
    ffiResult := Telos initializeFFI()
    if(ffiResult == nil,
        writeln("FFI initialization failed")
        return false
    )
    writeln("FFI initialized successfully")
    
    // Test loading neural backend module
    writeln("Loading neural_backend module...")
    try(
        moduleHandle := Telos loadModule("neural_backend")
        if(moduleHandle == nil,
            writeln("Failed to load neural_backend module")
            return false
        )
        writeln("Module loaded successfully: ", moduleHandle)
    ) catch(Exception,
        writeln("Exception loading module: ", Exception message)
        return false
    )
    
    // Test neural self-test function
    writeln("Running neural self-test...")
    try(
        selfTestResult := Telos callFunction(moduleHandle, "neural_self_test", list())
        writeln("Self-test result: ", selfTestResult)
        
        if(selfTestResult == true,
            writeln("✓ Neural backend self-test PASSED")
            return true
        ,
            writeln("✗ Neural backend self-test FAILED")
            return false
        )
    ) catch(Exception,
        writeln("Exception in self-test: ", Exception message)
        return false
    )
)

// Run basic test
if(testBasicNeuralFFI(),
    writeln("Basic neural FFI test completed successfully")
,
    writeln("Basic neural FFI test failed")
)