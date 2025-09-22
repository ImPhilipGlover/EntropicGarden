// Minimal Morphic click test: toggle rectangle color on click and show snapshots
Telos do(
    init
)

world := Telos createWorld

rect := Lobby getSlot("RectangleMorph") clone do(
    x := 20; y := 30; width := 80; height := 40
)
text := Lobby getSlot("TextMorph") clone do(
    x := 15; y := 15; text := "Click Test"
)

rect addMorph(text)
world addMorph(rect)

// Before
writeln("--- Before click ---")
Telos draw
writeln(Telos captureScreenshot)

// Simulate a click inside the rectangle to toggle color
Telos click(25, 35)

// After
writeln("--- After click ---")
Telos draw
writeln(Telos captureScreenshot)

// Run a short main loop for heartbeat
Telos mainLoop
