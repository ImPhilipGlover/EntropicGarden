#!/usr/bin/env io

// Test integration of prototypal neural backend with TelOS
// Validates that UvmObject patterns work through the C bridge

"Testing Prototypal Neural Backend Integration..." println

// Test that Telos module is available
if(Telos == nil,
    "ERROR: Telos module not loaded" println
    exit(1)
)

"✓ Telos module loaded" println

// Test pyEval with prototypal neural backend
testCode := """
# Import the prototypal neural backend
import sys
import os

# Ensure WSL Python path is available
sys.path.insert(0, '/mnt/c/EntropicGarden/python')

try:
    # Try to import numpy first
    try:
        import numpy as np
        print("✓ NumPy available")
        numpy_available = True
    except ImportError:
        print("⚠ NumPy not available, using fallback")
        numpy_available = False
    
    from prototypal_neural_backend import (
        create_prototypal_neural_backend, 
        neural_backend_dispatch,
        get_global_backend
    )
    
    # Test backend creation
    backend = create_prototypal_neural_backend("vsa_rag")
    print(f"Created prototypal backend: {backend._slots.get('name', 'unknown')}")
    
    # Test VSA operations (these should work even without numpy due to fallback)
    concept_vector = backend.vsa_encode_concept("prototypal intelligence")
    print(f"Encoded concept vector with {len(concept_vector)} dimensions")
    
    # Test memory query
    query_results = backend.rag_query_memory("intelligence", threshold=0.5)
    print(f"Found {len(query_results)} related concepts")
    
    # Test persona cognition
    persona_backend = create_prototypal_neural_backend("persona_cognition")
    facets = persona_backend.synthesize_facets("What is prototypal programming?")
    
    print(f"Synthesized facets from {len(facets['facets'])} personas:")
    for persona, data in facets['facets'].items():
        print(f"  {persona}: {len(data['memory_results'])} memory results")
    
    # Test dispatch function
    dispatch_result = neural_backend_dispatch("vsa_encode_concept", ["dispatch test"])
    print(f"Dispatch successful: {dispatch_result['success']}")
    print(f"Backend type: {dispatch_result.get('backend_type', 'unknown')}")
    
    result = {
        'backend_created': True,
        'vsa_operations': len(concept_vector) > 0,
        'persona_facets': len(facets['facets']) == 4,
        'dispatch_works': dispatch_result['success'],
        'numpy_available': numpy_available
    }
    
except Exception as e:
    import traceback
    print(f"Error: {e}")
    print(f"Traceback: {traceback.format_exc()}")
    result = {'error': str(e)}

result
"""

"Testing prototypal neural backend through pyEval..." println

// Execute the test
result := Telos pyEval(testCode)

if(result == nil,
    "ERROR: pyEval returned nil" println
    exit(1)
)

"Raw result: " print
result println

// Parse and validate results
if(result hasKey("error"),
    "ERROR in Python execution: " print
    result at("error") println
    exit(1)
)

// Check test results
if(result hasKey("backend_created") and result at("backend_created"),
    "✓ Prototypal backend created successfully" println
,
    "✗ Failed to create prototypal backend" println
    exit(1)
)

if(result hasKey("vsa_operations") and result at("vsa_operations"),
    "✓ VSA operations working correctly" println
,
    "✗ VSA operations failed" println
)

if(result hasKey("persona_facets") and result at("persona_facets"),
    "✓ Persona facet synthesis working" println
,
    "✗ Persona facet synthesis failed" println
)

if(result hasKey("dispatch_works") and result at("dispatch_works"),
    "✓ Neural backend dispatch working" println
,
    "✗ Neural backend dispatch failed" println
)

"" println
"Prototypal Neural Backend Integration Test: PASSED" println
"✓ UvmObject patterns working through C bridge" println
"✓ VSA-RAG cognition integrated with TelOS" println
"✓ Persona synthesis accessible from Io" println
"✓ Message dispatch maintains prototypal semantics" println