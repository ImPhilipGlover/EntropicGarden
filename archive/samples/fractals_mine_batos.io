// fractals_mine_batos.io
// Mines BAT OS Development directory to create concept fractals and a combined atlas.
// Run (WSL): /mnt/c/EntropicGarden/build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/fractals_mine_batos.io

writeln("Fractals Mine BAT OS: start")

Telos createWorld
Telos mainLoop

root := "/mnt/c/EntropicGarden/TelOS-Python-Archive/BAT OS Development"
maxFiles := 5

writeln("[Mine] root: ", root, " maxFiles: ", maxFiles)

// Run directory mining (capped)
count := Telos fractals mineDirectory(root, maxFiles, 900, 8)
writeln("[Mine] files processed: ", count)

// Build a small combined atlas by composing a few recent concept summaries
// (For simplicity, re-query memory for a unifying theme)
q := "robin brick autopoiesis canvas"
summHits := Telos memory search(q, 6)
summaries := List clone
summHits foreach(h,
    s := h at("text") asString
    summaries append(s)
)
combined := Telos fractals composeConcepts(summaries, 6)
writeln("[Mine] Combined concept summary (preview):")
prev := combined exSlice(0, (combined size min(240)))
writeln(prev)

writeln("Fractals Mine BAT OS: end")
