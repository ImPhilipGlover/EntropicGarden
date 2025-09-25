// Comprehensive Real Cognitive Cycle Test for TelOS
// This test demonstrates the complete LLM-GCE-HRC-AGL cycle with real mathematical operations

writeln("🧠 === TELOS REAL COGNITIVE CYCLE TEST ===")
writeln("Testing real LLM-GCE-HRC-AGL cycle with mathematical operations")

// Test 1: Verify all components are loaded
writeln("\n📋 1. SYSTEM STATUS CHECK:")
writeln("   TelOS system loaded: " .. (Telos != nil))
writeln("   cognitiveQuery method: " .. (Telos hasSlot("cognitiveQuery")))
writeln("   Python FFI available: " .. (Telos hasSlot("pyEval")))

// Test 2: Direct Python Cognitive Services Test
writeln("\n🔬 2. PYTHON COGNITIVE SERVICES TEST:")
pythonTest := Telos pyEval("
import sys
import json
import traceback
sys.path.append('/mnt/c/EntropicGarden/python')

try:
    from real_cognitive_services import RealCognitiveCoordinator
    coordinator = RealCognitiveCoordinator()
    
    # Test the complete cognitive cycle
    query = 'What is the nature of consciousness?'
    context = 'neuroscience perspective'
    
    print('📊 Starting real cognitive query...')
    result = coordinator.real_cognitive_query(query, context)
    
    # Return detailed result
    output = {
        'status': 'success',
        'query': query,
        'context': context,
        'result_type': type(result).__name__,
        'result_keys': list(result.keys()) if isinstance(result, dict) else 'not_dict',
        'sample_content': str(result)[:200] + '...' if len(str(result)) > 200 else str(result)
    }
    
    json.dumps(output, indent=2, default=str)
    
except Exception as e:
    json.dumps({
        'status': 'error',
        'error': str(e),
        'traceback': traceback.format_exc()
    }, indent=2)
")

writeln("Python cognitive services result:")
writeln(pythonTest)

// Test 3: TelOS Cognitive Query Integration
writeln("\n🤖 3. TELOS COGNITIVE QUERY TEST:")

writeln("Calling: Telos cognitiveQuery('What is consciousness?', 'neuroscience')")
cogResult := Telos cognitiveQuery("What is consciousness?", "neuroscience")

writeln("Result type: " .. cogResult type)

if(cogResult type == "Map",
    writeln("Result is a Map object - examining contents:")
    
    // Try to examine the map contents
    if(cogResult hasSlot("keys"),
        keys := cogResult keys
        writeln("Map keys: " .. keys asString)
        
        keys foreach(key,
            writeln("  " .. key .. ": " .. cogResult at(key) asString)
        )
    ,
        writeln("Map object doesn't respond to 'keys' - trying manual inspection:")
        writeln("Raw map: " .. cogResult asString)
    )
,
    writeln("Result content: " .. cogResult asString)
)

// Test 4: Component by Component Analysis
writeln("\n🔍 4. COMPONENT ANALYSIS:")

// Test GCE directly if possible
if(Lobby hasSlot("GeometricContextEngine"),
    writeln("GCE prototype available: YES")
    gceTest := GeometricContextEngine clone
    if(gceTest initialize,
        writeln("GCE initialized successfully")
        candidates := gceTest retrieve("consciousness", Map clone)
        writeln("GCE retrieved candidates: " .. candidates size)
    ,
        writeln("GCE failed to initialize")
    )
,
    writeln("GCE prototype available: NO")
)

// Test HRC directly if possible  
if(Lobby hasSlot("HyperdimensionalReasoningCore"),
    writeln("HRC prototype available: YES")
    hrcTest := HyperdimensionalReasoningCore clone
    if(hrcTest initialize,
        writeln("HRC initialized successfully")
    ,
        writeln("HRC failed to initialize")
    )
,
    writeln("HRC prototype available: NO")
)

// Test 5: Real VSA Operations Check
writeln("\n⚡ 5. VSA OPERATIONS VERIFICATION:")
vsaTest := Telos pyEval("
import sys
sys.path.append('/mnt/c/EntropicGarden/python')

try:
    from real_cognitive_services import RealHyperdimensionalReasoningCore
    hrc = RealHyperdimensionalReasoningCore(dimensions=1000, vsa_type='HRR')
    
    # Test basic VSA operations
    import torch_hd
    a = torch_hd.random(1000, 'HRR')
    b = torch_hd.random(1000, 'HRR')
    
    # Binding operation
    bound = torch_hd.bind(a, b)
    
    # Bundling operation  
    bundled = torch_hd.bundle(a, b)
    
    result = {
        'vsa_working': True,
        'dimensions': 1000,
        'binding_similarity': torch_hd.cosine_similarity(bound, a).item(),
        'bundling_similarity': torch_hd.cosine_similarity(bundled, a).item(),
        'operations_completed': ['bind', 'bundle', 'cosine_similarity']
    }
    
    import json
    json.dumps(result, indent=2)
    
except Exception as e:
    import json
    json.dumps({'vsa_working': False, 'error': str(e)}, indent=2)
")

writeln("VSA operations test:")
writeln(vsaTest)

// Test 6: Ollama Integration Check
writeln("\n🦙 6. OLLAMA INTEGRATION CHECK:")
ollamaTest := Telos pyEval("
import requests
import json

try:
    # Test Ollama connectivity
    response = requests.post('http://localhost:11434/api/generate', 
        json={'model': 'gemma2:2b', 'prompt': 'What is 2+2?', 'stream': False},
        timeout=10
    )
    
    if response.status_code == 200:
        result = response.json()
        json.dumps({
            'ollama_working': True,
            'model': 'gemma2:2b',
            'test_response': result.get('response', 'no response field')[:100] + '...'
        }, indent=2)
    else:
        json.dumps({
            'ollama_working': False,
            'status_code': response.status_code,
            'error': 'HTTP error'
        }, indent=2)
        
except Exception as e:
    json.dumps({
        'ollama_working': False,
        'error': str(e)
    }, indent=2)
")

writeln("Ollama integration test:")
writeln(ollamaTest)

writeln("\n✅ === COMPREHENSIVE TEST COMPLETE ===")
writeln("Real TelOS cognitive architecture test completed with detailed diagnostics")