/*
   TelosMorphic-Core.io - Core Morphic UI Framework
   Base Morph prototype, event system, and fundamental UI architecture
   Part of the modular TelosMorphic system
*/

// === TELOS MORPHIC CORE MODULE ===

TelosMorphicCore := Object clone
TelosMorphicCore version := "1.0.0 (modular-prototypal)"
TelosMorphicCore loadTime := Date clone now

// === EVENT SYSTEM FOR MORPHIC INTERACTION ===

// Event prototype - represents user input events from SDL2
Event := Object clone do(
    type := "unknown"
    x := 0
    y := 0
    button := 0
    timestamp := 0

    // Factory method for mouse events
    mouseEvent := method(eventType, mouseX, mouseY, mouseButton,
        newEvent := self clone
        newEvent type = eventType
        newEvent x = mouseX
        newEvent y = mouseY
        newEvent button = mouseButton
        newEvent timestamp = Date now asNumber
        newEvent
    )

    // Check if point is within bounds (for hit testing)
    isWithinBounds := method(bounds,
        (self x >= bounds x) and
        (self x <= (bounds x + bounds width)) and
        (self y >= bounds y) and
        (self y <= (bounds y + bounds height))
    )
)

// Register Event globally for system use
Lobby Event := Event

// === BASE MORPH PROTOTYPE ===
// The universal graphical primitive with event handling and scene graph management

Morph := Object clone do(
    // Core slots for state (as documented)
    bounds := Object clone do(
        x := 0; y := 0; width := 50; height := 50
        setPosition := method(newX, newY, x = newX; y = newY; self)
        setSize := method(newW, newH, width = newW; height = newH; self)
        containsPoint := method(px, py,
            (px >= self x) and (px <= (self x + self width)) and
            (py >= self y) and (py <= (self y + self height))
        )
    )
    color := Object clone do(
        r := 0.5; g := 0.5; b := 0.8; a := 1.0  // Default blue
        setColor := method(newR, newG, newB, newA,
            r = newR; g = newG; b = newB
            if(newA, a = newA, a = 1.0)
            self
        )
    )
    submorphs := List clone
    owner := nil
    id := "morph_" .. Date now asString

    // INTERACTIVE BEHAVIOR: Event handling methods
    leftMouseDown := method(event,
        writeln("Morph " .. self id .. ": Received leftMouseDown at (" .. event x .. "," .. event y .. ")")

        # Default behavior: change color to indicate selection
        self color setColor(0.9, 0.7, 0.7, 1.0)  # Light red to show interaction

        # Log state change to WAL if available
        if(Telos hasSlot("walAppend"),
            walEntry := "MORPH_INTERACT {\"id\":\"" .. self id .. "\",\"event\":\"leftMouseDown\",\"x\":" .. event x .. ",\"y\":" .. event y .. "}"
            Telos walAppend(walEntry)
        )

        # Return self to indicate event was handled
        self
    )

    leftMouseUp := method(event,
        writeln("Morph " .. self id .. ": Received leftMouseUp at (" .. event x .. "," .. event y .. ")")

        # Default behavior: restore original color
        self color setColor(0.5, 0.5, 0.8, 1.0)  # Back to default blue

        # Log state change to WAL if available
        if(Telos hasSlot("walAppend"),
            walEntry := "MORPH_INTERACT {\"id\":\"" .. self id .. "\",\"event\":\"leftMouseUp\",\"x\":" .. event x .. ",\"y\":" .. event y .. "}"
            Telos walAppend(walEntry)
        )

        # Return self to indicate event was handled
        self
    )

    mouseMoved := method(event,
        # Default: only handle if mouse is down (dragging)
        # Subclasses can override for hover effects
        nil  # Return nil to indicate event not handled by default
    )

    // Core behavior slots (as documented)
    drawOn := method(canvas,
        // Draw self first, then recursively draw all submorphs on top
        self drawSelfOn(canvas)
        self submorphs foreach(submorph, submorph drawOn(canvas))
        self
    )

    drawSelfOn := method(canvas,
        // Default: draw as a simple rectangle
        canvas fillRectangle(bounds, color)
        self
    )

    addMorph := method(aMorph,
        // Proper ownership management (as documented)
        if(aMorph owner, aMorph owner removeMorph(aMorph))
        self submorphs append(aMorph)
        aMorph owner = self
        self
    )

    removeMorph := method(aMorph,
        self submorphs remove(aMorph)
        if(aMorph owner == self, aMorph owner = nil)
        self
    )

    // Event handling (message-based as documented) - delegates to specific event methods
    handleEvent := method(event,
        // Events "fall through" the hierarchy via message delegation
        eventHandled := false

        # Map generic event to specific mouse message
        if(event type == "mouseDown",
            if(self hasSlot("leftMouseDown"),
                result := self leftMouseDown(event)
                if(result != nil, eventHandled = true)
            )
        )
        if(event type == "mouseUp",
            if(self hasSlot("leftMouseUp"),
                result := self leftMouseUp(event)
                if(result != nil, eventHandled = true)
            )
        )
        if(event type == "mouseMoved",
            if(self hasSlot("mouseMoved"),
                result := self mouseMoved(event)
                if(result != nil, eventHandled = true)
            )
        )

        # If not handled, pass to submorphs (front to back for proper occlusion)
        if(eventHandled not,
            self submorphs reverseForeach(submorph,
                if(eventHandled not,
                    if(submorph handleEvent(event), eventHandled = true)
                )
            )
        )

        eventHandled
    )
)

