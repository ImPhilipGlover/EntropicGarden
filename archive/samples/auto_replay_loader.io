// Auto-replay loader demo: createWorld with autoReplay true reconstructs morphs from WAL
Telos init
Telos autoReplay := true
world := Telos createWorld

// Should reconstruct morphs by reading SET <id>.type lines then applying state
writeln("-- Auto-Replay Snapshot --")
writeln(Telos captureScreenshot)

"Auto-replay loader demo done" println
