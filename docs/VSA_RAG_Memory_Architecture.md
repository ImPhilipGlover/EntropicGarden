# VSA-RAG Memory Substrate Architecture

## Overview
Three-tiered neuro-symbolic memory system that bridges Io prototypal cognition with Python vector operations via the Enhanced Synaptic Bridge.

## Architecture Layers

### L1: FAISS Fast Cache (Python Substrate)
- **Purpose**: Ultra-fast vector similarity search for active memory
- **Technology**: Facebook FAISS library via Synaptic Bridge
- **Size**: 1000-5000 most recently accessed vectors
- **Access Pattern**: Direct queries, automatic LRU eviction
- **Persistence**: Memory-resident, reconstructed on startup

### L2: DiskANN Persistent Storage (Python Substrate)  
- **Purpose**: Large-scale persistent vector storage
- **Technology**: Microsoft DiskANN via Synaptic Bridge
- **Size**: Unlimited persistent storage
- **Access Pattern**: Background indexing, batch queries
- **Persistence**: Disk-backed, incrementally updated

### L3: Transactional Semantic Store (Io Cognitive Layer)
- **Purpose**: Symbolic relationships and metadata management
- **Technology**: Pure Io prototypal objects with WAL persistence
- **Content**: Concept hierarchies, semantic tags, temporal sequences
- **Access Pattern**: Graph traversal, symbolic reasoning
- **Persistence**: Living Image + WAL transactions

## Prototypal Interface Design

### VSAMemory Prototype
```io
VSAMemory := Object clone do(
    // L1 Fast Cache Interface
    fastCache := Object clone
    fastCache vectors := Map clone
    fastCache index := nil // Python FAISS index handle
    fastCache capacity := 1000
    
    // L2 Persistent Storage Interface  
    persistentStore := Object clone
    persistentStore indexPath := "data/vsa/diskann.index"
    persistentStore handle := nil // Python DiskANN handle
    
    // L3 Semantic Layer Interface
    semanticStore := Object clone
    semanticStore concepts := Map clone
    semanticStore relationships := List clone
    semanticStore temporal := List clone
    
    // Core Operations
    embed := method(content, model,
        // Convert text/object to vector via Python embeddings
    )
    
    store := method(vectorObj, metadata,
        // Store across all three layers with consistency
    )
    
    search := method(queryVector, k, filters,
        // Hierarchical search: L1 fast -> L2 persistent -> L3 semantic
    )
    
    consolidate := method(
        // Background process: merge L1->L2, update L3 relationships
    )
)
```

### Integration Points

1. **Enhanced Synaptic Bridge Utilization**:
   - Use `IoTelos_marshalIoToPython()` for vector data transfer
   - Leverage `IoTelos_executeAsync()` for background indexing
   - Handle system via cross-language handles for Python ML objects

2. **Living Image Persistence**:
   - L3 semantic store persists via existing WAL system
   - Vector metadata and relationships survive restart
   - L1/L2 reconstructed from L3 semantic pointers

3. **Morphic UI Integration**:
   - Visual memory browser showing concept clusters
   - Interactive vector space navigation
   - Real-time similarity visualization

## Implementation Strategy

### Phase 1: Python ML Integration
- Install and test FAISS, sentence-transformers, DiskANN
- Create Python embedding functions accessible via bridge
- Implement basic vector storage and retrieval

### Phase 2: Prototypal Memory Objects
- Create VSAMemory prototype with three-layer architecture
- Implement Io-level concept management and metadata
- Add WAL persistence for semantic relationships

### Phase 3: Hierarchical Search
- Implement multi-layer search strategy
- Add automatic consolidation and background maintenance
- Create performance optimization and caching

### Phase 4: Morphic Memory Browser
- Visual memory exploration interface
- Concept clustering and relationship visualization
- Interactive memory modification and curation

This architecture enables true neuro-symbolic cognition by combining the computational power of modern ML libraries with the symbolic reasoning capabilities of prototypal Io, all integrated through our enhanced Synaptic Bridge.