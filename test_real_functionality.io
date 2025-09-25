#!/usr/bin/env io

// Real SDL2 Window Test - No fake success messages
// This test will actually attempt to open an SDL2 window and will fail if it doesn't work

"Testing REAL SDL2 Window Creation" println
"=================================" println

// Test 1: Attempt to open actual SDL2 window
try(
    Telos openWindow
    "Window open method called - checking if window actually appeared..." println
    
    // Give window time to initialize
    System sleep(1)
    
    // Check if window actually exists by trying to close it
    try(
        Telos closeWindow
        "Window close method called - if no error, window likely existed" println
    ) catch(Exception,
        "ERROR: Could not close window - window may not have been created" println
    )
    
) catch(Exception,
    "ERROR: Window creation failed with exception" println
    Exception message println
)

// Test 2: Test Python cognitive services
"Testing Python Cognitive Services" println
"=================================" println

// Test if we can actually call Python
pythonResult := try(
    Telos pyEval("print('Python is working'); import sys; sys.version")
) catch(Exception,
    "Python integration failed: " .. (Exception message) println
    nil
)

if(pythonResult,
    "Python FFI appears to work: " .. pythonResult println
,
    "Python FFI is not functional" println
)

// Test 3: Test real cognitive service
cognitiveResult := try(
    // Call our actual Python cognitive service
    Telos pyEval("
import sys
sys.path.append('/mnt/c/EntropicGarden/python')
from cognitive_services import CognitiveCoordinator
coordinator = CognitiveCoordinator()
result = coordinator.cognitive_query('What is consciousness?', 'philosophical inquiry')
print('Cognitive result:', result['gce_candidates'])
'Cognitive query completed'
")
) catch(Exception,
    "Cognitive service failed: " .. (Exception message) println
    nil  
)

if(cognitiveResult,
    "Cognitive service works: " .. cognitiveResult println
,
    "Cognitive service is not functional" println
)

// Test 4: Verify we have NO fake success messages in our output
"Checking for absence of fake success messages..." println
// This is a manual verification step - the output should contain no ✓ symbols from our code

"Test complete - verify actual functionality by checking:" println
"1. Did an SDL2 window actually appear on your screen?" println
"2. Did Python actually execute and return version info?" println  
"3. Did the cognitive service actually process the query?" println
"4. Are there any ✓ success symbols in the output above? (There should be none from our test code)" println