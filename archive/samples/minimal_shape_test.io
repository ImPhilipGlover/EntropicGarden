#!/usr/bin/env io

// Minimal SDL2 Test - Just One Shape
writeln("🔍 Minimal SDL2 Test - One Shape Only")

// Quick init
Telos createWorld
Telos openWindow
world := Telos world

// Create one blue rectangle
rect := RectangleMorph clone
rect setColor(0, 0, 255) setPosition(200, 200) setSize(100, 80)
world addMorph(rect)

writeln("✓ Created blue rectangle at (200,200)")
writeln("✓ Morph count: ", world morphs size)

// Single draw
world heartbeat
Telos draw
writeln("✓ Drew to SDL2 window")

// Exit immediately
writeln("✅ Done - window should show blue rectangle!")
0