/*
   TelosMorphic.io - Direct Manipulation UI: Living Objects in Visual Space
   MINIMAL VERSION FOR TESTING
*/

// === TELOS MORPHIC MODULE ===

TelosMorphic := Object clone
TelosMorphic version := "1.0.0 (modular-prototypal)"
TelosMorphic loadTime := Date clone now

// Load method required by TelosCore
TelosMorphic load := method(
    writeln("TelOS Morphic: Direct Manipulation UI module loaded - visual interface ready")
    self
)

writeln("TelOS Morphic: Minimal test version loaded")