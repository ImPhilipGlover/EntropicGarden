writeln("--- TelOS Research Loop Demo (BABS) ---")

Telos openWindow
Telos createWorld

babs := Telos personaCodex choose("BABS")
babs loadPersonaContext

// Build a weak concept lacking a summary
cf1 := ContextFractal with("Forward/doesNotUnderstand handling")
weakConcept := ConceptFractal clone bind(cf1)
weakConcept meta atPut("gap", true)

// BABS finds gaps
candidates := babs identifyConceptGaps(list(weakConcept))
writeln("Gaps identified: ", candidates size)

// BABS drafts WING prompts (to be run by human research tool)
prompts := babs suggestWingPrompts(candidates)
writeln("Wing prompts (sample): ", prompts slice(0, 2))

// Simulate a human-produced research report
report := "Report: Strategies for forwarding and doesNotUnderstand; include proxy patterns, methodMissing, and capability checks."

// Ingest report and refine concept
babs ingestResearchReport(weakConcept, report)
writeln("Concept summary (after ingest): ", weakConcept summary)

// Persist a note and draw
babs commit(Telos, "lastResearchTopic", "forward/doesNotUnderstand")
m := TextMorph clone
m setText("BABS Research loop complete")
Telos addSubmorph(Telos world, m)
Telos draw

writeln("--- Demo complete ---")
