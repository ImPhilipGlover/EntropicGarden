#!/usr/bin/env io

// Simple heartbeat isolation test
// Tests only the heartbeat/draw functionality

writeln("Test starting: Heartbeat functionality isolation")

try(
    writeln("Attempting: Telos createWorld")
    world := Telos createWorld
    writeln("Completed: createWorld call returned")
    
    writeln("Attempting: Telos openWindow")
    Telos openWindow
    writeln("Completed: openWindow call returned")
    
    writeln("Attempting: world heartbeat")
    world heartbeat
    writeln("Completed: world heartbeat returned")
    
    writeln("Attempting: Telos draw")
    Telos draw
    writeln("Completed: Telos draw returned")
    
    writeln("Test complete: All heartbeat calls completed without exceptions")
    
) catch(
    writeln("Test complete: Exception caught during heartbeat/draw")
)

writeln("Test finished: Heartbeat isolation complete")