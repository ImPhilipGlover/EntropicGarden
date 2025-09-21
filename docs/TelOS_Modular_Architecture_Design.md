# TelOS Modular Architecture Design

**Problem Identified**: The current IoTelos.io file is 3950 lines long and causing segmentation faults during loading. This monolithic approach violates Io's modular design principles and creates maintenance nightmares.

**Solution**: Restructure TelOS following Io's addon architecture patterns, creating focused, interconnected modules that mirror the Io standard library organization.

## Current IoTelos.io Analysis

The monolithic file currently contains:

1. **Core Infrastructure** (~200 lines): Basic utilities, JSON, prototypal purity enforcement
2. **FFI/Synaptic Bridge** (~300 lines): Python integration, FFI calls, marshalling
3. **Persistence System** (~800 lines): WAL, snapshots, replay, transactions
4. **Morphic UI System** (~600 lines): World, morphs, events, direct manipulation
5. **VSA-RAG Memory** (~1200 lines): Hyperdimensional computing, neural networks, advanced vector search
6. **LLM Integration** (~400 lines): Persona management, Ollama integration, streaming
7. **Query Architecture** (~300 lines): Conversational VSA, unbind-cleanup dialogue
8. **Logging & Curation** (~200 lines): JSONL logging, curation queues
9. **Command System** (~150 lines): Runtime command dispatch
10. **Legacy Compatibility** (~800 lines): Various helper methods and stubs

## Proposed Modular Structure

Following Io's addon pattern (examine `libs/iovm/io/AddonLoader.io`), create focused modules:

```
libs/Telos/io/
├── TelosCore.io          # Core infrastructure, JSON, utilities
├── TelosFFI.io           # Synaptic Bridge (Io↔Python FFI)
├── TelosPersistence.io   # WAL, snapshots, transactions, replay
├── TelosMorphic.io       # Morphic UI system, direct manipulation
├── TelosMemory.io        # VSA-RAG memory, hyperdimensional computing
├── TelosPersona.io       # LLM integration, persona management
├── TelosQuery.io         # VSA query architecture, conversational dialogue
├── TelosLogging.io       # JSONL logging, curation, provenance
├── TelosCommands.io      # Runtime command system
└── A0_TelosLoader.io     # Module loader, dependency management
```

## Module Responsibilities

### TelosCore.io (~200 lines)
- Basic Telos prototype setup
- JSON utilities
- Prototypal purity enforcement
- Essential helper methods
- No dependencies

### TelosFFI.io (~300 lines)  
- Python FFI bridge (synaptic bridge)
- Cross-language marshalling
- Virtual environment management
- Error handling and cleanup
- Depends: TelosCore

### TelosPersistence.io (~400 lines)
- WAL (Write-Ahead Logging) system
- Snapshot creation and restoration
- Transaction management  
- Replay functionality
- Depends: TelosCore

### TelosMorphic.io (~400 lines)
- Morphic world and morph management
- Direct manipulation events
- UI state persistence
- Canvas and rendering coordination
- Depends: TelosCore, TelosPersistence

### TelosMemory.io (~600 lines)
- VSA-RAG hyperdimensional memory
- Neural network integration
- Advanced vector search (FAISS/DiskANN/HNSWLIB)
- Bind/bundle/unbind operations
- Depends: TelosCore, TelosFFI

### TelosPersona.io (~300 lines)
- LLM provider management (Ollama)
- Persona consistency scoring
- Generation parameter management
- Streaming response handling
- Depends: TelosCore, TelosFFI, TelosLogging

### TelosQuery.io (~200 lines)
- VSA conversational query architecture
- Unbind→cleanup dialogue patterns
- Compositional query planning
- Semantic-weighted bundling
- Depends: TelosCore, TelosMemory

### TelosLogging.io (~200 lines)
- JSONL logging infrastructure
- Curation queue management
- Provenance tracking
- Log rotation and maintenance
- Depends: TelosCore

### TelosCommands.io (~150 lines)
- Runtime command dispatch
- Debugging and inspection utilities
- Development helpers
- Depends: All other modules

### A0_TelosLoader.io (~100 lines)
- Module dependency resolution
- Load order management
- Error handling during startup
- Configuration management
- Loads all other modules in correct order

## Loading Architecture

Following Io's pattern with `A0_` prefix for loading order:

```io
// A0_TelosLoader.io - Loads modules in dependency order
TelosLoader := Object clone do(
    loadOrder := list(
        "TelosCore",
        "TelosFFI", 
        "TelosPersistence",
        "TelosLogging",
        "TelosMorphic",
        "TelosMemory",
        "TelosQuery",
        "TelosPersona",
        "TelosCommands"
    )
    
    loadModules := method(
        loadOrder foreach(moduleName,
            path := "libs/Telos/io/" .. moduleName .. ".io"
            doFile(path)
            writeln("TelOS: Loaded ", moduleName)
        )
    )
)

TelosLoader loadModules
```

## Benefits of Modular Architecture

1. **Resolves Segfault**: Smaller files load without memory issues
2. **Maintainability**: Focused modules easier to understand and modify
3. **Testability**: Each module can be tested independently
4. **Performance**: Only load needed modules, lazy loading possible
5. **Collaboration**: Different developers can work on different modules
6. **Follows Io Patterns**: Consistent with Io standard library architecture
7. **Scalability**: Easy to add new modules without affecting existing ones

## Migration Strategy

1. **Phase 1**: Create modular structure and A0_TelosLoader.io
2. **Phase 2**: Extract TelosCore.io (essential utilities only)
3. **Phase 3**: Extract TelosFFI.io (fix current segfault issue)
4. **Phase 4**: Extract remaining modules in dependency order
5. **Phase 5**: Update all test files to use new modular loading
6. **Phase 6**: Remove monolithic IoTelos.io file

## Prototypal Purity Compliance

Each module will maintain strict prototypal purity:
- All parameters treated as objects with message passing
- All variables implemented as slots, never simple assignments
- Immediate usability after cloning, no init methods
- Complete elimination of class-like patterns

This modular architecture aligns with both Io's design philosophy and our prototypal purity requirements while solving the immediate segfault issue.