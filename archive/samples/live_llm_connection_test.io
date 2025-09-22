#!/usr/bin/env io

// Live LLM Connection Test - Proper Ollama Setup
// Tests actual live connections to Ollama

"=== Live LLM Connection Test ===" println
"🔗 Setting up proper Ollama connection" println

// Load personas
doFile("core_persona_cognition.io")

// Check initial state
"" println
"Initial LLM provider state:" println
("  useOllama: " .. Telos llmProvider atIfAbsent("useOllama", "not set")) println
("  baseUrl: " .. Telos llmProvider atIfAbsent("baseUrl", "not set")) println

// Properly enable Ollama
"" println
"Enabling Ollama..." println
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")

"Updated LLM provider state:" println
("  useOllama: " .. Telos llmProvider atIfAbsent("useOllama", "not set")) println
("  baseUrl: " .. Telos llmProvider atIfAbsent("baseUrl", "not set")) println

// Test direct LLM call
"" println
"Test 1: Direct Telos llmCall..." println
try(
    spec := Map clone
    spec atPut("model", "telos/brick")
    spec atPut("prompt", "Say hello briefly")
    spec atPut("system", "Be concise")
    spec atPut("temperature", 0.5)
    
    "Calling Telos llmCall..." println
    result := Telos llmCall(spec)
    
    if(result containsSeq("[OFFLINE_STUB"),
        "❌ Still getting offline stub - Ollama connection issue" println,
        ("✅ Live LLM response: " .. result slice(0, 100) .. "...") println
    )
,
    ("❌ Direct llmCall failed: " .. call sender) println
)

// Test 2: Persona facet call
"" println
"Test 2: Persona facet call..." println
try(
    queryObj := Object clone
    queryObj queryText := "Hello world"
    queryObj topicName := "Connection Test"
    
    tamlandFacet := BrickTamlandFacet clone
    
    "Calling BrickTamlandFacet processQuery..." println
    result := tamlandFacet processQuery(queryObj)
    
    if(result response containsSeq("[OFFLINE_STUB"),
        "❌ Persona still returning offline stub" println,
        ("✅ Live persona response: " .. result response slice(0, 100) .. "...") println
    )
,
    ("❌ Persona call failed: " .. call sender) println
)

// Test 3: Check FFI bridge
"" println  
"Test 3: Check FFI bridge availability..." println
if(Telos hasSlot("Telos_rawOllamaGenerate"),
    "✅ Telos_rawOllamaGenerate FFI available" println,
    "❌ Telos_rawOllamaGenerate FFI missing - that's the problem!" println
)

"" println
"🏁 Connection test complete!" println