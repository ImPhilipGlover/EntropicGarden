// TelOS SDL2 Direct Rendering Demonstration
"=== TelOS SDL2 Graphics Demonstration ===" println

// Test SDL2 window creation directly
"Creating SDL2 window..." println
windowResult := Telos openWindow("TelOS Neuro-Symbolic Interface", 800, 600)
windowResult println

if(windowResult == "Window created successfully",
    then(
        "✓ SDL2 window successfully created and visible" println
        
        // Demonstrate cognitive processing during window display
        "Running cognitive processing while window is displayed..." println
        cogResult := Telos pyEval("
from cognitive_services import CognitiveCoordinator
coord = CognitiveCoordinator()
result = coord.cognitive_query('visual consciousness', 'morphic SDL2 rendering')
print('=== COGNITIVE PROCESSING DURING RENDERING ===')
print('GCE visual candidates:', len(result.get('gce_candidates', [])))  
print('HRC rendering operations:', result.get('hrc_reasoning', {}).get('binding_operations', 0))
print('Visual-cognitive integration complete')
")
        cogResult println
        
        // Test drawing operations
        "Attempting to draw to SDL2 surface..." println  
        drawResult := Telos drawWorld
        drawResult println
        
        // Keep window visible
        "Window displayed for 3 seconds - demonstrating persistent rendering" println
        System sleep(3)
        
        // Clean window closure
        "Closing SDL2 window..." println
        closeResult := Telos closeWindow
        closeResult println
        
        "✓ SDL2 window lifecycle complete: create → render → close" println
    ),
    else(
        "✗ SDL2 window creation failed" println
        windowResult println
    )
)

"=== SDL2 DEMONSTRATION COMPLETE ===" println
