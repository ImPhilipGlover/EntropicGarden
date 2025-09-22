// concept_fractals_refine_demo.io
// Demonstrates iterative refinement of a concept using memory + VSA helpers.
// Run (WSL): /mnt/c/EntropicGarden/build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/concept_fractals_refine_demo.io

writeln("Concept Fractals Refine Demo: start")

Telos createWorld
Telos mainLoop

// Seed: index a few thematic strings if memory is empty
seed := list(
    "TelOS embraces autopoiesis and prototypal purity.",
    "Morphic canvases encourage direct manipulation and liveliness.",
    "A write-ahead log (WAL) persists state changes for replay.",
    "Concept fractals bind contexts to form emergent structure.")
Telos memory index(seed)

// Refine around a theme
q := "autopoiesis prototypal purity morphic"
writeln("[Refine] seed query: ", q)
Telos fractals refineIterative(q, 2, 5)

// Inspect a few retrievals post-refinement
hits := Telos memory search("autopoiesis", 3)
writeln("[Refine] hits after refinement:")
hits foreach(h,
    tx := h at("text") asString
    preview := tx exSlice(0, (tx size min(80)))
    writeln("- ", h at("score"), " :: ", preview)
)

writeln("Concept Fractals Refine Demo: end")
