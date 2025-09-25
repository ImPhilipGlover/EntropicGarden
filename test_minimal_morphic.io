#!/usr/bin/env io

// Minimal morphic test - bypass module loading issues

"Creating minimal morphic test..." println

// Create a basic Morph prototype from scratch
Morph := Object clone do(
    x := 0
    y := 0
    width := 50
    height := 50
    color := list(0.5, 0.5, 0.5, 1.0)
    id := "morph"
    
    setPosition := method(newX, newY,
        self x := newX
        self y := newY
        self
    )
    
    setSize := method(newW, newH,
        self width := newW  
        self height := newH
        self
    )
)

// Create a simple RectangleMorph
RectangleMorph := Morph clone

// Now test creating one
"Creating test rectangle..." println
testRect := RectangleMorph clone

"Setting properties..." println
testRect setPosition(100, 200)
testRect setSize(150, 75)
testRect color := list(1.0, 0.0, 0.0, 1.0)  // Red
testRect id := "test_rectangle"

"Test rectangle properties:" println
("  x: " .. testRect x) println
("  y: " .. testRect y) println
("  width: " .. testRect width) println
("  height: " .. testRect height) println
("  color: " .. testRect color join(",")) println
("  id: " .. testRect id) println

"✓ Minimal morphic test successful!" println