// Register base Morph in global namespace
Lobby Morph := Morph

// === TELOS INTEGRATION ===
// Extend Telos object with Morphic capabilities

Telos do(
    // Initialize world tracking first - immediate usability
    world := nil

    // Add focused morph tracking for keyboard input
    focusedMorph := nil

    // World management - create world with proper C-level access and event delegation
    createWorld := method(
        currentWorld := self world
        if(currentWorld == nil,
            # Call C-level world creation first
            if(self hasSlot("Telos_rawCreateWorld"),
                self Telos_rawCreateWorld
            ,
                writeln("Telos: Creating world (fallback)")
            )
            # Create Io-level world object as a Morph with event handling
            newWorld := Morph clone
            newWorld id := "RootWorld"
            newWorld bounds setSize(640, 480)  # Match window size
            newWorld color setColor(0.1, 0.1, 0.1, 1.0)  # Dark background

            # CRITICAL: World event delegation implementation
            newWorld handleMouseEvent := method(event,
                writeln("World: Handling mouse event " .. event type .. " at (" .. event x .. "," .. event y .. ")")

                # Delegate to submorphs in reverse order (front to back for proper occlusion)
                eventHandled := false
                morphIndex := self submorphs size - 1

                while(morphIndex >= 0 and eventHandled not,
                    morph := self submorphs at(morphIndex)

                    # Check if event is within morph bounds
                    if(event isWithinBounds(morph bounds),
                        writeln("World: Event within bounds of morph " .. morph id)

                        # Send appropriate message to morph based on event type
                        if(event type == "mouseDown",
                            if(morph hasSlot("leftMouseDown"),
                                result := morph leftMouseDown(event)
                                if(result != nil, eventHandled = true)
                            )
                        )
                        if(event type == "mouseUp",
                            if(morph hasSlot("leftMouseUp"),
                                result := morph leftMouseUp(event)
                                if(result != nil, eventHandled = true)
                            )
                        )
                        if(event type == "mouseMoved",
                            if(morph hasSlot("mouseMoved"),
                                result := morph mouseMoved(event)
                                if(result != nil, eventHandled = true)
                            )
                        )
                    )
                    morphIndex = morphIndex - 1
                )

                if(eventHandled not,
                    writeln("World: Event not handled by any morph - background click at (" .. event x .. "," .. event y .. ")")
                )

                eventHandled
            )

            newWorld refresh := method(
                count := self submorphs size
                writeln("TelOS: Refreshing display with " .. count .. " morphs")
                self
            )

            self world := newWorld
        )
        self world
    )

    // Window management - call C-level openWindow via raw function
    openWindow := method(
        // First create world if needed
        self createWorld
        // Call actual C-level SDL2 window creation
        if(self hasSlot("Telos_rawOpenWindow"),
            self Telos_rawOpenWindow
        ,
            writeln("UI: Opening a 640x480 window titled 'The Entropic Garden' (fallback)")
        )
        self
    )

    // Close window gracefully - set exit flag and let display loop handle C-level close
    closeWindowGracefully := method(
        writeln("TelOS: Requesting graceful window close...")

        // Set exit flag to stop any running loops
        if(self hasSlot("shouldExit"),
            self shouldExit := true
            writeln("TelOS: Exit flag set - display loops will terminate")
        )

        // The actual C-level closeWindow should be called by the main loop
        // or when the system shuts down to avoid race conditions
        self
    )

    // Main event loop - display window content and handle events
    mainLoop := method(
        writeln("TelOS: Starting SDL2 main event loop...")

        // NOTE: Telos_rawMainLoop is BLOCKING - it runs infinite loop until window closed
        // For demos, we use timed display instead
        writeln("TelOS: Using timed display loop (non-blocking)...")
        for(i, 1, 60,
            self drawWorld
            System sleep(0.1)
            if(i % 10 == 0, write("."))
        )

        writeln("\nTelOS: Main loop completed")
        self
    )

    // Run blocking SDL2 main loop (WARNING: blocks until window closed)
    runBlockingLoop := method(
        writeln("TelOS: WARNING - Starting BLOCKING SDL2 main loop...")
        writeln("TelOS: This will block until window is closed via SDL2 events!")

        if(self hasSlot("Telos_rawMainLoop"),
            self Telos_rawMainLoop
        ,
            writeln("TelOS: No C-level main loop available")
        )

        writeln("TelOS: Blocking main loop ended")
        self
    )

    // Simple display loop for timed demonstrations
    displayFor := method(seconds,
        writeln("TelOS: Displaying content for " .. seconds .. " seconds...")
        writeln("TelOS: Press ESC or close window to exit early")

        # Use C-level displayFor if available (supports perpetual mode with 0/-1)
        if(self hasSlot("Telos_rawDisplayFor"),
            self Telos_rawDisplayFor(seconds)
        ,
            # Fallback to Io implementation
            iterations := (seconds * 10) floor
            for(i, 1, iterations,
                # CRITICAL: Process SDL2 events FIRST (including close button)
                if(self hasSlot("Telos_rawHandleEvent"),
                    self Telos_rawHandleEvent
                )

                # Check if exit was requested
                if(self hasSlot("shouldExit") and self shouldExit,
                    writeln("\nTelOS: Exit requested - stopping display loop")
                    break
                )

                self drawWorld
                System sleep(0.1)
                if(i % 10 == 0, write("."))
            )
        )

        writeln("\nTelOS: Display period completed")
        self
    )

    // Add morph to world
    addMorph := method(morph,
        currentWorld := self world
        if(currentWorld != nil,
            currentWorld submorphs append(morph)
            morphId := morph id
            writeln("TelOS: Added morph '" .. morphId .. "' to world")
        )
        self
    )

    // Refresh display - actually draw to SDL2 window
    refresh := method(
        currentWorld := self world
        count := currentWorld submorphs size
        writeln("TelOS: Refreshing display with " .. count .. " morphs")

        # CRITICAL: Process SDL2 events (including window close button)
        if(self hasSlot("Telos_rawHandleEvent"),
            self Telos_rawHandleEvent
        )

        # Call C-level drawing if available
        if(self hasSlot("Telos_rawDraw"),
            self Telos_rawDraw
        ,
            writeln("TelOS: Drawing (fallback mode)")
        )
        self
    )

    // Draw world - render all morphs to SDL2 window using Io-level Canvas
    drawWorld := method(
        currentWorld := self world
        count := currentWorld submorphs size
        writeln("TelOS: Drawing world with " .. count .. " morphs")

        # Clear screen and prepare SDL2 back buffer
        if(self hasSlot("Telos_rawDrawWorld"),
            self Telos_rawDrawWorld  // This clears screen with world background
        )
        
        # Create Canvas and let morphs draw themselves (proper Morphic architecture)
        canvas := Canvas clone
        currentWorld drawOn(canvas)
        
        # Present the frame to make drawings visible
        canvas present
        
        writeln("TelOS: Completed Canvas-based world rendering")
        self
    )

    // Draw individual morph (calls C-level drawing)
    drawMorph := method(morph,
        if(self hasSlot("Telos_rawDrawMorph"),
            // Use C-level morph drawing
            self Telos_rawDrawMorph(morph)
        ,
            morphId := morph id
            morphX := morph x
            morphY := morph y
            writeln("TelOS: Drawing morph '" .. morphId .. "' at (" .. morphX .. "," .. morphY .. ")")

            // Call C-level fallback if available
            if(self hasSlot("drawRect"),
                self drawRect(morphX, morphY, morph width, morph height, morph color)
            )
        )
    )

    // Present the current frame to screen
    presentFrame := method(
        if(self hasSlot("Telos_rawDraw"),
            self Telos_rawDraw
        ,
            framePresenter := Object clone
            framePresenter message := "TelOS: Presenting frame (fallback)"
            writeln(framePresenter message)
        )
    )

    // CRITICAL: Bridge method for C-level to dispatch events to World
    dispatchMouseEvent := method(eventType, x, y, button,
        writeln("Telos: Dispatching mouse event " .. eventType .. " at (" .. x .. "," .. y .. ")")

        currentWorld := self world
        if(currentWorld != nil,
            # Create Event object from C-level parameters
            event := Event mouseEvent(eventType, x, y, button)

            # Dispatch to World for delegation to morphs
            currentWorld handleMouseEvent(event)
        ,
            writeln("Telos: No world available for event dispatch")
        )

        self
    )

    // Keyboard event dispatching
    dispatchKeyEvent := method(keyName, isDown,
        writeln("Telos: Dispatching key event " .. keyName .. " isDown=" .. isDown)

        focusedMorph := self focusedMorph
        if(focusedMorph != nil,
            if(isDown == true,
                if(focusedMorph hasSlot("keyDown"),
                    focusedMorph keyDown(keyName)
                )
            ,
                if(focusedMorph hasSlot("keyUp"),
                    focusedMorph keyUp(keyName)
                )
            )
        ,
            writeln("Telos: No focused morph for key event")
        )

        self
    )

    // Text input dispatching
    dispatchTextInput := method(text,
        writeln("Telos: Dispatching text input '" .. text .. "'")

        focusedMorph := self focusedMorph
        if(focusedMorph != nil,
            if(focusedMorph hasSlot("textInput"),
                focusedMorph textInput(text)
            )
        ,
            writeln("Telos: No focused morph for text input")
        )

        self
    )
)

