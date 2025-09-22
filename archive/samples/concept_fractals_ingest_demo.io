// concept_fractals_ingest_demo.io
// Vertical slice: UI heartbeat + fractal extraction + memory index + WAL/logs
// Run (WSL): /mnt/c/EntropicGarden/build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/concept_fractals_ingest_demo.io

writeln("Concept Fractals Ingest Demo: start")

// UI Heartbeat
Telos createWorld
Telos mainLoop

// Choose a small BAT OS Development file to ingest (adjust if missing)
root := "/mnt/c/EntropicGarden/TelOS-Python-Archive/BAT OS Development"
candidate := root .. "/10.txt"

f := File with(candidate)
if(f exists not,
    writeln("[Demo] Candidate not found: ", candidate)
    writeln("[Demo] Please adjust the path to an existing small text file under BAT OS Development.")
,
    text := f contents
    // Extract concept fractal (contexts + concept summary)
    rc := Telos fractals extractConcept(text, 900, 5)
    writeln("[Demo] extractConcept rc: ", rc)
    
    // Query memory to verify contexts indexed
    q := "autopoiesis" // common theme; adjust as needed
    hits := Telos memory search(q, 3)
    writeln("[Demo] memory hits for '", q, "':")
    hits foreach(h,
        tx := h at("text") asString
        preview := tx exSlice(0, (tx size min(80)))
        writeln("- ", h at("score"), " :: ", preview)
    )
)

writeln("Concept Fractals Ingest Demo: end")
