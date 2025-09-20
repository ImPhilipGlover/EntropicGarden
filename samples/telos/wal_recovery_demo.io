// WAL Recovery Demo: only complete BEGIN/END frames should be applied
// Steps:
// - Create world and two morphs; write a complete framed transaction (frame1)
// - Write a second BEGIN without END (simulate crash) with changes (frame2)
// - Reset world and replay WAL; only frame1 changes should appear

Telos init
w := Telos createWorld

// Seed two rects with stable ids
r1 := RectangleMorph clone do(setSlot("id", "rect1"); moveTo(10,10); resizeTo(40,30))
r2 := RectangleMorph clone do(setSlot("id", "rect2"); moveTo(80,20); resizeTo(50,50))
w addMorph(r1)
w addMorph(r2)

// Ensure clean WAL
File with("telos.wal") setContents("")

// Frame 1: complete transaction
Telos walCommit("frame1", Map clone do(atPut("note","good")),
    block(
        r1 moveTo(25, 35)
        r1 setColor(0,1,0,1)
        r2 resizeTo(60, 40)
    )
)

// Frame 2: start but do not end (simulate crash)
Telos walBegin("frame2", Map clone do(atPut("note","incomplete")))
r1 moveTo(200, 200) // should be ignored by replay
r2 setColor(1,0,0,1) // should be ignored
// intentionally omit: Telos walEnd("frame2")

snapA := Telos captureScreenshot
"-- Snapshot A (before reset) --" println
snapA println

// Reset world
Telos setSlot("world", nil)
w2 := Telos createWorld
// Recreate rects with same ids (blank state)
r1b := RectangleMorph clone do(setSlot("id", "rect1"))
r2b := RectangleMorph clone do(setSlot("id", "rect2"))
w2 addMorph(r1b)
w2 addMorph(r2b)

// Replay
Telos replayWal("telos.wal")

snapB := Telos captureScreenshot
"-- Snapshot B (after replay) --" println
snapB println

"-- Complete Frames --" println
Telos walListCompleteFrames("telos.wal") foreach(m, writeln("tag=", m at("tag"), " setCount=", m at("setCount")))

"WAL recovery demo completed" println
