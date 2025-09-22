// samples/telos/fractal_reasoning_demo.io
// Demonstrates context fractals and concept fractals binding

writeln("--- Fractal Reasoning Demo ---")

// Seed contexts
c1 := ContextFractal with("Photosynthesis converts light into chemical energy")
c2 := ContextFractal with("Entropy favors distributions; life exports entropy")
c3 := ContextFractal with("Vectors can represent concepts in high-dimensional space")

// Add contexts to memory (stub logs)
Telos memory addContext(c1 payload)
Telos memory addContext(c2 payload)
Telos memory addContext(c3 payload)

// Compose a higher-level concept fractal
cf := ConceptFractal clone
cf bind(c1) bind(c2) bind(c3)

// Summarize with LLM stub and refine via VSA-like search
sum := cf summarize
writeln("summary: ", sum)
cf refineWithVSA("energy entropy vector concepts")

// Vectorize and score via composite metric
vec := cf vectorize
writeln("vector: ", vec)
score := cf score
writeln("score: ", score)

writeln("--- Demo Complete ---")
