// Morphic WAL Replay Smoke Test
// 1) Create world with two rects and apply some changes
// 2) Snapshot A and write to WAL frame
// 3) Reset world to a fresh instance
// 4) Replay WAL and snapshot B
// 5) Print both snapshots for visual diff

Telos init
w := Telos createWorld

// Build scene
r1 := RectangleMorph clone do(
	id := "rect1"; x := 10; y := 10; width := 80; height := 50
)
r1 setColor(1,0,0,1)
r2 := RectangleMorph clone do(
	id := "rect2"; x := 120; y := 30; width := 60; height := 60
)
r2 setColor(0,0,1,1)
w addMorph(r1)
w addMorph(r2)

Telos walBegin("frame")
// Mutate
r1 moveTo(50, 40)
r1 setColor(0,1,0,1)
r2 resizeTo(100, 40)
Telos walEnd("frame")

Telos draw
snapA := Telos captureScreenshot
"-- Snapshot A --" println
snapA println

// Reset world
Telos world := nil
ww := Telos createWorld
// Recreate rects with same ids (blank state)
r1b := RectangleMorph clone do(id := "rect1")
r2b := RectangleMorph clone do(id := "rect2")
ww addMorph(r1b)
ww addMorph(r2b)

// Replay from WAL
Telos replayWal("telos.wal")

Telos draw
snapB := Telos captureScreenshot
"-- Snapshot B (after replay) --" println
snapB println

"Morphic WAL replay smoke completed" println
