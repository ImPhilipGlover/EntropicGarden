// TelOS Morphic Simple Fixed Demo
// Test the corrected Morph architecture

writeln("TelOS Morphic: Simple fixed demo starting...")

// Create SDL2 window
writeln("Opening window...")
Telos openWindow("Fixed Demo", 800, 600)

// Create world
writeln("Creating world...")
Telos createWorld

// Create a single rectangle with proper object structure
writeln("Creating test rectangle with proper bounds and color objects...")
testRect := Morph clone do(
    // CRITICAL: bounds must be an OBJECT with x, y, width, height properties
    bounds := Object clone do(
        x := 100
        y := 100
        width := 200
        height := 150
    )
    
    // CRITICAL: color must be an OBJECT with r, g, b, a properties (0.0-1.0 range)
    color := Object clone do(
        r := 1.0  // Red
        g := 0.0
        b := 0.0
        a := 1.0
    )
    
    id := "test-rect"
    type := "RectangleMorph"
)

// Add to world submorphs
if(Telos submorphs == nil, Telos submorphs := List clone)
Telos submorphs append(testRect)

writeln("Test rectangle created and added to world")
writeln("Rectangle bounds: x=" .. testRect bounds x .. " y=" .. testRect bounds y .. 
        " width=" .. testRect bounds width .. " height=" .. testRect bounds height)
writeln("Rectangle color: r=" .. testRect color r .. " g=" .. testRect color g .. 
        " b=" .. testRect color b .. " a=" .. testRect color a)
writeln("World submorphs count: " .. Telos submorphs size)

// Draw and display
writeln("Drawing world...")
Telos drawWorld

writeln("Starting display loop for 5 seconds...")
Telos displayFor(5)

writeln("Simple fixed demo complete!")