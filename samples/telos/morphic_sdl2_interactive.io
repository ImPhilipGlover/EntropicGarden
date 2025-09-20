// Interactive SDL2 Morphic Demo: Create clickable rectangles with SDL2 window
Telos do(
    init
)

// Create world and open SDL2 window
world := Telos createWorld
Telos openWindow

// Create some colorful rectangles
rect1 := RectangleMorph clone do(
    x := 50; y := 50; width := 100; height := 60
    id := "rect1"
    color := list(1.0, 0.2, 0.2, 1.0) // Red
)
world addMorph(rect1)

rect2 := RectangleMorph clone do(
    x := 200; y := 100; width := 80; height := 80
    id := "rect2" 
    color := list(0.2, 1.0, 0.2, 1.0) // Green
)
world addMorph(rect2)

rect3 := RectangleMorph clone do(
    x := 350; y := 80; width := 120; height := 40
    id := "rect3"
    color := list(0.2, 0.2, 1.0, 1.0) // Blue
)
world addMorph(rect3)

// Add a text label
textMorph := TextMorph clone do(
    x := 50; y := 200; width := 300; height := 30
    id := "label"
    text := "Click rectangles to toggle colors, drag to move!"
    color := list(1.0, 1.0, 1.0, 1.0) // White text
)
world addMorph(textMorph)

writeln("=== Interactive SDL2 Morphic Demo ===")
writeln("- Click rectangles to toggle colors")
writeln("- Drag rectangles to move them around")
writeln("- Close window to exit")
writeln("")
writeln("Starting main loop...")

// Run interactive loop (SDL2 events will be processed)
Telos mainLoop

// Cleanup
Telos closeWindow

writeln("SDL2 morphic demo completed")