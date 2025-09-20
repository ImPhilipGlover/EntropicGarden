/*
   IoTelos.io - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

Telos := Object clone do(

    // Initialize the TelOS zygote - the computational embryo
    init := method(
        self world := nil
        self morphs := List clone
    )

    // Pillar 1: Synaptic Bridge - Reach into Python muscle
    getPythonVersion := method(
        Telos_rawGetPythonVersion
    )

    // Pillar 2: First Heartbeat - Transactional persistence
    transactional_setSlot := method(target, slotName, value,
        Telos_rawTransactional_setSlot(target, slotName, value)
    )

    // Pillar 3: First Glance - UI window stub
    openWindow := method(
        Telos_rawOpenWindow
    )

    // Create the root world (Morphic's World)
    createWorld := method(
        Telos_rawCreateWorld
        world = Telos_rawCreateWorld
        writeln("Telos: Morphic World initialized - living canvas ready")
        world
    )

    // Start the main event loop - the heart of the living interface
    mainLoop := method(
        if(world == nil, return "Telos: No world exists - call createWorld first")
        writeln("Telos: Starting Morphic main loop (direct manipulation active)")
        Telos_rawMainLoop
        "Telos: Main loop completed"
    )

    // Create a new morph - a living visual object
    createMorph := method(
        morph := Telos_rawCreateMorph
        morph submorphs := List clone
        morphs append(morph)
        writeln("Telos: Living morph created and added to ecosystem")
        morph
    )

    // Add a submorph to build the living hierarchy
    addSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        Telos_rawAddSubmorph(parent, child)
        parent submorphs append(child)
        "Telos: Morph added to living hierarchy"
    )

    // Remove a submorph from the living hierarchy
    removeSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        Telos_rawRemoveSubmorph(parent, child)
        parent submorphs remove(child)
        "Telos: Morph removed from living hierarchy"
    )

    // Draw the world and all living morphs
    draw := method(
        if(world == nil, return "Telos: No world to draw")
        Telos_rawDraw
        "Telos: World rendered"
    )

    // Handle direct manipulation events
    handleEvent := method(event,
        Telos_rawHandleEvent(event)
        "Telos: Event processed through living interface"
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
        "Telos: Morph moved to living position"
    )

    // Resize the morph (direct manipulation)
    resizeTo := method(newWidth, newHeight,
        self width = newWidth
        self height = newHeight
        "Telos: Morph resized in living space"
    )

    // Change color (direct manipulation)
    setColor := method(r, g, b, a := 1,
        self color = list(r, g, b, a)
        "Telos: Morph color changed in living palette"
    )

    // Check if point is inside morph bounds
    containsPoint := method(px, py,
        (px >= x and px <= (x + width)) and (py >= y and py <= (y + height))
    )

    // Add a submorph to this morph
    addMorph := method(child,
        child owner = self
        submorphs append(child)
        Telos addSubmorph(self, child)
    )

    // Remove a submorph
    removeMorph := method(child,
        submorphs remove(child)
        child owner = nil
        Telos removeSubmorph(self, child)
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
        writeln("Telos: Drawing rectangle at (", x, ",", y, ") size ", width, "x", height)
    )
)

// Circle morph - another basic shape
CircleMorph := Morph clone do(
    draw := method(
        radius := width / 2
        centerX := x + radius
        centerY := y + radius
        writeln("Telos: Drawing circle at (", centerX, ",", centerY, ") radius ", radius)
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
        writeln("Telos: Drawing text '", text, "' at (", x, ",", y, ") size ", fontSize)
    )

    setText := method(newText,
        self text = newText
        "Telos: Text morph updated with living message"
    )
)

writeln("Telos: Zygote pillars loaded - mind touches muscle, heartbeat begins, first glance opens")