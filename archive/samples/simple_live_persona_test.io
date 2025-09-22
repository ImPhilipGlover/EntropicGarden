#!/usr/bin/env io

// Simple Live Persona Cognition Test - Single Facet
// Tests one cognitive facet with live Ollama integration

"=== Simple Live Persona Cognition Test ===" println

// Enable live LLM integration
Telos llmProvider atPut("useOllama", true)  
Telos llmProvider atPut("baseUrl", "http://localhost:11434")
"✅ Ollama integration enabled" println

// Load core system (without auto-demo)
doFile("core_persona_cognition.io")

// Test single facet with live LLM call
"--- Testing Single Cognitive Facet with Live LLM ---" println

// Create test query
testQuery := Object clone
testQuery queryText := "What makes a good conversation?"
testQuery topicName := "Communication Quality"

// Test BRICK TamlandEngine facet
"Testing BRICK TamlandEngine with live Ollama call..." println
tamlandFacet := BrickTamlandFacet clone

try(
    startTime := Date now asNumber
    facetResult := tamlandFacet processQuery(testQuery)
    endTime := Date now asNumber
    responseTime := ((endTime - startTime) * 1000) asInteger
    
    ("✅ Live LLM Response (" .. responseTime .. "ms):") println
    ("   Model: " .. facetResult model) println  
    ("   Facet: " .. facetResult facetName) println
    ("   Response: " .. facetResult response slice(0, 200) .. "...") println
    
    if(facetResult response containsSeq("[OFFLINE_STUB"),
        "❌ Still getting offline stub - LLM not working properly" println,
        "🎯 Live LLM integration successful!" println
    )
,
    ("❌ Error in live facet test: " .. call sender) println
)

"" println

// Test different model (ROBIN)
"Testing ROBIN AlanWattsSage with live Ollama call..." println  
sageFacet := RobinSageFacet clone

try(
    startTime := Date now asNumber
    facetResult := sageFacet processQuery(testQuery)
    endTime := Date now asNumber
    responseTime := ((endTime - startTime) * 1000) asInteger
    
    ("✅ Live LLM Response (" .. responseTime .. "ms):") println
    ("   Model: " .. facetResult model) println
    ("   Facet: " .. facetResult facetName) println
    ("   Response: " .. facetResult response slice(0, 200) .. "...") println
    
    if(facetResult response containsSeq("[OFFLINE_STUB"),
        "❌ Still getting offline stub - LLM not working properly" println,
        "🎯 Live LLM integration successful!" println  
    )
,
    ("❌ Error in live facet test: " .. call sender) println
)

"" println
"=== Simple Live Test Complete ===" println