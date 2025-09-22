// WAL Export Demo: Create framed interactions, then export frames to JSON
// 1) Initialize and perform a few framed operations
Telos init
Telos walCommit("demo.frame1", Map clone atPut("note","first"), block(
    r := Lobby getSlot("RectangleMorph") clone
    r moveTo(10, 20)
    r resizeTo(80, 40)
    Telos addSubmorph(Telos world ifNil(Telos createWorld), r)
))
Telos walCommit("demo.frame2", Map clone atPut("note","second"), block(
    t := Lobby getSlot("TextMorph") clone
    t moveTo(15, 15)
    t setText("Hello WAL")
    Telos addSubmorph(Telos world, t)
))

// 2) Export complete frames to JSON under logs
out := Telos commands run("wal.export.json", list("logs/wal_frames.json", "telos.wal"))
writeln("Exported frames to: ", out)

// 3) Touch FFI seam briefly
ver := Telos getPythonVersion
writeln("Python: ", ver)
