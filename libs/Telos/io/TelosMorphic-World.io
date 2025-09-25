/*
   TelosMorphic-World.io - Morphic World and Window Management
   MorphicWorld, window lifecycle, and display coordination
   Part of the modular TelosMorphic system
*/

// === TELOS MORPHIC WORLD MODULE ===

TelosMorphicWorld := Object clone
TelosMorphicWorld version := "1.0.0 (modular-prototypal)"
TelosMorphicWorld loadTime := Date clone now

// === MORPHIC WORLD ===
// The root container for all morphs with window management

MorphicWorld := Morph clone do(
    type := "world"
    title := "TelOS Morphic World"
    isRunning := false
    lastFrameTime := 0

    // World-specific initialization
    init := method(
        # Call parent init
        resend

        # World-specific setup
        self bounds setSize(640, 480)
        self color setColor(0.1, 0.1, 0.1, 1.0)  # Dark background
        self id := "RootWorld"

        self
    )

    // Enhanced event handling for world-level coordination
    handleEvent := method(event,
        # World handles events differently - it coordinates between morphs
        eventHandled := false

        # Special world-level handling
        if(event type == "windowClose",
            self isRunning = false
            eventHandled = true
            writeln("World: Window close event received - stopping")
        )

        if(event type == "windowResize",
            # Update world bounds to match new window size
            self bounds setSize(event x, event y)
            eventHandled = true
            writeln("World: Window resized to " .. event x .. "x" .. event y)
        )

        # If not handled at world level, delegate to morphs
        if(eventHandled not,
            eventHandled = resend  # Call parent Morph handleEvent
        )

        eventHandled
    )

    // World-specific drawing - clears screen and draws all morphs
    drawOn := method(canvas,
        # Clear the screen first (world background)
        canvas fillRectangle(self bounds, self color)

        # Draw all submorphs on top
        self submorphs foreach(submorph, submorph drawOn(canvas))

        self
    )

    // Animation and update loop
    step := method(
        # Called each frame for animations/updates
        currentTime := Date now asNumber

        # Calculate delta time
        deltaTime := if(self lastFrameTime > 0, currentTime - self lastFrameTime, 0)
        self lastFrameTime = currentTime

        # Update any animated morphs
        self submorphs foreach(submorph,
            if(submorph hasSlot("step"),
                submorph step(deltaTime)
            )
        )

        self
    )

    // Start the world's event loop
    start := method(
        self isRunning = true
        self lastFrameTime = Date now asNumber

        writeln("MorphicWorld: Starting event loop for '" .. self title .. "'")

        # Open window if not already open
        if(Telos hasSlot("openWindow"),
            Telos openWindow
        )

        # Main event loop
        while(self isRunning,
            # Process events
            if(Telos hasSlot("Telos_rawHandleEvent"),
                Telos Telos_rawHandleEvent
            )

            # Update world state
            self step

            # Draw everything
            self draw

            # Small delay to prevent 100% CPU usage
            System sleep(0.016)  # ~60 FPS
        )

        writeln("MorphicWorld: Event loop ended")
        self
    )

    // Stop the world's event loop
    stop := method(
        self isRunning = false
        writeln("MorphicWorld: Stop requested")
        self
    )

    // Draw the world (called each frame)
    draw := method(
        # Use Telos drawing system
        if(Telos hasSlot("drawWorld"),
            Telos drawWorld
        ,
            # Fallback drawing
            canvas := Canvas clone
            self drawOn(canvas)
            writeln("World: Drew " .. self submorphs size .. " morphs (fallback)")
        )

        self
    )

    // Enhanced morph management with world-specific logic
    addMorph := method(aMorph,
        # Call parent method
        resend

        # World-specific: ensure morph is within bounds
        if(aMorph bounds x < 0, aMorph bounds x = 0)
        if(aMorph bounds y < 0, aMorph bounds y = 0)
        if(aMorph bounds x + aMorph bounds width > self bounds width,
            aMorph bounds x = self bounds width - aMorph bounds width
        )
        if(aMorph bounds y + aMorph bounds height > self bounds height,
            aMorph bounds y = self bounds height - aMorph bounds height
        )

        # Log to WAL
        if(Telos hasSlot("walAppend"),
            walEntry := "WORLD_ADD_MORPH {\"world\":\"" .. self id .. "\",\"morph\":\"" .. aMorph id .. "\",\"totalMorphs\":" .. self submorphs size .. "}"
            Telos walAppend(walEntry)
        )

        self
    )

    // Factory method for creating worlds
    withTitle := method(worldTitle,
        newWorld := self clone
        newWorld title = worldTitle
        newWorld
    )

    // Factory method with size
    withTitleAndSize := method(worldTitle, width, height,
        newWorld := self withTitle(worldTitle)
        newWorld bounds setSize(width, height)
        newWorld
    )

    description := method(
        "MorphicWorld(\"" .. self title .. "\"," .. self bounds width .. "x" .. self bounds height .. "," .. self submorphs size .. " morphs)"
    )
)

// === WINDOW MANAGER ===
// Coordinates window lifecycle and SDL2 integration

