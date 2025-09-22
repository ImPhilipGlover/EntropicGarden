// Vertical Slice: Grow VSA memory via Ollama-backed LLM call and persist, with UI heartbeat
// 1) Initialize and open world
Telos init
Telos createWorld

// 2) Grow memory from a topic prompt (uses Ollama when configured, offline stub otherwise)
count := Telos commands run("rag.grow", list("List 8 core ideas about Morphic canvases for prototypal UI.", "BABS", 8))
writeln("rag.grow count: ", count)

// 3) Query memory to see retrieval live
hits := Telos rag query("morphic prototypal UI", 3)
writeln("Top hits:\n", hits)

// 4) Persist: save memory index and a UI snapshot; WAL framing already done in grow
_ := Telos memory save(nil)
_ := Telos saveSnapshot("logs/ui_snapshot.txt")
_ := Telos saveSnapshotJson("logs/ui_snapshot.json")

// 5) UI heartbeat
Telos ui heartbeat(1)
