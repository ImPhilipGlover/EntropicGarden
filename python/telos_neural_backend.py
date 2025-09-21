#!/usr/bin/env python3
"""
TelOS Neural Computation Backend
===============================

Production-grade neural computation module for VSA-RAG cognitive dialogue.
Implements real hyperdimensional computing with torchhd, advanced vector search
with FAISS/HNSWLIB, and neural network scoring for the unbind→cleanup loop.

This is the "Python muscle" called by the Io mind through the FFI synaptic bridge.
"""

import numpy as np
import math
import os
import pickle
from typing import List, Dict, Any, Optional, Tuple, Union

# Advanced vector search backends
try:
    import faiss
    FAISS_AVAILABLE = True
except ImportError:
    FAISS_AVAILABLE = False

try:
    import hnswlib
    HNSWLIB_AVAILABLE = True
except ImportError:
    HNSWLIB_AVAILABLE = False

# Hyperdimensional computing with torchhd
try:
    import torch
    import torchhd
    from torchhd import functional as thdF
    from torchhd.tensors import FHRRTensor
    TORCHHD_AVAILABLE = True
except ImportError:
    TORCHHD_AVAILABLE = False

# Neural network frameworks
try:
    import torch.nn as nn
    import torch.optim as optim
    NN_AVAILABLE = True
except ImportError:
    NN_AVAILABLE = False

