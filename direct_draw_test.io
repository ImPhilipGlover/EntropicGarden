// TelOS Direct Drawing Test
// Test the C-level drawing functions directly

writeln("Testing direct C-level drawing...")

// Create SDL2 window 
Telos openWindow("Direct Drawing Test", 800, 600)
Telos createWorld

// Test direct drawing calls
writeln("Testing Telos_rawDrawRect...")

// Draw 6 colored rectangles directly using C functions
colors := list(
    list(1.0, 0.0, 0.0, 1.0),  // Red
    list(0.0, 1.0, 0.0, 1.0),  // Green  
    list(0.0, 0.0, 1.0, 1.0),  // Blue
    list(1.0, 1.0, 0.0, 1.0),  // Yellow
    list(1.0, 0.0, 1.0, 1.0),  // Magenta
    list(0.0, 1.0, 1.0, 1.0)   // Cyan
)

positions := list(
    list(50, 50, 150, 100),     // Red
    list(300, 50, 150, 100),    // Green
    list(550, 50, 150, 100),    // Blue
    list(150, 250, 150, 100),   // Yellow
    list(400, 250, 150, 100),   // Magenta
    list(300, 400, 150, 100)    // Cyan
)

colors foreach(i, colorValues,
    pos := positions at(i)
    x := pos at(0)
    y := pos at(1) 
    w := pos at(2)
    h := pos at(3)
    r := colorValues at(0)
    g := colorValues at(1) 
    b := colorValues at(2)
    a := colorValues at(3)
    
    // Call C function directly
    Telos Telos_rawDrawRect(x, y, w, h, r, g, b, a)
    writeln("Drew rectangle " .. i .. " at (" .. x .. "," .. y .. ") size " .. w .. "x" .. h)
)

// Present the frame
writeln("Presenting frame...")
Telos Telos_rawPresent
writeln("Frame presented")

writeln("Displaying for 5 seconds...")
Telos displayFor(5)

writeln("Direct drawing test complete!")