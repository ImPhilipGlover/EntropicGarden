#!/usr/bin/env io

// Enhanced Generative Kernel with Live LLM Persona Integration
// Combines the forward protocol with live persona cognition for intelligent synthesis

"=== Live LLM-Enhanced Generative Kernel Demo ===" println
"🚀 Combining forward protocol with persona cognition" println
"" println

// Enable live LLM integration
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")
"✅ Ollama integration enabled for generative synthesis" println

// Load live persona cognition system
doFile("core_persona_cognition.io")

// Create world for demonstration
world := Telos createWorld
"🌍 Living world created" println
"" println

// Enhanced synthesis that uses live persona cognition
enhancedSynthesisExample := method(
    "=== Test 1: Persona-Guided Synthesis ===" println
    
    // Test unknown method that gets analyzed by BRICK for structure
    unknownResult := Telos analyzeUnknownPattern("complex data structure")
    ("Generated result: " .. unknownResult asString) println
    "" println
    
    "=== Test 2: Creative Synthesis via ROBIN ===" println
    
    // Test creative synthesis that should route to ROBIN for wisdom
    creativeResult := Telos synthesizeCreativeApproach("artistic visualization")
    ("Creative synthesis: " .. creativeResult asString) println
    "" println
    
    "=== Test 3: Technical Synthesis via BRICK ===" println
    
    // Test technical method that BRICK should handle literally
    technicalResult := Telos implementTechnicalSpecification("performance optimization")
    ("Technical synthesis: " .. technicalResult asString) println
    "" println
    
    "=== Test 4: Adaptive Behavior Learning ===" println
    
    // Test learning from multiple attempts
    adaptive1 := Telos learnFromInteraction("first attempt", "basic")
    ("Adaptive 1: " .. adaptive1 asString) println
    
    adaptive2 := Telos learnFromInteraction("second attempt", "improved")  
    ("Adaptive 2: " .. adaptive2 asString) println
    
    adaptive3 := Telos learnFromInteraction("third attempt", "optimized")
    ("Adaptive 3: " .. adaptive3 asString) println
    "" println
)

// Enhanced forward method that integrates persona cognition
Telos enhancedForward := method(
    // Capture the unknown message and arguments
    msg := call message
    args := call evalArgs
    selector := msg name
    
    // Create query for persona analysis
    queryObj := Object clone
    queryObj queryText := "How should I implement a method called '" .. selector .. "' with arguments: " .. args asString .. "?"
    queryObj topicName := "Generative Synthesis"
    
    // Route to appropriate persona based on method characteristics
    if(selector containsSeq("technical") or selector containsSeq("implement") or selector containsSeq("optimize"),
        // Use BRICK for technical/literal analysis
        ("🧱 BRICK analyzing technical synthesis: " .. selector) println
        try(
            tamlandFacet := BrickTamlandFacet clone
            brickResult := tamlandFacet processQuery(queryObj)
            
            // Create synthetic result based on BRICK's analysis
            result := Object clone
            result type := "BrickSynthesis"
            result method := selector
            result analysis := brickResult response
            result implementation := method("Technical implementation guided by BRICK literal analysis")
            
            ("✅ BRICK synthesis complete") println
            return result
        ,
            ("❌ BRICK synthesis failed, falling back to standard") println
        )
    )
    
    if(selector containsSeq("creative") or selector containsSeq("artistic") or selector containsSeq("synthesize"),
        // Use ROBIN for creative/philosophical synthesis
        ("🐦 ROBIN providing creative synthesis: " .. selector) println
        try(
            sageFacet := RobinSageFacet clone
            robinResult := sageFacet processQuery(queryObj)
            
            // Create synthetic result based on ROBIN's wisdom
            result := Object clone
            result type := "RobinSynthesis"
            result method := selector  
            result wisdom := robinResult response
            result implementation := method("Creative implementation guided by ROBIN philosophical wisdom")
            
            ("✅ ROBIN synthesis complete") println
            return result
        ,
            ("❌ ROBIN synthesis failed, falling back to standard") println
        )
    )
    
    // Default to original generative kernel
    ("🔄 Using standard generative synthesis for: " .. selector) println
    return self forward
)

// Override the forward method with enhanced version
Telos forward := Telos enhancedForward

// Run the demonstration
enhancedSynthesisExample

"=== Test 5: Morphic Synthesis with Context ===" println

// Test morphic creation with live persona guidance
morphResult := Telos createIntelligentMorph("responsive interface element")
("Morph synthesis: " .. morphResult asString) println

"" println
"🎯 DEMO COMPLETE: Live LLM-Enhanced Generative Kernel" println
"✨ The system now uses BRICK and ROBIN personas to guide synthesis!" println
"📝 Check output above for persona-guided synthesis results" println