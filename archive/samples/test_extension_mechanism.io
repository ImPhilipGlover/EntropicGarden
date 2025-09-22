// Test to isolate the module extension mechanism issue

writeln("=== Testing Module Extension Mechanism ===")

// First, test if direct Telos do() extension works
writeln("1. Testing direct Telos extension...")
Telos do(
    testMethod := method(
        writeln("testMethod called successfully")
        return "direct_extension_works"
    )
)

hasTestMethod := Telos hasSlot("testMethod")
writeln("Has testMethod after direct extension: " .. hasTestMethod)

if(hasTestMethod,
    result := Telos testMethod
    writeln("testMethod result: " .. result)
)

writeln()

// Second, test if doFile can extend Telos
writeln("2. Testing doFile-based extension...")

// Create a minimal test module file
testModuleContent := "// Test module
writeln(\"Test module executing...\")

Telos do(
    fileBasedMethod := method(
        writeln(\"fileBasedMethod called successfully\")
        return \"file_extension_works\"
    )
)

writeln(\"Test module extension complete\")
"

// Write test module to file
testFile := File with("test_module.io")
testFile openForUpdating
testFile remove
testFile openForUpdating
testFile write(testModuleContent)
testFile close

// Load it via doFile
writeln("Loading test_module.io via doFile...")
doFile("test_module.io")

// Check if the extension worked
hasFileMethod := Telos hasSlot("fileBasedMethod")
writeln("Has fileBasedMethod after doFile: " .. hasFileMethod)

if(hasFileMethod,
    result := Telos fileBasedMethod
    writeln("fileBasedMethod result: " .. result)
)

// Clean up
File with("test_module.io") remove

writeln()
writeln("=== Extension Mechanism Test Complete ===")