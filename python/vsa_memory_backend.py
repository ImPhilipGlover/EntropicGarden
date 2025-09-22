"""
VSA-RAG Memory Substrate - Python ML Backend
Provides vector embedding, similarity search, and persistent storage capabilities
Called via Enhanced Synaptic Bridge from Io cognitive layer
"""

import numpy as np
import faiss
import json
import os
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import weakref

# Global state for memory substrate
memory_backend = None

class VSAMemoryBackend:
    """Python backend for VSA-RAG memory operations"""
    
    def __init__(self, dimension=384, cache_size=1000):
        self.dimension = dimension
        self.cache_size = cache_size
        
        # L1: FAISS Fast Cache
        self.fast_index = faiss.IndexFlatIP(dimension)  # Inner product for cosine similarity
        self.fast_vectors = []
        self.fast_metadata = []
        
        # L2: Persistent storage preparation
        self.persistent_path = "data/vsa"
        self.ensure_directories()
        
        # Cross-language handles registry
        self.handles = weakref.WeakValueDictionary()
        
    def ensure_directories(self):
        """Create necessary directories for persistent storage"""
        os.makedirs(self.persistent_path, exist_ok=True)
        
    def embed_text(self, text: str, model: str = "all-MiniLM-L6-v2") -> np.ndarray:
        """Convert text to vector embedding using sentence transformers"""
        try:
            from sentence_transformers import SentenceTransformer
            
            # Load or get cached model
            if not hasattr(self, '_embedding_model'):
                self._embedding_model = SentenceTransformer(model)
                
            embedding = self._embedding_model.encode(text)
            
            # Normalize for cosine similarity
            embedding = embedding / np.linalg.norm(embedding)
            
            return embedding.astype(np.float32)
            
        except ImportError:
            # Fallback: simple hash-based embedding for testing
            import hashlib
            hash_obj = hashlib.sha256(text.encode())
            # Convert hash to pseudo-embedding
            hash_bytes = hash_obj.digest()
            embedding = np.frombuffer(hash_bytes, dtype=np.uint8)[:self.dimension]
            embedding = embedding.astype(np.float32) / 255.0
            # Pad if necessary
            if len(embedding) < self.dimension:
                padding = np.zeros(self.dimension - len(embedding), dtype=np.float32)
                embedding = np.concatenate([embedding, padding])
            return embedding
    
    def store_vector(self, vector: np.ndarray, metadata: Dict) -> str:
        """Store vector in L1 fast cache with metadata"""
        if len(vector) != self.dimension:
            raise ValueError(f"Vector dimension {len(vector)} != expected {self.dimension}")
            
        # Generate unique ID
        vector_id = f"vec_{len(self.fast_vectors)}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Add to fast cache
        self.fast_index.add(vector.reshape(1, -1))
        self.fast_vectors.append(vector)
        self.fast_metadata.append({
            'id': vector_id,
            'timestamp': datetime.now().isoformat(),
            **metadata
        })
        
        # Check cache size limit
        if len(self.fast_vectors) > self.cache_size:
            self._evict_oldest()
            
        return vector_id
    
    def search_vectors(self, query_vector: np.ndarray, k: int = 5) -> List[Dict]:
        """Search for similar vectors in fast cache"""
        if len(self.fast_vectors) == 0:
            return []
            
        if len(query_vector) != self.dimension:
            raise ValueError(f"Query vector dimension {len(query_vector)} != expected {self.dimension}")
            
        # Search FAISS index
        scores, indices = self.fast_index.search(query_vector.reshape(1, -1), min(k, len(self.fast_vectors)))
        
        results = []
        for score, idx in zip(scores[0], indices[0]):
            if idx >= 0 and idx < len(self.fast_metadata):
                result = self.fast_metadata[idx].copy()
                result['similarity_score'] = float(score)
                results.append(result)
                
        return results
    
    def _evict_oldest(self):
        """Remove oldest vector from cache (simple FIFO for now)"""
        if len(self.fast_vectors) > 0:
            # Remove from tracking
            self.fast_vectors.pop(0)
            self.fast_metadata.pop(0)
            
            # Rebuild FAISS index (inefficient but simple for now)
            self.fast_index = faiss.IndexFlatIP(self.dimension)
            if self.fast_vectors:
                vectors_matrix = np.vstack(self.fast_vectors)
                self.fast_index.add(vectors_matrix)
    
    def get_stats(self) -> Dict:
        """Return memory backend statistics"""
        return {
            'dimension': self.dimension,
            'cache_size': self.cache_size,
            'vectors_cached': len(self.fast_vectors),
            'cache_utilization': len(self.fast_vectors) / self.cache_size,
            'has_embedding_model': hasattr(self, '_embedding_model')
        }

