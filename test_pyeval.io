#!/usr/bin/env io

"Testing basic pyEval functionality..." println

result := Telos pyEval("print('Hello from Python!'); print('2 + 2 =', 2 + 2)")
"Python result:" println
result println

# Test import
result2 := Telos pyEval("import sys; print('Python executable:', sys.executable)")  
"Python executable result:" println
result2 println

"pyEval test complete" println