// TelOS Morphic Working Rectangles Demo
// Using the correct world access pattern

writeln("TelOS Morphic: Working rectangles demo...")

// Create SDL2 window and world
Telos openWindow("Working Rectangles Demo", 800, 600)
Telos createWorld

// Get the world object correctly
world := Telos world
writeln("Got world: " .. world type .. " with id: " .. world id)

// Check if world has submorphs slot, if not create it
if(world submorphs == nil,
    world submorphs := List clone
    writeln("Created submorphs list on world")
,
    writeln("World already has submorphs: " .. world submorphs size)
)

// Create a red rectangle with proper object architecture
redRect := Morph clone do(
    // bounds as object with x, y, width, height properties
    bounds := Object clone do(
        x := 100
        y := 100  
        width := 200
        height := 150
    )
    
    // color as object with r, g, b, a properties
    color := Object clone do(
        r := 1.0  // Red
        g := 0.0
        b := 0.0
        a := 1.0  // Opaque
    )
    
    id := "red-rectangle"
    type := "RectangleMorph"
)

// Create a green rectangle
greenRect := Morph clone do(
    bounds := Object clone do(
        x := 350
        y := 100
        width := 200
        height := 150
    )
    
    color := Object clone do(
        r := 0.0
        g := 1.0  // Green
        b := 0.0
        a := 1.0
    )
    
    id := "green-rectangle"
    type := "RectangleMorph"
)

// Create a blue rectangle
blueRect := Morph clone do(
    bounds := Object clone do(
        x := 225
        y := 300
        width := 200
        height := 150
    )
    
    color := Object clone do(
        r := 0.0
        g := 0.0
        b := 1.0  // Blue
        a := 1.0
    )
    
    id := "blue-rectangle"
    type := "RectangleMorph"
)

// Add rectangles to world
world submorphs append(redRect)
world submorphs append(greenRect)
world submorphs append(blueRect)

writeln("Added 3 rectangles to world submorphs")
writeln("World now has " .. world submorphs size .. " submorphs")

// Verify the rectangles have correct structure
world submorphs foreach(i, morph,
    writeln("Morph " .. i .. ": id=" .. morph id .. 
            " bounds=(" .. morph bounds x .. "," .. morph bounds y .. "," .. 
                         morph bounds width .. "," .. morph bounds height .. ")" ..
            " color=(" .. morph color r .. "," .. morph color g .. "," .. 
                        morph color b .. "," .. morph color a .. ")")
)

// Draw the world
writeln("Drawing world with rectangles...")
Telos drawWorld

// Display for 8 seconds
writeln("Displaying for 8 seconds...")
Telos displayFor(8)

writeln("Demo complete!")