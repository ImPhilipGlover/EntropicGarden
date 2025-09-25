#!/usr/bin/env io

"Testing minimal chat with Ollama integration..." println

# Load the core system  
doFile("libs/Telos/io/TelosCore.io")

# Simple chat test
testChat := method(userMessage,
    ("User: " .. userMessage) println
    
    # Direct call to TelosOllama
    response := TelosOllama sendToOllama("gemma3:4b", userMessage)
    
    if(response success,
        ("AI: " .. response response) println
        return response response
    ,
        errorMsg := if(response hasSlot("error"), response error, "Unknown error") 
        ("ERROR: " .. errorMsg) println
        return nil
    )
)

"=== TelOS Chat Test ===" println

# Test 1
testChat("Hello, please respond with just one word.")

# Test 2
testChat("What is 2+2? Answer briefly.")

"Chat test complete." println