// RAG-on-Canvas vertical slice: UI panel shows top RAG hit with persistence
Telos do(
    init
)

world := Telos createWorld

// Build a simple panel with a text morph
panel := Lobby getSlot("RectangleMorph") clone do(
    x := 10; y := 10; width := 360; height := 140; id := "ragPanel"
)
label := Lobby getSlot("TextMorph") clone do(
    x := 20; y := 20; text := "RAG: initializing"; id := "ragText"
)
panel addMorph(label)
world addMorph(panel)

// Index a small corpus
corpus := list(
    "The Morphic canvas beats with a living heartbeat.",
    "The zygote breathes through persistence and replay.",
    "Direct manipulation brings clarity and liveliness.",
    "Transactional persistence uses a WAL for replay."
)
rc := Telos rag index(corpus)
writeln("index rc: ", rc)

// Query and update UI
q := "canvas clarity"
res := Telos rag query(q, 3)
lines := res split("\n")
first := if(lines size > 0, lines at(0), "")
parts := first split("\t")
doc := if(parts size > 2, parts at(2), first)
label setText("RAG: " .. doc)

// Persist a small note
Telos transactional_setSlot(Telos, "lastRagUiUpdate", Date clone now asString)

// Draw and snapshot
writeln("-- RAG Panel Snapshot --")
Telos draw
writeln(Telos captureScreenshot)

// Short heartbeat
Telos mainLoop
