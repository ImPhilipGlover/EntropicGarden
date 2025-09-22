#!/usr/bin/env io

// Minimal Live LLM Test - Direct TelOS llmCall

"=== Minimal Live LLM Test ===" println

// Enable Ollama
Telos llmProvider atPut("useOllama", true)
"✅ Ollama enabled" println

// Direct test
"Testing direct TelOS llmCall..." println
result := Telos llmCall(Map clone do(
    atPut("model", "telos/robin")  
    atPut("prompt", "Hello! Please respond with exactly: LIVE_LLM_WORKING")
    atPut("system", "You are a test assistant. Respond exactly as requested.")
    atPut("temperature", 0.1)
))

("Result: " .. result) println

if(result containsSeq("LIVE_LLM_WORKING"),
    "🎯 SUCCESS: Live LLM integration working!",
    "❌ ISSUE: Expected response not found"
) println