#!/usr/bin/env io

// Simple test to debug pyEval issue
"Testing pyEval basic functionality..." println

// Test basic Python
result1 := Telos pyEval("2 + 2")
"Basic math result: " print
result1 println

// Test Python with import
result2 := Telos pyEval("""
import sys
sys.version
""")
"Python version result: " print
result2 println

// Test Python with path manipulation
result3 := Telos pyEval("""
import sys
sys.path.insert(0, '/mnt/c/EntropicGarden/python')
'Path added successfully'
""")
"Path manipulation result: " print
result3 println

// Test simple prototypal backend import
result4 := Telos pyEval("""
try:
    import sys
    sys.path.insert(0, '/mnt/c/EntropicGarden/python')
    from prototypal_neural_backend import create_prototypal_neural_backend
    'Import successful'
except Exception as e:
    f'Import failed: {e}'
""")
"Import test result: " print
result4 println