class VSANeuralComputer:
    """
    Core VSA (Vector Symbolic Architecture) neural computation engine.
    Implements FHRR (Fourier Holographic Reduced Representations) operations
    with real neural network learning and advanced vector search.
    """
    
    def __init__(self, dimensions=10000, device='cpu'):
        self.dimensions = dimensions
        self.device = device
        self.vector_memory = {}  # token -> hypervector storage
        self.concept_memory = []  # list of (vector, metadata) tuples
        self.neural_network = None
        self.faiss_index = None
        self.hnswlib_index = None
        self.is_trained = False
        
        # Initialize neural network for semantic scoring
        if NN_AVAILABLE:
            self._initialize_neural_network()
    
    def _initialize_neural_network(self):
        """Initialize neural network for semantic similarity scoring."""
        class SemanticScorer(nn.Module):
            def __init__(self, input_dim):
                super().__init__()
                self.encoder = nn.Sequential(
                    nn.Linear(input_dim, 512),
                    nn.ReLU(),
                    nn.Dropout(0.2),
                    nn.Linear(512, 256),
                    nn.ReLU(),
                    nn.Dropout(0.2),
                    nn.Linear(256, 128),
                    nn.ReLU(),
                    nn.Linear(128, 1),
                    nn.Sigmoid()
                )
            
            def forward(self, x):
                return self.encoder(x)
        
        self.neural_network = SemanticScorer(self.dimensions * 2)  # Concatenated vector pairs
        self.optimizer = optim.Adam(self.neural_network.parameters(), lr=0.001)
        self.criterion = nn.BCELoss()
    
    def generate_hypervector(self, seed: Union[str, int]) -> np.ndarray:
        """Generate a random hyperdimensional vector with optional seed."""
        if TORCHHD_AVAILABLE:
            torch.manual_seed(hash(str(seed)) % 2**32)
            vector = torchhd.random(self.dimensions, generator=torch.Generator())
            return vector.numpy()
        else:
            # Fallback implementation
            np.random.seed(hash(str(seed)) % 2**32)
            return np.random.choice([-1, 1], self.dimensions).astype(np.float32)
    
    def bind(self, vector1: np.ndarray, vector2: np.ndarray) -> np.ndarray:
        """FHRR Binding operation (⊗): element-wise complex multiplication."""
        if TORCHHD_AVAILABLE:
            v1 = torch.tensor(vector1)
            v2 = torch.tensor(vector2)
            result = thdF.bind(v1, v2)
            return result.numpy()
        else:
            # Fallback: element-wise multiplication
            return (vector1 * vector2).astype(np.float32)
    
    def bundle(self, vectors: List[np.ndarray], weights: Optional[List[float]] = None) -> np.ndarray:
        """
        FHRR Bundling operation (⊕): weighted vector addition.
        This is the SEMANTIC-WEIGHTED BUNDLING from Phase 2.1.
        """
        if not vectors:
            return np.zeros(self.dimensions, dtype=np.float32)
        
        if TORCHHD_AVAILABLE:
            torch_vectors = [torch.tensor(v) for v in vectors]
            if weights:
                # Semantic-weighted bundling
                weighted_vectors = [w * v for w, v in zip(weights, torch_vectors)]
                result = thdF.bundle(weighted_vectors)
            else:
                result = thdF.bundle(torch_vectors)
            return result.numpy()
        else:
            # Fallback implementation with semantic weighting
            if weights is None:
                weights = [1.0] * len(vectors)
            
            result = np.zeros(self.dimensions, dtype=np.float32)
            total_weight = sum(weights)
            
            for vector, weight in zip(vectors, weights):
                result += (weight / total_weight) * vector
            
            return result
    
    def unbind(self, composite: np.ndarray, key: np.ndarray) -> np.ndarray:
        """
        FHRR Unbinding operation (⊘): inverse of binding.
        Produces NOISY result that requires cleanup.
        """
        if TORCHHD_AVAILABLE:
            comp = torch.tensor(composite)
            k = torch.tensor(key)
            result = thdF.unbind(comp, k)
            return result.numpy()
        else:
            # Fallback: element-wise division (produces noise)
            # Add noise to simulate the unbinding process
            result = np.divide(composite, key, out=np.zeros_like(composite), where=key!=0)
            noise = np.random.normal(0, 0.1, result.shape)
            return (result + noise).astype(np.float32)
    
    def cosine_similarity(self, vector1: np.ndarray, vector2: np.ndarray) -> float:
        """Compute cosine similarity between two hypervectors."""
        dot_product = np.dot(vector1, vector2)
        norm1 = np.linalg.norm(vector1)
        norm2 = np.linalg.norm(vector2)
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return float(dot_product / (norm1 * norm2))
    
    def cleanup(self, noisy_vector: np.ndarray, k: int = 5) -> List[Tuple[np.ndarray, float, Dict]]:
        """
        CONSTRAINED CLEANUP OPERATION: Find clean prototypes from noisy unbind result.
        This is the critical second half of the unbind→cleanup conversational loop.
        """
        if not self.concept_memory:
            return []
        
        # Use advanced vector search for cleanup
        candidates = self.advanced_vector_search(noisy_vector, k * 2)  # Get more candidates
        
        # Apply neural network scoring for semantic refinement
        scored_candidates = []
        for candidate_vector, score, metadata in candidates:
            if self.neural_network and self.is_trained:
                neural_score = self._compute_neural_similarity(noisy_vector, candidate_vector)
                combined_score = 0.6 * score + 0.4 * neural_score
            else:
                combined_score = score
            
            scored_candidates.append((candidate_vector, combined_score, metadata))
        
        # Sort by combined score and return top k
        scored_candidates.sort(key=lambda x: x[1], reverse=True)
        return scored_candidates[:k]
    
    def _compute_neural_similarity(self, query: np.ndarray, candidate: np.ndarray) -> float:
        """Compute neural network similarity score between vectors."""
        if not self.neural_network:
            return 0.5
        
        # Concatenate vectors as input to neural network
        input_tensor = torch.tensor(np.concatenate([query, candidate]), dtype=torch.float32)
        
        with torch.no_grad():
            score = self.neural_network(input_tensor.unsqueeze(0))
        
        return float(score.item())
    
    def add_concept(self, vector: np.ndarray, metadata: Dict[str, Any]) -> bool:
        """Add a concept vector to memory for cleanup operations."""
        self.concept_memory.append((vector.copy(), metadata))
        
        # Rebuild indices if we have many concepts
        if len(self.concept_memory) % 100 == 0:
            self._rebuild_indices()
        
        return True
    
    def _rebuild_indices(self):
        """Rebuild FAISS and HNSWLIB indices for fast similarity search."""
        if not self.concept_memory:
            return
        
        vectors = np.array([concept[0] for concept in self.concept_memory], dtype=np.float32)
        
        # Build FAISS index
        if FAISS_AVAILABLE:
            self.faiss_index = faiss.IndexFlatIP(self.dimensions)  # Inner product for cosine similarity
            faiss.normalize_L2(vectors)  # Normalize for cosine similarity
            self.faiss_index.add(vectors)
        
        # Build HNSWLIB index
        if HNSWLIB_AVAILABLE:
            self.hnswlib_index = hnswlib.Index(space='cosine', dim=self.dimensions)
            self.hnswlib_index.init_index(max_elements=len(vectors) * 2, ef_construction=200, M=16)
            self.hnswlib_index.add_items(vectors, list(range(len(vectors))))
            self.hnswlib_index.set_ef(50)
    
    def advanced_vector_search(self, query_vector: np.ndarray, k: int = 5) -> List[Tuple[np.ndarray, float, Dict]]:
        """
        Advanced vector search using FAISS/HNSWLIB for the cleanup operation.
        Returns list of (vector, similarity_score, metadata) tuples.
        """
        if not self.concept_memory:
            return []
        
        results = []
        
        # Try FAISS search first
        if self.faiss_index and FAISS_AVAILABLE:
            query_normalized = query_vector.reshape(1, -1).astype(np.float32)
            faiss.normalize_L2(query_normalized)
            
            scores, indices = self.faiss_index.search(query_normalized, min(k, len(self.concept_memory)))
            
            for score, idx in zip(scores[0], indices[0]):
                if idx >= 0 and idx < len(self.concept_memory):
                    vector, metadata = self.concept_memory[idx]
                    results.append((vector, float(score), {**metadata, 'method': 'faiss'}))
        
        # Try HNSWLIB search as backup/comparison
        elif self.hnswlib_index and HNSWLIB_AVAILABLE:
            labels, distances = self.hnswlib_index.knn_query(query_vector.reshape(1, -1), k=min(k, len(self.concept_memory)))
            
            for label, distance in zip(labels[0], distances[0]):
                if label < len(self.concept_memory):
                    vector, metadata = self.concept_memory[label]
                    similarity = 1.0 - distance  # Convert distance to similarity
                    results.append((vector, similarity, {**metadata, 'method': 'hnswlib'}))
        
        # Fallback: linear search with cosine similarity
        else:
            similarities = []
            for i, (vector, metadata) in enumerate(self.concept_memory):
                sim = self.cosine_similarity(query_vector, vector)
                similarities.append((sim, i))
            
            similarities.sort(reverse=True)
            
            for sim, idx in similarities[:k]:
                vector, metadata = self.concept_memory[idx]
                results.append((vector, sim, {**metadata, 'method': 'linear'}))
        
        return results
    
    def train_neural_network(self, training_pairs: List[Tuple[np.ndarray, np.ndarray, float]], epochs: int = 50):
        """
        Train the neural network for better semantic similarity scoring.
        training_pairs: List of (vector1, vector2, similarity_score) tuples
        """
        if not self.neural_network or not training_pairs:
            return False
        
        print(f"Training neural network on {len(training_pairs)} pairs for {epochs} epochs...")
        
        self.neural_network.train()
        
        for epoch in range(epochs):
            total_loss = 0.0
            
            for v1, v2, target_score in training_pairs:
                self.optimizer.zero_grad()
                
                # Concatenate vectors as input
                input_tensor = torch.tensor(np.concatenate([v1, v2]), dtype=torch.float32)
                target_tensor = torch.tensor([target_score], dtype=torch.float32)
                
                # Forward pass
                predicted_score = self.neural_network(input_tensor.unsqueeze(0))
                loss = self.criterion(predicted_score, target_tensor.unsqueeze(0))
                
                # Backward pass
                loss.backward()
                self.optimizer.step()
                
                total_loss += loss.item()
            
            if epoch % 10 == 0:
                avg_loss = total_loss / len(training_pairs)
                print(f"Epoch {epoch}, Average Loss: {avg_loss:.4f}")
        
        self.is_trained = True
        print("Neural network training complete!")
        return True
    
    def encode_text(self, text: str) -> np.ndarray:
        """
        Convert text to hypervector using token-based encoding.
        Builds up compositional representation through binding and bundling.
        """
        if not text:
            return self.generate_hypervector("empty")
        
        tokens = text.lower().split()
        if not tokens:
            return self.generate_hypervector("empty")
        
        # Generate or retrieve token vectors
        token_vectors = []
        for token in tokens:
            if token not in self.vector_memory:
                self.vector_memory[token] = self.generate_hypervector(token)
            token_vectors.append(self.vector_memory[token])
        
        # Bundle all token vectors with positional encoding
        if len(token_vectors) == 1:
            return token_vectors[0]
        
        # Add positional information through binding
        result_vectors = []
        for i, token_vector in enumerate(token_vectors):
            position_vector = self.generate_hypervector(f"pos_{i}")
            positioned_token = self.bind(token_vector, position_vector)
            result_vectors.append(positioned_token)
        
        # Bundle all positioned tokens
        return self.bundle(result_vectors)
    
    def save_state(self, filepath: str):
        """Save the complete state of the neural computer."""
        state = {
            'dimensions': self.dimensions,
            'vector_memory': self.vector_memory,
            'concept_memory': self.concept_memory,
            'is_trained': self.is_trained
        }
        
        # Save neural network state if available
        if self.neural_network:
            state['neural_network_state'] = self.neural_network.state_dict()
        
        with open(filepath, 'wb') as f:
            pickle.dump(state, f)
    
    def load_state(self, filepath: str):
        """Load the complete state of the neural computer."""
        with open(filepath, 'rb') as f:
            state = pickle.load(f)
        
        self.dimensions = state['dimensions']
        self.vector_memory = state['vector_memory']
        self.concept_memory = state['concept_memory']
        self.is_trained = state.get('is_trained', False)
        
        # Restore neural network state if available
        if 'neural_network_state' in state and self.neural_network:
            self.neural_network.load_state_dict(state['neural_network_state'])
        
        # Rebuild indices
        if self.concept_memory:
            self._rebuild_indices()

