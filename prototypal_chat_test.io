#!/usr/bin/env io

writeln("=== Prototypal ChatInterface Test ===")

// Test pure prototypal creation - just clone, no initialization needed
writeln("Creating world...")
Telos createWorld

writeln("Opening window...")
Telos openWindow("Prototypal Chat Test", 800, 600)

writeln("Creating ChatInterface via pure cloning...")
chatInterface := ChatInterface clone
writeln("✓ ChatInterface created: " .. chatInterface type)
writeln("  Message history size: " .. chatInterface messageHistory size)
writeln("  Has input field: " .. (chatInterface inputField != nil))
writeln("  Has send button: " .. (chatInterface sendButton != nil))
writeln("  Has messages area: " .. (chatInterface messagesArea != nil))

writeln("Adding to world...")
Telos world addMorph(chatInterface)
writeln("✓ ChatInterface added to morphic world")

writeln("Testing message functionality...")
chatInterface addMessage("Test", "Hello from prototypal system!")
writeln("✓ Message added successfully")

writeln("Testing Ollama query...")
chatInterface processCognitiveQuery("What is consciousness?")
writeln("✓ Query processed")

writeln("Running for 10 seconds to show interface...")
counter := 0
while(counter < 100,
    Telos pyEval("import time; time.sleep(0.1)")
    counter = counter + 1
    
    if(counter % 25 == 0,
        elapsed := counter / 10
        writeln("  Interface running for " .. elapsed .. " seconds...")
    )
)

Telos closeWindow
writeln("✓ Test completed successfully")

writeln("=== Prototypal Test Complete ===")