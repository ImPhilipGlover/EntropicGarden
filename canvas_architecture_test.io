// TelOS Morphic Canvas Architecture Test
// Test the fixed Canvas-based Morphic rendering with proper delegation

writeln("Testing Canvas-based Morphic architecture...")

// Create SDL2 window and world
Telos openWindow("Canvas Architecture Test", 800, 600)
Telos createWorld

// Get the world object
world := Telos world
writeln("Got world: " .. world type .. " with id: " .. world id)

// Create 6 colored rectangles following proper Morphic architecture
colors := list(
    list(1.0, 0.0, 0.0, 1.0),  // Red
    list(0.0, 1.0, 0.0, 1.0),  // Green
    list(0.0, 0.0, 1.0, 1.0),  // Blue
    list(1.0, 1.0, 0.0, 1.0),  // Yellow
    list(1.0, 0.0, 1.0, 1.0),  // Magenta
    list(0.0, 1.0, 1.0, 1.0)   // Cyan
)

positions := list(
    list(50, 50),     // Red
    list(300, 50),    // Green
    list(550, 50),    // Blue
    list(150, 250),   // Yellow
    list(400, 250),   // Magenta
    list(300, 400)    // Cyan
)

writeln("Creating 6 colored rectangles with proper object architecture...")

rectangles := list()
colors foreach(i, colorValues,
    pos := positions at(i)
    rect := RectangleMorph clone do(
        // bounds as object with x, y, width, height properties
        bounds := Object clone do(
            x := pos at(0)
            y := pos at(1)
            width := 150
            height := 100
        )
        
        // color as object with r, g, b, a properties
        color := Object clone do(
            r := colorValues at(0)
            g := colorValues at(1)
            b := colorValues at(2)
            a := colorValues at(3)
        )
        
        id := "rect_" .. i
    )
    
    world submorphs append(rect)
    rectangles append(rect)
    writeln("Created " .. rect id .. " at (" .. rect bounds x .. "," .. rect bounds y .. ") with color (" .. 
           rect color r .. "," .. rect color g .. "," .. rect color b .. ")")
)

writeln("Added " .. rectangles size .. " rectangles to world")
writeln("World submorphs count: " .. world submorphs size)

// Test the Canvas-based drawing architecture
writeln("Testing Canvas-based drawing...")
Telos drawWorld

writeln("Displaying for 10 seconds...")
Telos displayFor(10)

writeln("Canvas architecture test complete!")