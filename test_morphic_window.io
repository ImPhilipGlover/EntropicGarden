// Test SDL2 morphic window creation and rendering
"=== Testing TelOS Morphic SDL2 Window Creation ===" println

// Test 1: Create world
"Creating Morphic World..." println
Telos createWorld
"World created successfully" println

// Test 2: Open SDL2 window  
"Opening SDL2 window..." println
Telos openWindow
"Window should now be visible" println

// Test 3: Create some morphic objects
"Creating morphic objects..." println

// Check if morphs are available
if(Lobby hasSlot("RectangleMorph") and Lobby hasSlot("CircleMorph"),
    // Create a red rectangle
    rect := RectangleMorph clone
    rect bounds setPosition(50, 50) setSize(200, 150)
    rect color setColor(1.0, 0.0, 0.0, 1.0)  // Red
    Telos addMorph(rect)
    
    // Create a blue circle
    circle := CircleMorph clone  
    circle bounds setPosition(300, 100) setSize(120, 120)
    circle color setColor(0.0, 0.0, 1.0, 1.0)  // Blue
    Telos addMorph(circle)
    
    // Create a green rectangle
    greenRect := RectangleMorph clone
    greenRect bounds setPosition(150, 250) setSize(150, 100)
    greenRect color setColor(0.0, 1.0, 0.0, 1.0)  // Green
    Telos addMorph(greenRect)
    
    // Create a text morph if available
    if(Lobby hasSlot("TextMorph"),
        textMorph := TextMorph clone
        textMorph text := "TelOS Morphic UI"
        textMorph bounds setPosition(50, 400) setSize(300, 30)
        textMorph color setColor(1.0, 1.0, 1.0, 1.0)  // White text
        Telos addMorph(textMorph)
    )
    
    "Morphic objects created and added to world" println
    "You should see: Red rectangle, Blue circle, Green rectangle, and white text" println
,
    "Morphic objects not available - TelosMorphic module may not have loaded properly" println
    "Available in Lobby:" println
    Lobby slotNames sort foreach(name, ("  " .. name) println)
)

// Test 4: Draw the world
"Drawing world..." println
Telos drawWorld
"World drawn to SDL2 renderer" println

// Debug: Check what morphs are in the world
"Debug: Checking world morphs..." println
world := Telos world
if(world,
    submorphs := world submorphs
    "World submorphs type: " .. submorphs type println
    "World has " .. submorphs size .. " submorphs:" println
    submorphs foreach(i, morph,
        "  Morph " .. i .. ": " .. morph type .. " (value: " .. morph .. ")" println
    )
    // Try to access morph properties
    if(submorphs size > 0,
        firstMorph := submorphs at(0)
        "First morph details:" println
        "  Type: " .. firstMorph type println
        "  Has bounds: " .. (firstMorph hasSlot("bounds")) println
        if(firstMorph hasSlot("bounds"),
            "  Bounds: (" .. firstMorph bounds x .. "," .. firstMorph bounds y .. ") " .. firstMorph bounds width .. "x" .. firstMorph bounds height println
        )
    )
,
    "No world object found!" println
)

// Test 5: Brief event loop test
"Starting brief event loop (5 seconds)..." println
"Window should show: Red rectangle, Blue circle, Green rectangle, and white text" println
"Press ESC or close window to exit early" println

for(i, 1, 50,
  Telos checkEvents
  Telos drawWorld  // Redraw each frame to show morphs
  if(Telos shouldExit, break)
  yield  // Let other processes run
  if(i % 10 == 0, "." print)  // Progress indicator
)

"" println
"Event loop test complete" println

// Test 6: Close window
"Closing window..." println  
Telos closeWindow
"Window closed" println

"=== SDL2 Morphic Test Complete ===" println
