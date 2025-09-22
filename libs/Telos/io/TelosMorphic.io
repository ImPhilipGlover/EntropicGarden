/*
   TelosMorphic.io - Direct Manipulation UI: Living Objects in Visual Space
   FULL IMPLEMENTATION WITH SDL2 WINDOW SUPPORT
*/

// === TELOS MORPHIC MODULE ===

TelosMorphic := Object clone
TelosMorphic version := "1.0.0 (modular-prototypal)"
TelosMorphic loadTime := Date clone now

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

// === MORPHIC UI IMPLEMENTATION ===

// Extend Telos object with Morphic capabilities
Telos do(
    // Initialize world tracking first - immediate usability
    world := nil
    
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
        iterations := (seconds * 10) floor
        
        for(i, 1, iterations,
            // CRITICAL: Process SDL2 events FIRST (including close button)
            if(self hasSlot("Telos_rawHandleEvent"),
                self Telos_rawHandleEvent
            )
            
            // Check if exit was requested
            if(self hasSlot("shouldExit") and self shouldExit,
                writeln("\nTelOS: Exit requested - stopping display loop")
                break
            )
            
            self drawWorld
            System sleep(0.1)
            if(i % 10 == 0, write("."))
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
    
    // Draw world - render all morphs to SDL2 window using existing C-level drawing
    drawWorld := method(
        currentWorld := self world
        count := currentWorld submorphs size
        writeln("TelOS: Drawing world with " .. count .. " morphs")
        
        # Use the C-level world drawing directly (this works!)
        if(self hasSlot("Telos_rawDraw"),
            self Telos_rawDraw
        ,
            writeln("TelOS: No C-level drawing available - using fallback")
        )
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
)

// === MORPHIC OBJECT PROTOTYPES ===
// Based on "Morphic UI Framework Training Guide Extension.txt"
// Implements proper scene graph with owner/submorphs relationships

// Base Morph prototype - the universal graphical primitive with event handling
Morph := Object clone do(
    // Core slots for state (as documented)
    bounds := Object clone do(
        x := 0; y := 0; width := 50; height := 50
        setPosition := method(newX, newY, x = newX; y = newY; self)
        setSize := method(newW, newH, width = newW; height = newH; self)
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

// RectangleMorph - Inherits from Morph (as documented)
RectangleMorph := Morph clone
RectangleMorph do(
    // Prototypal clone method
    clone := method(
        newRect := resend
        newRect id := "rect_" .. Date now asString
        newRect
    )
    
    // Convenience methods using new Morph structure
    setPosition := method(newX, newY,
        self bounds setPosition(newX, newY)
        self
    )
    
    setSize := method(newW, newH,
        self bounds setSize(newW, newH)
        self
    )
    
    setBounds := method(newX, newY, newW, newH,
        self bounds setPosition(newX, newY) setSize(newW, newH)
        self
    )
    
    setColor := method(r, g, b, a,
        self color setColor(r, g, b, a)
        self
    )
)

// TextMorph - Text display object (inherits from Morph)
TextMorph := Morph clone
TextMorph do(
    text := "Default Text"
    
    // Prototypal clone method
    clone := method(
        newText := resend
        newText id := "text_" .. Date now asString
        newText text := "Default Text"
        newText
    )
    
    // Override drawSelfOn to draw text instead of rectangle
    drawSelfOn := method(canvas,
        canvas drawText(self text, bounds, color)
        self
    )
)

// CircleMorph - Circular visual object (inherits from Morph)
CircleMorph := Morph clone
CircleMorph do(
    radius := 25  // Default radius
    id := "defaultCircle"
    
    // Prototypal clone method
    clone := method(
        newCircle := resend
        newCircle id := "circle_" .. Date now asString
        newCircle
    )
    
    // Override drawSelfOn to draw circle instead of rectangle
    drawSelfOn := method(canvas,
        canvas fillCircle(bounds, radius, color)
        self
    )
    
    setRadius := method(newRadius,
        radiusAssigner := Object clone
        radiusAssigner value := if(newRadius == nil, 25, newRadius)
        self radius := radiusAssigner value
        self
    )
)

// Canvas - Abstraction layer for drawing operations (as documented)
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
)

// Register Morphic objects in global Lobby namespace immediately
Lobby Morph := Morph
Lobby Canvas := Canvas
Lobby RectangleMorph := RectangleMorph
Lobby TextMorph := TextMorph
Lobby CircleMorph := CircleMorph



// Add captureScreenshot method to Telos
Telos captureScreenshot := method(
    currentWorld := self world
    if(currentWorld == nil, return "[no world]")
    describe := method(m, indent,
        morphType := m type ifNil("Morph")
        hasId := m hasSlot("id")
        morphId := if(hasId, m id, "?")
        hasZIndex := m hasSlot("zIndex")
        zIndex := if(hasZIndex, m zIndex, 0)
        morphX := m x
        morphY := m y
        morphWidth := m width
        morphHeight := m height
        line := indent .. morphType .. "#" .. morphId .. " @(" .. morphX .. "," .. morphY .. ") " .. morphWidth .. "x" .. morphHeight .. " z=" .. zIndex
        hasColor := m hasSlot("color")
        if(hasColor,
            morphColor := m color
            r := morphColor atIfAbsent(0,0)
            g := morphColor atIfAbsent(1,0)
            b := morphColor atIfAbsent(2,0)
            a := morphColor atIfAbsent(3,1)
            line = line .. " color=[" .. r .. "," .. g .. "," .. b .. "," .. a .. "]"
        )
        hasText := m hasSlot("text")
        if(hasText, 
            morphText := m text
            line = line .. " text='" .. morphText .. "'"
        )
        line
    )
    
    lines := List clone
    submorphs := currentWorld submorphs
    count := submorphs size
    lines append("World(" .. count .. " morphs):")
    submorphs foreach(m, lines append(describe(m, "  ")))
    lines join("\n")
)



// WAL-integrated morph creation with state logging
Telos createMorphWithLogging := method(morphType, x, y, width, height,
    // Create morph instance
    morphCreator := Object clone
    morphCreator type := if(morphType == nil, "RectangleMorph", morphType asString)
    morphCreator morph := Lobby getSlot(morphCreator type) ifNil(RectangleMorph) clone
    
    // Set properties with WAL logging
    morphCreator morph x := if(x == nil, 100, x)
    morphCreator morph y := if(y == nil, 100, y)
    morphCreator morph width := if(width == nil, 100, width)
    morphCreator morph height := if(height == nil, 100, height)
    
    // Log morphic state change to WAL
    if(Telos hasSlot("walAppend"),
        morphState := Object clone
        morphState id := morphCreator morph id
        morphState type := morphCreator type
        morphState x := morphCreator morph x
        morphState y := morphCreator morph y
        morphState width := morphCreator morph width
        morphState height := morphCreator morph height
        
        walEntry := "MORPH_CREATE {\"id\":\"" .. morphState id .. "\",\"type\":\"" .. morphState type .. "\",\"x\":" .. morphState x .. ",\"y\":" .. morphState y .. ",\"width\":" .. morphState width .. ",\"height\":" .. morphState height .. "}"
        Telos walAppend(walEntry)
        writeln("TelOS Morphic: Logged morph creation to WAL - " .. morphState id)
    )
    
    // Add to world and trigger C-level rendering
    if(self world != nil,
        self world addMorph(morphCreator morph)
        self createMorph  // Trigger C-level rendering
    )
    
    morphCreator morph
)

// Note: createMorphWithLogging defined once above

// Module load method for system integration (working around module loading failure)
TelosMorphic load := method(
    writeln("TelosMorphic: Direct Manipulation UI module loaded - visual interface ready")
    writeln("TelosMorphic: SDL2 window support enabled")
    writeln("TelosMorphic: Morphic objects registered globally: RectangleMorph, TextMorph, CircleMorph")
    writeln("TelosMorphic: WAL integration enabled for state persistence")
    
    // Mark load in WAL if available
    if(Telos hasSlot("walAppend"), Telos walAppend("MARK morphic.load {}"))
    
    // Return self to indicate successful load
    self
)

// === AUTOPOIETIC MORPHIC EVOLUTION ===
// Enable morphs to grow new capabilities through doesNotUnderstand protocol

MorphicAutopoiesis := Object clone
MorphicAutopoiesis synthesizeMorphicCapability := method(morphType, unknownMessage,
    # Create synthesis context
    synthContext := Object clone
    synthContext morphType := morphType
    synthContext requestedMessage := unknownMessage name
    synthContext timestamp := System time
    
    writeln("🧬 MORPHIC SYNTHESIS: Creating ", synthContext requestedMessage, " for ", synthContext morphType)
    
    # Route to capability synthesizer based on message pattern
    if(synthContext requestedMessage beginsWithSeq("draw"),
        # Drawing capability synthesis
        drawingSynthesizer := Object clone
        drawingSynthesizer newMethod := method(
            writeln("🎨 Auto-synthesized drawing method: ", synthContext requestedMessage)
            # Placeholder behavior - future LLM will generate actual drawing logic
        )
        return drawingSynthesizer newMethod
    )
    
    if(synthContext requestedMessage beginsWithSeq("animate"),
        # Animation capability synthesis  
        animationSynthesizer := Object clone
        animationSynthesizer newMethod := method(
            writeln("✨ Auto-synthesized animation method: ", synthContext requestedMessage)
            # Placeholder behavior - future LLM will generate actual animation logic
        )
        return animationSynthesizer newMethod
    )
    
    # Default synthesis for unknown patterns
    defaultSynthesizer := Object clone
    defaultSynthesizer newMethod := method(
        writeln("🌱 Auto-synthesized morphic method: ", synthContext requestedMessage)
        writeln("   This capability emerged through autopoietic evolution!")
        self
    )
    defaultSynthesizer newMethod
)

# Install autopoietic forward on morphic prototypes
if(Lobby hasSlot("RectangleMorph"),
    RectangleMorph forward := method(
        capability := MorphicAutopoiesis synthesizeMorphicCapability("RectangleMorph", call message)
        # Install the synthesized capability
        self setSlot(call message name, capability)
        # Execute it immediately
        self performWithArgList(call message name, call message arguments)
    )
    writeln("TelOS Morphic: Autopoietic forward installed on RectangleMorph")
)

if(Lobby hasSlot("TextMorph"),
    TextMorph forward := method(
        capability := MorphicAutopoiesis synthesizeMorphicCapability("TextMorph", call message)
        self setSlot(call message name, capability)
        self performWithArgList(call message name, call message arguments)
    )
    writeln("TelOS Morphic: Autopoietic forward installed on TextMorph")
)

if(Lobby hasSlot("CircleMorph"),
    CircleMorph forward := method(
        capability := MorphicAutopoiesis synthesizeMorphicCapability("CircleMorph", call message)
        self setSlot(call message name, capability)
        self performWithArgList(call message name, call message arguments)
    )
    writeln("TelOS Morphic: Autopoietic forward installed on CircleMorph")
)

writeln("TelOS Morphic: Full SDL2 implementation loaded")
writeln("TelOS Morphic: Objects registered in global namespace") 
writeln("TelOS Morphic: WAL integration enabled for state persistence")
writeln("TelOS Morphic: Autopoietic evolution enabled for all morphs")
writeln("TelOS Morphic: Module load method registered")