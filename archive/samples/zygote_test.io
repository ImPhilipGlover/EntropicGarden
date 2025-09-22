// samples/telos/zygote_test.io

System writeln("--- TelOS Zygote Test: Vertical Slice ---")

// Pillar 3: The First Glance
// Simulate opening the UI window.
Telos openWindow

// Pillar 1: The Synaptic Bridge
// Reach into the Python muscle and get a piece of information.
pythonVersion := Telos getPythonVersion

// Pillar 2: The First Heartbeat
// Persist this information to the living image's log.
Telos transactional_setSlot(Lobby, "pythonVersion", pythonVersion)

System writeln("--- Zygote Test Complete. Check telos.wal for result. ---")
