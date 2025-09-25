// TelOS Neuro-Symbolic Intelligence Demonstration
"=== TelOS Neuro-Symbolic Intelligence System ===" println

// Test basic FFI connectivity  
"Testing synaptic bridge..." println
ffiTest := Telos pyEval("print('Python muscle connected successfully')")
ffiTest println

// Test cognitive services
"Testing cognitive services..." println
cogTest := Telos pyEval("
from cognitive_services import CognitiveCoordinator
coord = CognitiveCoordinator()
result = coord.cognitive_query('consciousness', 'AI context')
print('GCE candidates:', len(result.get('gce_candidates', [])))
print('HRC operations:', result.get('hrc_reasoning', {}).get('binding_operations', 0))
print('Cognitive cycle complete')
")
cogTest println

// Test Ollama
"Testing Ollama integration..." println
ollamaTest := Telos pyEval("
import subprocess
try:
    result = subprocess.run(['ollama', 'list'], capture_output=True, text=True, timeout=3)
    if result.returncode == 0:
        lines = result.stdout.strip().split('\\n')[1:]
        models = [line.split()[0] for line in lines if line.strip()]
        print('Ollama models available:', len(models))
    else:
        print('Ollama service not accessible')
except:
    print('Ollama check timeout')
")
ollamaTest println

"=== DEMONSTRATION COMPLETE ===" println
