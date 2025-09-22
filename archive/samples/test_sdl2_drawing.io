/*
   SDL2 Window Drawing Test - Demonstrates actual content rendering
*/

// Load TelOS Core (which loads all modules including TelosMorphic)
doFile("libs/Telos/io/TelosCore.io")

"=== SDL2 Window Drawing Test ===" println

// Create world and open SDL2 window
world := Telos createWorld
Telos openWindow

"SDL2 Window opened! Adding visual content..." println

// Create some test morphs
rect1 := RectangleMorph clone
rect1 x := 100
rect1 y := 100
rect1 width := 200
rect1 height := 150
rect1 color := list(0.8, 0.2, 0.2, 1.0)  // Red
rect1 id := "redRectangle"

rect2 := RectangleMorph clone
rect2 x := 200
rect2 y := 200
rect2 width := 150
rect2 height := 100
rect2 color := list(0.2, 0.8, 0.2, 1.0)  // Green
rect2 id := "greenRectangle"

text1 := TextMorph clone
text1 x := 150
text1 y := 50
text1 text := "TelOS SDL2 Window Test"
text1 id := "titleText"

// Add morphs to world
world addMorph(rect1)
world addMorph(rect2)
world addMorph(text1)

"Drawing content to SDL2 window..." println

// Display content for 5 seconds with active drawing
Telos displayFor(5)

"Content displayed! Now closing window..." println

// Properly close the SDL2 window
Telos closeWindow

"SDL2 window closed successfully!" println