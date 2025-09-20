// samples/telos/cognitive_stub_demo.io
// Demonstrates offline stubs for Memory, LLM, Tools, and Metric

writeln("--- TelOS Cognitive Stub Demo ---")

// Ensure Telos is present (autoload should have loaded IoTelos.io)
writeln("Telos proto type: ", Protos Telos type)

// VSA-RAG memory stubs
Protos Telos memory addContext("The seed is an idea; the organism is a system.")
results := Protos Telos memory search("organism idea", 3)
writeln("memory search results: ", results)

// Non-local LLM stub
resp := Protos Telos llmCall(map(prompt: "Say hello", provider: "offline"))
writeln("llm stub response: ", resp)

// Tool use stub
toolResp := Protos Telos toolUse(map(name: "ping", args: list("127.0.0.1")))
writeln("tool stub response: ", toolResp)

// Composite metric stub
score := Protos Telos scoreSolution(map(alpha: 2, beta: 1, gamma: 1, delta: 1))
writeln("metric: ", score)

writeln("--- Demo Complete ---")
