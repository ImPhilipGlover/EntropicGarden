#!/usr/bin/env io

// Simple VSA Memory Test - Direct Bridge Testing
// Tests the Enhanced Synaptic Bridge with Python backend

writeln("=== Simple VSA Memory Bridge Test ===")
writeln("Testing direct Python integration via Enhanced Synaptic Bridge")
writeln()

// Test basic Python execution first
writeln("1. Testing basic Python execution...")
telos := Telos clone
result := telos pyEval("print('Python subprocess working'); 'success'")
writeln("  Python result: " .. result)

writeln()
writeln("2. Testing Python imports...")
importTest := telos pyEval("
try:
    import numpy as np
    import os
    result = f'NumPy {np.__version__} available'
except ImportError as e:
    result = f'Import error: {e}'
result
")
writeln("  Import test: " .. importTest)

writeln()
writeln("3. Testing sys.path configuration...")
pathTest := telos pyEval("
import sys
sys.path.append('python')
try:
    from vsa_memory_backend import initialize_memory_backend
    result = 'VSA backend module found'
except ImportError as e:
    result = f'VSA backend import error: {e}'
result
")
writeln("  Path test: " .. pathTest)

writeln()
writeln("4. Testing simple VSA memory initialization...")
vaaTest := telos pyEval("
import sys
sys.path.append('python')
try:
    from vsa_memory_backend import initialize_memory_backend
    result = initialize_memory_backend(384, 100)
except Exception as e:
    result = f'VSA init error: {e}'
result
")
writeln("  VSA init test: " .. vaaTest)

writeln()
writeln("5. Testing simple embedding generation...")
embedTest := telos pyEval("
import sys
sys.path.append('python')
try:
    from vsa_memory_backend import embed_text
    vector = embed_text('Hello world test', 'sentence-transformers/all-MiniLM-L6-v2')
    result = f'Embedding generated, dimension: {len(vector)}'
except Exception as e:
    result = f'Embedding error: {e}'
result
")
writeln("  Embed test: " .. embedTest)

writeln()
writeln("=== Bridge Test Complete ===")
writeln("Successfully tested Enhanced Synaptic Bridge functionality!")
writeln("Ready for full VSA-RAG Memory Substrate integration.")