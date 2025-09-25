// TelOS System Diagnostic - Check what's actually working
"=== TelOS System Diagnostic ===" println
"" println

// 1. Basic TelOS system check
"1. TelOS Core System:" println
"   Type: " print
Telos type println
"   Available? " print
if(Telos, "✓ YES" println, "✗ NO" println)

// 2. Check all available slots on Telos
"" println
"2. Available TelOS Methods:" println
Telos slotNames sort foreach(slot,
    "   " print
    slot print
    " -> " print
    (Telos getSlot(slot) type) println
)

// 3. Check for Morphic-related objects
"" println  
"3. Morphic System Check:" println

morphicObjects := list("RectangleMorph", "TextMorph", "CircleMorph", "Morph", "World")
morphicObjects foreach(objName,
    "   " print
    objName print
    ": " print
    try(
        obj := self doString(objName)
        if(obj,
            "✓ Available (" print
            obj type print
            ")" println,
            "✗ Not found" println
        )
    ,
        "✗ Error accessing" println
    )
)

// 4. Check FFI system
"" println
"4. FFI System Check:" println
"   ffiHealth: " print
try(
    result := Telos ffiHealth
    result println
,
    "✗ Error calling ffiHealth" println
)

// 5. Check Python integration
"" println  
"5. Python Integration Check:" println
"   pyEval test: " print
try(
    result := Telos pyEval("print('Python OK')")
    "✓ " print
    result println
,
    "✗ Python integration failed" println  
)

// 6. Check specific Morphic methods
"" println
"6. Morphic Method Check:" println
morphicMethods := list("openWindow", "createWorld", "initializeSDL2")
morphicMethods foreach(method,
    "   " print
    method print
    ": " print
    if(Telos hasSlot(method),
        "✓ Available" println,
        "✗ Not found" println
    )
)

// 7. Try to get more specific info about window creation
"" println
"7. Window System Details:" println
try(
    "   Attempting basic window creation..." println
    
    // Try different approaches to create a window
    if(Telos hasSlot("openWindow"),
        "   Telos openWindow method found, testing..." println
        window := Telos openWindow
        if(window,
            "   ✓ Window object created: " print
            window type println
            
            // Check window capabilities
            "   Window slots: " println
            window slotNames foreach(slot,
                "      " print
                slot println
            )
        ,
            "   ✗ Window creation returned nil" println
        )
    ,
        "   ✗ Telos openWindow method not available" println
    )
,
    "   ✗ Error in window creation test" println
)

// 8. SDL2 specific checks
"" println
"8. SDL2 System Check:" println
try(
    if(SDL2 != nil,
        "   ✓ SDL2 object available" println
        "   SDL2 type: " print
        SDL2 type println
    ,
        "   ✗ SDL2 object not found" println
    )
,
    "   ✗ Error checking SDL2" println
)

"" println
"=== Diagnostic Complete ===" println