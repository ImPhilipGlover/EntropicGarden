// Demo: curation flush with persona consistency score gating
// 1) Initialize and enqueue a few offline LLM calls under different personas
// 2) Flush the curation queue with a minimum score threshold and show summary

Telos init
// Generate a couple of stubbed completions (identical content but different persona contexts)
Telos llmCall(map(persona: "BRICK", prompt: "Design invariants for morphic UI"))
Telos llmCall(map(persona: "ROBIN", prompt: "Draw one rectangle and one text"))
Telos llmCall(map(persona: "BABS",  prompt: "Summarize WAL replay guarantees"))

writeln("\n-- Performing filtered flush (minScore=0.2) --")
opts := Map clone
opts atPut("dedupe", true)
opts atPut("minScore", 0.2)
res := Telos curator flushToCandidates(100, opts)
writeln("Flush result: ", res)

// Show last summary line
sumPath := "logs/curation_summary.log"
if((File with(sumPath)) exists,
	content := (File with(sumPath)) contents
	if(content,
		lines := content split("\n")
		if(lines size > 1, writeln("Summary: ", lines at(lines size - 2)))
	)
)
