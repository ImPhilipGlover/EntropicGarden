/*
   Simple Morphic Object Test
*/

// Load TelOS Core just once
doFile("libs/Telos/io/TelosCore.io")

"=== Testing Module Objects ===" println

// Check if TelosMorphic object exists
if(Lobby hasSlot("TelosMorphic"),
    "✅ TelosMorphic module object found" println
    
    // Try to call load method manually
    if(TelosMorphic hasSlot("load"),
        "✅ TelosMorphic has load method, calling it..." println
        TelosMorphic load
    ,
        "❌ TelosMorphic has no load method" println
    )
,
    "❌ TelosMorphic module object NOT found" println
)

// Check what global objects exist
"Available global slots after loading:" println
Lobby slotNames size println

// Check specifically for Morphic-related slots
Lobby slotNames foreach(name,
    if(name asLowercase containsSeq("morph"),
        ("Found morph-related slot: " .. name) println
    )
)