/*
   Simple SDL2 Window Test - Open, Draw, Close
*/

// Load TelOS Core
doFile("libs/Telos/io/TelosCore.io")

"=== Simple SDL2 Window Test ===" println

// Create world and open window
world := Telos createWorld
Telos openWindow

"Window opened! Creating one rectangle..." println

// Create simple test content
rect := RectangleMorph clone
rect x := 100
rect y := 100
rect width := 200
rect height := 150
rect color := list(0.8, 0.2, 0.2, 1.0)
rect id := "testRect"

world addMorph(rect)

"Drawing content..." println
world refresh

"Waiting 2 seconds..." println
System sleep(2)

"Closing window..." println
Telos closeWindow

"Test complete!" println