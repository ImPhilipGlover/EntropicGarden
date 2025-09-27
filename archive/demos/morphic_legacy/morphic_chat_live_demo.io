#!/usr/bin/env io

writeln("=== TelOS Live Morphic Chat Interface Demo ===")

try(
    writeln("Creating morphic world with SDL2 window...")
    
    // Create world and open window
    Telos createWorld
    Telos openWindow("TelOS Morphic Chat Interface", 800, 600)
    
    writeln("World and window created - now creating chat interface...")
    
    // Create the chat interface morph
    chatInterface := ChatInterface clone initialize(50, 50)
    
    // Add chat interface to world
    if(Telos world != nil,
        Telos world addMorph(chatInterface)
        writeln("✓ Chat interface added to morphic world")
        
        // Let's also add some visual elements to show the morphic system works
        testRect := RectangleMorph clone initialize(570, 100, 200, 100)
        testRect color setColor(0.2, 0.7, 0.9, 0.8)  // Blue
        Telos world addMorph(testRect)
        
        testButton := ButtonMorph clone initialize("Test Button", 580, 220)
        testButton setAction(method(
            writeln("Test button clicked!")
        ))
        Telos world addMorph(testButton)
        
        writeln("✓ Additional morphic objects added")
    ,
        writeln("✗ World not available")
    )
    
    writeln("Starting interactive loop...")
    writeln("  The window should now show the chat interface")
    writeln("  Chat interface includes input field and send button")
    writeln("  Messages will be sent to Ollama LLM")
    
    // Keep window alive with interactive loop
    counter := 0
    while(counter < 200,  // Run for 20 seconds
        // Process SDL events
        Telos pyEval("
import time
time.sleep(0.1)
")
        counter = counter + 1
        
        // Status update every 5 seconds
        if(counter % 50 == 0,
            elapsed := counter / 10
            writeln("   Chat interface running for " .. elapsed .. " seconds...")
        )
    )
    
    writeln("Closing morphic interface...")
    Telos closeWindow
    writeln("✓ Interface closed gracefully")
    
) catch(Exception,
    writeln("Error in morphic chat demo: " .. Exception type)
    try(Telos closeWindow) catch(e, writeln("Cleanup error: " .. e type))
)

writeln("=== Live Morphic Chat Demo Complete ===")