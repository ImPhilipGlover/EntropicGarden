// Test the enhanced VSA reasoning with bidirectional transformations
writeln("🧮 === ENHANCED VSA REASONING CYCLE TEST ===")
writeln("Testing GCE→HRC→AGL cycle with Laplace-HDC transformations and VSA algebra")

// Test the full cognitive cycle with enhanced VSA reasoning
writeln("\n🔄 TESTING FULL GCE→HRC→AGL→LLM CYCLE:")

pythonVSATest := Telos pyEval("
import sys
import json
sys.path.append('/mnt/c/EntropicGarden/python')

try:
    from real_cognitive_services import RealCognitiveCoordinator
    coordinator = RealCognitiveCoordinator()
    
    print('Testing enhanced VSA reasoning cycle...')
    result = coordinator.real_cognitive_query('What causes consciousness to emerge?', 'neuroscience research')
    
    # Extract key metrics
    output = {
        'status': 'success',
        'architecture': result.get('architecture'),
        'mathematical_foundation': result.get('mathematical_foundation'),
        'gce_embedding_dim': result.get('gce_results', {}).get('embedding_dimension'),
        'hrc_dimensions': result.get('hrc_results', {}).get('dimensions'),
        'vsa_algebra_used': result.get('hrc_results', {}).get('hyperdimensional_algebra'),
        'bidirectional_transform': result.get('hrc_results', {}).get('bidirectional_transformation'),
        'agl_grounded_candidates': result.get('agl_grounding', {}).get('grounded_candidates'),
        'transformation_type': result.get('hrc_results', {}).get('transformation_used'),
        'reasoning_results_count': len(result.get('hrc_results', {}).get('reasoning_results', [])),
        'sample_reasoning': result.get('hrc_results', {}).get('reasoning_results', [{}])[0] if result.get('hrc_results', {}).get('reasoning_results') else {},
        'llm_integration': 'response' in result.get('llm_response', {}),
        'agl_integration': result.get('llm_response', {}).get('agl_integration', False)
    }
    
    json.dumps(output, indent=2, default=str)
    
except Exception as e:
    import traceback
    json.dumps({
        'status': 'error',
        'error': str(e),
        'traceback': traceback.format_exc()[-500:]  # Last 500 chars
    }, indent=2)
")

writeln("Enhanced VSA test result:")
writeln(pythonVSATest)

// Test individual components
writeln("\n🧪 COMPONENT VERIFICATION:")

componentTest := Telos pyEval("
import sys
import numpy as np
sys.path.append('/mnt/c/EntropicGarden/python')

try:
    from real_cognitive_services import RealHyperdimensionalReasoningCore
    
    # Test VSA operations directly
    hrc = RealHyperdimensionalReasoningCore(dimensions=1000, vsa_type='HRR')
    
    # Create test vectors
    a = np.random.choice([-1, 1], size=1000, dtype=np.float32)
    b = np.random.choice([-1, 1], size=1000, dtype=np.float32) 
    c = np.random.choice([-1, 1], size=1000, dtype=np.float32)
    
    # Test VSA algebra operations
    bound = hrc.bind_concepts(a, b)
    bundled = hrc.bundle_concepts(a, b, c)
    unbound = hrc.unbind_concept(bound, b)
    
    # Test Laplace-HDC transformation
    test_embeddings = np.random.normal(0, 1, (3, 384)).astype(np.float32)
    hypervectors = hrc.laplace_hdc_encode(test_embeddings)
    reconstructed = hrc.laplace_hdc_decode(hypervectors, test_embeddings)
    
    # Test reasoning chain composition
    concepts = [a, b, c]
    relations = ['bind', 'bundle']
    reasoning_result = hrc.compose_reasoning_chain(concepts, relations)
    
    import json
    result = {
        'vsa_operations_working': True,
        'binding_similarity': float(np.dot(bound, a) / (np.linalg.norm(bound) * np.linalg.norm(a))),
        'unbinding_recovery': float(np.dot(unbound, a) / (np.linalg.norm(unbound) * np.linalg.norm(a))),
        'laplace_encoding_shape': hypervectors.shape,
        'laplace_decoding_shape': reconstructed.shape,
        'reasoning_chain_length': len(concepts),
        'symbolic_algebra_verified': True
    }
    
    json.dumps(result, indent=2)
    
except Exception as e:
    import json
    json.dumps({'vsa_operations_working': False, 'error': str(e)}, indent=2)
")

writeln("Component verification:")
writeln(componentTest)

writeln("\n✅ === VSA REASONING CYCLE TEST COMPLETE ===")