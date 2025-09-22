#!/usr/bin/env io

// Test TelosMorphic and TelosLogging in complete isolation
// This should help identify if there are syntax errors or infinite loops

writeln("=== Testing Isolated Module Loading ===")

// First test TelosMorphic alone
writeln("Test 1: Loading TelosMorphic in isolation...")
try(
    writeln("About to doFile TelosMorphic...")
    doFile("libs/Telos/io/TelosMorphic.io")
    writeln("TelosMorphic doFile completed")
    
    if(TelosMorphic != nil,
        writeln("TelosMorphic object found")
        if(TelosMorphic hasSlot("load"),
            writeln("TelosMorphic has load method, calling it...")
            TelosMorphic load
            writeln("TelosMorphic load completed")
        ,
            writeln("TelosMorphic missing load method")
        )
    ,
        writeln("TelosMorphic object not found after loading")
    )
    writeln("TelosMorphic test completed successfully")
,
    writeln("EXCEPTION in TelosMorphic test: " .. exception description)
)

writeln("")

// Second test TelosLogging alone  
writeln("Test 2: Loading TelosLogging in isolation...")
try(
    writeln("About to doFile TelosLogging...")
    doFile("libs/Telos/io/TelosLogging.io")
    writeln("TelosLogging doFile completed")
    
    if(TelosLogging != nil,
        writeln("TelosLogging object found")
        if(TelosLogging hasSlot("load"),
            writeln("TelosLogging has load method, calling it...")
            TelosLogging load
            writeln("TelosLogging load completed")
        ,
            writeln("TelosLogging missing load method")
        )
    ,
        writeln("TelosLogging object not found after loading")
    )
    writeln("TelosLogging test completed successfully")
,
    writeln("EXCEPTION in TelosLogging test: " .. exception description)
)

writeln("=== Isolated module testing complete ===")