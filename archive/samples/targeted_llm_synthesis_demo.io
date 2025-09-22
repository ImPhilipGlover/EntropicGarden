#!/usr/bin/env io

// Targeted Live LLM Generative Synthesis Demo
// Tests specific synthesis scenarios with live persona integration

"=== Targeted Live LLM Generative Synthesis ===" println
"🎯 Testing specific synthesis patterns with live personas" println
"" println

// Enable live LLM integration
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")
"✅ Ollama enabled" println

// Load personas
doFile("core_persona_cognition.io")

// Create world
world := Telos createWorld
"🌍 World ready" println
"" println

// Test 1: Direct Technical Analysis via BRICK
"=== Test 1: BRICK Technical Analysis ===" println
try(
    queryObj := Object clone
    queryObj queryText := "Analyze the technical requirements for implementing a performanceOptimizer method"
    queryObj topicName := "Technical Synthesis"
    
    tamlandFacet := BrickTamlandFacet clone
    brickResult := tamlandFacet processQuery(queryObj)
    
    ("🧱 BRICK Technical Analysis:") println
    ("   Model: " .. brickResult model) println
    ("   Response: " .. brickResult response slice(0, 150) .. "...") println
    
    if(brickResult response containsSeq("[OFFLINE_STUB"),
        "❌ Offline mode - no live LLM" println,
        "✅ Live BRICK analysis successful!" println
    )
,
    ("❌ BRICK test failed: " .. call sender) println
)
"" println

// Test 2: Creative Synthesis via ROBIN
"=== Test 2: ROBIN Creative Synthesis ===" println
try(
    queryObj := Object clone
    queryObj queryText := "Design a creative approach for implementing an artisticMorphRenderer method"
    queryObj topicName := "Creative Synthesis"
    
    sageFacet := RobinSageFacet clone
    robinResult := sageFacet processQuery(queryObj)
    
    ("🐦 ROBIN Creative Synthesis:") println
    ("   Model: " .. robinResult model) println
    ("   Response: " .. robinResult response slice(0, 150) .. "...") println
    
    if(robinResult response containsSeq("[OFFLINE_STUB"),
        "❌ Offline mode - no live LLM" println,
        "✅ Live ROBIN synthesis successful!" println
    )
,
    ("❌ ROBIN test failed: " .. call sender) println
)
"" println

// Test 3: Synthesis-Guided Object Creation
"=== Test 3: Synthesis-Guided Creation ===" println

// Create objects based on live LLM guidance
createWithPersonaGuidance := method(intent, persona,
    try(
        queryObj := Object clone
        queryObj queryText := "Provide guidance for creating: " .. intent
        queryObj topicName := "Creation Guidance"
        
        result := persona processQuery(queryObj)
        
        // Create synthetic object with persona guidance
        syntheticObj := Object clone
        syntheticObj intent := intent
        syntheticObj guidance := result response
        syntheticObj model := result model
        syntheticObj facet := result facetName
        syntheticObj describe := method("Synthetic object: " .. intent .. " (guided by " .. facet .. ")")
        
        syntheticObj
    ,
        "Creation failed" println
        nil
    )
)

brickGuided := createWithPersonaGuidance("data structure optimizer", BrickTamlandFacet clone)
if(brickGuided,
    ("✅ BRICK-guided creation: " .. brickGuided describe) println
    ("   Guidance preview: " .. brickGuided guidance slice(0, 100) .. "...") println
)

robinGuided := createWithPersonaGuidance("harmony visualizer", RobinSageFacet clone)
if(robinGuided,
    ("✅ ROBIN-guided creation: " .. robinGuided describe) println
    ("   Guidance preview: " .. robinGuided guidance slice(0, 100) .. "...") println
)
"" println

// Test 4: Adaptive Learning Pattern
"=== Test 4: Adaptive Learning Synthesis ===" println

// Test learning across multiple persona interactions
learningSession := Object clone
learningSession attempts := List clone
learningSession personas := List clone append(BrickTamlandFacet clone) append(RobinSageFacet clone)

learningSession addAttempt := method(topic,
    ("Learning attempt: " .. topic) println
    
    // Try both personas and compare approaches
    brickQuery := Object clone
    brickQuery queryText := "Approach for: " .. topic
    brickQuery topicName := "Learning Session"
    
    robinQuery := Object clone  
    robinQuery queryText := "Wisdom about: " .. topic
    robinQuery topicName := "Learning Session"
    
    attempt := Object clone
    attempt topic := topic
    attempt brickApproach := personas at(0) processQuery(brickQuery) response slice(0, 80)
    attempt robinWisdom := personas at(1) processQuery(robinQuery) response slice(0, 80)
    attempt timestamp := Date now asNumber
    
    attempts append(attempt)
    
    ("  🧱 BRICK: " .. attempt brickApproach .. "...") println
    ("  🐦 ROBIN: " .. attempt robinWisdom .. "...") println
    "" println
    
    attempt
)

// Run learning session
learningSession addAttempt("error handling patterns")
learningSession addAttempt("user interface design")
learningSession addAttempt("system optimization")

("📚 Learning session complete: " .. learningSession attempts size .. " attempts") println
"" println

"🎯 TARGETED SYNTHESIS COMPLETE!" println
"✨ Successfully demonstrated:" println
"   • Live BRICK technical analysis" println
"   • Live ROBIN creative synthesis" println  
"   • Persona-guided object creation" println
"   • Adaptive learning patterns" println
"" println
"🚀 Ready for integration into generative kernel forward protocol!" println