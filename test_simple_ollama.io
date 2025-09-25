#!/usr/bin/env io

# Simple Ollama test - no JSON parsing complexity

doFile("libs/Telos/io/TelosCore.io")

# Simple Ollama call using Python to extract just the response text
simpleOllamaCall := method(model, prompt,
    pythonCode := """
import requests
import json

try:
    response = requests.post('http://localhost:11434/api/generate', 
                           json={
                               'model': '""" .. model .. """',
                               'prompt': '""" .. prompt .. """',
                               'stream': False
                           }, 
                           timeout=15)
    
    if response.status_code == 200:
        data = response.json()
        # Just print the response text directly
        print(data.get('response', 'No response field found'))
    else:
        print('ERROR: HTTP ' + str(response.status_code))
        
except Exception as e:
    print('ERROR: ' + str(e))
"""
    
    if(Telos hasSlot("pyEval"),
        result := Telos pyEval(pythonCode)
        ("Ollama response: " .. result) println
        result
    ,
        "Python FFI not available" println
        nil
    )
)

"Testing simple Ollama call..." println
response := simpleOllamaCall("gemma3:4b", "Say hello in exactly 3 words")
"Test complete." println