// WAL rotation demo: create a big wal then rotate
Telos init
w := Telos createWorld

// Write many entries to grow wal
Telos walBegin("frame")
for(i, 1, 500,
    Telos transactional_setSlot(Telos, "demo.key" .. i, "value" .. i)
)
Telos walEnd("frame")

// Check size and rotate at a small threshold for demo
rot := Telos rotateWal("telos.wal", 4096)
writeln("rotation result: " .. rot)
