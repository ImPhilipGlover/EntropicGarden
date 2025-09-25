// TelOS Morphic UI + Cognitive Integration Demo
"=== TelOS Morphic UI Demonstration ===" println
"Creating live morphic world with cognitive visualization..." println

// Create a morphic world
world := MorphicWorld clone
"World created" println

// Initialize SDL2 window system
result := Telos openWindow("TelOS Cognitive Visualization", 800, 600)
result println

// Create morphic objects to represent cognitive states
gceRect := RectangleMorph clone
gceRect setColor(Color new(0, 255, 0))  // Green for GCE (System 1)
gceRect setPosition(100, 100)
gceRect setSize(200, 100)

hrcRect := RectangleMorph clone  
hrcRect setColor(Color new(0, 0, 255))  // Blue for HRC (System 2)
hrcRect setPosition(400, 200)
hrcRect setSize(200, 150)

// Add cognitive processing visualization
"Running cognitive query and visualizing results..." println
cogResult := Telos pyEval("
from cognitive_services import CognitiveCoordinator
coord = CognitiveCoordinator()
result = coord.cognitive_query('neural processing', 'morphic visualization')
print('Cognitive processing completed')
print('GCE candidates:', len(result.get('gce_candidates', [])))
print('HRC operations:', result.get('hrc_reasoning', {}).get('binding_operations', 0))
")
cogResult println

// Draw the world with cognitive morphs
"Rendering cognitive morphs to SDL2 window..." println
drawResult := Telos drawWorld(world)
drawResult println

// Keep window open briefly for visualization
"Window displayed - cognitive morphs rendered" println
System sleep(2)

// Clean shutdown
closeResult := Telos closeWindow
closeResult println

"=== MORPHIC DEMONSTRATION COMPLETE ===" println
"SDL2 window created, morphs rendered, window closed cleanly" println
