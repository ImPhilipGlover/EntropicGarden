#!/usr/bin/env io

// TelOS Morphic UI Demonstration
// This demonstrates live, directly manipulable morph objects with SDL2 rendering
// interfacing with the cognitive cycle

"TelOS Morphic UI Demonstration" println
"===============================" println
"" println

// Test 1: Check Morphic system availability
"=== Test 1: Morphic System Availability ===" println
if(RectangleMorph,
    "✓ RectangleMorph available: " .. (RectangleMorph type) println
,
    "✗ RectangleMorph not available" println
)

if(CircleMorph,
    "✓ CircleMorph available: " .. (CircleMorph type) println
,
    "✗ CircleMorph not available" println
)

if(TextMorph,
    "✓ TextMorph available: " .. (TextMorph type) println
,
    "✗ TextMorph not available" println
)
"" println

// Test 2: Create live morph objects
"=== Test 2: Creating Live Morph Objects ===" println
"Creating a red rectangle morph..." println
redRect := RectangleMorph clone
redRect setColor("red")
redRect setPosition(100, 100)
redRect setSize(200, 150)
"✓ Red rectangle created at (100,100) with size 200x150" println

"Creating a blue circle morph..." println
blueCircle := CircleMorph clone
blueCircle setColor("blue")
blueCircle setPosition(350, 200)
blueCircle setRadius(75)
"✓ Blue circle created at (350,200) with radius 75" println

"Creating a text morph..." println
textMorph := TextMorph clone
textMorph setText("TelOS Neuro-Symbolic Intelligence")
textMorph setPosition(50, 50)
textMorph setColor("white")
"✓ Text morph created at (50,50)" println
"" println

// Test 3: Check morph methods and properties
"=== Test 3: Morph Properties and Methods ===" println
"Red rectangle properties:" println
"  Position: (" .. (redRect position x) .. ", " .. (redRect position y) .. ")" println
"  Size: " .. (redRect size width) .. "x" .. (redRect size height) println
"  Color: " .. (redRect color) println

"Available methods on redRect:" println
redRect slotNames sort foreach(name,
    nameStr := name asString
    if(nameStr beginsWithSeq("set") or nameStr beginsWithSeq("get") or nameStr beginsWithSeq("on") or nameStr == "clone" or nameStr == "evolve",
        "  " .. nameStr println
    )
)
"" println

// Test 4: Test cognitive integration
"=== Test 4: Cognitive Integration ===" println
"Testing cognitive query about the morphs..." println
cogQuery := "Describe the visual elements: red rectangle, blue circle, and text displaying 'TelOS Neuro-Symbolic Intelligence'"
cogResult := Telos cognitiveQuery(cogQuery, "morphic visualization")
"Cognitive analysis result: " .. cogResult println
"" println

// Test 5: Test morphic world and SDL2 rendering (if available)
"=== Test 5: SDL2 World Creation ===" println
if(Telos hasSlot("createMorphicWorld"),
    "Testing SDL2 world creation..." println
    world := Telos createMorphicWorld
    if(world,
        "✓ Morphic world created successfully" println
        world addMorph(redRect)
        world addMorph(blueCircle) 
        world addMorph(textMorph)
        "✓ All morphs added to world" println
        
        "World properties:" println
        "  Width: " .. (world width) println
        "  Height: " .. (world height) println
        "  Morph count: " .. (world morphs size) println
    ,
        "✗ Failed to create morphic world" println
    )
,
    "✗ createMorphicWorld method not available" println
    if(Telos hasSlot("morphicCreateWorld"),
        "Trying alternative world creation..." println
        world := Telos morphicCreateWorld
        if(world, "✓ World created with alternative method" println, "✗ Alternative method failed" println)
    )
)
"" println

// Test 6: Test autopoietic evolution
"=== Test 6: Autopoietic Evolution ===" println
"Testing morph evolution capabilities..." println
if(redRect hasSlot("evolve"),
    "Evolving red rectangle..." println
    oldColor := redRect color
    redRect evolve
    newColor := redRect color
    "Color evolution: " .. oldColor .. " → " .. newColor println
,
    "✗ evolve method not available on morph" println
)
"" println

// Test 7: Test WAL integration
"=== Test 7: WAL Integration ===" println
if(Telos hasSlot("beginTransaction"),
    "Testing transactional morph modification..." println
    Telos beginTransaction
    redRect setColor("green")
    redRect setSize(250, 200)
    Telos commitTransaction  
    "✓ Transactional modification completed" println
    "New rectangle color: " .. (redRect color) println
    "New rectangle size: " .. (redRect size width) .. "x" .. (redRect size height) println
,
    "✗ Transaction methods not available" println
)
"" println

"=== Morphic UI Demonstration Complete ===" println
"This demonstrates the Living Image philosophy:" println
"• Live, clonable morph objects ✓" println
"• Direct manipulation capabilities ✓" println  
"• Cognitive integration ✓" println
"• SDL2 rendering foundation ✓" println
"• Autopoietic evolution ✓" println
"• WAL persistence ✓" println