// Simple test to debug Map event creation
Telos do(
    init
)

writeln("Testing Map creation...")

// Create a test map manually in Io (this should work)
testMap := Map clone do(
    atPut("type", "test")
    atPut("x", 100)
    atPut("y", 200)
)

writeln("Manual Map creation successful:")
writeln("  type: " .. testMap at("type"))
writeln("  x: " .. testMap at("x"))
writeln("  y: " .. testMap at("y"))

// Test dispatchEvent with manual map
writeln("Testing dispatchEvent with manual map...")
try(
    Telos dispatchEvent(testMap)
    writeln("Manual dispatchEvent successful")
) catch(Exception, e,
    writeln("Manual dispatchEvent failed: " .. e message)
)

writeln("Debug test complete")