#!/usr/bin/env io

// Test the raw C-level Telos FFI methods directly  
("=== Raw C-Level Telos FFI Validation Test ===" println)

// Get the raw prototype from Lobby Protos
rawTelos := Lobby Protos Telos

// Test 1: Initialize FFI
("1. Testing FFI initialization..." println)
result := rawTelos initializeFFI("./python/venv")
("✓ FFI initialized: " .. result println)

// Test 2: Load a Python module
("2. Testing module loading..." println)
try(
    mathModule := rawTelos loadModule("math")
    if(mathModule,
        ("✓ Successfully loaded math module, handle type: " .. mathModule type println),
        ("✗ Failed to load math module" println)
    )
) catch(Exception,
    ("✗ Exception loading module: " .. Exception description println)
)

// Test 3: Test function calling if module loaded
if(mathModule,
    ("3. Testing function calls..." println)
    try(
        # Test math.sqrt(16) -> 4.0
        result := rawTelos callFunction(mathModule, "sqrt", list(16))
        if(result,
            ("✓ Successfully called math.sqrt(16), handle type: " .. result type println)
            
            # Test marshalling result back to Io
            ioResult := rawTelos marshalPythonToIo(result)
            if(ioResult,
                ("✓ Successfully marshalled Python result to Io: " .. ioResult println),
                ("✗ Failed to marshal Python result to Io" println)
            ),
            ("✗ Function call returned nil" println)
        )
    ) catch(Exception,
        ("✗ Exception during function call: " .. Exception description println)
    ),
    
    ("3. Skipping function call test - no module loaded" println)
)

// Test 4: Test data marshalling Io -> Python -> Io
("4. Testing data marshalling..." println)
try(
    ioNumber := 42
    pythonHandle := rawTelos marshalIoToPython(ioNumber)
    if(pythonHandle,
        ("✓ Successfully marshalled Io number to Python handle, type: " .. pythonHandle type println)
        
        ioResult := rawTelos marshalPythonToIo(pythonHandle)
        if(ioResult,
            ("✓ Successfully marshalled Python handle back to Io: " .. ioResult .. " (type: " .. ioResult type  .. ")" println),
            ("✗ Failed to marshal Python handle back to Io" println)
        ),
        ("✗ Failed to marshal Io number to Python" println)
    )
) catch(Exception,
    ("✗ Exception during data marshalling: " .. Exception description println)
)

// Test 5: Test string marshalling
("5. Testing string marshalling..." println)
try(
    ioString := "Hello from Io!"
    pythonHandle := rawTelos marshalIoToPython(ioString)
    if(pythonHandle,
        ("✓ Successfully marshalled Io string to Python handle, type: " .. pythonHandle type println)
        
        ioResult := rawTelos marshalPythonToIo(pythonHandle)
        if(ioResult,
            ("✓ Successfully marshalled Python string back to Io: " .. ioResult println),
            ("✗ Failed to marshal Python string back to Io" println)
        ),
        ("✗ Failed to marshal Io string to Python" println)
    )
) catch(Exception,
    ("✗ Exception during string marshalling: " .. Exception description println)
)

("=== Raw C-Level FFI Validation Complete ===" println)