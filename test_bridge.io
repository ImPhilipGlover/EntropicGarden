#!/usr/bin/env io

//
// Simple test to isolate the TelOS bridge initialization issue
//

writeln("Testing TelOS bridge initialization...")

// Load the TelosBridge addon directly
addon := Addon clone setRootPath("build/addons") setName("TelosBridge")

writeln("Attempting to load addon...")
try(
    result := addon load
    if(result isNil,
        Exception raise("Addon load returned nil")
    )
    "✅ Addon loaded successfully" println
) catch(Exception e,
    "❌ Addon load failed: " .. e error println
    e pass
)

// Check if protos were registered
if(Lobby hasSlot("TelosBridge") and Lobby hasSlot("SharedMemoryHandle"),
    TelosBridgePrototype := Lobby TelosBridge
    SharedMemoryHandlePrototype := Lobby SharedMemoryHandle
    "✅ Protos found after addon load" println
,
    "❌ Protos not found after addon load attempt" println
    exit(1)
)

// Try to create Telos namespace
Telos := Object clone do(
    Bridge := TelosBridgePrototype clone do(
        maxWorkers := 4
    )
    SharedMemoryHandle := SharedMemoryHandlePrototype
)

writeln("Testing bridge initialization...")
try(
    result := Telos Bridge initialize(4)
    if(result,
        "✅ Bridge initialized successfully" println
        status := Telos Bridge status
        "Bridge status: " .. status println
    ,
        "❌ Bridge initialization failed" println
        error := Telos Bridge getLastError
        "Last error: " .. error println
    )
) catch(Exception e,
    "❌ Bridge initialization threw exception: " .. e error println
    exit(1)
)

writeln("✅ Test completed successfully")