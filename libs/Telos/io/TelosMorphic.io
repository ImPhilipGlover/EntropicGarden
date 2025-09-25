// === TELOS MORPHIC UI FRAMEWORK ===
// Modular Morphic UI system for TelOS
// Extends Telos with Morphic capabilities

// Create the TelosMorphic module object
TelosMorphic := Object clone
TelosMorphic version := "1.0.0 (modular-prototypal)"
TelosMorphic loadTime := Date clone now

// Load method for module initialization
TelosMorphic load := method(
    writeln("TelosMorphic: Initializing modular Morphic UI framework...")
    
    // Load all Morphic submodules
    doFile("libs/Telos/io/TelosMorphic-Core.io")
    doFile("libs/Telos/io/TelosMorphic-Shapes.io")
    doFile("libs/Telos/io/TelosMorphic-UI.io")
    doFile("libs/Telos/io/TelosMorphic-World.io")
    doFile("libs/Telos/io/TelosMorphic-Cognitive.io")
    doFile("libs/Telos/io/TelosMorphic-Chat.io")
    doFile("libs/Telos/io/TelosMorphic-Autopoiesis.io")
    
    writeln("TelosMorphic: All submodules loaded successfully")
    self
)

// Extend Telos prototype with Morphic shortcuts if available
if(Lobby hasSlot("Telos"),
    // Add Morphic convenience methods to main Telos prototype
    Telos createMorphicWorld := method(TelosMorphic createWorld())
    Telos morphicCanvas := method(TelosMorphic getCanvas())
    
    extensionReporter := Object clone
    extensionReporter message := "TelosMorphic: Extended Telos prototype with Morphic operations"
    writeln(extensionReporter message)
,
    warningReporter := Object clone
    warningReporter message := "TelosMorphic: Warning - Telos prototype not available for extension"
    writeln(warningReporter message)
)

// Initialize the module
TelosMorphic load()