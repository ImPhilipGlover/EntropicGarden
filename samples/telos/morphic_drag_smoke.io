// Minimal drag interaction test: drag the rectangle by simulating mouse events
Telos do(
    init
)

world := Telos createWorld
rect := Lobby getSlot("RectangleMorph") clone do(
    x := 20; y := 30; width := 80; height := 40
)
world addMorph(rect)

writeln("--- Before drag ---")
Telos draw
writeln(Telos captureScreenshot)

// Simulate drag from inside the rectangle to a new position
Telos mouseDown(30, 40)
Telos mouseMove(100, 120)
Telos mouseUp(100, 120)

writeln("--- After drag ---")
Telos draw
writeln(Telos captureScreenshot)

Telos mainLoop
