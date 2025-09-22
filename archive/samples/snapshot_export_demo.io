// Export the current world snapshot to JSON and text
Telos init
world := Telos createWorld

r := RectangleMorph clone; r moveTo(20,20); r resizeTo(70,40); Telos addSubmorph(world, r)
t := TextMorph clone; t moveTo(25,80); t setText("Snapshot"); Telos addSubmorph(world, t)

Telos draw
writeln(Telos captureScreenshot)
writeln("JSON path:", Telos saveSnapshotJson)
writeln("Text path:", Telos saveSnapshot)

writeln("DONE")
