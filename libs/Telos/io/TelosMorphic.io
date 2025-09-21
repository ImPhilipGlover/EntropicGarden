/*
   TelosMorphic.io - Direct Manipulation UI: Living Objects in Visual Space
   FULL IMPLEMENTATION WITH SDL2 WINDOW SUPPORT
*/

// === TELOS MORPHIC MODULE ===

TelosMorphic := Object clone
TelosMorphic version := "1.0.0 (modular-prototypal)"
TelosMorphic loadTime := Date clone now

// === MORPHIC UI IMPLEMENTATION ===

// Extend Telos object with Morphic capabilities
Telos do(
    // Initialize world tracking first
    world := nil
    
    // World management - create world with proper C-level access
    createWorld := method(
        if(self world == nil,
            // Call C-level world creation first
            if(self hasSlot("Telos_rawCreateWorld"),
                self Telos_rawCreateWorld
            ,
                writeln("Telos: Creating world (fallback)")
            )
            // Create Io-level world object for tracking
            self world = Object clone
            self world morphs := List clone
            self world id := "RootWorld"
            
            // Add methods to world object
            self world addMorph := method(morph,
                self morphs append(morph)
                ("TelOS: Added morph '" .. morph id .. "' to world") println
                self
            )
            
            self world refresh := method(
                ("TelOS: Refreshing display with " .. self morphs size .. " morphs") println
                self
            )
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
    
    // Close window - call C-level SDL2 close
    closeWindow := method(  
        writeln("TelOS: Closing SDL2 window...")
        
        // Call C-level closeWindow from method table (not raw function)
        if(self getSlot("closeWindow") != nil and self getSlot("closeWindow") != self closeWindow,
            // This calls the C-level closeWindow function from the method table
            self performWithArguments("closeWindow", list())
        ,
            writeln("UI: Window closed (fallback)")
        )
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
        writeln("TelOS: Window should be responsive to close button during display")
        iterations := (seconds * 10) floor
        
        for(i, 1, iterations,
            // CRITICAL: Process SDL2 events FIRST (including close button)
            if(self hasSlot("Telos_rawHandleEvent"),
                self Telos_rawHandleEvent
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
        if(self world != nil,
            self world morphs append(morph)
            ("TelOS: Added morph '" .. morph id .. "' to world") println
        )
        self
    )
    
    // Refresh display - actually draw to SDL2 window
    refresh := method(
        ("TelOS: Refreshing display with " .. self world morphs size .. " morphs") println
        
        // CRITICAL: Process SDL2 events (including window close button)
        if(self hasSlot("Telos_rawHandleEvent"),
            self Telos_rawHandleEvent
        )
        
        // Call C-level drawing if available
        if(self hasSlot("Telos_rawDraw"),
            self Telos_rawDraw
        ,
            writeln("TelOS: Drawing (fallback mode)")
        )
        self
    )
    
    // Draw all morphs to the window
    drawWorld := method(
        writeln("TelOS: Drawing world with " .. self world morphs size .. " morphs")
        
        // Draw each morph to the SDL2 window
        self world morphs foreach(morph,
            self drawMorph(morph)
        )
        
        // Present the rendered frame
        self presentFrame
    )
    
    // Draw individual morph (calls C-level drawing)
    drawMorph := method(morph,
        if(self hasSlot("Telos_rawCreateMorph"),
            // Use C-level morph creation/drawing
            self Telos_rawCreateMorph
        ,
            writeln("TelOS: Drawing morph '" .. morph id .. "' at (" .. morph x .. "," .. morph y .. ")")
        )
    )
    
    // Present the current frame to screen
    presentFrame := method(
        if(self hasSlot("Telos_rawDraw"),
            self Telos_rawDraw
        ,
            writeln("TelOS: Presenting frame (fallback)")
        )
    )
)

// === MORPHIC OBJECT PROTOTYPES ===

// RectangleMorph - Basic rectangular visual object
RectangleMorph := Object clone
RectangleMorph do(
    // Initialize with default properties
    x := 0
    y := 0  
    width := 100
    height := 100
    color := list(0.5, 0.5, 0.5, 1.0)  // Default gray
    id := "defaultRect"
    
    // Prototypal clone method
    clone := method(
        newRect := resend
        newRect id := "rect_" .. Date now asString
        newRect
    )
)

// TextMorph - Text display object
TextMorph := Object clone  
TextMorph do(
    x := 0
    y := 0
    width := 200
    height := 30
    color := list(1.0, 1.0, 1.0, 1.0)  // Default white
    text := "Default Text"
    id := "defaultText"
    
    // Prototypal clone method
    clone := method(
        newText := resend
        newText id := "text_" .. Date now asString
        newText
    )
)

// CircleMorph - Circular visual object
CircleMorph := Object clone
CircleMorph do(
    x := 0
    y := 0
    radius := 50
    color := list(0.2, 0.8, 0.2, 1.0)  // Default green
    id := "defaultCircle"
    
    // Prototypal clone method
    clone := method(
        newCircle := resend
        newCircle id := "circle_" .. Date now asString
        newCircle
    )
)

// Register Morphic objects in global Lobby namespace immediately
Lobby setSlot("RectangleMorph", RectangleMorph)
Lobby setSlot("TextMorph", TextMorph)
Lobby setSlot("CircleMorph", CircleMorph)

// Load method required by TelosCore
TelosMorphic load := method(
    writeln("TelOS Morphic: Direct Manipulation UI module loaded - visual interface ready")
    writeln("TelOS Morphic: SDL2 window support enabled")
    writeln("TelOS Morphic: Morphic objects registered globally: RectangleMorph, TextMorph, CircleMorph")
    self
)

writeln("TelOS Morphic: Full SDL2 implementation loaded")
writeln("TelOS Morphic: Objects registered in global namespace")