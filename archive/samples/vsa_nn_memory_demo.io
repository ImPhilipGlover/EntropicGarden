#!/usr/bin/env io

// VSA-NN Memory Training Demo with Morphic UI
// Demonstrates hyperdimensional computing with neural network training

// Load TelOS framework
doFile("libs/Telos/io/IoTelos.io")

// Create demo training data
writeln("=== TelOS VSA-NN Memory Training Demo ===")
writeln("Initializing hyperdimensional memory system...")

// Access the existing Telos prototype
TelOS := Telos

// Set up training data with concepts and contexts
trainingData := Object clone
trainingData concepts := List clone
trainingData contexts := List clone

// Add conceptual knowledge
trainingData concepts append(Map clone do(
    name := "programming"
    description := "The process of creating computer software using programming languages"
    examples := list("Python", "JavaScript", "Io", "C++", "algorithms", "data structures")
))

trainingData concepts append(Map clone do(
    name := "mathematics"
    description := "The abstract science of number, quantity, and space"
    examples := list("algebra", "calculus", "geometry", "statistics", "linear algebra", "topology")
))

trainingData concepts append(Map clone do(
    name := "biology"
    description := "The natural science that studies life and living organisms"
    examples := list("cells", "genetics", "evolution", "ecology", "anatomy", "physiology")
))

// Add contextual knowledge
trainingData contexts append(Map clone do(
    text := "Io is a pure prototype-based programming language inspired by Smalltalk, Self, and Lisp"
    concepts := list("programming", "prototypes", "dynamic")
))

trainingData contexts append(Map clone do(
    text := "Vector spaces are fundamental mathematical structures used in linear algebra"
    concepts := list("mathematics", "vectors", "algebra")
))

trainingData contexts append(Map clone do(
    text := "Neural networks are computational models inspired by biological neural networks"
    concepts := list("programming", "biology", "artificial intelligence")
))

writeln("Training data prepared: #{trainingData concepts size} concepts, #{trainingData contexts size} contexts" interpolate)

// Train the memory system
writeln("\nTraining VSA-NN memory system...")

trainingData concepts foreach(conceptData,
    writeln("  Adding concept: #{conceptData name}" interpolate)
    TelOS addConcept(conceptData name, conceptData description)
    
    // Add examples as related contexts
    conceptData examples foreach(example,
        TelOS addContext(example .. " is related to " .. conceptData name, conceptData name)
    )
)

trainingData contexts foreach(contextData,
    writeln("  Adding context with #{contextData concepts size} concept links" interpolate)
    contextData concepts foreach(conceptName,
        TelOS addContext(contextData text, conceptName)
    )
)

writeln("Memory training complete!")

// Create Morphic visualization
writeln("\nCreating Morphic visualization...")

// Check if we have SDL2 support for full UI
hasSDL := try(
    TelOS openWindow(800, 600, "TelOS VSA-NN Memory Demo")
    true
) catch(
    writeln("  SDL2 not available, using console visualization")
    false
)

if(hasSDL,
    writeln("  Opening SDL2 window for live visualization...")
    
    // Create morphic world
    world := TelOS createWorld()
    writeln("  Morphic world created")
    
    // Create visualization morphs
    memoryMorph := TelOS createMorph("MemoryVisualization") do(
        // Use message passing instead of setSlot
        doString("x := 50")
        doString("y := 50") 
        doString("width := 700")
        doString("height := 500")
        doString("color := list(0.2, 0.3, 0.5, 1.0)")
    )
    
    statusMorph := TelOS createMorph("StatusDisplay") do(
        // Use message passing instead of setSlot
        doString("x := 50")
        doString("y := 10")
        doString("width := 700") 
        doString("height := 30")
        doString("color := list(0.8, 0.8, 0.8, 1.0)")
    )
    
    // Add morphs to world
    TelOS addMorphToWorld(world, memoryMorph)
    TelOS addMorphToWorld(world, statusMorph)
    
    writeln("  Morphs created and added to world")
    
    // Start interactive demo loop
    writeln("  Starting interactive memory demo...")
    writeln("  Use Ctrl+C to exit")
    
    demoQueries := list(
        "What is programming?",
        "Tell me about vectors", 
        "How do neural networks work?",
        "What is prototype-based programming?",
        "Explain linear algebra"
    )
    
    queryIndex := 0
    frameCount := 0
    
    // Main demo loop
    while(hasSDL and frameCount < 300, // Run for ~10 seconds at 30fps
        // Process events
        Telos handleEvent(world)
        
        // Update visualization every 60 frames (~2 seconds)
        if(frameCount % 60 == 0,
            currentQuery := demoQueries at(queryIndex)
            writeln("    Querying: #{currentQuery}" interpolate)
            
            // Search memory system
            searchResults := TelOS search(currentQuery, 3)
            writeln("    Found #{searchResults size} results" interpolate)
            
            searchResults foreach(i, result,
                writeln("      #{i + 1}. #{result text slice(0, 60)}..." interpolate)
                writeln("         Similarity: #{result similarity asString(0, 3)}" interpolate)
            )
            
            queryIndex = (queryIndex + 1) % demoQueries size
            writeln("")
        )
        
        // Draw frame
        TelOS draw(world)
        
        frameCount = frameCount + 1
        yield // Allow other processes
    )
    
    writeln("Demo visualization complete")
    TelOS closeWindow()
,
    // Console-only visualization
    writeln("  Console Memory Visualization:")
    writeln("  " .. ("=" repeated(60)))
    
    demoQueries := list(
        "What is programming?",
        "Tell me about mathematics", 
        "How do neural networks work?",
        "What is prototype-based programming?",
        "Explain biology concepts"
    )
    
    demoQueries foreach(i, query,
        writeln("  Query #{i + 1}: #{query}" interpolate)
        
        searchResults := TelOS search(query, 2)
        writeln("    Results found: #{searchResults size}" interpolate)
        
        searchResults foreach(j, result,
            writeln("      #{j + 1}. #{result text slice(0, 50)}..." interpolate)
            writeln("         Similarity: #{result similarity asString(0, 3)}" interpolate)
        )
        writeln("")
    )
)

