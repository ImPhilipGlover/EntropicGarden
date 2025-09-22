// Simple Forward Protocol Test
// Quick validation of the doesNotUnderstand implementation

writeln("🧬 FORWARD PROTOCOL TEST")
writeln("")

// Test forward on Object prototype  
testObj := Object clone
testObj id := "TestObject"

writeln("Testing unknown message 'testMethod' on Object...")
result := testObj testMethod
writeln("Result: ", result)

// Test if method was installed
if(testObj hasSlot("testMethod"),
    writeln("✅ Method was synthesized and installed")
,
    writeln("❌ Method synthesis failed")
)

writeln("")
writeln("Forward protocol test complete")

"Test completed"