#!/usr/bin/env io
/*
 * Minimal debug test to check Telos initialization
 */

writeln("Testing Telos initialization...")

// Check if Telos exists
writeln("Telos type: " .. Telos type)

// Try to initialize explicitly
writeln("Calling Telos init...")
try(
    Telos init
    writeln("Init completed successfully")
) catch(Exception,
    writeln("Init failed: " .. Exception description)
)

// Check if slots are available after init
writeln("Checking slots after init:")
if(Telos hasSlot("walPath"),
    writeln("  walPath: " .. Telos walPath)
,
    writeln("  walPath: NOT FOUND")
)

if(Telos hasSlot("morphs"),
    writeln("  morphs: " .. Telos morphs type .. " (size: " .. Telos morphs size .. ")")
,
    writeln("  morphs: NOT FOUND")
)

if(Telos hasSlot("world"),
    if(Telos world == nil,
        writeln("  world: nil")
    ,
        writeln("  world: " .. Telos world type)
    )
,
    writeln("  world: NOT FOUND")
)

writeln("Debug test complete.")