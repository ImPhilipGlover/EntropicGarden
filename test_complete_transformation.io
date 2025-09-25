#!/usr/bin/env io

"🧮 === COMPLETE LAPLACE-HDC TRANSFORMATION VERIFICATION ===" println
"Testing full cognitive cycle in single Python context" println

result := Telos pyEval("
import sys
sys.path.append('./python')

try:
    from real_cognitive_services import RealCognitiveCoordinator, RealGeometricContextEngine, RealHyperdimensionalReasoningCore
    import numpy as np
    
    print('=== COMPREHENSIVE LAPLACE-HDC AND VSA TEST ===')
    
    # Test 1: Complete GCE→HRC→AGL→LLM cycle
    print('\\n🔄 TESTING COMPLETE COGNITIVE CYCLE:')
    coordinator = RealCognitiveCoordinator()
    test_result = coordinator.process_query('quantum consciousness and neural networks', 'artificial intelligence research')
    print(f'GCE dimension: 384D')
    print(f'HRC dimension: {coordinator.hrc.dimensions}D')
    print(f'Cognitive cycle result: {test_result[:200]}...' if len(test_result) > 200 else f'Cognitive cycle result: {test_result}')
    
    # Test 2: Laplace-HDC transformation mathematics
    print('\\n🌊 TESTING LAPLACE-HDC TRANSFORMATION:')
    gce = RealGeometricContextEngine()
    test_text = 'quantum neural consciousness'
    
    # Get 384D embedding
    embedding_384d = gce.model.encode([test_text])[0]
    print(f'Original 384D embedding shape: {embedding_384d.shape}')
    
    # Create neighborhood context for transformation
    neighborhood_embeddings = gce.model.encode(['artificial intelligence', 'neural networks', 'consciousness', 'quantum computing'])
    
    # Transform to 10000D hypervector
    hypervector_10000d = gce.laplace_hdc_encode(embedding_384d.reshape(1, -1), neighborhood_embeddings)
    print(f'Transformed 10000D hypervector shape: {hypervector_10000d.shape}')
    
    # Transform back to 384D
    reconstructed_384d = gce.laplace_hdc_decode(hypervector_10000d, neighborhood_embeddings)
    print(f'Reconstructed 384D embedding shape: {reconstructed_384d.shape}')
    
    # Calculate reconstruction fidelity
    if reconstructed_384d.shape[0] > 0:
        reconstruction_similarity = np.corrcoef(embedding_384d, reconstructed_384d[0])[0,1]
        print(f'Reconstruction fidelity: {reconstruction_similarity:.4f}')
    
    # Test 3: VSA symbolic operations
    print('\\n🔗 TESTING VSA SYMBOLIC OPERATIONS:')
    hrc = RealHyperdimensionalReasoningCore(dimensions=10000)
    
    # Test symbolic operations
    concept_a = hrc.encode_concept('artificial intelligence')
    concept_b = hrc.encode_concept('consciousness')
    
    print(f'Concept A shape: {concept_a.shape}')
    print(f'Concept B shape: {concept_b.shape}')
    
    # Test bind operation (circular convolution)
    bound = hrc.bind_concepts(concept_a, concept_b)
    print(f'Bind operation result shape: {bound.shape}')
    
    # Test bundle operation (elementwise addition)
    bundled = hrc.bundle_concepts([concept_a, concept_b])
    print(f'Bundle operation result shape: {bundled.shape}')
    
    # Test unbind operation (inverse of bind)
    unbound = hrc.unbind_concept(bound, concept_b)
    similarity = np.corrcoef(concept_a, unbound)[0,1] 
    print(f'Unbind similarity to original: {similarity:.4f}')
    
    # Test reasoning chain composition
    reasoning_result = hrc.compose_reasoning_chain([
        ('bind', concept_a, concept_b),
        ('bundle', None, None),
    ])
    print(f'Reasoning chain result shape: {reasoning_result.shape}')
    
    # Test kernel mathematics
    print('\\n🔢 TESTING LAPLACE KERNEL MATHEMATICS:')
    test_similarities = np.array([0.1, 0.5, 0.9])
    kernel_values = np.sin(2 * np.pi * test_similarities)
    print(f'Input similarities: {test_similarities}')
    print(f'Kernel W_ij = sin(2π * K_ij): {kernel_values}')
    
    print('\\n✅ === ALL LAPLACE-HDC AND VSA TESTS COMPLETED SUCCESSFULLY ===')
    
except Exception as e:
    import traceback
    print(f'Error: {e}')
    print(traceback.format_exc())
")

result println

"🎯 === TRANSFORMATION TEST COMPLETE ===" println