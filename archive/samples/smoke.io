writeln("TelOS smoke: starting")

// Check if Telos methods are available
telosObj := Protos Telos
writeln("Telos object available: " .. (telosObj != nil))

// Check what slots Telos has
writeln("Telos slots: " .. telosObj slotNames join(", "))

// FFI: Python version
if(telosObj hasSlot("pyEval"),
    pyv := telosObj pyEval("import sys; sys.version.split()[0]")
    writeln("Python version: ", pyv)
,
    writeln("pyEval method not available")
)

// Persistence: WAL write
if(telosObj hasSlot("walAppend"),
    telosObj walAppend("SET zygote TO alive")
    writeln("WAL append successful")
,
    writeln("walAppend method not available")
)

// UI: Create world and short main loop
if(telosObj hasSlot("createWorld"),
    telosObj createWorld
    writeln("World created")
,
    writeln("createWorld method not available")
)

if(telosObj hasSlot("mainLoop"),
    telosObj mainLoop
    writeln("Main loop completed")
,
    writeln("mainLoop method not available")
)

writeln("TelOS smoke: done")
