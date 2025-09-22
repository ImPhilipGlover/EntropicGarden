#!/usr/bin/env io

// Simple test to explore available Telos methods

writeln("Test starting: Exploring Telos available methods")

try(
    writeln("Attempting: Telos slotNames")
    slotNames := Telos slotNames
    writeln("Available Telos slots: ", slotNames)
    
    writeln("Attempting: Check for ui slot")
    if(Telos hasSlot("ui"),
        writeln("Telos has ui slot")
        writeln("ui slot names: ", Telos ui slotNames)
    ,
        writeln("Telos does not have ui slot")
    )
    
    writeln("Attempting: Check for heartbeat methods")
    slotNames foreach(slotName,
        if(slotName containsSeq("heartbeat") or slotName containsSeq("beat"),
            writeln("Found heartbeat-related slot: ", slotName)
        )
    )
    
    writeln("Test complete: Method exploration complete")
    
) catch(
    writeln("Test complete: Exception caught during exploration")
)

writeln("Test finished: Exploration complete")