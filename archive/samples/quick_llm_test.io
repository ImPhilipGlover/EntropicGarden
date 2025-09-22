#!/usr/bin/env io

// Quick LLM Test - Validate Live Persona Connection
// Tests that we can reach Ollama and get responses

"=== Quick LLM Validation ===" println
"🔍 Testing basic Ollama connectivity" println

// Load personas with minimal setup
doFile("core_persona_cognition.io")

// Test 1: Direct HTTP Test
"" println
"Test 1: Raw HTTP connectivity..." println
try(
    // Simple curl test
    result := System system("curl -s --max-time 10 http://localhost:11434/api/tags | head -5")
    if(result == 0,
        "✅ Ollama HTTP connection successful" println,
        "❌ Ollama HTTP connection failed" println
    )
,
    "❌ HTTP test exception" println
)

// Test 2: Quick Persona Query
"" println
"Test 2: Quick persona query with timeout..." println
try(
    queryObj := Object clone
    queryObj queryText := "Hello"
    queryObj topicName := "Connection Test"
    
    tamlandFacet := BrickTamlandFacet clone
    
    // Set a short timeout in the facet if possible
    tamlandFacet timeout := 5
    
    "Sending query to BRICK..." println
    result := tamlandFacet processQuery(queryObj)
    
    if(result response,
        ("✅ BRICK responded: " .. result response slice(0, 50) .. "...") println,
        "❌ BRICK no response" println
    )
,
    ("❌ BRICK query failed: " .. call sender) println
)

"" println
"Test 3: Check persona facet setup..." println
brick := BrickPersona clone
if(brick tamlandFacet,
    ("✅ BRICK facets loaded: " .. brick tamlandFacet type) println,
    "❌ BRICK facets not found" println
)

robin := RobinPersona clone  
if(robin sageFacet,
    ("✅ ROBIN facets loaded: " .. robin sageFacet type) println,
    "❌ ROBIN facets not found" println
)

"" println
"🏁 Quick validation complete!" println