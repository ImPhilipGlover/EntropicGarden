// BABS Query: Search ingested BAT OS contexts and synthesize a concept summary
// Usage (WSL): ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/babs_query_batos.io "query text"

q := System args atIfAbsent(0, "watercourse autopoiesis invariants")
writeln("[BABS] Query: ", q)

Telos createWorld

hits := Telos memory search(q, 10)
writeln("[BABS] Top hits (text trimmed):")
i := 0
while(i < hits size,
    m := hits at(i)
    txt := m at("text")
    sc := m at("score")
    preview := if(txt size > 160, txt exSlice(0, 160) .. "...", txt)
    writeln("  ", i+1, ") score=", sc asString, " :: ", preview)
    i = i + 1
)

// Build a quick ConceptFractal from the top 3 hits
cf := ConceptFractal clone init
j := 0
while(j < hits size and j < 3,
    cf bind(ContextFractal with(hits at(j) at("text")))
    j = j + 1
)
sum := cf summarize
writeln("[BABS] Concept summary: ", sum)
