/*
   Simple SDL2 Window Test - Modular System
   Demonstrates real SDL2 window opening via modular TelosMorphic
*/

// Load TelOS Core (all modules)
doFile("libs/Telos/io/TelosCore.io")

"=== Simple SDL2 Window Test ===" println

// Create world and open window
world := Telos createWorld
Telos openWindow

"SDL2 Window opened! Testing basic morph creation..." println

// Create a simple rectangle
rect := RectangleMorph clone
rect x := 100
rect y := 100
rect width := 200
rect height := 150
rect color := list(0.2, 0.8, 0.2, 1.0)  // Green
rect id := "testRectangle"

world addMorph(rect)

"Rectangle added to world. Window should display for 3 seconds..." println

// Simple display loop
for(i, 1, 30,
    System sleep(0.1)
    if(i % 10 == 0, 
        write(".")
        world refresh
    )
)

writeln("\nWindow test complete!")

// Close window
Telos closeWindow