#!/usr/bin/env io

writeln("=== Morphic Interface Debug Test ===")

// Test step by step
writeln("Step 1: Create world...")
try(
    Telos createWorld
    writeln("✓ World created successfully")
) catch(e,
    writeln("✗ World creation failed: " .. e type)
    exit
)

writeln("Step 2: Open window...")
try(
    result := Telos openWindow("Debug Test", 800, 600)
    writeln("✓ Window opened successfully")
) catch(e,
    writeln("✗ Window opening failed: " .. e type)
    exit
)

writeln("Step 3: Test basic morph creation...")
try(
    testRect := RectangleMorph clone initialize(100, 100, 200, 100)
    writeln("✓ RectangleMorph created successfully")
) catch(e,
    writeln("✗ RectangleMorph creation failed: " .. e type)
    exit
)

writeln("Step 4: Add morph to world...")
try(
    Telos world addMorph(testRect)
    writeln("✓ Morph added to world successfully")
) catch(e,
    writeln("✗ Adding morph to world failed: " .. e type)
    exit  
)

writeln("Step 5: Test TextInputMorph creation...")
try(
    textInput := TextInputMorph clone initialize(150, 250, 300)
    writeln("✓ TextInputMorph created successfully")
) catch(e,
    writeln("✗ TextInputMorph creation failed: " .. e type)
    exit
)

writeln("Step 6: Test ChatInterface creation...")
try(
    chatInterface := ChatInterface clone initialize(50, 50)
    writeln("✓ ChatInterface created successfully") 
) catch(exception,
    writeln("✗ ChatInterface creation failed: " .. exception type)
    writeln("Checking ChatInterface availability...")
    if(Lobby hasSlot("ChatInterface"),
        writeln("ChatInterface is available in Lobby")
        writeln("ChatInterface type: " .. ChatInterface type)
    ,
        writeln("ChatInterface is NOT available in Lobby")
    )
    exit
)

writeln("All tests passed! Displaying for 5 seconds...")
counter := 0
while(counter < 50,
    Telos pyEval("import time; time.sleep(0.1)")
    counter = counter + 1
)

Telos closeWindow
writeln("✓ Debug test completed successfully")