# Global functions for Synaptic Bridge integration
def initialize_memory_backend(dimension=384, cache_size=1000):
    """Initialize the global memory backend"""
    global memory_backend
    memory_backend = VSAMemoryBackend(dimension, cache_size)
    return "Memory backend initialized"

def embed_text(text, model="all-MiniLM-L6-v2"):
    """Embed text using the memory backend"""
    global memory_backend
    if memory_backend is None:
        initialize_memory_backend()
    
    vector = memory_backend.embed_text(text, model)
    return vector.tolist()  # Convert to list for JSON serialization

def store_vector(vector_list, metadata):
    """Store vector with metadata"""
    global memory_backend
    if memory_backend is None:
        initialize_memory_backend()
    
    vector = np.array(vector_list, dtype=np.float32)
    vector_id = memory_backend.store_vector(vector, metadata)
    return vector_id

def search_vectors(query_vector_list, k=5):
    """Search for similar vectors"""
    global memory_backend
    if memory_backend is None:
        initialize_memory_backend()
    
    query_vector = np.array(query_vector_list, dtype=np.float32)
    results = memory_backend.search_vectors(query_vector, k)
    return results

def get_memory_stats():
    """Get memory backend statistics"""
    global memory_backend
    if memory_backend is None:
        return {"status": "not_initialized"}
    
    return memory_backend.get_stats()

# Test function for bridge validation
def test_memory_operations():
    """Test basic memory operations"""
    # Initialize
    initialize_memory_backend()
    
    # Test embedding
    text1 = "This is a test document about machine learning"
    text2 = "Machine learning and artificial intelligence are fascinating"
    text3 = "I love cooking pasta with tomato sauce"
    
    vec1 = embed_text(text1)
    vec2 = embed_text(text2)
    vec3 = embed_text(text3)
    
    # Store vectors
    id1 = store_vector(vec1, {"text": text1, "category": "ML"})
    id2 = store_vector(vec2, {"text": text2, "category": "ML"})
    id3 = store_vector(vec3, {"text": text3, "category": "food"})
    
    # Search
    results = search_vectors(vec1, k=3)
    
    return {
        "stored_vectors": [id1, id2, id3],
        "search_results": results,
        "stats": get_memory_stats()
    }

# FHRR VSA Operations - Fourier Holographic Reduced Representations
# Based on torchhd.FHRRTensor for complex-valued vector symbolic operations

def fhrr_generate_vector(seed):
    """Generate FHRR hypervector from seed"""
    try:
        import torchhd
        import torch
        
        # Use seed for reproducible generation
        torch.manual_seed(seed)
        
        # Generate FHRR vector
        vector = torchhd.FHRRTensor.random(1024)  # Standard FHRR dimension
        
        return vector.tolist()
        
    except ImportError:
        # Fallback: generate pseudo-random complex vector
        import random
        random.seed(seed)
        
        # Generate complex-valued vector (real + imaginary parts)
        real_part = [random.gauss(0, 1) for _ in range(512)]
        imag_part = [random.gauss(0, 1) for _ in range(512)]
        
        # Normalize
        magnitude = sum(r*r + i*i for r, i in zip(real_part, imag_part)) ** 0.5
        real_part = [r/magnitude for r in real_part]
        imag_part = [i/magnitude for i in imag_part]
        
        # Return as complex numbers string representation
        complex_vector = [complex(r, i) for r, i in zip(real_part, imag_part)]
        return str(complex_vector)

