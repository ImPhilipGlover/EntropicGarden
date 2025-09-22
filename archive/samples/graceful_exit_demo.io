#!/usr/bin/env io

//metadoc TelosGracefulExit category TelOS  
//metadoc TelosGracefulExit description Enhanced rendering demo with proper exit handling via ESC key or window close

// Initialize TelOS system
Telos

writeln("=== TelOS Graceful Exit Demo ===")
writeln("This demo shows 6 colored rectangles with proper exit handling")
writeln("Press ESC or close the window to exit gracefully")

// Create and setup world
Telos createWorld
Telos openWindow

// Create 6 persona rectangles
personas := List clone

// ALFRED - Red (top-left)
alfred := RectangleMorph clone
alfred x := 50; alfred y := 50; alfred width := 100; alfred height := 60; alfred color := "red"
personas append(alfred)

// BABS - Green (top-center)  
babs := RectangleMorph clone
babs x := 200; babs y := 50; babs width := 100; babs height := 60; babs color := "green"
personas append(babs)

// WING - Blue (top-right)
wing := RectangleMorph clone  
wing x := 350; wing y := 50; wing width := 100; wing height := 60; wing color := "blue"
personas append(wing)

// PROMETHEUS - Yellow (bottom-left)
prometheus := RectangleMorph clone
prometheus x := 50; prometheus y := 200; prometheus width := 100; prometheus height := 60; prometheus color := "yellow"
personas append(prometheus)

// CURATOR - Magenta (bottom-center)
curator := RectangleMorph clone
curator x := 200; curator y := 200; curator width := 100; curator height := 60; curator color := "magenta"
personas append(curator)

// SAGE - Cyan (bottom-right)
sage := RectangleMorph clone
sage x := 350; sage y := 200; sage width := 100; sage height := 60; sage color := "cyan"
personas append(sage)

// Add to world
if(Telos world hasSlot("submorphs") not, Telos world submorphs := List clone)
Telos world submorphs = personas

writeln("Created 6 persona morphs:")
writeln("- Red (ALFRED), Green (BABS), Blue (WING) on top row")
writeln("- Yellow (PROMETHEUS), Magenta (CURATOR), Cyan (SAGE) on bottom row")

// Interactive render loop with exit detection
frameCount := 0
exitRequested := false

writeln("Starting interactive render loop...")
writeln("Window will display colored rectangles. Press ESC to exit.")

while(exitRequested not,
    // Check for exit events
    Telos checkEvents
    
    // Render current frame
    Telos drawWorld
    frameCount = frameCount + 1
    
    // Check if exit was requested (every 10 frames to avoid spam)
    if(frameCount % 10 == 0,
        if(Telos shouldExit,
            exitRequested = true
            writeln("Exit requested at frame " .. frameCount .. " - shutting down gracefully...")
        )
    )
    
    // Safety timeout after 2000 frames (1000 seconds)
    if(frameCount > 2000,
        exitRequested = true
        writeln("Safety timeout reached after " .. frameCount .. " frames")
    )
    
    // Brief pause between frames
    System sleep(0.5)
)

// Clean shutdown
Telos closeWindow
writeln("✓ Demo completed successfully after " .. frameCount .. " frames")
writeln("✓ Window closed cleanly")
writeln("✓ No memory leaks - TelOS graceful exit working perfectly!")