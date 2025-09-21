"""
Neural Backend Foundation - Pure Prototypal Integration
=====================================================

Production-ready neural computation module designed for prototypal FFI integration.
Focuses on essential operations without complex dependencies.
"""

import math
import random
from typing import List, Dict, Any, Optional

class NeuralBackend:
    """Core neural computation engine for VSA-RAG operations."""
    
    def __init__(self, dimension: int = 1000):
        self.dimension = dimension
        self.vector_store = {}
        self.memory_database = []
        
    def generate_hypervector(self, seed: str) -> List[float]:
        """Generate a hyperdimensional vector from a seed string."""
        # Use seed for reproducible randomness
        random.seed(hash(seed) % (2**32))
        
        # Generate bipolar hypervector [-1, 1]
        vector = []
        for i in range(self.dimension):
            vector.append(1.0 if random.random() > 0.5 else -1.0)
        
        return vector
    
    def bind_vectors(self, v1: List[float], v2: List[float]) -> List[float]:
        """FHRR binding operation (element-wise multiplication)."""
        if len(v1) != len(v2):
            raise ValueError("Vector dimensions must match")
        
        result = []
        for i in range(len(v1)):
            result.append(v1[i] * v2[i])
        
        return result
    
    def bundle_vectors(self, vectors: List[List[float]]) -> List[float]:
        """FHRR bundling operation (element-wise addition with normalization)."""
        if not vectors:
            return [0.0] * self.dimension
        
        if len(vectors) == 1:
            return vectors[0].copy()
        
        result = [0.0] * len(vectors[0])
        
        # Sum all vectors
        for vector in vectors:
            for i in range(len(vector)):
                result[i] += vector[i]
        
        # Normalize by count (averaging)
        count = len(vectors)
        for i in range(len(result)):
            result[i] /= count
        
        return result
    
    def unbind_vectors(self, composite: List[float], key: List[float]) -> List[float]:
        """FHRR unbinding operation (inverse of binding) - produces noisy result."""
        if len(composite) != len(key):
            raise ValueError("Vector dimensions must match")
        
        result = []
        for i in range(len(composite)):
            # Division produces noisy result that needs cleanup
            if abs(key[i]) > 1e-10:  # Avoid division by zero
                result.append(composite[i] / key[i])
            else:
                result.append(0.0)
        
        return result
    
    def cosine_similarity(self, v1: List[float], v2: List[float]) -> float:
        """Compute cosine similarity between two vectors."""
        if len(v1) != len(v2):
            return 0.0
        
        dot_product = sum(a * b for a, b in zip(v1, v2))
        
        norm1 = math.sqrt(sum(a * a for a in v1))
        norm2 = math.sqrt(sum(b * b for b in v2))
        
        if norm1 == 0 or norm2 == 0:
            return 0.0
        
        return dot_product / (norm1 * norm2)
    
    def encode_text(self, text: str) -> List[float]:
        """Convert text to hypervector using token-based encoding."""
        if not text:
            return self.generate_hypervector("empty")
        
        # Simple tokenization
        tokens = text.lower().split()
        if not tokens:
            return self.generate_hypervector("empty")
        
        # Generate vectors for each token
        token_vectors = []
        for token in tokens:
            if token not in self.vector_store:
                self.vector_store[token] = self.generate_hypervector(token)
            token_vectors.append(self.vector_store[token])
        
        # Bundle token vectors
        return self.bundle_vectors(token_vectors)
    
    def add_memory(self, text: str) -> int:
        """Add text to memory database and return index."""
        vector = self.encode_text(text)
        entry = {
            'text': text,
            'vector': vector,
            'index': len(self.memory_database)
        }
        self.memory_database.append(entry)
        return entry['index']
    
    def search_memory(self, query: str, k: int = 3) -> List[Dict]:
        """Search memory database using vector similarity."""
        if not self.memory_database:
            return []
        
        query_vector = self.encode_text(query)
        
        # Score all entries
        scored_entries = []
        for entry in self.memory_database:
            score = self.cosine_similarity(query_vector, entry['vector'])
            scored_entries.append({
                'text': entry['text'],
                'score': score,
                'index': entry['index']
            })
        
        # Sort by score descending
        scored_entries.sort(key=lambda x: x['score'], reverse=True)
        
        # Return top-k
        return scored_entries[:k]
    
    def cleanup_noisy_vector(self, noisy_vector: List[float]) -> Optional[List[float]]:
        """Find the closest clean vector in memory to the noisy result."""
        if not self.memory_database:
            return None
        
        best_match = None
        best_score = -1.0
        
        for entry in self.memory_database:
            score = self.cosine_similarity(noisy_vector, entry['vector'])
            if score > best_score:
                best_score = score
                best_match = entry['vector']
        
        return best_match if best_match else None

