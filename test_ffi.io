#!/usr/bin/env io

// Test real FFI functionality - no fake messages

// Test 1: Basic Python execution
pythonTest := try(
    Telos pyEval("print('Python FFI test successful')")
) catch(Exception,
    "Python FFI failed: " println
    Exception message println
    nil
)

if(pythonTest,
    "Python FFI result: " println
    pythonTest println
,
    "Python FFI did not work" println
)

// Test 2: Cognitive query
cogTest := try(
    Telos cognitiveQuery("What is consciousness?", "philosophical")
) catch(Exception,
    "Cognitive query failed: " println
    Exception message println
    nil
)

if(cogTest,
    "Cognitive result: " println
    cogTest println
,
    "Cognitive system did not work" println
)