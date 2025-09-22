/*
   IoTelos.io - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

Telos := Object clone do(

    // Initialize the TelOS zygote - the computational embryo
    // REMOVED: init method - objects must be immediately usable after cloning
    // State lives directly in prototype slots
    world := nil
    morphs := List clone
    morphIndex := Map clone
    nextId := 1

    // Pillar 1: Synaptic Bridge - Reach into Python muscle (helper)
    pythonVersion := method(
        getPythonVersion
    )

    // Pillar 2: First Heartbeat - Transactional persistence (use primitive directly)

    // Pillar 3: First Glance - UI window stub (use primitive directly)

    // Create the root world (Morphic's World) and anchor Io state
    bootWorld := method(
        createWorld
        worldSetter := Object clone
        worldSetter worldValue := self
        self world := worldSetter worldValue
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
            idSetter := Object clone
            idSetter idValue := ("m" .. nextId asString)
            morph id := idSetter idValue
            nextIdIncrementer := Object clone
            nextIdIncrementer currentValue := nextId
            nextIdIncrementer newValue := nextIdIncrementer currentValue + 1
            self nextId := nextIdIncrementer newValue
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
            idSetter := Object clone
            idSetter idValue := ("m" .. nextId asString)
            child id := idSetter idValue
            nextIdIncrementer := Object clone
            nextIdIncrementer currentValue := nextId
            nextIdIncrementer newValue := nextIdIncrementer currentValue + 1
            self nextId := nextIdIncrementer newValue
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
                            if(slot == "x",
                                valueSetter := Object clone
                                valueSetter value := hasNum ifTrue(valNum) ifFalse(m x)
                                m x := valueSetter value
                            )
                            if(slot == "y",
                                valueSetter := Object clone
                                valueSetter value := hasNum ifTrue(valNum) ifFalse(m y)
                                m y := valueSetter value
                            )
                            if(slot == "width",
                                valueSetter := Object clone
                                valueSetter value := hasNum ifTrue(valNum) ifFalse(m width)
                                m width := valueSetter value
                            )
                            if(slot == "height",
                                valueSetter := Object clone
                                valueSetter value := hasNum ifTrue(valNum) ifFalse(m height)
                                m height := valueSetter value
                            )
                            if(slot == "color",
                                comps := rhs split(",")
                                if(comps size >= 4,
                                    colorSetter := Object clone
                                    colorSetter colorValue := list(Number fromString(comps at(0)), Number fromString(comps at(1)), Number fromString(comps at(2)), Number fromString(comps at(3)))
                                    m color := colorSetter colorValue
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

    // REMOVED: init method - objects must be immediately usable after cloning
    // State lives directly in prototype slots
    x := 100
    y := 100
    width := 50
    height := 50
    color := list(1, 0, 0, 1)  // Red by default
    submorphs := List clone
    owner := nil

    // Move the morph (direct manipulation)
    moveTo := method(newX, newY,
        positionSetter := Object clone
        positionSetter xValue := newX
        positionSetter yValue := newY
        self x := positionSetter xValue
        self y := positionSetter yValue
        if(self hasSlot("id"), Telos walSet(self id, "x", newX asString); Telos walSet(self id, "y", newY asString))
        "Telos: Morph moved to living position"
    )

    // Resize the morph (direct manipulation)
    resizeTo := method(newWidth, newHeight,
        sizeSetter := Object clone
        sizeSetter widthValue := newWidth
        sizeSetter heightValue := newHeight
        self width := sizeSetter widthValue
        self height := sizeSetter heightValue
        if(self hasSlot("id"), Telos walSet(self id, "width", newWidth asString); Telos walSet(self id, "height", newHeight asString))
        "Telos: Morph resized in living space"
    )

    // Change color (direct manipulation)
    setColor := method(r, g, b, a := 1,
        colorSetter := Object clone
        colorSetter colorValue := list(r, g, b, a)
        self color := colorSetter colorValue
        if(self hasSlot("id"), Telos walSet(self id, "color", ("" .. r .. "," .. g .. "," .. b .. "," .. a)))
        "Telos: Morph color changed in living palette"
    )

    // Check if point is inside morph bounds
    containsPoint := method(px, py,
        (px >= x and px <= (x + width)) and (py >= y and py <= (y + height))
    )

    // Add a submorph to this morph
    addMorph := method(child,
        ownerSetter := Object clone
        ownerSetter ownerValue := self
        child owner := ownerSetter ownerValue
        submorphs append(child)
        Telos addSubmorph(self, child)
    )

    // Remove a submorph
    removeMorph := method(child,
        submorphs remove(child)
        ownerSetter := Object clone
        ownerSetter ownerValue := nil
        child owner := ownerSetter ownerValue
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
    // REMOVED: init method - objects must be immediately usable after cloning
    // State lives directly in prototype slots
    text := "Hello TelOS"
    fontSize := 12

    draw := method(
        writeln("Telos: Drawing text '", text, "' at (", x, ",", y, ") size ", fontSize)
    )

    setText := method(newText,
        textSetter := Object clone
        textSetter textValue := newText
        self text := textSetter textValue
        "Telos: Text morph updated with living message"
    )
)

writeln("Telos: Zygote pillars loaded - mind touches muscle, heartbeat begins, first glance opens")