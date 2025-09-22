#!/usr/bin/env io

// Minimal exit test - just check if methods exist

writeln("=== Minimal Exit Test ===")

// Load just basic Telos
Telos

writeln("Telos loaded")

// Check if methods exist
if(Telos hasSlot("shouldExit"),
    writeln("shouldExit method exists"),
    writeln("shouldExit method missing")
)

if(Telos hasSlot("checkEvents"),
    writeln("checkEvents method exists"),
    writeln("checkEvents method missing")
)

writeln("Test complete")