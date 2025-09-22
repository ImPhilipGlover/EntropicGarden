writeln("TelOS Vertical Slice Replay: starting")

doFile("libs/Telos/io/TelosCore.io")

// Attempt to replay WAL and show state
applied := Telos replayWal
appliedStr := if(applied == nil, "nil", applied asString)
writeln("WAL replay applied operations: " .. appliedStr)

// Load snapshot if exists
_ := Telos loadSnapshot("logs/world_snapshot.json")

// Show Morphic world briefly
Telos createWorld
Telos openWindow
Telos refresh
Telos displayFor(1)

writeln("TelOS Vertical Slice Replay: complete")
