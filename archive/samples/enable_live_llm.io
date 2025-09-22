#!/usr/bin/env io

// Enable Live LLM Integration - Configure TelOS for Ollama
// This configures TelOS to use live Ollama instead of offline stubs

"=== Enabling Live LLM Integration via Ollama ===" println

// Configure TelOS to use Ollama
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")

// Verify configuration
"LLM Provider Configuration:" println
Telos llmProvider keys foreach(key,
    ("  " .. key .. ": " .. Telos llmProvider at(key)) println
)

// Test basic Ollama connectivity
"Testing Ollama connectivity..." println
testResult := Telos llmCall(Map clone do(
    atPut("model", "telos/robin")
    atPut("prompt", "Say hello")
    atPut("system", "You are a helpful assistant")
))

("Test result: " .. testResult) println

"✅ Live LLM integration enabled!" println