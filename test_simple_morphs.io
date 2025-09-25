// Minimal Working Morphic System - Proper Io Syntax
// Following IoGuide.html and IoTutorial.html conventions

// Base Morph prototype
Morph := Object clone
Morph x := 0
Morph y := 0  
Morph width := 100
Morph height := 100

// ButtonMorph inherits from Morph
ButtonMorph := Morph clone
ButtonMorph label := "Button"

ButtonMorph leftMouseDown := method(event,
    ("Button clicked: " .. self label) println
    self
)

// RectangleMorph inherits from Morph  
RectangleMorph := Morph clone
RectangleMorph color := "blue"

// Test the morphs exist
"Testing morphs..." println
ButtonMorph println
RectangleMorph println

// Test creating instances
button := ButtonMorph clone
button label := "Test Button"
button leftMouseDown(nil)

rectangle := RectangleMorph clone  
rectangle color := "red"
("Rectangle color: " .. rectangle color) println

"Morphs work correctly!" println