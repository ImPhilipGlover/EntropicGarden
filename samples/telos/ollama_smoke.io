// Ollama smoke test: run a minimal prompt through Telos -> Ollama
// Pre-req: Ollama running on localhost:11434 and model pulled, e.g. `ollama pull llama3.1:8b`

Telos init
Telos llmProvider atPut("name", "ollama")
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")

// Pick a persona; mapping in Telos.personaModels controls default model
p := Telos personaCodex get("BRICK")
p loadPersonaContext

writeln("[SMOKE] Provider=", Telos llmProvider at("name"),
        " model=", Telos personaModels at("BRICK"))

reply := p converse("In one sentence, explain the watercourse way.")
writeln("[OLLAMA REPLY] ", reply)
