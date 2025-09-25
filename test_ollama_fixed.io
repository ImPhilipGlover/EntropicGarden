// Test the fixed TelosOllama sendToOllama method

"Testing fixed TelosOllama integration..." println

// Test direct Ollama call
response := TelosOllama sendToOllama("telos/alfred:latest", "Hello, tell me about consciousness in one sentence.")

if(response hasSlot("success"),
    if(response success,
        "✓ SUCCESS: Ollama responded!" println
        ("Model: " .. response model) println  
        ("Response: " .. response response) println
    ,
        "✗ FAILED: Ollama call failed" println
        ("Error: " .. response error) println
    )
,
    "✗ FAILED: Invalid response object" println
    response println
)

"Test completed." println