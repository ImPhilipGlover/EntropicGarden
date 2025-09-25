#!/usr/bin/env io

"🧪 Testing Cognitive Services with Simple Calls..." println

// Test 1: Simple import test
"Test 1: Testing imports..." println
result1 := Telos pyEval("import sys; sys.path.append('./python'); from real_cognitive_services import RealCognitiveCoordinator; print('RealCognitiveCoordinator imported successfully')")
result1 println

// Test 2: Initialize coordinator
"Test 2: Initializing coordinator..." println  
result2 := Telos pyEval("coordinator = RealCognitiveCoordinator(); print('Coordinator initialized with HRC dimensions:', coordinator.hrc.dimensions)")
result2 println

// Test 3: Test simple query
"Test 3: Testing process_query..." println
result3 := Telos pyEval("result = coordinator.process_query('artificial intelligence', 'computer science'); print('Query result:', result[:100] if len(result) > 100 else result)")
result3 println

"✅ Basic cognitive services test complete!" println