WindowManager := Object clone do(
    type := "windowManager"
    currentWorld := nil
    isInitialized := false

    // Initialize SDL2 window system
    initialize := method(
        if(self isInitialized not,
            writeln("WindowManager: Initializing SDL2 window system...")

            # Call C-level initialization
            if(Telos hasSlot("Telos_rawInitSDL"),
                result := Telos Telos_rawInitSDL
                if(result,
                    self isInitialized = true
                    writeln("WindowManager: SDL2 initialized successfully")
                ,
                    writeln("WindowManager: SDL2 initialization failed")
                )
            ,
                writeln("WindowManager: No C-level SDL2 initialization available")
            )
        )

        self
    )

    // Create and show a window with a world
    openWindow := method(world,
        self initialize

        if(world != nil,
            self currentWorld = world

            # Set window title
            if(Telos hasSlot("Telos_rawSetWindowTitle"),
                Telos Telos_rawSetWindowTitle(world title)
            )

            # Open the actual window
            if(Telos hasSlot("Telos_rawOpenWindow"),
                Telos Telos_rawOpenWindow
                writeln("WindowManager: Window opened for world '" .. world title .. "'")
            ,
                writeln("WindowManager: No C-level window opening available")
            )
        ,
            writeln("WindowManager: No world provided to openWindow")
        )

        self
    )

    // Close current window
    closeWindow := method(
        if(self currentWorld != nil,
            # Stop the world if running
            self currentWorld stop

            # Close C-level window
            if(Telos hasSlot("Telos_rawCloseWindow"),
                Telos Telos_rawCloseWindow
                writeln("WindowManager: Window closed")
            ,
                writeln("WindowManager: No C-level window closing available")
            )

            self currentWorld = nil
        )

        self
    )

    // Handle window events
    handleEvent := method(event,
        if(self currentWorld != nil,
            self currentWorld handleEvent(event)
        ,
            false  # No world to handle event
        )
    )

    // Get current window size
    getWindowSize := method(
        if(Telos hasSlot("Telos_rawGetWindowSize"),
            size := Telos Telos_rawGetWindowSize
            size  # Return the size object
        ,
            # Default size
            Object clone do(width := 640; height := 480)
        )
    )

    // Set window size
    setWindowSize := method(width, height,
        if(Telos hasSlot("Telos_rawSetWindowSize"),
            Telos Telos_rawSetWindowSize(width, height)
            writeln("WindowManager: Window size set to " .. width .. "x" .. height)
        ,
            writeln("WindowManager: No C-level window resizing available")
        )

        self
    )
)

// === DISPLAY COORDINATOR ===
// Manages frame timing, refresh rates, and display updates

DisplayCoordinator := Object clone do(
    type := "displayCoordinator"
    targetFPS := 60
    frameTime := 1 / 60  # 16.67ms per frame
    lastFrameTime := 0
    frameCount := 0

    // Start display coordination
    start := method(
        self lastFrameTime = Date now asNumber
        self frameCount = 0
        writeln("DisplayCoordinator: Started at " .. self targetFPS .. " FPS target")
        self
    )

    // Wait for next frame (maintain frame rate)
    waitForNextFrame := method(
        currentTime := Date now asNumber
        elapsed := currentTime - self lastFrameTime
        sleepTime := self frameTime - elapsed

        if(sleepTime > 0,
            System sleep(sleepTime)
        )

        self lastFrameTime = Date now asNumber
        self frameCount = self frameCount + 1

        self
    )

    // Get current FPS
    getFPS := method(
        if(self frameCount > 0,
            elapsed := Date now asNumber - self lastFrameTime
            if(elapsed > 0, self frameCount / elapsed, 0)
        ,
            0
        )
    )

    // Reset frame counter
    reset := method(
        self frameCount = 0
        self lastFrameTime = Date now asNumber
        self
    )
)

// Register world components in global namespace
Lobby MorphicWorld := MorphicWorld
Lobby WindowManager := WindowManager
Lobby DisplayCoordinator := DisplayCoordinator

// Extend Telos with world management
Telos do(
    windowManager := WindowManager clone
    displayCoordinator := DisplayCoordinator clone

    // Enhanced world creation
    createMorphicWorld := method(title,
        world := MorphicWorld withTitle(title)
        self windowManager openWindow(world)
        world
    )

    // Enhanced window management
    openMorphicWindow := method(title, width, height,
        world := MorphicWorld withTitleAndSize(title, width, height)
        self windowManager openWindow(world)
        self world = world  # Set as current world
        world
    )

    // Start morphic display loop
    startMorphicLoop := method(
        if(self world != nil,
            self displayCoordinator start
            self world start
        ,
            writeln("Telos: No world available to start morphic loop")
        )
        self
    )

    // Stop morphic display loop
    stopMorphicLoop := method(
        if(self world != nil,
            self world stop
        )
        if(self windowManager != nil,
            self windowManager closeWindow
        )
        self
    )
)

// Module load method
TelosMorphicWorld load := method(
    writeln("TelosMorphic-World: Morphic world and window management loaded")
    writeln("TelosMorphic-World: MorphicWorld, WindowManager, DisplayCoordinator registered")
    self
)

writeln("TelosMorphic-World: Morphic world and window management module loaded")

// Register TelosMorphicWorld in global namespace
Lobby TelosMorphicWorld := TelosMorphicWorld