// Simple FFI Test - No Infinite Loops
// This tests the fixed Python integration

writeln("=== Testing Fixed Python FFI (No Infinite Loops) ===")

// Test 1: Basic Python initialization
writeln("Test 1: Basic Python version check")
version := Telos getPythonVersion()
writeln("Python version: " .. version)

// Test 2: Simple Python evaluation (synchronous, safe)
writeln("Test 2: Simple Python evaluation")
result := Telos pyEval("2 + 2")
writeln("2 + 2 = " .. result)

// Test 3: Safe string evaluation
writeln("Test 3: String evaluation")
stringResult := Telos pyEval("'Hello from Python'")
writeln("String result: " .. stringResult)

writeln("=== All tests completed successfully (no infinite loops) ===")