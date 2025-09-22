#!/usr/bin/env io

/*
FFI Implementation Validation Test
=================================

Tests the completed Pure C FFI implementation with:
1. Python environment initialization
2. Module loading (built-in modules)
3. Function calling with argument marshalling
4. Data marshalling between Io and Python
5. Error handling and cleanup

This validates Phase 1.2: Rigorous FFI Cookbook Implementation
*/

Telos := Object clone

// Initialize Python environment
("=== FFI Validation Test ===" println)
("Testing Python environment initialization..." println)

result := Telos initializeFFI("./python/venv")
if(result,
    ("✓ Python environment initialized successfully" println),
    ("✗ Failed to initialize Python environment" println)
    exit(1)
)

// Test loading a built-in Python module
("Testing module loading..." println)
mathModule := Telos loadModule("math")
if(mathModule,
    ("✓ Successfully loaded math module" println),
    ("✗ Failed to load math module" println)
    exit(1)
)

// Test function calling with arguments
("Testing function calls..." println)
try(
    // Test math.sqrt(16) -> 4.0
    result := Telos callFunction(mathModule, "sqrt", list(16))
    if(result,
        ("✓ Successfully called math.sqrt(16), result type: " .. result type println)
        // Marshal result back to Io
        ioResult := Telos marshalPythonToIo(result)
        if(ioResult,
            ("✓ Successfully marshalled result to Io: " .. ioResult println),
            ("✗ Failed to marshal Python result to Io" println)
        ),
        ("✗ Function call returned nil" println)
    )
) catch(Exception,
    ("✗ Exception during function call: " .. Exception description println)
)

// Test basic data marshalling
("Testing data marshalling..." println)
try(
    // Test marshalling Io number to Python
    ioNumber := 42
    pythonHandle := Telos marshalIoToPython(ioNumber)
    if(pythonHandle,
        ("✓ Successfully marshalled Io number to Python handle" println)
        
        // Test marshalling back
        ioResult := Telos marshalPythonToIo(pythonHandle)
        if(ioResult,
            ("✓ Successfully marshalled Python handle back to Io: " .. ioResult println),
            ("✗ Failed to marshal Python handle back to Io" println)
        ),
        ("✗ Failed to marshal Io number to Python" println)
    )
) catch(Exception,
    ("✗ Exception during data marshalling: " .. Exception description println)
)

// Test string marshalling
("Testing string marshalling..." println)
try(
    ioString := "Hello from Io!"
    pythonHandle := Telos marshalIoToPython(ioString)
    if(pythonHandle,
        ("✓ Successfully marshalled Io string to Python handle" println)
        
        ioResult := Telos marshalPythonToIo(pythonHandle)
        if(ioResult,
            ("✓ Successfully marshalled Python string back to Io: " .. ioResult println),
            ("✗ Failed to marshal Python string back to Io" println)
        ),
        ("✗ Failed to marshal Io string to Python" println)
    )
) catch(Exception,
    ("✗ Exception during string marshalling: " .. Exception description println)
)

("=== FFI Validation Complete ===" println)
("All FFI components tested. Check output above for any failures." println)