// TelOS Morphic Rectangle Demo
// This script tests the TelOS Morphic UI system by creating rectangle morphs

"=== TelOS Morphic Rectangle Demo ===" println
"" println

// Test basic TelOS functionality first
"Testing TelOS system..." println
"TelOS type: " print
Telos type println

"TelOS available slots:" println
Telos slotNames foreach(slot,
    "  - " print
    slot println
)
"" println

// Test Morphic system availability
"Testing Morphic system..." println
if(Telos hasSlot("openWindow"),
    "✓ Morphic window system available" println,
    "✗ Morphic window system not found" println
)

// Test Rectangle Morph creation
"" println
"Creating rectangle morphs..." println

// Try to create a simple rectangle morph
if(RectangleMorph,
    "✓ RectangleMorph prototype available" println
    
    // Create some rectangle morphs
    rect1 := RectangleMorph clone
    "✓ Created first rectangle morph" println
    
    rect2 := RectangleMorph clone  
    "✓ Created second rectangle morph" println
    
    // Try to set some properties
    if(rect1 hasSlot("setColor"),
        rect1 setColor("red")
        "✓ Set first rectangle color to red" println,
        "- Rectangle color setting not available" println
    )
    
    if(rect2 hasSlot("setColor"),
        rect2 setColor("blue") 
        "✓ Set second rectangle color to blue" println,
        "- Rectangle color setting not available" println
    )
    
    // Try to set positions
    if(rect1 hasSlot("setPosition"),
        rect1 setPosition(50, 50)
        "✓ Set first rectangle position to (50, 50)" println,
        "- Rectangle positioning not available" println
    )
    
    if(rect2 hasSlot("setPosition"),
        rect2 setPosition(150, 100)
        "✓ Set second rectangle position to (150, 100)" println,
        "- Rectangle positioning not available" println
    )
    
    // Try to set sizes
    if(rect1 hasSlot("setSize"),
        rect1 setSize(100, 80)
        "✓ Set first rectangle size to 100x80" println,
        "- Rectangle sizing not available" println
    )
    
    if(rect2 hasSlot("setSize"),
        rect2 setSize(120, 60)
        "✓ Set second rectangle size to 120x60" println,
        "- Rectangle sizing not available" println
    )
    
    // Try to create a window and add the morphs
    "" println
    "Attempting to create window and display morphs..." println
    
    if(Telos hasSlot("openWindow"),
        try(
            // Create a window
            window := Telos openWindow
            "✓ Window created successfully" println
            
            // Add rectangles to the window
            if(window hasSlot("addMorph"),
                window addMorph(rect1)
                "✓ Added first rectangle to window" println
                
                window addMorph(rect2) 
                "✓ Added second rectangle to window" println
                
                // Try to show the window
                if(window hasSlot("show"),
                    window show
                    "✓ Window shown - check for SDL2 window!" println,
                    "- Window show method not available" println
                )
            ,
                "- Window addMorph method not available" println  
            )
        ,
            // Catch any errors
            "✗ Error creating window: " print
            call message println
        ),
        "✗ Telos openWindow method not available" println
    )
,
    "✗ RectangleMorph prototype not found" println
)

"" println
"=== Demo Complete ===" println

// Keep the system alive for a moment to see any windows
"Waiting 3 seconds to observe any windows..." println
System sleep(3)

"Demo finished." println