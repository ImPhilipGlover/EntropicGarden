#!/usr/bin/env io

// Morph Property Debug Test - Isolate Each Property Method
writeln("Test starting: Morph property method isolation")

try(
    // Basic setup without world/window to isolate issue
    writeln("Attempting: RectangleMorph clone")
    rect := RectangleMorph clone
    writeln("Completed: RectangleMorph clone returned")
    
    // Test basic property access (should work)
    writeln("Attempting: Property read - rect x")
    xValue := rect x
    writeln("Completed: rect x = ", xValue)
    
    writeln("Attempting: Property read - rect color")
    colorValue := rect color
    writeln("Completed: rect color = ", colorValue)
    
    // Test direct property assignment (should work)
    writeln("Attempting: Direct assignment - rect x := 200")
    rect x := 200
    writeln("Completed: Direct assignment returned")
    
    // Now test the problematic methods one by one
    writeln("Attempting: setColor method call")
    rect setColor(255, 0, 0)
    writeln("Completed: setColor returned")
    
) catch(Exception, e,
    writeln("Test complete: Exception caught - ", e description)
)

writeln("Test finished: Property method isolation complete")
0