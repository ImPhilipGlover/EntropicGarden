/*
   IoTelos.io - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

Telos := Object clone do(

    // Initialize the TelOS zygote - the computational embryo
    init := method(
        self world := nil
        self morphs := List clone
        self morphIndex := Map clone
        self nextId := 1
    )

    // Pillar 1: Synaptic Bridge - Reach into Python muscle (helper)
    pythonVersion := method(
        getPythonVersion
    )

    // Pillar 2: First Heartbeat - Transactional persistence (use primitive directly)

    // Pillar 3: First Glance - UI window stub (use primitive directly)

    // Create the root world (Morphic's World) and anchor Io state
    bootWorld := method(
        createWorld
        self world = self // anchor
        writeln("Telos: Morphic World initialized - living canvas ready")
        self
    )

    // Start the main event loop - the heart of the living interface
    runMainLoop := method(
        if(world == nil, return "Telos: No world exists - call createWorld first")
        writeln("Telos: Starting Morphic main loop (direct manipulation active)")
        mainLoop
        "Telos: Main loop completed"
    )

    // Create a new morph - a living visual object
    newMorph := method(
        morph := createMorph
        morph submorphs := List clone
        // assign id
        if(morph hasSlot("id") not,
            morph id := ("m" .. nextId asString)
            nextId = nextId + 1
        )
        morphs append(morph)
        morphIndex atPut(morph id, morph)
        writeln("Telos: Living morph created and added to ecosystem as ", morph id)
        morph
    )

    // Add a submorph to build the living hierarchy
    linkSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        addSubmorph(parent, child)
        parent submorphs append(child)
        "Telos: Morph added to living hierarchy"
    )

    // Add a morph directly to the world (drawn by C loop)
    addToWorld := method(child,
        if(child == nil, return "Telos: Invalid morph")
        addMorphToWorld(child)
        morphs appendIfAbsent(child)
        if(child hasSlot("id") not,
            child id := ("m" .. nextId asString)
            nextId = nextId + 1
        )
        morphIndex atPut(child id, child)
        "Telos: Morph added to world"
    )

    // Remove a submorph from the living hierarchy
    unlinkSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        removeSubmorph(parent, child)
        parent submorphs remove(child)
        "Telos: Morph removed from living hierarchy"
    )

    // Draw the world and all living morphs
    renderWorld := method(
        if(world == nil, return "Telos: No world to draw")
        draw
        "Telos: World rendered"
    )

    // Handle direct manipulation events
    dispatchEvent := method(event,
        handleEvent(event)
        "Telos: Event processed through living interface"
    )

    // Persistence helpers
    walSet := method(id, slot, valueString,
        transactional_setSlot(self, (id .. "." .. slot) asMutable, valueString asMutable)
    )

    // Snapshot of morph specs
    captureSnapshot := method(
        writeln("Telos Snapshot:")
        morphs foreach(m,
            writeln(" - ", m id, " @(", m x, ",", m y, ") size ", m width, "x", m height, " color ", m color)
        )
        "ok"
    )

    // Minimal WAL replay: parse `SET <id>.<slot> TO <value>` and apply
    replayWal := method(path := "telos.wal",
        f := File with(path)
        if(f exists not, return "no wal")
        lines := f openForReading readLines; f close
        lines foreach(line,
            l := line strip
            if(l beginsWithSeq("SET "),
                rest := l exSlice(4) // after 'SET '
                parts := rest split(" TO ")
                if(parts size >= 2,
                    lhs := parts at(0)
                    rhs := parts at(1)
                    idSlot := lhs split(".")
                    if(idSlot size >= 2,
                        mid := idSlot at(0)
                        slot := idSlot at(1)
                        m := morphIndex at(mid)
                        if(m,
                            // naive numeric parse
                            valNum := Number fromString(rhs) ; hasNum := (valNum isNan not)
                            if(slot == "x", m x = hasNum ifTrue(valNum) ifFalse(m x))
                            if(slot == "y", m y = hasNum ifTrue(valNum) ifFalse(m y))
                            if(slot == "width", m width = hasNum ifTrue(valNum) ifFalse(m width))
                            if(slot == "height", m height = hasNum ifTrue(valNum) ifFalse(m height))
                            if(slot == "color",
                                comps := rhs split(",")
                                if(comps size >= 4,
                                    m color = list(Number fromString(comps at(0)), Number fromString(comps at(1)), Number fromString(comps at(2)), Number fromString(comps at(3)))
                                )
                            )
                        )
                    )
                )
            )
        )
        "ok"
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
        if(self hasSlot("id"), Telos walSet(self id, "x", newX asString); Telos walSet(self id, "y", newY asString))
        "Telos: Morph moved to living position"
    )

    // Resize the morph (direct manipulation)
    resizeTo := method(newWidth, newHeight,
        self width = newWidth
        self height = newHeight
        if(self hasSlot("id"), Telos walSet(self id, "width", newWidth asString); Telos walSet(self id, "height", newHeight asString))
        "Telos: Morph resized in living space"
    )

    // Change color (direct manipulation)
    setColor := method(r, g, b, a := 1,
        self color = list(r, g, b, a)
        if(self hasSlot("id"), Telos walSet(self id, "color", ("" .. r .. "," .. g .. "," .. b .. "," .. a)))
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