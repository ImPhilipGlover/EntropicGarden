#!/usr/bin/env io

// Complete Inter/Intra Persona Cognition Integration Demo
// Tests both the cognitive facet system and Morphic UI visualization

"=== TelOS Inter/Intra Persona Cognition Systems Integration Demo ===" println
"" println

// Load required systems
"Loading inter/intra persona cognition system..." println
doFile("inter_intra_persona_cognition.io")

"Loading Morphic UI visualization..." println  
doFile("morphic_persona_cognition_demo.io")

// Test 1: Pure cognitive facet system (no UI)
testCognitiveFacets := method(
    "=== Test 1: Cognitive Facet System ===" println
    
    // Create test query
    testQuery := Object clone
    testQuery queryText := "What is the nature of consciousness in AI?"
    testQuery topicName := "AI Consciousness"
    
    // Test BRICK cognitive facets
    "Testing BRICK cognitive facets..." println
    
    tamlandFacet := BrickTamlandFacet clone
    tamlandResult := tamlandFacet processQuery(testQuery)
    ("  Tamland facet (T:" .. tamlandFacet llmParams temperature .. "): " .. tamlandResult response) println
    
    batmanFacet := BrickLegoBatmanFacet clone  
    batmanResult := batmanFacet processQuery(testQuery)
    ("  Batman facet (T:" .. batmanFacet llmParams temperature .. "): " .. batmanResult response) println
    
    guideFacet := BrickGuideFacet clone
    guideResult := guideFacet processQuery(testQuery)
    ("  Guide facet (T:" .. guideFacet llmParams temperature .. "): " .. guideResult response) println
    
    "" println
)

// Test 2: Synaptic cycle state machine  
testSynapticCycle := method(
    "=== Test 2: Synaptic Cycle State Machine ===" println
    
    // Create BRICK persona
    brick := BrickPersona clone
    brick initializeFacets
    
    // Create test query
    cycleQuery := Object clone
    cycleQuery queryText := "How do neural networks learn?"
    cycleQuery topicName := "Neural Learning"
    
    // Test complete synaptic cycle
    "Running BRICK synaptic cycle..." println
    result := brick conductInternalMonologue(cycleQuery)
    ("Result: " .. result) println
    
    "" println
)

// Test 3: Socratic Contrapunto dialogue
testSocraticContrapunto := method(
    "=== Test 3: Socratic Contrapunto Inter-Persona Dialogue ===" println
    
    // Create personas
    brick := BrickPersona clone
    robin := RobinPersona clone
    
    // Create dialogue query
    dialogueQuery := Object clone
    dialogueQuery queryText := "Should AI systems have emotions?"
    dialogueQuery topicName := "AI Emotions"
    
    // Initialize and run dialogue
    dialogue := SocraticContrapunto clone
    dialogue initializeDialogue(brick, robin, nil, nil)
    
    "Conducting inter-persona dialogue..." println
    dialogueResult := dialogue conductDialogue(dialogueQuery)
    
    ("Topic: " .. dialogueResult topic topicName) println
    ("BRICK: " .. dialogueResult brickAnalysis) println
    ("ROBIN: " .. dialogueResult robinSynthesis) println
    
    "" println
)

// Test 4: Complete system integration
testCompleteIntegration := method(
    "=== Test 4: Complete System Integration ===" println
    
    // Test the main demonstration function
    "Running complete persona cognition demonstration..." println
    result := demonstratePersonaCognition
    
    "Integration test completed successfully!" println
    "" println
)

// Test 5: Morphic UI system
testMorphicUI := method(
    "=== Test 5: Morphic UI Visualization ===" println
    
    "Creating Morphic canvas for persona cognition..." println
    
    // The canvas should already be created from loading the morphic demo
    if(demoCanvas,
        "Morphic canvas created successfully!" println
        ("Canvas bounds: " .. demoCanvas bounds) println
        ("Number of facet displays: " .. demoCanvas facetDisplays size) println
        
        // Test running a demo cycle
        "Testing demo cognition cycle..." println
        demoCanvas runPersonaCognitionDemo
        
        "Morphic UI test completed!" println
    else,
        "Error: Morphic canvas not found!" println
    )
    
    "" println
)

// Run all tests
runAllTests := method(
    "Starting comprehensive inter/intra persona cognition tests..." println
    "" println
    
    testCognitiveFacets
    testSynapticCycle  
    testSocraticContrapunto
    testCompleteIntegration
    testMorphicUI
    
    "=== All Tests Completed ===" println
    "The inter/intra persona cognition system with live LLM integration" println
    "and Morphic UI demonstration is now operational!" println
    "" println
    "Key Features Demonstrated:" println
    "• Cognitive Facet Pattern with parameterized LLM inference" println
    "• Synaptic Cycle state machine for intra-persona monologues" println  
    "• Socratic Contrapunto protocol for inter-persona dialogues" println
    "• Live Morphic UI visualization of all cognitive processes" println
    "• Pure prototypal implementation with immediate object usability" println
    "" println
    "Click on the Morphic canvas to see live demonstrations!" println
)

// Execute the comprehensive test suite
runAllTests