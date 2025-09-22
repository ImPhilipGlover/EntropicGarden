#!/usr/bin/env io

// Simple SDL2 Shapes Test - Validate Basic Drawing
writeln("🎨 Simple SDL2 Shapes Test")
writeln("=" repeated(30))

// Initialize world and window
Telos createWorld
writeln("✓ World created")

Telos openWindow  
writeln("✓ SDL2 window opened")

world := Telos world
writeln("✓ Got world reference")

// Test 1: Simple rectangle
writeln("\n🟦 Test 1: Blue Rectangle")
rect := RectangleMorph clone
rect setColor(0, 0, 255)  // Blue
rect setPosition(100, 100)
rect setSize(80, 60)
world addMorph(rect)
writeln("   Rectangle created at (100,100) size 80x60")

// Test 2: Red rectangle  
writeln("\n🟥 Test 2: Red Rectangle")
rect2 := RectangleMorph clone
rect2 setColor(255, 0, 0)  // Red
rect2 setPosition(200, 150)
rect2 setSize(60, 80)
world addMorph(rect2)
writeln("   Rectangle created at (200,150) size 60x80")

// Test 3: Green circle
writeln("\n🟢 Test 3: Green Circle")
circle := CircleMorph clone
circle setColor(0, 255, 0)  // Green
circle setPosition(300, 200)
circle setSize(50, 50)
world addMorph(circle)
writeln("   Circle created at (300,200) size 50x50")

// Test 4: White text
writeln("\n⬜ Test 4: White Text")
text := TextMorph clone
text setText("Hello SDL2!")
text setColor(255, 255, 255)  // White
text setPosition(150, 50)
world addMorph(text)
writeln("   Text created at (150,50)")

// Show what we have
writeln("\n📊 Summary:")
writeln("   Total morphs: ", world morphs size)
writeln("   Morph types: Rectangle, Rectangle, Circle, Text")

// Draw once and exit
writeln("\n🎨 Drawing shapes...")
world heartbeat
Telos draw
writeln("✓ Shapes drawn to SDL2 window")

// Brief pause to see the result
writeln("\n⏳ Showing result for 2 seconds...")
Telos sleep(2000)

// Clean exit
writeln("\n🚪 Closing window...")
writeln("✅ Simple shapes test complete!")
0