def fhrr_bind(vec_a_str, vec_b_str):
    """Bind two FHRR vectors using element-wise complex multiplication"""
    try:
        import torchhd
        import torch
        
        # Parse vectors (handle both torchhd and fallback formats)
        if isinstance(vec_a_str, str) and vec_a_str.startswith('['):
            # Fallback format - parse complex numbers
            vec_a = [complex(x.strip('()')) for x in vec_a_str.strip('[]').split(',')]
            vec_b = [complex(x.strip('()')) for x in vec_b_str.strip('[]').split(',')]
            vec_a = torch.tensor(vec_a, dtype=torch.complex64)
            vec_b = torch.tensor(vec_b, dtype=torch.complex64)
        else:
            # Assume torchhd tensors
            vec_a = torchhd.FHRRTensor(vec_a_str)
            vec_b = torchhd.FHRRTensor(vec_b_str)
        
        # FHRR binding: element-wise complex multiplication
        bound = vec_a * vec_b
        
        return bound.tolist()
        
    except ImportError:
        # Fallback: simple complex multiplication
        vec_a = [complex(x.strip('()')) for x in vec_a_str.strip('[]').split(',')]
        vec_b = [complex(x.strip('()')) for x in vec_b_str.strip('[]').split(',')]
        
        bound = [a * b for a, b in zip(vec_a, vec_b)]
        return str(bound)

def fhrr_bundle(vector_list_str):
    """Bundle multiple FHRR vectors using superposition"""
    try:
        import torchhd
        import torch
        
        # Parse vector list
        vectors = []
        for vec_str in vector_list_str.strip('[]').split("','"):
            if vec_str.startswith('['):
                vec = [complex(x.strip('()')) for x in vec_str.strip('[]').split(',')]
                vec = torch.tensor(vec, dtype=torch.complex64)
            else:
                vec = torchhd.FHRRTensor(vec_str)
            vectors.append(vec)
        
        # FHRR bundling: sum all vectors
        bundled = torch.stack(vectors).sum(dim=0)
        
        return bundled.tolist()
        
    except ImportError:
        # Fallback: sum complex vectors
        all_vectors = []
        for vec_str in vector_list_str.strip('[]').split("','"):
            vec = [complex(x.strip('()')) for x in vec_str.strip('[]').split(',')]
            all_vectors.append(vec)
        
        # Sum corresponding elements
        bundled = []
        for i in range(len(all_vectors[0])):
            sum_val = sum(vec[i] for vec in all_vectors)
            bundled.append(sum_val)
        
        return str(bundled)

def fhrr_unbind(bound_vec_str, role_vec_str):
    """Unbind FHRR vector to recover original (produces noisy result)"""
    try:
        import torchhd
        import torch
        
        # Parse vectors
        if isinstance(bound_vec_str, str) and bound_vec_str.startswith('['):
            bound_vec = [complex(x.strip('()')) for x in bound_vec_str.strip('[]').split(',')]
            role_vec = [complex(x.strip('()')) for x in role_vec_str.strip('[]').split(',')]
            bound_vec = torch.tensor(bound_vec, dtype=torch.complex64)
            role_vec = torch.tensor(role_vec, dtype=torch.complex64)
        else:
            bound_vec = torchhd.FHRRTensor(bound_vec_str)
            role_vec = torchhd.FHRRTensor(role_vec_str)
        
        # FHRR unbinding: element-wise complex division
        unbound = bound_vec / role_vec
        
        return unbound.tolist()
        
    except ImportError:
        # Fallback: complex division
        bound_vec = [complex(x.strip('()')) for x in bound_vec_str.strip('[]').split(',')]
        role_vec = [complex(x.strip('()')) for x in role_vec_str.strip('[]').split(',')]
        
        unbound = [b / r for b, r in zip(bound_vec, role_vec)]
        return str(unbound)

def fhrr_cleanup(noisy_vec_str):
    """Clean up noisy FHRR vector using neural network ANN search"""
    try:
        import torchhd
        import torch
        import torch.nn as nn
        
        # Parse noisy vector
        if isinstance(noisy_vec_str, str) and noisy_vec_str.startswith('['):
            noisy_vec = [complex(x.strip('()')) for x in noisy_vec_str.strip('[]').split(',')]
            noisy_vec = torch.tensor(noisy_vec, dtype=torch.complex64)
        else:
            noisy_vec = torchhd.FHRRTensor(noisy_vec_str)
        
        # For now, return the vector as-is (ANN cleanup would require training data)
        # In a full implementation, this would use a trained autoencoder or similarity search
        return noisy_vec.tolist()
        
    except ImportError:
        # Fallback: return as-is
        return noisy_vec_str

if __name__ == "__main__":
    # Standalone test
    test_result = test_memory_operations()
    print(json.dumps(test_result, indent=2))