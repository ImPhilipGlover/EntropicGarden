// Simple layout demo using RowLayout and ColumnLayout
Telos init
world := Telos createWorld

// Create some rectangles
r1 := RectangleMorph clone; r1 resizeTo(60,40); Telos addSubmorph(world, r1)
r2 := RectangleMorph clone; r2 resizeTo(50,50); r2 setColor(0,1,0,1); Telos addSubmorph(world, r2)
r3 := RectangleMorph clone; r3 resizeTo(40,60); r3 setColor(0.8,0.3,0.3,1); Telos addSubmorph(world, r3)

// Apply a row layout to the world
RowLayout apply(world)

Telos draw
writeln(Telos captureScreenshot)

writeln("DONE")
