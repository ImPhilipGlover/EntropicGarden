// Consolidated Morphic interaction regression: click toggle, drag move, WAL assertions
Telos do(
    init
)

// Reset WAL
wal := File with("telos.wal")
if(wal exists, wal remove)

world := Telos createWorld
rect := Lobby getSlot("RectangleMorph") clone do(
    x := 20; y := 30; width := 80; height := 40; id := "rect1"
)
world addMorph(rect)

writeln("-- Pre-interaction snapshot --")
Telos draw
writeln(Telos captureScreenshot)

// Click inside rect to toggle color (persisted)
Telos click(25, 35)

// Drag the rect
Telos mouseDown(30, 40)
Telos mouseMove(90, 110)
Telos mouseUp(90, 110)

writeln("-- Post-interaction snapshot --")
Telos draw
writeln(Telos captureScreenshot)

writeln("-- WAL contents --")
System system("cat telos.wal")

// Brief main loop for heartbeat
Telos mainLoop
