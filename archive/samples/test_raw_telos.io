#!/usr/bin/env io

// Test the raw C-level Telos prototype directly
("Checking raw C-level Telos prototype..." println)

// Get the raw prototype from Lobby Protos
rawTelos := Lobby Protos Telos
if(rawTelos,
    ("Raw Telos prototype found" println)
    ("Raw Telos methods:" println)
    rawTelos slotNames foreach(name, name println)
    
    // Try calling initializeFFI directly on the raw prototype
    ("Testing initializeFFI on raw prototype..." println)
    try(
        result := rawTelos initializeFFI("./python/venv")
        ("initializeFFI result: " .. result println)
    ) catch(Exception,
        ("initializeFFI failed: " .. Exception description println)
    ),
    
    ("No raw Telos prototype found" println)
)