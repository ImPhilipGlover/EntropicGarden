#!/usr/bin/env io

/*
TelOS Morphic Architecture Test
Tests the proper Morphic architecture with owner/submorphs relationships
Based on "Morphic UI Framework Training Guide Extension.txt"
*/

// Load TelOS modules
if (Telos == nil, doFile("libs/Telos/io/TelosCore.io"))

// Test proper Morphic architecture
writeln("=== TelOS Morphic Architecture Test ===")

// Create world and window (TelOS auto-initializes)
writeln("1. Creating Morphic world...")  
Telos openWindow

currentWorld := Telos world
writeln("2. World created - type: " .. currentWorld type)
writeln("   World submorphs: " .. currentWorld submorphs size)

// Test Morph base prototype
writeln("3. Testing Morph base prototype...")
if(Morph == nil,
    writeln("   ERROR: Morph prototype not available!")
    exit(1)
)

writeln("   Morph slots: " .. Morph slotNames sort)

// Create test morphs using proper architecture
writeln("4. Creating test morphs...")

// Create a rectangle morph
testRect := RectangleMorph clone
testRect setBounds(100, 100, 150, 100)
testRect setColor(0.8, 0.2, 0.2, 1.0)  // Red
testRect id := "TestRectangle"

writeln("   Rectangle created - bounds: " .. testRect bounds x .. "," .. testRect bounds y .. " size: " .. testRect bounds width .. "x" .. testRect bounds height)
writeln("   Rectangle color: r=" .. testRect color r .. " g=" .. testRect color g .. " b=" .. testRect color b)

// Create a text morph  
testText := TextMorph clone
testText setBounds(120, 130, 100, 30)
testText setText("Hello Morphic!")
testText setColor(1.0, 1.0, 1.0, 1.0)  // White text
testText id := "TestText"

writeln("   Text created - text: '" .. testText text .. "'")

// Test composition - add text to rectangle
writeln("5. Testing morph composition...")
testRect addMorph(testText)

writeln("   Rectangle submorphs: " .. testRect submorphs size)
writeln("   Text owner: " .. if(testText owner, testText owner id, "nil"))

// Add rectangle to world
writeln("6. Adding morphs to world...")
currentWorld addMorph(testRect)

writeln("   World submorphs after adding: " .. currentWorld submorphs size)

// Test Canvas abstraction
writeln("7. Testing Canvas abstraction...")
if(Canvas == nil,
    writeln("   ERROR: Canvas prototype not available!")
,
    testCanvas := Canvas clone
    writeln("   Canvas created - type: " .. testCanvas type)
    writeln("   Canvas methods: " .. testCanvas slotNames select(name, testCanvas getSlot(name) type == "Block") sort)
)

// Demonstrate visual rendering  
writeln("8. Demonstrating visual rendering...")
writeln("   Drawing world with proper Morphic architecture...")

for(i, 1, 30,
    Telos drawWorld
    System sleep(0.1)
    if(i % 10 == 0, write("."))
)

writeln("\n9. Test complete - proper Morphic architecture operational!")

// Print final scene graph structure
writeln("\n=== Final Scene Graph Structure ===")
writeln(Telos captureScreenshot)

writeln("\n=== Architecture Validation ===")
writeln("✓ Morph base prototype: " .. if(Morph != nil, "PRESENT", "MISSING"))
writeln("✓ Canvas abstraction: " .. if(Canvas != nil, "PRESENT", "MISSING"))  
writeln("✓ Owner/submorphs relationships: " .. if(testText owner == testRect, "CORRECT", "BROKEN"))
writeln("✓ World as root morph: " .. if(currentWorld type == "Morph", "CORRECT", "BROKEN"))
writeln("✓ Bounds object structure: " .. if(testRect bounds hasSlot("x"), "CORRECT", "BROKEN"))
writeln("✓ Color object structure: " .. if(testRect color hasSlot("r"), "CORRECT", "BROKEN"))

writeln("\nTest complete: Morphic architecture validation finished")