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

// Vertical slice (UI + FFI + Persistence)
run("samples/telos/vertical_slice_demo.io")
run("samples/telos/vertical_slice_replay.io")

// Morphic UI tests (visual window-based - our native interface)
run("samples/telos/morphic_streaming_test.io")
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

// Fractals ingest + memory smoke
run("samples/telos/concept_fractals_ingest_demo.io")

// Fractals refinement smoke
run("samples/telos/concept_fractals_refine_demo.io")

// BAT OS directory mining
run("samples/telos/fractals_mine_batos.io")

// Ollama LLM bridge (requires Ollama server)
run("samples/telos/persona_chat_console_demo.io")

// Streaming LLM bridge 
run("samples/telos/streaming_llm_demo.io")

// Python eval bridge
run("samples/telos/python_eval_demo.io")

// Generative Kernel
run("samples/telos/generative_kernel_demo.io")

writeln("TelOS regression smokes: end")