# Global backend instance
_neural_backend = None

def get_neural_backend(dimension: int = 1000) -> NeuralBackend:
    """Get or create the global neural backend instance."""
    global _neural_backend
    if _neural_backend is None:
        _neural_backend = NeuralBackend(dimension)
    return _neural_backend

# FFI-friendly function interface
def neural_generate_vector(seed: str, dimension: int = 1000) -> List[float]:
    """Generate hypervector from seed string."""
    backend = get_neural_backend(dimension)
    return backend.generate_hypervector(seed)

def neural_bind(v1: List[float], v2: List[float]) -> List[float]:
    """Bind two vectors using FHRR."""
    backend = get_neural_backend()
    return backend.bind_vectors(v1, v2)

def neural_bundle(vectors: List[List[float]]) -> List[float]:
    """Bundle multiple vectors using FHRR."""
    backend = get_neural_backend()
    return backend.bundle_vectors(vectors)

def neural_unbind(composite: List[float], key: List[float]) -> List[float]:
    """Unbind vectors using FHRR (produces noisy result)."""
    backend = get_neural_backend()
    return backend.unbind_vectors(composite, key)

def neural_similarity(v1: List[float], v2: List[float]) -> float:
    """Calculate cosine similarity between vectors."""
    backend = get_neural_backend()
    return backend.cosine_similarity(v1, v2)

def neural_encode_text(text: str) -> List[float]:
    """Encode text as hypervector."""
    backend = get_neural_backend()
    return backend.encode_text(text)

def neural_add_memory(text: str) -> int:
    """Add text to memory and return index."""
    backend = get_neural_backend()
    return backend.add_memory(text)

def neural_search(query: str, k: int = 3) -> List[Dict]:
    """Search memory using vector similarity."""
    backend = get_neural_backend()
    return backend.search_memory(query, k)

def neural_cleanup(noisy_vector: List[float]) -> Optional[List[float]]:
    """Cleanup noisy vector by finding closest clean match."""
    backend = get_neural_backend()
    return backend.cleanup_noisy_vector(noisy_vector)

# Self-test function
def neural_self_test() -> bool:
    """Run basic self-tests on neural backend."""
    try:
        backend = get_neural_backend(100)  # Small dimension for testing
        
        # Test vector generation
        v1 = backend.generate_hypervector("test1")
        v2 = backend.generate_hypervector("test2")
        
        if len(v1) != 100 or len(v2) != 100:
            return False
        
        # Test bind/unbind
        bound = backend.bind_vectors(v1, v2)
        unbound = backend.unbind_vectors(bound, v2)
        
        # Test similarity (should be close to v1)
        sim = backend.cosine_similarity(v1, unbound)
        
        # Test text encoding
        text_vec = backend.encode_text("hello world test")
        if len(text_vec) != 100:
            return False
        
        # Test memory operations
        idx = backend.add_memory("test memory entry")
        results = backend.search_memory("test", 1)
        
        if not results or len(results) == 0:
            return False
        
        return True
        
    except Exception:
        return False

if __name__ == "__main__":
    # Run self-test when executed directly
    if neural_self_test():
        print("Neural backend self-test PASSED")
    else:
        print("Neural backend self-test FAILED")