writeln("[demo] Telos command script demo")
Telos init
Telos createWorld

// Create two rectangles and a label via commands
idA := Telos commands run("newRect", list(40, 40, 80, 50, 0.2, 0.6, 0.9))
idB := Telos commands run("newRect", list(160, 60, 100, 70, 1, 0, 0))
Telos commands run("newText", list(50, 140, "Command Demo"))

// Move and recolor
Telos commands run("move", list(idA, 120, 100))
Telos commands run("color", list(idB, 0, 1, 0, 1))
Telos commands run("front", list(idB))

// Export world JSON and snapshot
Telos commands run("export.json", list("logs/world.json"))
Telos commands run("snapshot")
Telos commands run("snapshot.json")

// Draw and heartbeat
Telos draw
Telos ui heartbeat(1)

writeln("[demo] done")