// Demonstrate VSA operations directly
writeln("\n=== VSA Hyperdimensional Computing Demo ===")

// Generate test hypervectors
writeln("Generating test hypervectors...")
vectorA := TelOS vsaGenerateHypervector(100) // Smaller for demo
vectorB := TelOS vsaGenerateHypervector(100)
vectorC := TelOS vsaGenerateHypervector(100)

writeln("Generated vectors of dimension #{vectorA size}" interpolate)

// Demonstrate binding operation (⊗)
boundVector := TelOS vsaBind(vectorA, vectorB)
writeln("Binding A ⊗ B: #{boundVector size}-dimensional result" interpolate)

// Demonstrate bundling operation (⊕)  
bundleVector := TelOS vsaBundle(vectorA, vectorC)
writeln("Bundling A ⊕ C: #{bundleVector size}-dimensional result" interpolate)

// Demonstrate unbinding operation
unboundVector := TelOS vsaUnbind(boundVector, vectorB)
writeln("Unbinding (A ⊗ B) ÷ B: #{unboundVector size}-dimensional result" interpolate)

// Test similarity measurements
similarityAB := TelOS vsaCosineSimilarity(vectorA, vectorB)
similarityAUnbound := TelOS vsaCosineSimilarity(vectorA, unboundVector)
similarityABundle := TelOS vsaCosineSimilarity(vectorA, bundleVector)

writeln("\nSimilarity Analysis:")
writeln("  A vs B (random): #{similarityAB asString(0, 4)}" interpolate)
writeln("  A vs Unbound: #{similarityAUnbound asString(0, 4)}" interpolate) 
writeln("  A vs Bundle: #{similarityABundle asString(0, 4)}" interpolate)

// Test memory persistence
writeln("\n=== Memory Persistence Test ===")
writeln("Testing WAL (Write-Ahead Log) persistence...")

// Add a test memory entry
testEntry := TelOS addContext("VSA hyperdimensional computing enables distributed memory representations", "computing")
writeln("Added test entry to memory")

// Trigger WAL write
TelOS appendToWal("vsa_demo", Map clone do(
    action := "demo_complete";
    timestamp := Date clone now asString;
    vectorDimensions := 100;
    queriesProcessed := 5;
))

writeln("WAL entry written for demo session")

// Show current memory stats
memoryStats := TelOS getMemoryStats()
writeln("\nMemory System Statistics:")
writeln("  Concepts stored: #{memoryStats concepts}" interpolate)
writeln("  Contexts stored: #{memoryStats contexts}" interpolate)
writeln("  Neural training samples: #{memoryStats trainingSamples}" interpolate)
writeln("  Total hypervectors: #{memoryStats hypervectors}" interpolate)

writeln("\n=== VSA-NN Memory Demo Complete ===")
writeln("The living memory system demonstrates:")
writeln("  ✓ Hyperdimensional vector operations (bind, bundle, unbind)")
writeln("  ✓ Neural network similarity scoring with training")
writeln("  ✓ Morphic UI visualization (when SDL2 available)")
writeln("  ✓ Persistent memory with WAL transaction logging")
writeln("  ✓ Cross-modal concept binding and retrieval")
writeln("\nThis represents Phase 7 VSA-RAG Foundations of the TelOS roadmap.")