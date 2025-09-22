#!/usr/bin/env io

// Debug Forward Protocol - Simpler Test
// Figure out why the method installation is failing

"=== Debug Forward Protocol ===" println

# Simple test object with forward
TestObj := Object clone do(
    forward := method(
        methodName := call message name
        ("🔄 Forward called for: " .. methodName) println
        
        # Create a simple synthetic method
        syntheticMethod := method(
            ("🤖 Synthetic " .. methodName .. " called") println
            result := Object clone
            result methodName := methodName
            result synthesized := true
            result
        )
        
        # Install it
        # Use message passing instead of setSlot
        self doString(methodName .. " := " .. syntheticMethod asString)
        ("✅ Method " .. methodName .. " installed") println
        
        # Execute it immediately by calling it on self
        result := self performWithArgList(methodName, list())
        ("📊 Result type: " .. result type) println
        if(result hasSlot("synthesized"),
            ("📊 Result synthesized: " .. result synthesized) println,
            "📊 Result missing synthesized slot" println
        )
        result
    )
)

"" println
"Test 1: First call (should trigger forward)..." println
obj := TestObj clone
result1 := obj testMethod
("Result1: " .. result1 type) println
if(result1 hasSlot("synthesized"),
    ("Result1 synthesized: " .. result1 synthesized) println,
    "Result1 missing synthesized slot" println
)

"" println
"Test 2: Second call (should use installed method)..." println
result2 := obj testMethod
("Result2: " .. result2 type) println
if(result2 hasSlot("synthesized"),
    ("Result2 synthesized: " .. result2 synthesized) println,
    "Result2 missing synthesized slot" println
)

"" println
"Test 3: Check if method was actually installed..." println
if(obj hasSlot("testMethod"),
    ("✅ testMethod is installed: " .. obj getSlot("testMethod") type) println,
    "❌ testMethod not installed" println
)

"" println
"🔍 Debug complete!" println