#!/usr/bin/env io

//=======================================================================
// TELOS REAL SDL2 WINDOW TEST
// Creates actual SDL2 window that should be visible on Windows desktop
// Tests X11 forwarding and real morphic GUI capability
//=======================================================================

writeln("=== TelOS SDL2 Window Test ===")
writeln("Creating real SDL2 window with X11 forwarding...")
writeln("")

// Ensure TelOS is initialized
if(Telos == nil,
    writeln("ERROR: TelOS not loaded. Please run from initialized Io REPL.")
    System exit(1)
)

writeln("✓ TelOS system loaded")

//=======================================================================
// CREATE AND DISPLAY SDL2 WINDOW
//=======================================================================

writeln("Creating SDL2 window...")

// Create the window
windowResult := try(
    Telos openWindow
) catch(Exception,
    writeln("ERROR creating window: " .. Exception description)
    nil
)

if(windowResult,
    writeln("✓ SDL2 window created successfully!")
    writeln("Window object: " .. windowResult type)
    
    writeln("")
    writeln("Window should now be visible on your Windows desktop.")
    writeln("Title: 'TelOS Living Image'")
    writeln("Size: 800x600")
    writeln("")
    
    // Keep window open for inspection
    writeln("Keeping window open for 10 seconds...")
    writeln("You should see a TelOS window appear on your Windows desktop.")
    
    // Simple event loop to keep window alive
    counter := 0
    while(counter < 10,
        writeln("Window display time: " .. counter .. "/10 seconds")
        System sleep(1)
        counter = counter + 1
    )
    
    writeln("")
    writeln("Test complete. Window should close automatically.")
    
,
    writeln("✗ Failed to create SDL2 window")
    writeln("Check X11 forwarding configuration")
)

//=======================================================================
// CLEANUP AND EXIT
//=======================================================================

writeln("")
writeln("=== SDL2 Window Test Complete ===")
writeln("If you saw a window appear, X11 forwarding is working!")
writeln("If not, please check:")
writeln("  1. WSLg is enabled (Windows 11 required)")  
writeln("  2. DISPLAY environment variable is set")
writeln("  3. X11 socket exists in /tmp/.X11-unix/")

System exit(0)