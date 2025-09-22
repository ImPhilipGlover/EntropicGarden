/*
   SDL2 Window Validation - Real Morphic Canvas Test
   Demonstrates actual SDL2 window creation with live rendering
   
   Expected Result: A 640x480 window opens with dark blue-gray background
   and an orange rectangle, displaying for 5 seconds with interactive events
*/

writeln("=== TelOS SDL2 Window Validation Slice ===")
writeln("Testing transition from console fallback to real SDL2 rendering...")

// Load TelOS system if not already loaded
if(Telos == nil,
    writeln("Error: Telos prototype not available")
    exit
)

writeln("Telos prototype found: " .. Telos type)

// Test 1: Create World
writeln("\n--- Test 1: Creating Morphic World ---")
world := Telos createWorld
writeln("World created: " .. world type)

// Test 2: Open SDL2 Window
writeln("\n--- Test 2: Opening SDL2 Window ---")
writeln("Expected: Real SDL2 window should open (not console fallback)")
Telos openWindow

// Test 3: Draw initial content
writeln("\n--- Test 3: Drawing World Content ---")
Telos drawWorld

// Test 4: Create test morph (orange rectangle)
writeln("\n--- Test 4: Creating Test Morph ---")
writeln("Expected: Orange rectangle should appear in window")
Telos createMorph

// Test 5: Display with event handling for 5 seconds
writeln("\n--- Test 5: Interactive Display Loop ---")
writeln("Window will display for 5 seconds with event handling...")
writeln("Try clicking the window or pressing keys!")
writeln("Close button should work to exit early")

Telos displayFor(5)

// Test 6: Close window cleanly
writeln("\n--- Test 6: Closing Window ---")
Telos closeWindow

writeln("\n=== SDL2 Window Validation Complete ===")
writeln("If you saw a real window (not just console text), SDL2 is working!")

// Test completion summary
writeln("\nValidation Results:")
writeln("✓ World creation: Complete")
writeln("✓ Window opening: Check for actual SDL2 window")
writeln("✓ Content rendering: Check for orange rectangle")
writeln("✓ Event handling: Check for responsive window")
writeln("✓ Clean shutdown: Complete")