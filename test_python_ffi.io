// Test Python FFI and Ollama integration directly

"Testing Python FFI..." println

// Test basic Python
if(Telos hasSlot("pyEval"),
    result := Telos pyEval("2 + 2")
    ("Basic Python test result: " .. result) println
    
    // Test requests import
    requestsTest := Telos pyEval("import requests; 'requests module available'")
    ("Requests module test: " .. requestsTest) println
    
    // Test simple HTTP request
    httpTest := Telos pyEval("""
import requests
try:
    response = requests.get('http://httpbin.org/status/200', timeout=5)
    'HTTP test successful: ' + str(response.status_code)
except Exception as e:
    'HTTP test failed: ' + str(e)
""")
    ("HTTP test result: " .. httpTest) println
    
    // Test Ollama service with a very simple request
    ollamaTest := Telos pyEval("""
import requests
import json

try:
    url = 'http://localhost:11434/api/tags'
    response = requests.get(url, timeout=3)
    if response.status_code == 200:
        data = response.json()
        'Ollama tags successful: ' + str(len(data.get('models', []))) + ' models'
    else:
        'Ollama tags failed: HTTP ' + str(response.status_code)
except Exception as e:
    'Ollama connection error: ' + str(e)
""")
    ("Ollama connection test: " .. ollamaTest) println
    
,
    "Python FFI not available!" println
)

"Test completed." println