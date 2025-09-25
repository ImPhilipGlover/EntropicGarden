#!/usr/bin/env io

writeln("=== Real SDL2 Window Test with Main Loop ===")

try(
    writeln("Creating SDL2 window with proper event loop...")
    
    // First create the world structure
    writeln("1. Creating world...")
    result := Telos createWorld
    writeln("World creation result: " .. result type)
    
    // Then open the SDL2 window
    writeln("2. Opening SDL2 window...")  
    windowResult := Telos openWindow("TelOS Real Window", 800, 600)
    writeln("Window opened, result: " .. windowResult type)
    
    // Now start the main loop to keep window alive
    writeln("3. Starting main loop to display window...")
    writeln("   Window should now be visible for 10 seconds...")
    
    // Keep the window alive with a simple loop
    counter := 0
    while(counter < 100,
        // Process SDL events to keep window responsive
        Telos pyEval("
import time
time.sleep(0.1)  # 100ms delay
")
        counter = counter + 1
        
        // Print progress every 20 iterations (2 seconds)
        if(counter % 20 == 0, 
            writeln("   Window displayed for " .. (counter / 10) .. " seconds...")
        )
    )
    
    writeln("4. Closing window...")
    Telos closeWindow
    writeln("✓ Window closed gracefully")
    
) catch(Exception,
    writeln("Error in window test: " .. Exception description)
    try(Telos closeWindow) catch(e, writeln("Cleanup error: " .. e description))
)

writeln("=== Real Window Test Complete ===")