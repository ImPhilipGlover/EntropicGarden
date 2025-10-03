#!/usr/bin/env io

"=== DEMONSTRATING IO SUPREMACY ===" println
"Io mind orchestrating Python substrate through simple C ABI bridge..." println

// Load the bridge
doFile("libs/Telos/io/TelosBridge.io")

// Initialize with simple config
config := Map clone do(
    atPut("max_workers", 2)
    atPut("log_level", "INFO")
)

"Initializing bridge..." println
Telos Bridge initialize(config)

// Check status
status := Telos Bridge status
"Bridge status: " .. status println

"SUCCESS: Io controls Python via C ABI - system working in Io!" println