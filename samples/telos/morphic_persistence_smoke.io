// Persistence smoke: clears WAL, performs a click and a drag, prints WAL
Telos do(
    init
)

// Clear WAL by removing it if present
wal := File with("telos.wal")
if(wal exists, wal remove)

world := Telos createWorld
rect := Lobby getSlot("RectangleMorph") clone do(
    x := 20; y := 30; width := 80; height := 40
)
world addMorph(rect)

// Click toggle (should write a color change)
Telos click(25, 35)

// Drag move (should write position changes)
Telos mouseDown(30, 40)
Telos mouseMove(100, 120)
Telos mouseUp(100, 120)

// Show snapshot and WAL
writeln("--- Snapshot ---")
Telos draw
writeln(Telos captureScreenshot)

writeln("--- telos.wal ---")
System system("cat telos.wal")

Telos mainLoop
