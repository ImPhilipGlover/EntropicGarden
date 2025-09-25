// Direct FFI test with fixed implementation
"=== Testing fixed FFI directly ===" println

// Test 1: Simple Python execution
"Test 1: Basic Python execution" println
result1 := Telos pyEval("print('FFI working')")
("Result 1: '" .. result1 .. "'") println

"=== FFI testing complete ===" println
