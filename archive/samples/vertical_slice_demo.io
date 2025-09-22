writeln("TelOS Vertical Slice Demo: starting")

doFile("libs/Telos/io/TelosCore.io")

// UI: create world and open a window (fallback prints if no SDL2)
Telos createWorld
Telos openWindow

// Add a rectangle morph and refresh
r := RectangleMorph clone
r x := 50; r y := 60; r width := 120; r height := 80; r color := list(0.9,0.2,0.2,1.0)
Telos addMorph(r)
Telos refresh

// FFI: simple Python eval
res := Telos pyEval("2 + 3")
writeln("FFI result 2+3 = " .. res)

// Persistence: WAL commit and snapshot
Telos walCommit("demo_slice", Map clone atPut("note","vertical_slice"), nil)
Telos saveSnapshot("logs/world_snapshot.json")

// Brief display period (prints heartbeat/fallback if no SDL2)
Telos displayFor(1)

writeln("TelOS Vertical Slice Demo: complete")
