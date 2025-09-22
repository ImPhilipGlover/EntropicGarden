#!/usr/bin/env io

// Simple SDL2 Window Test for Modular TelOS
// Tests if we can open an actual visible window

"=== Modular TelOS SDL2 Window Test ===" println
"Testing real window creation..." println

// Create world and open window
world := Telos createWorld
Telos openWindow

// Create some morphs to display
rect1 := RectangleMorph clone
rect1 x := 100
rect1 y := 100  
rect1 width := 150
rect1 height := 100
rect1 color := list(1.0, 0.3, 0.3, 1.0)  // Red
rect1 id := "testRect1"

// Add to world
world addMorph(rect1)

rect2 := RectangleMorph clone
rect2 x := 300
rect2 y := 150
rect2 width := 120
rect2 height := 80
rect2 color := list(0.3, 1.0, 0.3, 1.0)  // Green  
rect2 id := "testRect2"

// Add to world
world addMorph(rect2)

// Add text
text1 := TextMorph clone
text1 x := 50
text1 y := 50
text1 width := 400
text1 height := 30
text1 text := "TelOS Modular SDL2 Window Test - SUCCESS!"
text1 color := list(1.0, 1.0, 1.0, 1.0)  // White
text1 id := "testText1"

// Add to world
world addMorph(text1)

"Window should now be visible with morphs!" println
"Morphs in world: " print
world morphs size println

// Refresh display a few times
for(refresh, 1, 5,
    ("Refresh #" .. refresh .. " - updating display") println
    Telos refresh
    System sleep(1)
)

"Window test completed - window should have been visible for 5+ seconds" println

// Close window
Telos closeWindow

"=== SDL2 Window Test Complete ===" println