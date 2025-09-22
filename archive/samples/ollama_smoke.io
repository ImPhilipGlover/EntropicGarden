// Ollama smoke test: run a minimal prompt through Telos -> Ollama
// Pre-req: Ollama running on localhost:11434 and model pulled, e.g. `ollama pull llama3.1:8b`

Telos init
Telos llmProvider atPut("name", "ollama")
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://127.0.0.1:11434")

// Pick a persona; mapping in Telos.personaModels controls default model
p := Telos personaCodex get("BRICK")
p loadPersonaContext

writeln("[SMOKE] Provider=", Telos llmProvider at("name"),
        " model=telos/brick:latest")

// Force the model at call time
reply := Telos llmCall(Map clone do(
    atPut("persona", "BRICK");
    atPut("model", "telos/brick:latest");
    atPut("prompt", "In one sentence, explain the watercourse way.");
    atPut("system", p composeSystemPrompt)
))
writeln("[OLLAMA REPLY] ", reply)
