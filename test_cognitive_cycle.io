#!/usr/bin/env io


// Test script for TelOS LLM-GCE-HRC-AGL cognitive cycle
"Testing TelOS Cognitive Cycle..." println
"" println

// Test 1: Basic Telos system availability
"=== Test 1: System Availability ===" println
Telos type println
"Telos system type confirmed: " .. (Telos type) println
"" println

// Test 2: Check available methods
"=== Test 2: Available Methods ===" println
"Available Telos methods:" println
Telos slotNames sort foreach(name,
    nameStr := name asString
    if(nameStr beginsWithSeq("cognitive") or nameStr beginsWithSeq("ollama") or nameStr beginsWithSeq("gce") or nameStr beginsWithSeq("hrc"),
        "  " .. nameStr println
    )
)
"" println

// Test 3: Test cognitive query
"=== Test 3: Cognitive Query ===" println
"Testing cognitiveQuery method..." println
if(Telos hasSlot("cognitiveQuery"),
    result := Telos cognitiveQuery("What is consciousness?", "philosophical inquiry")
    "Cognitive query result: " .. result println
,
    "cognitiveQuery method not found" println
)
"" println

// Test 4: Test Ollama integration
"=== Test 4: Ollama Integration ===" println
"Testing Ollama integration..." println
if(Telos hasSlot("ollamaQuery"),
    ollamaResult := Telos ollamaQuery("telos/alfred:latest", "Explain your role as ALFRED in one sentence", "system context")
    "Ollama result: " .. ollamaResult println
,
    "ollamaQuery method not found" println
)
"" println

// Test 5: Test FFI health
"=== Test 5: FFI Health Check ===" println
if(Telos hasSlot("ffiHealth"),
    ffiStatus := Telos ffiHealth
    "FFI Status: " .. ffiStatus println
,
    "ffiHealth method not found" println
)
"" println

"=== Cognitive Cycle Test Complete ===" println