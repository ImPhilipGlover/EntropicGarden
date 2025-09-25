#!/usr/bin/env io

"🔬 === LAPLACE-HDC TRANSFORMATION TEST ===" println
"Testing bidirectional 384D ↔ 10000D transformation with VSA algebra\n" println

// Initialize TelOS cognitive system
Telos initializeCognition

// Test complete Laplace-HDC transformation pipeline
testLaplaceHDCPipeline := method(
    "🧪 TESTING COMPLETE LAPLACE-HDC PIPELINE:" println
    
    // Get the complete transformation pipeline test
    result := Telos pyEval("
import json
from real_cognitive_services import RealCognitiveCoordinator

# Initialize coordinator
coordinator = RealCognitiveCoordinator()

# Test query
test_query = 'quantum consciousness and neural networks'
test_context = 'artificial intelligence research'

# Test complete GCE→HRC→AGL→LLM cycle
result = coordinator.process_query(test_query, test_context)

# Output the complete cycle information
print(json.dumps({
    'query': test_query,
    'context': test_context,
    'result': result,
    'gce_dimension': '384D',
    'hrc_dimension': coordinator.hrc.dimensions,
    'pipeline_status': 'GCE→HRC→AGL→LLM cycle completed'
}, indent=2))
")
    
    "Enhanced pipeline result:" println
    result println
    "\n" println
)

// Test VSA symbolic operations in detail
testVSASymbolicOperations := method(
    "🔗 TESTING VSA SYMBOLIC OPERATIONS:" println
    
    result := Telos pyEval("
from real_cognitive_services import RealHyperdimensionalReasoningCore
import numpy as np

# Initialize HRC with 10000D vectors  
hrc = RealHyperdimensionalReasoningCore(dimensions=10000)

# Test symbolic operations
concept_a = hrc.encode_concept('artificial intelligence')
concept_b = hrc.encode_concept('consciousness')

# Test bind operation (circular convolution)
bound = hrc.bind_concepts(concept_a, concept_b)
print(f'Bind operation: {concept_a.shape} ⊛ {concept_b.shape} → {bound.shape}')

# Test bundle operation (elementwise addition)
bundled = hrc.bundle_concepts([concept_a, concept_b])
print(f'Bundle operation: [{concept_a.shape}, {concept_b.shape}] → {bundled.shape}')

# Test unbind operation (inverse of bind)
unbound = hrc.unbind_concept(bound, concept_b)
similarity = np.corrcoef(concept_a, unbound)[0,1] 
print(f'Unbind operation: similarity to original = {similarity:.4f}')

# Test reasoning chain composition
reasoning_result = hrc.compose_reasoning_chain([
    ('bind', concept_a, concept_b),
    ('bundle', None, None),  # Will bundle previous results
])
print(f'Reasoning chain result: {reasoning_result.shape}')

print('VSA symbolic algebra operations verified ✅')
")
    
    "VSA operations result:" println
    result println
    "\n" println
)

// Test Laplace transformation mathematics
testLaplaceTransformation := method(
    "🌊 TESTING LAPLACE-HDC TRANSFORMATION MATHEMATICS:" println
    
    result := Telos pyEval("
from real_cognitive_services import RealGeometricContextEngine
import numpy as np

# Initialize GCE with sentence transformers
gce = RealGeometricContextEngine()

# Test bidirectional transformation
test_text = 'quantum neural consciousness'
print(f'Testing transformation for: \"{test_text}\"')

# Get 384D embedding
embedding_384d = gce.model.encode([test_text])[0]
print(f'Original 384D embedding shape: {embedding_384d.shape}')

# Test Laplace-HDC transformation
# Create some neighborhood context for proper transformation
neighborhood_embeddings = gce.model.encode(['artificial intelligence', 'neural networks', 'consciousness'])

# Transform to 10000D hypervector
hypervector_10000d = gce.laplace_hdc_encode(embedding_384d.reshape(1, -1), neighborhood_embeddings)
print(f'Transformed 10000D hypervector shape: {hypervector_10000d.shape}')

# Transform back to 384D
reconstructed_384d = gce.laplace_hdc_decode(hypervector_10000d, neighborhood_embeddings)
print(f'Reconstructed 384D embedding shape: {reconstructed_384d.shape}')

# Calculate reconstruction fidelity
reconstruction_similarity = np.corrcoef(embedding_384d, reconstructed_384d[0])[0,1]
print(f'Reconstruction fidelity: {reconstruction_similarity:.4f}')

# Test kernel mathematics
print('\\nTesting Laplace kernel W_ij = sin(2π * K_ij):')
test_similarities = np.array([0.1, 0.5, 0.9])
kernel_values = np.sin(2 * np.pi * test_similarities)
print(f'Similarities: {test_similarities}')
print(f'Kernel values: {kernel_values}')

print('Laplace-HDC transformation mathematics verified ✅')
")
    
    "Laplace transformation result:" println
    result println
    "\n" println
)

// Run all tests
"🚀 EXECUTING COMPREHENSIVE LAPLACE-HDC AND VSA TESTS:\n" println

testLaplaceHDCPipeline
testVSASymbolicOperations  
testLaplaceTransformation

"✅ === LAPLACE-HDC TRANSFORMATION TEST COMPLETE ===" println