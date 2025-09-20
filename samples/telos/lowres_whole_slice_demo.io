// Low-resolution whole-system slice demo: UI + FFI stub + Persistence + Index
writeln("[demo] Telos vertical slice: UI+FFI+WAL")
Telos init
world := Telos createWorld

// Build a tiny scene via config
spec := list(
    map(type: "RectangleMorph", x: 40, y: 40, width: 80, height: 50, color: "[0.2,0.6,0.9,1]", id: "rectA"),
    map(type: "RectangleMorph", x: 160, y: 60, width: 100, height: 70, color: "[1,0,0,1]", id: "rectB"),
    map(type: "TextMorph", x: 50, y: 140, text: "Low-Res Whole Slice", id: "label1")
)
Telos loadConfig(spec)

// Heartbeat + draw + snapshot
Telos ui heartbeat(2)
Telos draw
writeln(Telos captureScreenshot)
Telos saveSnapshot
Telos saveSnapshotJson

// WAL markers
Telos walBegin("demo", map(note: "toggle & drag"))
Telos click(60, 60) // toggle rectangle color
Telos mouseDown(60,60); Telos mouseMove(120,80); Telos mouseUp(120,80) // drag
Telos walEnd("demo")

// Quick memory use
Telos memory index(list("one small step", "watercourse way", "living image"))
writeln("Search results:", Telos memory search("living"))

writeln("DONE")
