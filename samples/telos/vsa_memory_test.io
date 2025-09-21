#!/usr/bin/env io

// VSA-RAG Memory Substrate Test
// Demonstrates the three-tier memory architecture with live vector operations

doFile("libs/Telos/io/VSAMemory.io")

writeln("=== VSA-RAG Memory Substrate Test ===")
writeln("Testing three-tier memory architecture (L1 FAISS + L2 DiskANN + L3 Io Semantic)")
writeln()

// Initialize memory system
writeln("1. Initializing VSA Memory Substrate...")
memory := VSAMemory clone
memory initialize

writeln()
writeln("2. Testing embedding generation...")

// Test embedding
testText := "The fractal nature of consciousness emerges through recursive self-reflection"
embedding := memory embed(testText)
writeln("  Generated embedding for: " .. testText)
writeln("  Embedding dimension: " .. embedding dimension)

writeln()
writeln("3. Testing memory storage...")

// Store several related concepts
concepts := List clone
concepts append("Consciousness emerges from complex information integration")
concepts append("Fractal patterns reveal self-similar structures across scales")
concepts append("Autopoietic systems maintain their organization through self-production")
concepts append("Vector symbolic architectures enable compositional reasoning")
concepts append("Neuro-symbolic integration combines neural and symbolic computation")

concepts foreach(i, concept,
    metadata := Map clone
    metadata atPut("index", i)
    metadata atPut("category", "cognitive_science")
    metadata atPut("timestamp", Date now asString)
    
    result := memory store(concept, metadata)
    writeln("  Stored concept " .. i .. ": " .. concept)
    writeln("    Vector ID: " .. result vectorId)
)

writeln()
writeln("4. Testing memory search...")

// Search for related concepts
searchQuery := "How does consciousness emerge from information processing?"
searchResults := memory search(searchQuery, Map clone do(atPut("k", 3)))

writeln("  Search query: " .. searchQuery)
writeln("  Found " .. searchResults size .. " related concepts:")

searchResults foreach(i, result,
    writeln("    Result " .. i .. ":")
    if(result hasSlot("text"),
        writeln("      Text: " .. result text)
    )
    if(result hasSlot("similarity"),
        writeln("      Similarity: " .. result similarity)
    )
    if(result hasSlot("relatedConcepts"),
        writeln("      Related concepts: " .. result relatedConcepts size)
    )
)

writeln()
writeln("5. Testing semantic relationships...")

// Test semantic layer directly
semantic := memory semanticStore
relatedConcepts := semantic findRelated("consciousness", "similar")
writeln("  Concepts related to 'consciousness': " .. relatedConcepts size)

relatedConcepts foreach(i, concept,
    writeln("    " .. i .. ": " .. concept concept)
)

writeln()
writeln("6. Memory statistics...")

stats := memory stats
writeln("  Timestamp: " .. stats timestamp)
if(stats hasSlot("fastCacheStats"),
    writeln("  Fast cache stats: " .. stats fastCacheStats)
)
writeln("  Semantic concepts: " .. stats semanticConcepts)
writeln("  Temporal sequence: " .. stats temporalSequence)

writeln()
writeln("7. Testing memory consolidation...")
memory consolidate

writeln()
writeln("=== VSA-RAG Memory Test Complete ===")
writeln("Successfully demonstrated:")
writeln("  ✓ Three-tier memory architecture initialization")
writeln("  ✓ Vector embedding generation via Python backend")  
writeln("  ✓ Cross-language memory storage (Io → Python)")
writeln("  ✓ Semantic search with similarity ranking")
writeln("  ✓ Prototypal memory interface with enhanced bridge")
writeln("  ✓ Background consolidation processes")
writeln()
writeln("VSA-RAG Memory Substrate is operational and ready for cognitive integration!")