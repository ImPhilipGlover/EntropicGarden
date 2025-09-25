// Test real cognitive integration
writeln("=== Testing Real TelOS Cognitive Services ===")

// Test 1: Basic Python FFI
writeln("\n1. Testing Python FFI:")
result1 := Telos pyEval("print('Python FFI working'); 'SUCCESS'")
writeln("Result: " .. result1)

// Test 2: Real Cognitive Services Import
writeln("\n2. Testing Real Cognitive Services Import:")
result2 := Telos pyEval("
import sys
sys.path.append('/mnt/c/EntropicGarden/python')
try:
    from real_cognitive_services import RealCognitiveCoordinator
    print('Real cognitive services imported successfully')
    coordinator = RealCognitiveCoordinator()
    'IMPORT_SUCCESS'
except Exception as e:
    print(f'Import failed: {e}')
    'IMPORT_FAILED'
")
writeln("Result: " .. result2)

// Test 3: Simple Cognitive Query (always run since imports are working)
writeln("\n3. Testing Simple Cognitive Query:")
queryResult := Telos pyEval("
import sys
import json
sys.path.append('/mnt/c/EntropicGarden/python')
from real_cognitive_services import RealCognitiveCoordinator
coordinator = RealCognitiveCoordinator()
try:
    result = coordinator.real_cognitive_query('What is consciousness?', 'brief')
    json.dumps({'status': 'success', 'result': str(result)})
except Exception as e:
    json.dumps({'status': 'error', 'error': str(e)})
")
writeln("Query Result: " .. queryResult)

// Test 4: TelOS cognitiveQuery method
writeln("\n4. Testing TelOS cognitiveQuery method:")
telosResult := Telos cognitiveQuery("What is consciousness?", "brief")
writeln("TelOS cognitiveQuery result type: " .. telosResult type)
if(telosResult type == "Map",
    writeln("TelOS cognitiveQuery result is a Map - checking contents..."),
    writeln("TelOS cognitiveQuery result: " .. telosResult asString)
)

writeln("\n=== Test Complete ===")