#!/usr/bin/env io

// Simple Morphic Positioning Debug Test

"Debug: Testing morphic positioning..." println

doFile("libs/Telos/io/TelosCore.io")

world := Telos createWorld
Telos openWindow

"Debug: Creating single test morph..." println

// Create one simple morph with explicit positioning
testMorph := RectangleMorph clone
testMorph width = 100
testMorph height = 50  
testMorph x = 200
testMorph y = 150
testMorph color = list(1.0, 0.0, 0.0, 1.0)  // Red
testMorph id = "test_morph"

"Debug: Test morph created with:" println
("  x: " .. testMorph x) println
("  y: " .. testMorph y) println  
("  width: " .. testMorph width) println
("  height: " .. testMorph height) println
("  color: " .. testMorph color join(",")) println

"Debug: Adding morph to world..." println
world addMorph(testMorph)

"Debug: World should have 1 morph, actual count: " .. world submorphs size println

"Debug: Running display for 10 seconds..." println
Telos displayFor(10)

"Test complete." println