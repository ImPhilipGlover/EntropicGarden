writeln("TelOS smoke: starting")

// FFI: Python version
pyv := Protos Telos getPythonVersion
writeln("Python version: ", pyv)

// Persistence: WAL write
Protos Telos transactional_setSlot(Lobby, "zygote", "alive")

// UI: Create world and short main loop
Protos Telos createWorld
Protos Telos mainLoop

writeln("TelOS smoke: done")
