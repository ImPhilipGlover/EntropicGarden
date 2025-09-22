// Persona chat console demo: non-interactive sample that sends a few messages
// Use the IoTelos-provided global Telos (already initialized by IoTelos.io)
cv := Canvas clone init
cv open

chat := ChatConsole clone init
chat setPersona("BRICK")

// Route LLM calls to Ollama (requires Ollama running on host)
Telos llmProvider atPut("name", "ollama")
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://127.0.0.1:11434")

msgs := list(
    "In one sentence, explain the watercourse way.",
    "In one sentence, what invariant should we preserve next?"
)
msgs foreach(m,
    // Let the window breathe before sending
    cv heartbeat(2)
    // Force model override per turn
    Telos llmProvider atPut("name", "ollama")
    Telos llmProvider atPut("useOllama", true)
    Telos llmProvider atPut("baseUrl", "http://127.0.0.1:11434")
    out := Telos llmCall(Map clone do(
        atPut("persona", "BRICK");
        atPut("model", "telos/brick:latest");
        atPut("prompt", m);
        atPut("system", (Telos personaCodex get("BRICK")) composeSystemPrompt)
    ))
    ("BRICK> " .. out) println
    // Give time to render and potentially receive streamed output in the future
    cv heartbeat(3)
)
// Keep the window visible a bit longer before closing
cv heartbeat(4)
cv close
"Persona chat console demo done" println
