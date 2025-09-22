/*
   Test Morphic Object Access
*/

// Load TelOS Core (which loads all modules including TelosMorphic)
doFile("libs/Telos/io/TelosCore.io")

"=== Testing Morphic Object Access ===" println

// Test if RectangleMorph is accessible
if(Lobby hasSlot("RectangleMorph"),
    "✅ RectangleMorph found in global namespace" println
    rect := RectangleMorph clone
    "✅ RectangleMorph clone successful: " print
    rect id println
,
    "❌ RectangleMorph NOT found in global namespace" println
    "Available slots containing 'Rectangle':" println
    Lobby slotNames select(name, name containsAnyCaseOf("Rectangle")) foreach(println)
)

// Test TextMorph and CircleMorph too
if(Lobby hasSlot("TextMorph"),
    "✅ TextMorph found" println
,
    "❌ TextMorph NOT found" println
)

if(Lobby hasSlot("CircleMorph"),
    "✅ CircleMorph found" println
,
    "❌ CircleMorph NOT found" println
)