#!/usr/bin/env io

// Simple test without exception handling
("=== Simple FFI Test ===" println)

rawTelos := Lobby Protos Telos

("1. Initializing FFI..." println)
rawTelos initializeFFI("./python/venv")

("2. Loading math module..." println)
mathModule := rawTelos loadModule("math")
("Module loaded: " .. mathModule println)
("Module type: " .. mathModule type println)

("3. Calling math.sqrt(16)..." println)
result := rawTelos callFunction(mathModule, "sqrt", list(16))
("Function result: " .. result println)
if(result, ("Result type: " .. result type println))

("4. Marshalling result to Io..." println)
if(result,
    ioResult := rawTelos marshalPythonToIo(result)
    ("Marshalled result: " .. ioResult println)
    if(ioResult, ("Marshalled type: " .. ioResult type println))
)

("5. Testing direct data marshalling..." println)
ioNumber := 42
("Original Io number: " .. ioNumber println)
pythonHandle := rawTelos marshalIoToPython(ioNumber)
("Python handle: " .. pythonHandle println) 
if(pythonHandle, ("Python handle type: " .. pythonHandle type println))

if(pythonHandle,
    backToIo := rawTelos marshalPythonToIo(pythonHandle)
    ("Back to Io: " .. backToIo println)
    if(backToIo, ("Back to Io type: " .. backToIo type println))
)

("=== Test Complete ===" println)