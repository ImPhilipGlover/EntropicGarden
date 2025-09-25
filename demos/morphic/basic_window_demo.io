#!/usr/bin/env io
/*
   Basic Morphic Window Demo - TelOS Living Image Demonstration
   
   This demo showcases the fundamental Morphic UI capabilities:
   - SDL2 window creation
   - Live Morph objects with direct manipulation
   - Real-time property modification
   - Event handling and interaction
   
   Usage: Run from Io REPL with: doFile("demos/morphic/basic_window_demo.io")
*/

writeln("=== TelOS Morphic UI Demo - Basic Window ===")
writeln("Initializing Living Image demonstration...")
writeln()

// Create the Morphic world - this initializes the SDL2 backend
writeln("1. Creating Morphic world...")
Telos createWorld
writeln("   ✓ World created with bounds: " .. Telos world bounds asString)

// Open the actual SDL2 window
writeln("2. Opening SDL2 window...")
Telos openWindow
writeln("   ✓ SDL2 window opened: 'The Entropic Garden' (640x480)")
writeln()

// Create live morphic objects
writeln("3. Creating live Morphic objects...")

// Red rectangle - demonstrates basic morph creation
writeln("   Creating red rectangle...")
redRect := RectangleMorph clone
redRect setColor(1, 0, 0, 1)          // Bright red
redRect setPosition(100, 100)
redRect setSize(120, 80)
redRect id := "RedRectangle"
Telos world addMorph(redRect)
writeln("   ✓ Red rectangle added at (100,100) with size 120x80")

// Blue circle - demonstrates specialized morph types
writeln("   Creating blue circle...")
blueCircle := CircleMorph clone
blueCircle setColor(0, 0.3, 1, 0.8)   // Semi-transparent blue
blueCircle setPosition(250, 150)
blueCircle setRadius(45)
blueCircle id := "BlueCircle"
Telos world addMorph(blueCircle)
writeln("   ✓ Blue circle added at (250,150) with radius 45")

// Green rectangle with different properties
writeln("   Creating green rectangle...")
greenRect := RectangleMorph clone
greenRect setColor(0, 0.8, 0, 0.9)    // Bright green, slightly transparent
greenRect setPosition(400, 200)
greenRect setSize(80, 120)
greenRect id := "GreenRectangle"
Telos world addMorph(greenRect)
writeln("   ✓ Green rectangle added at (400,200) with size 80x120")

// Text morph - demonstrates text rendering
writeln("   Creating text morph...")
titleText := TextMorph clone
titleText setText("Living Image Demo")
titleText setPosition(50, 50)
titleText setColor(1, 1, 1, 1)        // White text
titleText setFontSize(24)
titleText id := "TitleText"
Telos world addMorph(titleText)
writeln("   ✓ Title text added at (50,50)")

// Status text
statusText := TextMorph clone
statusText setText("All objects are live and inspectable!")
statusText setPosition(50, 400)
statusText setColor(0.8, 0.8, 0.8, 1) // Light gray
statusText setFontSize(16)
statusText id := "StatusText"
Telos world addMorph(statusText)
writeln("   ✓ Status text added at (50,400)")

writeln()
writeln("4. Demo objects created successfully!")
writeln("   Total morphs in world: " .. Telos world submorphs size)
writeln()

writeln("=== Living Image Capabilities ===")
writeln("All objects are now live in the Io system. You can:")
writeln("• Inspect any object: redRect inspect")
writeln("• Modify properties: redRect setColor(1, 1, 0, 1)")
writeln("• Move objects: blueCircle setPosition(300, 100)")
writeln("• Change text: titleText setText(\"Modified at Runtime!\")")
writeln("• Add new morphs: Telos world addMorph(CircleMorph clone)")
writeln()

writeln("=== Available Objects ===")
writeln("• redRect - Red rectangle morph")
writeln("• blueCircle - Blue circle morph") 
writeln("• greenRect - Green rectangle morph")
writeln("• titleText - Title text morph")
writeln("• statusText - Status text morph")
writeln("• Telos world - The root world containing all morphs")
writeln()

writeln("Try interacting with the objects in real-time!")
writeln("The window should now be visible with your live Morphic objects.")
writeln()

// Return the world for further interaction
Telos world