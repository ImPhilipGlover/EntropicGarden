// Test fixed FFI with better error handling
"Testing improved FFI error handling..." println
result := Telos pyEval("
from cognitive_services import CognitiveCoordinator
coord = CognitiveCoordinator()
result = coord.cognitive_query('what is consciousness', 'neuro-symbolic AI context')
print('GCE candidates:', len(result.get('gce_candidates', [])))
print('HRC operations:', result.get('hrc_reasoning', {}).get('binding_operations', 0))
print('Query completed successfully')
")
"FFI Result:" println
result println
"Test complete" println
