writeln("TelOS regression smokes: start")

ioPath := "/mnt/c/EntropicGarden/build/_build/binaries/io"
root := "/mnt/c/EntropicGarden"

run := method(relPath,
    full := root .. "/" .. relPath
    writeln("-- running ", relPath)
    try(
        System system(ioPath .. " " .. full)
    )
)

// Core smoke
run("samples/telos/smoke.io")

// Morphic canvas & WAL
run("samples/telos/morphic_canvas_smoke.io")
run("samples/telos/morphic_persistence_smoke.io")
run("samples/telos/morphic_wal_replay_smoke.io")
run("samples/telos/wal_recovery_demo.io")
run("samples/telos/morphic_interaction_regression.io")

// Curation
run("samples/telos/curation_flush.io")
run("samples/telos/curation_flush_filtered.io")

// RAG skeleton
run("samples/telos/rag_skeleton_demo.io")
run("samples/telos/rag_on_canvas_demo.io")

// Ollama LLM bridge (requires Ollama server)
run("samples/telos/persona_chat_console_demo.io")

writeln("TelOS regression smokes: end")
