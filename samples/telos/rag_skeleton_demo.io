writeln("RAG skeleton demo: start")

// UI Heartbeat
Telos createWorld
Telos mainLoop

// Index some simple docs
corpus := list(
    "The Morphic canvas beats with a living heartbeat.",
    "Prototypal purity and antifragility guide TelOS.",
    "Direct manipulation brings clarity and liveliness.",
    "Transactional persistence uses a WAL for replay.")

writeln("has Telos_rawRagIndex: ", Telos hasSlot("Telos_rawRagIndex"))
writeln("has Telos_rawRagQuery: ", Telos hasSlot("Telos_rawRagQuery"))
rc := Telos rag index(corpus)
writeln("index rc: ", rc)

// Query the memory
q := "morphic canvas clarity"
res := Telos rag query(q, 3)
writeln("query: ", q)
writeln("results:\n", res)

writeln("RAG skeleton demo: end")