class HybridQueryPlanner:
    """
    HYBRID QUERY PLANNER: Metacognitive optimization for complex VSA-RAG queries.
    Implements multi-hop reasoning, query decomposition, and result synthesis.
    """
    
    def __init__(self, neural_computer: VSANeuralComputer):
        self.neural_computer = neural_computer
        self.query_cache = {}  # Cache for expensive query results
        self.optimization_stats = {
            'queries_processed': 0,
            'cache_hits': 0,
            'multi_hop_queries': 0,
            'decomposed_queries': 0
        }
    
    def plan_query(self, query_spec: Dict[str, Any]) -> Dict[str, Any]:
        """
        Plan and optimize a complex VSA-RAG query.
        Returns optimized execution plan with estimated costs.
        """
        query_text = query_spec.get('text', '')
        query_type = query_spec.get('type', 'simple')
        context = query_spec.get('context', {})
        
        # Check cache first
        cache_key = self._compute_cache_key(query_spec)
        if cache_key in self.query_cache:
            self.optimization_stats['cache_hits'] += 1
            return self.query_cache[cache_key]
        
        self.optimization_stats['queries_processed'] += 1
        
        # Analyze query complexity
        complexity_analysis = self._analyze_query_complexity(query_text, context)
        
        # Generate execution plan based on complexity
        if complexity_analysis['is_multi_hop']:
            plan = self._plan_multi_hop_query(query_spec, complexity_analysis)
            self.optimization_stats['multi_hop_queries'] += 1
        elif complexity_analysis['needs_decomposition']:
            plan = self._plan_decomposed_query(query_spec, complexity_analysis)
            self.optimization_stats['decomposed_queries'] += 1
        else:
            plan = self._plan_simple_query(query_spec, complexity_analysis)
        
        # Cache result for future use
        self.query_cache[cache_key] = plan
        
        return plan
    
    def _analyze_query_complexity(self, query_text: str, context: Dict) -> Dict[str, Any]:
        """Analyze query to determine optimal execution strategy."""
        tokens = query_text.lower().split()
        
        # Look for multi-hop indicators
        multi_hop_indicators = ['and', 'then', 'because', 'therefore', 'which', 'that', 'who', 'when', 'where']
        is_multi_hop = any(indicator in tokens for indicator in multi_hop_indicators)
        
        # Look for decomposition indicators
        decomposition_indicators = ['explain', 'analyze', 'compare', 'contrast', 'summarize', 'evaluate']
        needs_decomposition = any(indicator in tokens for indicator in decomposition_indicators)
        
        # Estimate query cost based on length and complexity
        base_cost = len(tokens)
        complexity_multiplier = 1.0
        
        if is_multi_hop:
            complexity_multiplier += 1.5
        if needs_decomposition:
            complexity_multiplier += 1.2
        if len(context) > 0:
            complexity_multiplier += 0.5
        
        estimated_cost = base_cost * complexity_multiplier
        
        return {
            'is_multi_hop': is_multi_hop,
            'needs_decomposition': needs_decomposition,
            'estimated_cost': estimated_cost,
            'token_count': len(tokens),
            'complexity_score': complexity_multiplier
        }
    
    def _plan_multi_hop_query(self, query_spec: Dict, analysis: Dict) -> Dict[str, Any]:
        """Plan execution for multi-hop reasoning queries."""
        query_text = query_spec.get('text', '')
        
        # Decompose into reasoning steps
        steps = self._decompose_reasoning_steps(query_text)
        
        # Create execution plan
        plan = {
            'type': 'multi_hop',
            'steps': steps,
            'execution_order': 'sequential',
            'estimated_cost': analysis['estimated_cost'],
            'requires_cleanup': True,
            'cache_intermediate': True
        }
        
        return plan
    
    def _plan_decomposed_query(self, query_spec: Dict, analysis: Dict) -> Dict[str, Any]:
        """Plan execution for queries that need decomposition."""
        query_text = query_spec.get('text', '')
        
        # Break down into sub-queries
        sub_queries = self._generate_sub_queries(query_text)
        
        plan = {
            'type': 'decomposed',
            'sub_queries': sub_queries,
            'execution_order': 'parallel',
            'synthesis_required': True,
            'estimated_cost': analysis['estimated_cost'],
            'requires_cleanup': True
        }
        
        return plan
    
    def _plan_simple_query(self, query_spec: Dict, analysis: Dict) -> Dict[str, Any]:
        """Plan execution for simple, direct queries."""
        plan = {
            'type': 'simple',
            'direct_search': True,
            'estimated_cost': analysis['estimated_cost'],
            'requires_cleanup': True
        }
        
        return plan
    
    def _decompose_reasoning_steps(self, query_text: str) -> List[Dict[str, Any]]:
        """Decompose complex query into reasoning steps."""
        # This is a simplified decomposition - in practice, this would use
        # more sophisticated NLP or learned decomposition patterns
        
        # Split on reasoning connectors
        connectors = ['and', 'then', 'because', 'therefore']
        steps = []
        current_step = []
        
        tokens = query_text.split()
        
        for token in tokens:
            if token.lower() in connectors and current_step:
                steps.append({
                    'text': ' '.join(current_step),
                    'type': 'reasoning_step',
                    'requires_previous': len(steps) > 0
                })
                current_step = []
            else:
                current_step.append(token)
        
        # Add final step
        if current_step:
            steps.append({
                'text': ' '.join(current_step),
                'type': 'reasoning_step',
                'requires_previous': len(steps) > 0
            })
        
        return steps if steps else [{'text': query_text, 'type': 'single_step', 'requires_previous': False}]
    
    def _generate_sub_queries(self, query_text: str) -> List[str]:
        """Generate sub-queries for decomposed analysis."""
        # Simplified sub-query generation
        sub_queries = []
        
        if 'explain' in query_text.lower():
            sub_queries.extend([
                f"What is {query_text}?",
                f"How does {query_text} work?",
                f"Why is {query_text} important?"
            ])
        elif 'compare' in query_text.lower():
            # Extract comparison entities (simplified)
            words = query_text.split()
            sub_queries.extend([
                f"Describe the first concept",
                f"Describe the second concept", 
                f"Identify similarities and differences"
            ])
        else:
            # Default decomposition
            sub_queries = [query_text]
        
        return sub_queries
    
    def _compute_cache_key(self, query_spec: Dict) -> str:
        """Compute cache key for query specification."""
        # Create deterministic hash of query specification
        import hashlib
        
        key_components = [
            query_spec.get('text', ''),
            query_spec.get('type', 'simple'),
            str(sorted(query_spec.get('context', {}).items()))
        ]
        
        key_string = '|'.join(key_components)
        return hashlib.md5(key_string.encode()).hexdigest()
    
    def execute_plan(self, plan: Dict[str, Any], query_spec: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the optimized query plan."""
        if plan['type'] == 'simple':
            return self._execute_simple_plan(plan, query_spec)
        elif plan['type'] == 'multi_hop':
            return self._execute_multi_hop_plan(plan, query_spec)
        elif plan['type'] == 'decomposed':
            return self._execute_decomposed_plan(plan, query_spec)
        else:
            raise ValueError(f"Unknown plan type: {plan['type']}")
    
    def _execute_simple_plan(self, plan: Dict, query_spec: Dict) -> Dict[str, Any]:
        """Execute a simple query plan."""
        query_text = query_spec.get('text', '')
        
        # Encode query as hypervector
        query_vector = self.neural_computer.encode_text(query_text)
        
        # Perform cleanup operation (find similar concepts)
        results = self.neural_computer.cleanup(query_vector, k=5)
        
        return {
            'type': 'simple_result',
            'results': results,
            'query_vector': query_vector,
            'execution_time': 0.1  # Mock timing
        }
    
    def _execute_multi_hop_plan(self, plan: Dict, query_spec: Dict) -> Dict[str, Any]:
        """Execute a multi-hop reasoning plan."""
        results = []
        intermediate_vectors = []
        
        for step in plan['steps']:
            step_vector = self.neural_computer.encode_text(step['text'])
            
            # If this step requires previous results, bind with previous vectors
            if step.get('requires_previous') and intermediate_vectors:
                # Bind current step with accumulated reasoning
                accumulated = self.neural_computer.bundle(intermediate_vectors)
                step_vector = self.neural_computer.bind(step_vector, accumulated)
            
            # Perform cleanup for this step
            step_results = self.neural_computer.cleanup(step_vector, k=3)
            results.extend(step_results)
            intermediate_vectors.append(step_vector)
        
        # Final synthesis
        final_vector = self.neural_computer.bundle(intermediate_vectors)
        final_results = self.neural_computer.cleanup(final_vector, k=5)
        
        return {
            'type': 'multi_hop_result',
            'step_results': results,
            'final_results': final_results,
            'reasoning_vector': final_vector,
            'execution_time': len(plan['steps']) * 0.15  # Mock timing
        }
    
    def _execute_decomposed_plan(self, plan: Dict, query_spec: Dict) -> Dict[str, Any]:
        """Execute a decomposed query plan."""
        sub_results = []
        sub_vectors = []
        
        for sub_query in plan['sub_queries']:
            sub_vector = self.neural_computer.encode_text(sub_query)
            sub_result = self.neural_computer.cleanup(sub_vector, k=3)
            
            sub_results.append({
                'query': sub_query,
                'results': sub_result,
                'vector': sub_vector
            })
            sub_vectors.append(sub_vector)
        
        # Synthesize results from all sub-queries
        if sub_vectors:
            synthesis_vector = self.neural_computer.bundle(sub_vectors)
            synthesized_results = self.neural_computer.cleanup(synthesis_vector, k=5)
        else:
            synthesized_results = []
        
        return {
            'type': 'decomposed_result',
            'sub_results': sub_results,
            'synthesized_results': synthesized_results,
            'synthesis_vector': synthesis_vector if sub_vectors else None,
            'execution_time': len(plan['sub_queries']) * 0.12  # Mock timing
        }
    
    def get_optimization_stats(self) -> Dict[str, Any]:
        """Get query optimization statistics."""
        return self.optimization_stats.copy()

# Global neural computer instance
_neural_computer = None
_query_planner = None

def initialize_neural_backend(dimensions=10000, device='cpu'):
    """Initialize the neural computation backend."""
    global _neural_computer, _query_planner
    
    print(f"Initializing TelOS Neural Backend (dimensions={dimensions}, device={device})")
    print(f"Available backends: FAISS={FAISS_AVAILABLE}, HNSWLIB={HNSWLIB_AVAILABLE}, TorchHD={TORCHHD_AVAILABLE}")
    
    _neural_computer = VSANeuralComputer(dimensions=dimensions, device=device)
    _query_planner = HybridQueryPlanner(_neural_computer)
    
    return True

def get_neural_computer():
    """Get the global neural computer instance."""
    if _neural_computer is None:
        initialize_neural_backend()
    return _neural_computer

def get_query_planner():
    """Get the global query planner instance."""
    if _query_planner is None:
        initialize_neural_backend()
    return _query_planner

# Convenience functions for FFI calls
def neural_bind(vector1, vector2):
    """FFI-callable bind operation."""
    nc = get_neural_computer()
    return nc.bind(np.array(vector1), np.array(vector2)).tolist()

def neural_bundle(vectors, weights=None):
    """FFI-callable bundle operation with semantic weighting."""
    nc = get_neural_computer()
    np_vectors = [np.array(v) for v in vectors]
    result = nc.bundle(np_vectors, weights)
    return result.tolist()

def neural_unbind(composite, key):
    """FFI-callable unbind operation."""
    nc = get_neural_computer()
    result = nc.unbind(np.array(composite), np.array(key))
    return result.tolist()

def neural_cleanup(noisy_vector, k=5):
    """FFI-callable cleanup operation."""
    nc = get_neural_computer()
    results = nc.cleanup(np.array(noisy_vector), k)
    
    # Convert to FFI-friendly format
    cleaned_results = []
    for vector, score, metadata in results:
        cleaned_results.append({
            'vector': vector.tolist(),
            'score': score,
            'metadata': metadata
        })
    
    return cleaned_results

def neural_encode_text(text):
    """FFI-callable text encoding."""
    nc = get_neural_computer()
    vector = nc.encode_text(text)
    return vector.tolist()

def neural_add_concept(vector, metadata):
    """FFI-callable concept addition."""
    nc = get_neural_computer()
    return nc.add_concept(np.array(vector), metadata)

def plan_and_execute_query(query_spec):
    """FFI-callable query planning and execution."""
    qp = get_query_planner()
    
    # Plan the query
    plan = qp.plan_query(query_spec)
    
    # Execute the plan
    result = qp.execute_plan(plan, query_spec)
    
    # Convert numpy arrays to lists for FFI compatibility
    def convert_numpy_to_lists(obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        elif isinstance(obj, dict):
            return {k: convert_numpy_to_lists(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [convert_numpy_to_lists(item) for item in obj]
        else:
            return obj
    
    return convert_numpy_to_lists(result)

if __name__ == "__main__":
    # Test the neural backend
    print("Testing TelOS Neural Computation Backend...")
    
    initialize_neural_backend()
    nc = get_neural_computer()
    qp = get_query_planner()
    
    # Test basic operations
    v1 = nc.generate_hypervector("concept1")
    v2 = nc.generate_hypervector("concept2")
    
    bound = nc.bind(v1, v2)
    bundled = nc.bundle([v1, v2], [0.7, 0.3])  # Semantic weighting
    unbound = nc.unbind(bound, v1)
    
    print(f"Generated vectors: {v1.shape}, {v2.shape}")
    print(f"Bound vector: {bound.shape}")
    print(f"Bundled vector: {bundled.shape}")
    print(f"Unbound vector: {unbound.shape}")
    
    # Test text encoding
    text_vector = nc.encode_text("artificial intelligence reasoning")
    print(f"Text vector: {text_vector.shape}")
    
    # Add some concepts for cleanup testing
    nc.add_concept(v1, {"name": "concept1", "type": "test"})
    nc.add_concept(v2, {"name": "concept2", "type": "test"})
    nc.add_concept(text_vector, {"name": "ai_reasoning", "type": "text"})
    
    # Test cleanup operation
    cleanup_results = nc.cleanup(unbound, k=2)
    print(f"Cleanup found {len(cleanup_results)} clean prototypes")
    
    # Test query planning
    query_spec = {
        'text': 'explain artificial intelligence and then analyze its reasoning capabilities',
        'type': 'complex',
        'context': {'domain': 'AI'}
    }
    
    plan = qp.plan_query(query_spec)
    print(f"Query plan: {plan['type']}, estimated cost: {plan['estimated_cost']}")
    
    result = qp.execute_plan(plan, query_spec)
    print(f"Query result: {result['type']}")
    
    print("Neural backend test complete!")