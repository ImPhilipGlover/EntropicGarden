// Test enhanced FFI with complex cognitive query
"Testing enhanced FFI with multi-line cognitive query..." println

complexQuery := """from cognitive_services import CognitiveCoordinator
coord = CognitiveCoordinator()
result = coord.cognitive_query('what is consciousness', 'neuro-symbolic AI context')
print('GCE candidates:', len(result.get('gce_candidates', [])))
print('HRC operations:', result.get('hrc_reasoning', {}).get('binding_operations', 0))
print('Query completed successfully')"""

result := Telos pyEval(complexQuery)
("Enhanced FFI Result: " .. result) println

"Test complete" println
