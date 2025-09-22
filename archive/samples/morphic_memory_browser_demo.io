#!/usr/bin/env io

// Morphic Memory Browser Demo
// Demonstrates visual direct manipulation of the VSA-RAG Memory Substrate

doFile("libs/Telos/io/MemoryBrowser.io")

writeln("=== Morphic Memory Browser Demo ===")
writeln("Visual direct manipulation of VSA-RAG Memory Substrate")
writeln()

// Initialize TelOS with Morphic Canvas
writeln("1. Initializing Morphic Canvas...")
telos := Telos clone
telos createWorld

// Create canvas for memory browser
canvas := Object clone
canvas title := "TelOS Memory Browser"
canvas size := List clone append(800, 600)
canvas world := telos world

writeln("   Canvas: " .. canvas title .. " (" .. canvas size at(0) .. "x" .. canvas size at(1) .. ")")

writeln()
writeln("2. Initializing Memory Browser...")
browser := MemoryBrowser clone
browser initialize(canvas)

writeln()
writeln("3. Adding sample concepts to memory...")
browser addSampleConcepts

writeln()
writeln("4. Testing concept selection...")
// Get first concept for selection test
if(browser conceptMorphs size > 0,
    firstConceptId := browser conceptMorphs keys at(0)
    firstConcept := browser conceptMorphs at(firstConceptId) getSlot("concept")
    if(firstConcept,
        browser selectConcept(firstConcept)
        writeln("   Selected concept: " .. firstConcept content slice(0, 50) .. "...")
    )
)

writeln()
writeln("5. Testing memory search...")
searchResults := browser search("consciousness information integration")
writeln("   Search results: " .. searchResults size .. " concepts found")

searchResults foreach(i, result,
    if(result hasSlot("text") and result hasSlot("similarity"),
        writeln("     Result " .. i .. ": " .. result text slice(0, 60) .. "... (score: " .. result similarity .. ")")
    )
)

writeln()
writeln("6. Testing related concept discovery...")
if(browser selectedConcept,
    browser showRelatedConcepts(browser selectedConcept)
    writeln("   Related concepts highlighted for: " .. browser selectedConcept content slice(0, 50) .. "...")
)

writeln()
writeln("7. Running Morphic interaction loop...")
canvas heartbeat(3)
writeln("   Morphic UI active for 3 heartbeats")

writeln()
writeln("8. Memory browser statistics...")
stats := browser stats
writeln("   Timestamp: " .. stats timestamp)
writeln("   Concepts in browser: " .. stats conceptCount)
writeln("   Selected concept: " .. (if(stats selectedConcept, stats selectedConcept, "none")))
writeln("   Last search query: '" .. stats searchQuery .. "'")
writeln("   Display mode: " .. stats displayMode)

if(stats hasSlot("memoryStats"),
    memStats := stats memoryStats
    writeln("   Memory substrate:")
    if(memStats hasSlot("semanticConcepts"),
        writeln("     Semantic concepts: " .. memStats semanticConcepts)
    )
    if(memStats hasSlot("temporalSequence"),
        writeln("     Temporal sequence: " .. memStats temporalSequence)
    )
)

writeln()
writeln("9. Testing memory persistence...")
browser memory consolidate

writeln()
writeln("10. Final canvas state...")
canvas captureScreenshot
writeln("    World morph tree captured")

writeln()
writeln("=== Morphic Memory Browser Demo Complete ===")
writeln("Successfully demonstrated:")
writeln("  ✓ Visual memory browser initialization")
writeln("  ✓ Sample concept creation with visual morphs") 
writeln("  ✓ Direct manipulation concept selection")
writeln("  ✓ Visual search with result highlighting")
writeln("  ✓ Related concept discovery and visualization")
writeln("  ✓ Live Morphic UI interaction loop")
writeln("  ✓ Memory substrate persistence integration")
writeln("  ✓ Comprehensive statistics and monitoring")
writeln()
writeln("VSA-RAG Memory Substrate is now accessible through direct manipulation!")
writeln("Users can visually explore, search, and interact with memory concepts.")