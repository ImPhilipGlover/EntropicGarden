// Multi-rectangle demo: hit-test and WAL markers around interactions
Telos do(
    init
)

// Start a frame
Telos walBegin("frame", map(note: "multi-rect demo"))

world := Telos createWorld
r1 := Lobby getSlot("RectangleMorph") clone do(x := 10; y := 10; width := 60; height := 40)
r2 := Lobby getSlot("RectangleMorph") clone do(x := 100; y := 50; width := 80; height := 50)
world addMorph(r1)
world addMorph(r2)

writeln("--- Before ---")
Telos draw
writeln(Telos captureScreenshot)

// Hit-test at (15,15)
hits := Telos hitTest(15, 15)
writeln("Hit-test at (15,15): count=", hits size)

// Interact: toggle r1, drag r2
Telos click(15, 15)
Telos mouseDown(110, 60)
Telos mouseMove(160, 90)
Telos mouseUp(160, 90)

writeln("--- After ---")
Telos draw
writeln(Telos captureScreenshot)

Telos walEnd("frame")

writeln("--- telos.wal ---")
System system("cat telos.wal")

Telos mainLoop
