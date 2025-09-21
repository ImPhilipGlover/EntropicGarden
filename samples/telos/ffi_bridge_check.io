#!/usr/bin/env io

// FFI Bridge Status Check
// Checks the state of the Ollama FFI bridge

"=== FFI Bridge Status Check ===" println

// Check if FFI bridge exists
"Checking FFI bridge..." println
if(Telos hasSlot("Telos_rawOllamaGenerate"),
    ("✅ Telos_rawOllamaGenerate available: " .. Telos getSlot("Telos_rawOllamaGenerate") type) println,
    "❌ Telos_rawOllamaGenerate missing!" println
)

// Check other TelOS FFI methods
"" println
"Other TelOS FFI methods:" println
if(Telos hasSlot("Telos_rawVSASearch"),
    ("✅ Telos_rawVSASearch: " .. Telos getSlot("Telos_rawVSASearch") type) println,
    "❌ Telos_rawVSASearch missing" println
)

if(Telos hasSlot("Telos_rawVSAAdd"),
    ("✅ Telos_rawVSAAdd: " .. Telos getSlot("Telos_rawVSAAdd") type) println,
    "❌ Telos_rawVSAAdd missing" println
)

// Check Python bridge
"" println
"Python bridge status:" println
try(
    result := Telos_rawPythonEval("print('Hello from Python'); 'Python OK'")
    ("✅ Python bridge working: " .. result) println
,
    "❌ Python bridge failed" println
)

// List all Telos slots to see what's available
"" println
"All Telos_ FFI methods:" println
telosSlots := Telos getSlot("proto") slotNames select(s, s beginsWithSeq("Telos_"))
if(telosSlots size > 0,
    telosSlots foreach(slot, ("  " .. slot) println),
    "  No Telos_ FFI methods found" println
)

"" println
"🔍 FFI Status check complete!" println