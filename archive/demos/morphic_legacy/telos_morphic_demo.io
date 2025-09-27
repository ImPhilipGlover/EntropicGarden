#!/usr/bin/env io

/*
   TelOS Morphic Interactive Demo
   Demonstrates the complete Morphic UI system with live interaction
   
   This script demonstrates:
   1. Real SDL2 window creation and management
   2. Interactive morphs with mouse event handling
   3. Live object manipulation and state changes
   4. Proper prototypal architecture with message passing
*/

writeln("=== TelOS MORPHIC INTERACTIVE DEMO ===")
writeln("Initializing TelOS Living Image system...")

// Load TelOS core system first
doFile("libs/Telos/io/TelosCore.io")

writeln("Creating Morphic World with interactive objects...")

// Create the world - this calls real SDL2 C code
Telos createWorld
Telos openWindow

writeln("World created successfully. Adding interactive morphs...")

// Create an interactive button that changes color when clicked
InteractiveButton := Morph clone do(
    type := "InteractiveButton"
    label := "Click Me!"
    isPressed := false
    
    // Initialize with specific bounds and color
    bounds setPosition(150, 100)
    bounds setSize(120, 60)
    color setColor(0.2, 0.6, 0.9, 1.0)  // Blue button
    
    // Override mouse down to show visual feedback
    leftMouseDown := method(event,
        writeln("InteractiveButton: Mouse down - changing to pressed state")
        self isPressed = true
        self color setColor(0.9, 0.2, 0.2, 1.0)  // Red when pressed
        
        // Log the interaction
        if(Telos hasSlot("walAppend"),
            logEntry := "BUTTON_PRESS {\"label\":\"" .. self label .. "\",\"time\":\"" .. Date now .. "\"}"
            Telos walAppend(logEntry)
        )
        
        self
    )
    
    // Override mouse up to return to normal state
    leftMouseUp := method(event,
        writeln("InteractiveButton: Mouse up - returning to normal state")
        self isPressed = false
        self color setColor(0.2, 0.6, 0.9, 1.0)  // Back to blue
        
        // Trigger button action
        writeln("InteractiveButton: ACTIVATED! Performing button action...")
        self performAction
        
        self
    )
    
    // Custom action method - can be overridden by clones
    performAction := method(
        writeln("InteractiveButton: Default action performed for button '" .. self label .. "'")
        
        // Example action: create a new morph in the world
        if(Telos world,
            newMorph := Morph clone
            newMorph bounds setPosition(300 + (Date now asNumber % 200), 200)
            newMorph bounds setSize(30, 30)
            newMorph color setColor(
                (Date now asNumber % 100) / 100.0,
                0.7,
                (Date now asNumber % 50) / 50.0,
                1.0
            )
            newMorph id = "generated_" .. Date now asNumber
            
            Telos addMorph(newMorph)
            writeln("InteractiveButton: Created new morph " .. newMorph id)
        )
        
        self
    )
)

// Create a draggable morph
DraggableMorph := Morph clone do(
    type := "DraggableMorph"
    isDragging := false
    dragStartX := 0
    dragStartY := 0
    
    // Initialize with distinctive appearance
    bounds setPosition(400, 150)
    bounds setSize(80, 80)
    color setColor(0.9, 0.7, 0.2, 1.0)  // Yellow/orange
    
    leftMouseDown := method(event,
        writeln("DraggableMorph: Starting drag at (" .. event x .. "," .. event y .. ")")
        self isDragging = true
        self dragStartX = event x - self bounds x
        self dragStartY = event y - self bounds y
        self color setColor(0.9, 0.9, 0.2, 1.0)  // Bright yellow when dragging
        self
    )
    
    leftMouseUp := method(event,
        if(self isDragging,
            writeln("DraggableMorph: Ending drag at (" .. event x .. "," .. event y .. ")")
            self isDragging = false
            self color setColor(0.9, 0.7, 0.2, 1.0)  // Back to orange
        )
        self
    )
    
    mouseMoved := method(event,
        if(self isDragging,
            newX := event x - self dragStartX
            newY := event y - self dragStartY
            writeln("DraggableMorph: Dragging to (" .. newX .. "," .. newY .. ")")
            self bounds setPosition(newX, newY)
        )
        self
    )
)

// Create a color-changing morph that cycles through colors
ColorCyclerMorph := Morph clone do(
    type := "ColorCyclerMorph"
    colorIndex := 0
    colors := list(
        list(1.0, 0.0, 0.0),  // Red
        list(0.0, 1.0, 0.0),  // Green
        list(0.0, 0.0, 1.0),  // Blue
        list(1.0, 1.0, 0.0),  // Yellow
        list(1.0, 0.0, 1.0),  // Magenta
        list(0.0, 1.0, 1.0)   // Cyan
    )
    
    bounds setPosition(50, 300)
    bounds setSize(100, 50)
    
    leftMouseDown := method(event,
        writeln("ColorCyclerMorph: Cycling color...")
        self colorIndex = (self colorIndex + 1) % self colors size
        currentColor := self colors at(self colorIndex)
        self color setColor(currentColor at(0), currentColor at(1), currentColor at(2), 1.0)
        
        colorName := "Color" .. self colorIndex
        writeln("ColorCyclerMorph: Changed to " .. colorName)
        self
    )
)

// Add all morphs to the world
writeln("Adding interactive morphs to world...")
Telos addMorph(InteractiveButton)
Telos addMorph(DraggableMorph)
Telos addMorph(ColorCyclerMorph)

// Add a title morph with text
TitleMorph := Morph clone do(
    type := "TitleMorph"
    text := "TelOS Living Image - Interactive Morphic Demo"
    
    bounds setPosition(50, 20)
    bounds setSize(500, 40)
    color setColor(0.1, 0.1, 0.2, 1.0)  // Dark background for text
    
    // Override drawing to include text
    drawSelfOn := method(canvas,
        // Draw background first
        canvas fillRectangle(bounds, color)
        
        // Draw text on top (if Canvas supports text rendering)
        if(canvas hasSlot("drawText"),
            textColor := Color white
            canvas drawText(self text, bounds, textColor)
        )
        self
    )
)

Telos addMorph(TitleMorph)

// Create instruction text
InstructionMorph := Morph clone do(
    type := "InstructionMorph"
    text := "Click blue button to create morphs. Drag yellow morph. Click small morph to change color."
    
    bounds setPosition(50, 400)
    bounds setSize(600, 30)
    color setColor(0.9, 0.9, 0.9, 1.0)  // Light gray background
    
    drawSelfOn := method(canvas,
        canvas fillRectangle(bounds, color)
        if(canvas hasSlot("drawText"),
            textColor := Color black
            canvas drawText(self text, bounds, textColor)
        )
        self
    )
)

Telos addMorph(InstructionMorph)

writeln("Morphic world setup complete. Interactive elements:")
writeln("• Blue Button (150,100): Click to create new morphs")
writeln("• Yellow Draggable (400,150): Click and drag to move")
writeln("• Color Cycler (50,300): Click to cycle through colors")

writeln("\nStarting interactive display...")
writeln("Window should open with interactive morphs.")
writeln("Press ESC or close window to exit.")

// Start the interactive display loop
// Using displayFor with 0 for perpetual mode (until user closes)
Telos displayFor(0)

writeln("\nDemo completed successfully!")
writeln("All morphs demonstrated live prototypal behavior with real SDL2 interaction.")