/*
   Minimal SDL2 Window Test - Direct C Function Calls
   Bypasses module loading to test SDL2 functionality directly
   
   Expected Result: A real SDL2 window opens and displays content
*/

writeln("=== Minimal SDL2 Window Test ===")
writeln("Testing direct C function calls to SDL2...")

// Check if Telos is available
if(Telos == nil,
    writeln("Error: Telos prototype not available")
    exit
)

writeln("Telos prototype found: " .. Telos type)

// Test the C-level functions directly (bypass Io module loading)
writeln("\n--- Direct C Function Test ---")

// Step 1: Create world using C function
writeln("Creating world...")
if(Telos hasSlot("createWorld"),
    Telos createWorld
    writeln("✓ World created via C function")
,
    writeln("✗ createWorld method not available")
)

// Step 2: Open window using C function
writeln("Opening SDL2 window...")
if(Telos hasSlot("openWindow"),
    Telos openWindow
    writeln("✓ Window opened via C function")
,
    writeln("✗ openWindow method not available")
)

// Step 3: Test raw drawing functions if available
if(Telos hasSlot("Telos_rawDraw"),
    writeln("Drawing using raw C function...")
    Telos Telos_rawDraw
    writeln("✓ Raw drawing called")
,
    writeln("Raw drawing function not available")
)

// Step 4: Test raw morph creation if available
if(Telos hasSlot("Telos_rawCreateMorph"),
    writeln("Creating morph using raw C function...")
    Telos Telos_rawCreateMorph
    writeln("✓ Raw morph created")
,
    writeln("Raw morph creation function not available")
)

// Step 5: Wait a bit to see the window
writeln("Waiting 3 seconds for window to be visible...")
for(i, 1, 30,
    // Process events to keep window responsive
    if(Telos hasSlot("Telos_rawHandleEvent"),
        Telos Telos_rawHandleEvent
    )
    System sleep(0.1)
    if(i % 10 == 0, write("."))
)
writeln("")

// Step 6: Close window cleanly
writeln("Closing window...")
if(Telos hasSlot("closeWindow"),
    Telos closeWindow
    writeln("✓ Window closed via C function")
,
    writeln("✗ closeWindow method not available")
)

writeln("\n=== SDL2 Test Complete ===")
writeln("If a real window appeared (not console text), SDL2 is working!")