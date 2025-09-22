// BABS Refine Concepts: Iterate LLM-NN-VSA-NN-LLM loop to refine concept summaries
// Usage (WSL): ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/babs_refine_concepts.io

logDir := "logs/babs"
contexts := logDir .. "/contexts.jsonl"
refined := logDir .. "/concepts_refined.jsonl"
Directory with(logDir) create

// Tail last N contexts from JSONL and build a concept, then LLM refine its summary
N := 50
lines := Telos logs tail(contexts, N)
if(lines size == 0, writeln("[BABS] No contexts to refine"); return)

cf := ConceptFractal clone init
idx := 0
while(idx < lines size,
    line := lines at(idx)
    // naive extract of text field
    t := line afterSeq("\"text\":")
    if(t != nil and t != line,
        // crude slice until next quote end; avoid heavy parsing
        s := t
        // remove leading space and optional quote
        s = s asString strip
        if(s beginsWithSeq("\""), s = s exSlice(1))
        // cut at last quote before a comma
        cut := s split("\"")
        chunk := cut atIfAbsent(0, s)
        cf bind(ContextFractal with(chunk))
    )
    idx = idx + 1
)

// Vector refine (stub VSA): mix in nearest neighbors
cf refineWithVSA("cohere TelOS vision morphic prototypal purity")

// LLM summarize
sum := cf summarize

// Score with ALFRED weights
al := Telos personaCodex get("ALFRED")
score := al evaluate(Map clone)

rec := Map clone
rec atPut("t", Date clone now asNumber)
rec atPut("count", lines size)
rec atPut("summary", sum)
rec atPut("score", score)
Telos logs append(refined, Telos json stringify(rec))
writeln("[BABS] Refined concept saved: ", refined)
