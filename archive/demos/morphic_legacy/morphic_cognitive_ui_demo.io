#!/usr/local/bin/io

// Simple TelOS Morphic Text Input Demo
// Demonstrates functional text input field with rendering

writeln("==========================================")
writeln("TelOS Morphic Text Input Demo")
writeln("==========================================")

// Initialize TelOS system
Telos initializeFullSystem

// Create a Morphic world with SDL2 window
world := MorphicWorld clone initialize(800, 600)
world title := "TelOS Text Input Demo"

// Create a prominent text input field
textInput := TextInputMorph clone initialize(100, 200, 600)
textInput placeholder := "Type here..."
textInput setText("")

// Create a status label
statusLabel := TextMorph clone initialize("Status: Ready", 100, 150)

// Add morphs to world
world addMorph(textInput)
world addMorph(statusLabel)

// Set this as the active Telos world for event dispatching
Telos world := world

// Demo: Simulate typing "Hello World" character by character
writeln("Starting TelOS Morphic Text Input Demo...")
writeln("Watch the text field as we simulate typing 'Hello World'")

// Simulate typing animation
helloWorld := "Hello World"
for(i, 0, helloWorld size - 1,
    char := helloWorld exSlice(i, i+1)
    textInput appendText(char)
    statusLabel setText("Typing: " .. textInput text)
    
    // Brief pause for animation effect
    System sleep(0.2)
)// Final status
statusLabel setText("Completed: " .. textInput text)
writeln("Text input demo completed successfully!")
writeln("The text field should show: " .. textInput text)

// Keep window open for a few seconds to see the result
world displayFor := method(seconds,
    writeln("Displaying for " .. seconds .. " seconds...")
    System sleep(seconds)
    self
)
world displayFor(3)

writeln("TelOS Morphic Text Input Demo completed")