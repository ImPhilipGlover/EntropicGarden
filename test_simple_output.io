#!/usr/bin/env io

"Testing simple Python output..." println

result := Telos pyEval("print('TEST: Python is working'); import sys; print('Python version:', sys.version[:10])")
"Result:" println
result println

// Test if it's an encoding issue
result2 := Telos pyEval("import sys; sys.path.append('./python'); from real_cognitive_services import RealCognitiveCoordinator; c=RealCognitiveCoordinator(); print('SUCCESS: Cognitive system initialized')")
"Result2:" println  
result2 println

"Test complete" println