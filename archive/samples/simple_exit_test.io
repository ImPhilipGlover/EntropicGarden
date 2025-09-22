#!/usr/bin/env io

// Simple test of exit detection without complex event loop

Telos

writeln("=== Simple Exit Detection Test ===")

// Create world and open window
Telos createWorld
Telos openWindow

// Test basic exit methods
writeln("Testing shouldExit method...")
result := Telos shouldExit
writeln("shouldExit returned: " .. result)

writeln("Testing checkEvents method...")
Telos checkEvents
writeln("checkEvents completed")

writeln("Rendering one frame...")
Telos drawWorld

writeln("Sleeping for 2 seconds...")
System sleep(2)

writeln("Checking events after sleep...")
Telos checkEvents

writeln("Final shouldExit check...")
result = Telos shouldExit
writeln("shouldExit returned: " .. result)

// Clean shutdown
Telos closeWindow
writeln("Window closed - test complete")