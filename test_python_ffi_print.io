// Test Python FFI with explicit print statements

"Testing Python FFI with explicit prints..." println

if(Telos hasSlot("pyEval"),
    // Test basic calculation with print
    result1 := Telos pyEval("print(2 + 2)")
    ("Math test result: '" .. result1 .. "'") println
    
    // Test string with print
    result2 := Telos pyEval("print('Hello from Python!')")
    ("String test result: '" .. result2 .. "'") println
    
    // Test imports with print
    result3 := Telos pyEval("import requests; print('requests imported successfully')")
    ("Import test result: '" .. result3 .. "'") println
    
    // Test HTTP request with output
    result4 := Telos pyEval("
import requests
try:
    response = requests.get('http://httpbin.org/json', timeout=5)
    print(f'HTTP test: status {response.status_code}')
except Exception as e:
    print(f'HTTP error: {e}')
")
    ("HTTP test result: '" .. result4 .. "'") println
    
    // Test Ollama with output
    result5 := Telos pyEval("
import requests
import json
try:
    response = requests.get('http://localhost:11434/api/tags', timeout=3)
    if response.status_code == 200:
        data = response.json()
        models = len(data.get('models', []))
        print(f'Ollama: {models} models available')
    else:
        print(f'Ollama error: HTTP {response.status_code}')
except Exception as e:
    print(f'Ollama connection failed: {e}')
")
    ("Ollama test result: '" .. result5 .. "'") println
    
,
    "Python FFI not available!" println
)

"Test completed." println