#!/usr/bin/env io

// Enhanced Synaptic Bridge Test
// Tests the new marshalling functions and async execution capabilities

writeln("=== Enhanced Synaptic Bridge Test ===")

// Test basic prototypal purity
telos := Telos clone

// Test 1: Enhanced Python evaluation with context marshalling
writeln("Test 1: Enhanced pyEval with context")
testContext := Map clone
testContext atPut("x", 42)
testContext atPut("message", "Hello from Io!")

result1 := telos pyEval("x * 2 + len(message)", testContext)
writeln("Result: ", result1)

// Test 2: Basic Python evaluation (backward compatibility)
writeln("\nTest 2: Basic pyEval")
result2 := telos pyEval("'Python bridge active: ' + str(3 + 4)")
writeln("Result: ", result2)

// Test 3: Async execution (if available)
writeln("\nTest 3: Async execution")
if(telos hasSlot("pyEvalAsync")) then(
    asyncResult := telos pyEvalAsync("import time; time.sleep(0.1); 'Async complete'")
    writeln("Async result: ", asyncResult)
) else(
    writeln("Async execution not available")
)

// Test 4: Complex data marshalling
writeln("\nTest 4: Complex data marshalling")
complexData := Map clone
complexData atPut("numbers", list(1, 2, 3, 4, 5))
complexData atPut("nested", Map clone atPut("inner", "value"))
complexData atPut("string", "test string")

result4 := telos pyEval("type(numbers).__name__ + ' with ' + str(len(numbers)) + ' items'", complexData)
writeln("Complex marshalling result: ", result4)

writeln("\n=== Enhanced Synaptic Bridge Test Complete ===")