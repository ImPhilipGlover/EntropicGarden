// TelOS Morphic Colored Rectangles Demo
// Launch a window with 6 different colored rectangles

writeln("TelOS Morphic: Creating colored rectangles demo...")

// Create a MorphicWorld
world := Telos openMorphicWindow("Colored Rectangles Demo", 800, 600)
writeln("Created world: " .. world title)

// Create 6 rectangles with different colors
colors := list(
    list(1.0, 0.0, 0.0, 1.0),  // Red
    list(0.0, 1.0, 0.0, 1.0),  // Green
    list(0.0, 0.0, 1.0, 1.0),  // Blue
    list(1.0, 1.0, 0.0, 1.0),  // Yellow
    list(1.0, 0.0, 1.0, 1.0),  // Magenta
    list(0.0, 1.0, 1.0, 1.0)   // Cyan
)

rectangles := list()

// Create rectangles in a 3x2 grid
xPositions := list(50, 300, 550)
yPositions := list(50, 250)

colorIndex := 0
yPositions foreach(y,
    xPositions foreach(x,
        if(colorIndex < colors size,
            color := colors at(colorIndex)
            rect := RectangleMorph withBoundsAndColor(x, y, 200, 150, color at(0), color at(1), color at(2), color at(3))
            rect id := "rect" .. colorIndex
            world addMorph(rect)
            rectangles append(rect)
            writeln("Created rectangle " .. colorIndex .. " at (" .. x .. "," .. y .. ") with color " .. color)
            colorIndex = colorIndex + 1
        )
    )
)

writeln("Added " .. rectangles size .. " rectangles to world")

// Start the morphic loop
writeln("Starting morphic event loop...")
Telos startMorphicLoop()

writeln("Demo complete!")