// === CANVAS ABSTRACTION ===
// Drawing operations that delegate to C-level implementations

Canvas := Object clone do(
    // Drawing methods that delegate to C-level implementations
    fillRectangle := method(bounds, color,
        // Extract bounds and color data for C-level call
        x := bounds x
        y := bounds y
        width := bounds width
        height := bounds height
        r := color r
        g := color g
        b := color b
        a := color a

        # Call C-level drawing
        if(Telos hasSlot("Telos_rawDrawRect"),
            Telos Telos_rawDrawRect(x, y, width, height, r, g, b, a)
        ,
            writeln("Canvas: Drawing rectangle at (" .. x .. "," .. y .. ") size " .. width .. "x" .. height)
        )
        self
    )

    fillCircle := method(bounds, radius, color,
        # Calculate circle center from bounds
        centerX := bounds x + (bounds width / 2)
        centerY := bounds y + (bounds height / 2)
        r := color r
        g := color g
        b := color b
        a := color a

        # Call C-level circle drawing
        if(Telos hasSlot("Telos_rawDrawCircle"),
            Telos Telos_rawDrawCircle(centerX, centerY, radius, r, g, b, a)
        ,
            writeln("Canvas: Drawing circle at (" .. centerX .. "," .. centerY .. ") radius " .. radius)
        )
        self
    )

    drawText := method(text, bounds, color,
        x := bounds x
        y := bounds y
        r := color r
        g := color g
        b := color b
        a := color a

        # Call C-level text drawing
        if(Telos hasSlot("Telos_rawDrawText"),
            Telos Telos_rawDrawText(text, x, y, r, g, b, a)
        ,
            writeln("Canvas: Drawing text '" .. text .. "' at (" .. x .. "," .. y .. ")")
        )
        self
    )
    
    // Present the canvas to screen (critical for SDL2 display)
    present := method(
        # Call C-level frame presentation
        if(Telos hasSlot("Telos_rawPresent"),
            Telos Telos_rawPresent
        ,
            writeln("Canvas: Presenting frame (fallback)")
        )
        self
    )
    
    // Set clipping region for efficient damage-based rendering
    clipTo := method(damageRect,
        x := damageRect x
        y := damageRect y
        width := damageRect width
        height := damageRect height
        
        # Call C-level clipping
        if(Telos hasSlot("Telos_rawSetClip"),
            Telos Telos_rawSetClip(x, y, width, height)
        ,
            writeln("Canvas: Setting clip region to (" .. x .. "," .. y .. "," .. width .. "," .. height .. ")")
        )
        self
    )
    
    // Clear clipping region
    clearClip := method(
        # Call C-level clip clearing
        if(Telos hasSlot("Telos_rawClearClip"),
            Telos Telos_rawClearClip
        ,
            writeln("Canvas: Clearing clip region")
        )
        self
    )
)

