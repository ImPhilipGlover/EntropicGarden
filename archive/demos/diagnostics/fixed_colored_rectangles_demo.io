// TelOS Morphic Fixed Colored Rectangles Demo
// Using the CORRECT Morph architecture with bounds/color objects

writeln("TelOS Morphic: Creating FIXED colored rectangles demo...")

// First, ensure Telos is properly initialized
writeln("Initializing TelOS system...")
Telos loadModulesIfNeeded

// Create the SDL2 window
writeln("Opening SDL2 window...")
Telos openWindow("Fixed Colored Rectangles", 800, 600)

// Create the MorphicWorld 
writeln("Creating MorphicWorld...")
Telos createWorld
world := Telos

// Define colors as proper RGBA values (0.0-1.0 range)
colors := list(
    list(1.0, 0.0, 0.0, 1.0),  // Red
    list(0.0, 1.0, 0.0, 1.0),  // Green  
    list(0.0, 0.0, 1.0, 1.0),  // Blue
    list(1.0, 1.0, 0.0, 1.0),  // Yellow
    list(1.0, 0.0, 1.0, 1.0),  // Magenta
    list(0.0, 1.0, 1.0, 1.0)   // Cyan
)

// Create rectangles with PROPER Morph architecture
rectangles := list()

// Grid positions
xPositions := list(50, 300, 550)
yPositions := list(50, 350)

colorIndex := 0
yPositions foreach(y,
    xPositions foreach(x,
        if(colorIndex < colors size,
            // Create a morph with proper bounds and color OBJECTS
            rect := Morph clone do(
                // Create bounds object with x, y, width, height properties
                bounds := Object clone do(
                    x := x
                    y := y  
                    width := 200
                    height := 120
                )
                
                // Create color object with r, g, b, a properties
                color := Object clone do(
                    colorValues := colors at(colorIndex)
                    r := colorValues at(0)
                    g := colorValues at(1) 
                    b := colorValues at(2)
                    a := colorValues at(3)
                )
                
                id := "rect" .. colorIndex
                type := "RectangleMorph"
            )
            
            // Add the morph to the world's submorphs list
            world submorphs := world submorphs ifNilEval(List clone)
            world submorphs append(rect)
            
            rectangles append(rect)
            writeln("Created rectangle " .. colorIndex .. " at (" .. x .. "," .. y .. ") with color RGBA(" .. 
                   colors at(colorIndex) at(0) .. "," .. colors at(colorIndex) at(1) .. "," .. 
                   colors at(colorIndex) at(2) .. "," .. colors at(colorIndex) at(3) .. ")")
            
            colorIndex = colorIndex + 1
        )
    )
)

writeln("Added " .. rectangles size .. " rectangles to world")
writeln("World submorphs count: " .. world submorphs size)

// Display the window with morphs
writeln("Drawing world with morphs...")
Telos drawWorld

writeln("Starting display loop for 10 seconds...")
Telos displayFor(10)

writeln("Fixed demo complete!")