#!/usr/bin/env io

// Direct SDL2 test with comprehensive error logging
writeln("=== SDL2 Window Creation Debug Test ===")

try(
    writeln("Testing SDL2 window creation with full debugging...")
    
    // Check if SDL2 environment is set up
    writeln("1. Checking display environment...")
    envCheck := Telos pyEval("import os; print(f'DISPLAY={os.environ.get(\"DISPLAY\", \"NOT_SET\")}'); print(f'WAYLAND_DISPLAY={os.environ.get(\"WAYLAND_DISPLAY\", \"NOT_SET\")}')")
    writeln("Environment: " .. envCheck)
    
    // Test basic SDL2 availability
    writeln("2. Testing SDL2 Python binding...")
    sdlTest := Telos pyEval("
try:
    import subprocess
    result = subprocess.run(['pkg-config', '--cflags', '--libs', 'sdl2'], capture_output=True, text=True)
    print('SDL2 pkg-config result:', result.returncode == 0)
    print('SDL2 flags:', result.stdout.strip())
    print('SDL2 errors:', result.stderr.strip())
except Exception as e:
    print('SDL2 check failed:', str(e))
'true'")
    writeln("SDL2 Test: " .. sdlTest)
    
    // Now test the actual window creation
    writeln("3. Attempting SDL2 window creation...")
    
    // Check if openWindow method exists
    if(Telos hasSlot("openWindow"),
        writeln("✓ openWindow method available")
        
        // Try creating window with explicit error handling
        writeln("Creating window with title 'TelOS Debug Test'...")
        
        // Call the C function directly and capture any errors
        result := Telos openWindow("TelOS Debug Test", 800, 600)
        writeln("Window creation result: " .. result asString)
        
        if(result == true or result asString == "true",
            writeln("✓ Window creation reported success")
            writeln("Keeping window open for 5 seconds...")
            
            // Keep window alive
            for(i, 1, 50,
                Telos pyEval("
import time
time.sleep(0.1)
")
            )
            
            writeln("Test completed - window should have been visible")
        ,
            writeln("✗ Window creation failed: " .. result asString)
        )
    ,
        writeln("✗ openWindow method not available")
        writeln("Available methods:")
        Telos slotNames foreach(slot, writeln("  " .. slot))
    )
    
) catch(Exception,
    writeln("Error in SDL2 test: " .. Exception description)
    writeln("Exception type: " .. Exception type)
)

writeln("=== Debug Test Complete ===")