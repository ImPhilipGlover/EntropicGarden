// Simple RectangleMorph Test
// Test basic RectangleMorph objects work, bypassing complex Canvas architecture

writeln("Testing RectangleMorph objects...")

// Create window first
Telos openWindow("RectangleMorph Test", 800, 600)  
Telos createWorld
world := Telos world

// Test creating RectangleMorph objects
writeln("Testing RectangleMorph creation...")

// Check if RectangleMorph is available
if(Lobby hasSlot("RectangleMorph"),
    writeln("✓ RectangleMorph prototype is available")
    
    rect1 := RectangleMorph clone do(
        bounds := Object clone do(
            x := 100
            y := 100
            width := 200
            height := 150
        )
        color := Object clone do(
            r := 1.0
            g := 0.0
            b := 0.0  
            a := 1.0
        )
        id := "test_rect"
    )
    
    writeln("✓ Created RectangleMorph: " .. rect1 type .. " with id: " .. rect1 id)
    writeln("  bounds: (" .. rect1 bounds x .. "," .. rect1 bounds y .. ") size " .. rect1 bounds width .. "x" .. rect1 bounds height)
    writeln("  color: (" .. rect1 color r .. "," .. rect1 color g .. "," .. rect1 color b .. ")")
    
    // Add to world
    world addMorph(rect1)
    writeln("✓ Added to world, world submorphs count: " .. world submorphs size)
    
    // Try drawing directly with C function
    writeln("Drawing rectangle directly with C function...")
    Telos Telos_rawDrawRect(rect1 bounds x, rect1 bounds y, rect1 bounds width, rect1 bounds height,
                           rect1 color r, rect1 color g, rect1 color b, rect1 color a)
    
    // Present frame
    Telos Telos_rawPresent
    writeln("✓ Frame presented")
    
,
    writeln("✗ RectangleMorph not available - checking what prototypes exist...")
    writeln("Available in Lobby:")
    Lobby slotNames select(name, name containsSeq("Morph") or name containsSeq("Rectangle")) foreach(println)
)

writeln("Displaying for 3 seconds...")
Telos displayFor(3)

writeln("RectangleMorph test complete!")