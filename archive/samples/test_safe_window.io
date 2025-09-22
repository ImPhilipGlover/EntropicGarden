/*
   Safe SDL2 Window Test - With automatic timeout and event handling
*/

// Load TelOS Core
doFile("libs/Telos/io/TelosCore.io")

"=== SAFE SDL2 Window Test (2 second timeout) ===" println

// Create world and open window
world := Telos createWorld
Telos openWindow

"Window opened! Should be responsive to close button..." println

// Create simple test content
rect := RectangleMorph clone  
rect x := 100
rect y := 100
rect width := 200
rect height := 150
rect color := list(0.8, 0.2, 0.2, 1.0)
rect id := "testRect"

world addMorph(rect)

"Displaying for 2 seconds with event processing..." println

// Safe display loop with event processing
for(i, 1, 20,  // 2 seconds = 20 * 0.1s
    // Process SDL2 events (including close button)
    if(Telos hasSlot("Telos_rawHandleEvent"),
        Telos Telos_rawHandleEvent
    )
    
    world refresh
    System sleep(0.1)
    if(i % 5 == 0, write("."))
)

writeln("\nClosing window...")
Telos closeWindow

"Test complete - window should be closed!" println