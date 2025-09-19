/*
   IoTelosUI.io - Morphic UI Framework for TelOS
   Living, directly manipulable interface objects
   */

TelosUI := Object clone do(

    // Initialize the Morphic world - the living canvas
    init := method(
        self world := nil
        self morphs := List clone
    )

    // Create the root world (Morphic's World)
    createWorld := method(
        TelosUI_rawCreateWorld
        world = TelosUI_rawCreateWorld
        writeln("TelosUI: Morphic World initialized - living canvas ready")
        world
    )

    // Start the main event loop - the heart of the living interface
    mainLoop := method(
        if(world == nil, return "TelosUI: No world exists - call createWorld first")
        writeln("TelosUI: Starting Morphic main loop (direct manipulation active)")
        TelosUI_rawMainLoop
        "TelosUI: Main loop completed"
    )

    // Create a new morph - a living visual object
    createMorph := method(
        morph := TelosUI_rawCreateMorph
        morph submorphs := List clone
        morphs append(morph)
        writeln("TelosUI: Living morph created and added to ecosystem")
        morph
    )

    // Add a submorph to build the living hierarchy
    addSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "TelosUI: Invalid morphs")
        TelosUI_rawAddSubmorph(parent, child)
        parent submorphs append(child)
        "TelosUI: Morph added to living hierarchy"
    )

    // Remove a submorph from the living hierarchy
    removeSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "TelosUI: Invalid morphs")
        TelosUI_rawRemoveSubmorph(parent, child)
        parent submorphs remove(child)
        "TelosUI: Morph removed from living hierarchy"
    )

    // Draw the world and all living morphs
    draw := method(
        if(world == nil, return "TelosUI: No world to draw")
        TelosUI_rawDraw
        "TelosUI: World rendered"
    )

    // Handle direct manipulation events
    handleEvent := method(event,
        TelosUI_rawHandleEvent(event)
        "TelosUI: Event processed through living interface"
    )
)

// Morph prototype - the fundamental living interface object
Morph := Object clone do(

    // Initialize a morph with living properties
    init := method(
        self x := 100
        self y := 100
        self width := 50
        self height := 50
        self color := list(1, 0, 0, 1)  // Red by default
        self submorphs := List clone
        self owner := nil
    )

    // Move the morph (direct manipulation)
    moveTo := method(newX, newY,
        self x = newX
        self y = newY
        "TelosUI: Morph moved to living position"
    )

    // Resize the morph (direct manipulation)
    resizeTo := method(newWidth, newHeight,
        self width = newWidth
        self height = newHeight
        "TelosUI: Morph resized in living space"
    )

    // Change color (direct manipulation)
    setColor := method(r, g, b, a := 1,
        self color = list(r, g, b, a)
        "TelosUI: Morph color changed in living palette"
    )

    // Check if point is inside morph bounds
    containsPoint := method(px, py,
        (px >= x and px <= (x + width)) and (py >= y and py <= (y + height))
    )

    // Add a submorph to this morph
    addMorph := method(child,
        child owner = self
        submorphs append(child)
        TelosUI addSubmorph(self, child)
    )

    // Remove a submorph
    removeMorph := method(child,
        submorphs remove(child)
        child owner = nil
        TelosUI removeSubmorph(self, child)
    )

    // Draw this morph and all submorphs
    drawOn := method(canvas,
        // Draw self
        self draw

        // Draw all submorphs
        submorphs foreach(morph, morph drawOn(canvas))
    )

    // Handle events (direct manipulation)
    handleEvent := method(event,
        // Check if event is for this morph
        if(self containsPoint(event x, event y),
            self processEvent(event)
            true,  // Event handled
            false  // Event not for this morph
        )
    )

    // Process event (specialize in living clones)
    processEvent := method(event,
        // Default: do nothing, let submorphs handle
        submorphs foreach(morph,
            if(morph handleEvent(event), return true)
        )
        false
    )
)

// Rectangle morph - basic shape
RectangleMorph := Morph clone do(
    draw := method(
        writeln("TelosUI: Drawing rectangle at (", x, ",", y, ") size ", width, "x", height)
    )
)

// Circle morph - another basic shape
CircleMorph := Morph clone do(
    draw := method(
        radius := width / 2
        centerX := x + radius
        centerY := y + radius
        writeln("TelosUI: Drawing circle at (", centerX, ",", centerY, ") radius ", radius)
    )
)

// Text morph - for displaying text
TextMorph := Morph clone do(
    init := method(
        resend
        self text := "Hello TelOS"
        self fontSize := 12
    )

    draw := method(
        writeln("TelosUI: Drawing text '", text, "' at (", x, ",", y, ") size ", fontSize)
    )

    setText := method(newText,
        self text = newText
        "TelosUI: Text morph updated with living message"
    )
)

writeln("TelosUI: Morphic framework loaded - living interface ready for direct manipulation")