#!/usr/bin/env io
"=== Working TelOS Morphic Visual Demo ===" println

// Based on diagnostic: openWindow and createWorld are available
// The system has RectangleMorph, TextMorph, CircleMorph, and world support

"1. Creating Morphic World..." println
world := Telos createWorld
if(world == nil,
    "ERROR: Failed to create world" println
    exit
,
    "✓ World created: " print
    world type println
)

"2. Testing morphs availability..." println
"RectangleMorph available: " print
(RectangleMorph != nil) println
"TextMorph available: " print  
(TextMorph != nil) println
"CircleMorph available: " print
(CircleMorph != nil) println

"3. Creating Rectangle Morph..." println
rect := RectangleMorph clone
if(rect != nil,
    "✓ Rectangle morph created: " print
    rect type println
    
    // Try to set basic properties if methods exist
    if(rect hasSlot("setSize"),
        rect setSize(100, 80)
        "✓ Rectangle size set to 100x80" println
    ,
        "- setSize method not available" println
    )
    
    if(rect hasSlot("setPosition"),
        rect setPosition(50, 50)
        "✓ Rectangle position set to (50,50)" println
    ,
        "- setPosition method not available" println
    )
    
    if(rect hasSlot("setColor"),
        rect setColor(255, 0, 0, 255)  // Red
        "✓ Rectangle color set to red" println
    ,
        "- setColor method not available" println
    )
,
    "ERROR: Failed to create rectangle morph" println
)

"4. Adding morph to world..." println
if(world hasSlot("addMorph") and rect != nil,
    result := world addMorph(rect)
    "✓ Morph added to world, result: " print
    result println
,
    "- addMorph not available or rect is nil" println
)

"5. Attempting window display..." println
if(Telos hasSlot("openWindow"),
    "Calling Telos openWindow..." println
    window := Telos openWindow
    "Window creation result: " print
    window type println
    
    // Check if window has display method
    if(window hasSlot("show"),
        window show
        "✓ Window show called" println
    ,
        "- Window show method not available" println
    )
    
    if(window hasSlot("display"),
        window display
        "✓ Window display called" println
    ,
        "- Window display method not available" println
    )
    
    if(window hasSlot("refresh"),
        window refresh
        "✓ Window refresh called" println
    ,
        "- Window refresh method not available" println
    )
,
    "ERROR: openWindow not available" println
)

"6. Trying main rendering loop..." println
if(Telos hasSlot("mainLoop"),
    "Attempting to start main loop..." println
    "NOTE: This may run indefinitely - use Ctrl+C to stop" println
    
    // Give user a moment to see the message
    if(Telos hasSlot("displayFor"),
        "Running display for 3 seconds..." println
        Telos displayFor(3)
    ,
        if(Telos hasSlot("presentFrame"),
            "Presenting single frame..." println
            Telos presentFrame
        ,
            "Starting main loop - press Ctrl+C to exit..." println
            Telos mainLoop
        )
    )
,
    "- mainLoop method not available" println
)

"7. Final system state check..." println
"World type: " print
if(world != nil, world type println, "nil" println)
"World morphs count: " print
if(world hasSlot("morphs"), 
    world morphs size println,
    "morphs slot not available" println
)

"=== Demo Complete ===" println