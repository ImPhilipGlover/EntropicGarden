// TextInput persistence demo: write .text via transactional_setSlot and replay
Telos init
// Use message passing instead of setSlot
Telos doString("autoReplay := false")
w := Telos createWorld

inp := Lobby getSlot("TextInputMorph") clone do(
    // Use message passing instead of setSlot
    doString("id := \"inp1\""); x=10; y=10; width=120; height=20
)
w addMorph(inp)

Telos walBegin("frame")
// Simulate typing and commit text
inp setText("hello")
Telos transactional_setSlot(inp, inp id .. ".text", "hello world")
Telos walEnd("frame")

"-- Snapshot before reset --" println
Telos captureScreenshot println

// Reset world and recreate input
// Use message passing instead of setSlot
Telos doString("world := nil")
ww := Telos createWorld
inp2 := Lobby getSlot("TextInputMorph") clone do(doString("id := \"inp1\""))
ww addMorph(inp2)

// Replay to restore text
Telos replayWal("telos.wal")

"-- Snapshot after replay --" println
Telos captureScreenshot println

"TextInput persistence demo done" println