// Register Canvas in global namespace
Lobby Canvas := Canvas

// === COLOR PROTOTYPE ===

Color := Object clone do(
    type := "color"
    r := 0.0
    g := 0.0
    b := 0.0
    a := 1.0  // Alpha (opacity)

    setColor := method(red, green, blue, alpha,
        self r := red
        self g := green
        self b := blue
        if(alpha, self a := alpha, self a := 1.0)
        self
    )

    description := method(
        "Color(" .. self r .. "," .. self g .. "," .. self b .. "," .. self a .. ")"
    )

    // Common color constructors
    red := method(
        self clone setColor(1.0, 0.0, 0.0, 1.0)
    )

    green := method(
        self clone setColor(0.0, 1.0, 0.0, 1.0)
    )

    blue := method(
        self clone setColor(0.0, 0.0, 1.0, 1.0)
    )

    white := method(
        self clone setColor(1.0, 1.0, 1.0, 1.0)
    )

    black := method(
        self clone setColor(0.0, 0.0, 0.0, 1.0)
    )

    gray := method(
        self clone setColor(0.5, 0.5, 0.5, 1.0)
    )
)

// Register Color in global namespace
Lobby Color := Color

// === POINT AND RECTANGLE SUPPORT ===

Point := Object clone do(
    type := "point"
    x := 0
    y := 0

    with := method(xVal, yVal,
        self clone setPosition(xVal, yVal)
    )

    setPosition := method(xVal, yVal,
        self x := xVal
        self y := yVal
        self
    )

    description := method(
        "Point(" .. self x .. "," .. self y .. ")"
    )
)

Rectangle := Object clone do(
    type := "rectangle"
    x := 0
    y := 0
    width := 0
    height := 0

    setPosition := method(xVal, yVal,
        self x := xVal
        self y := yVal
        self
    )

    setSize := method(w, h,
        self width := w
        self height := h
        self
    )

    description := method(
        "Rectangle(" .. self x .. "," .. self y .. "," .. self width .. "," .. self height .. ")"
    )
)

// Register support objects
Lobby Point := Point
Lobby Rectangle := Rectangle

// Module load method
TelosMorphicCore load := method(
    writeln("TelosMorphic-Core: Base Morphic UI framework loaded")
    writeln("TelosMorphic-Core: Event system and scene graph initialized")
    writeln("TelosMorphic-Core: Core prototypes registered: Morph, Event, Canvas, Color")
    self
)

writeln("TelosMorphic-Core: Core Morphic UI framework module loaded")

// Register TelosMorphicCore in global namespace
Lobby TelosMorphicCore := TelosMorphicCore