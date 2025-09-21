#!/usr/bin/env io

// Simple test of the inter/intra persona cognition system
// Focus on core functionality without complex UI

"=== Simple Inter/Intra Persona Cognition Test ===" println

// Load just the core cognition system
doFile("inter_intra_persona_cognition.io")

// Test the complete persona cognition system
testPersonaCognition := method(
    "Testing complete persona cognition integration..." println
    
    // Create test query
    testQuery := Object clone
    testQuery queryText := "How can we create AI systems that are both creative and reliable?"
    testQuery topicName := "Creative AI Design"
    
    // Test individual cognitive facets
    "--- Testing Individual Cognitive Facets ---" println
    
    // BRICK facets
    "BRICK Tamland Facet:" println
    tamlandFacet := BrickTamlandFacet clone
    tamlandResult := tamlandFacet processQuery(testQuery)
    ("  Response: " .. tamlandResult response) println
    ("  Parameters: T=" .. tamlandFacet llmParams temperature .. ", P=" .. tamlandFacet llmParams top_p) println
    
    "BRICK LEGO Batman Facet:" println
    batmanFacet := BrickLegoBatmanFacet clone
    batmanResult := batmanFacet processQuery(testQuery)
    ("  Response: " .. batmanResult response) println
    ("  Parameters: T=" .. batmanFacet llmParams temperature .. ", P=" .. batmanFacet llmParams top_p) println
    
    // ROBIN facets
    "ROBIN Sage Facet:" println
    sageFacet := RobinSageFacet clone
    sageResult := sageFacet processQuery(testQuery)
    ("  Response: " .. sageResult response) println
    ("  Parameters: T=" .. sageFacet llmParams temperature .. ", P=" .. sageFacet llmParams top_p) println
    
    "" println
    
    // Test complete persona internal monologue
    "--- Testing Complete Persona Internal Monologue ---" println
    
    brick := BrickPersona clone
    brick initializeFacets
    
    "BRICK Internal Monologue:" println
    brickResult := brick conductInternalMonologue(testQuery)
    ("  Final synthesis: " .. brickResult) println
    
    "" println
    
    robin := RobinPersona clone
    robin initializeFacets
    
    "ROBIN Internal Monologue:" println
    robinResult := robin conductInternalMonologue(testQuery)
    ("  Final synthesis: " .. robinResult) println
    
    "" println
    
    // Test inter-persona dialogue
    "--- Testing Inter-Persona Dialogue (Socratic Contrapunto) ---" println
    
    dialogue := SocraticContrapunto clone
    dialogue initializeDialogue(brick, robin, nil, nil)
    
    dialogueResult := dialogue conductDialogue(testQuery)
    
    "Dialogue Results:" println
    ("  Topic: " .. dialogueResult topic topicName) println
    ("  BRICK Analysis: " .. dialogueResult brickAnalysis) println
    ("  ROBIN Synthesis: " .. dialogueResult robinSynthesis) println
    
    "" println
    "=== Test Complete ===" println
    "All persona cognition systems are operational!" println
)

// Run the test
testPersonaCognition