#!/usr/bin/env io

# Test the updated TelosOllama with simplified approach

doFile("libs/Telos/io/TelosCore.io")

# Load TelosOllama module
Telos loadModule("TelosOllama")

"Testing updated TelosOllama with gemma3:4b model..." println

# Test with a simple prompt
response := TelosOllama sendToOllama("gemma3:4b", "Say hello briefly")

if(response success,
    ("✓ SUCCESS: " .. response response) println
    ("Model used: " .. response model) println
,
    ("✗ FAILED: " .. response error) println
)

"Test completed." println