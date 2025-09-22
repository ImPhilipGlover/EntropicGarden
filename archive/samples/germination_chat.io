// Germination Chat UI: minimal vertical slice
// - World & canvas
// - TextInputMorph for user input
// - Persona conversation (default BRICK)
// - ALFRED commentary
// - ROBIN proposal (uses textual screenshot)

Telos init
Telos createWorld

// provider: use Ollama if available (falls back to offline if not configured)
Telos llmProvider atPut("name", "ollama")
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")

world := Telos world

// Create basic UI morphs
title := TextMorph clone do(
  setText("TelOS Germination Chat")
  moveTo(20, 20)
  resizeTo(300, 20)
)

log := TextMorph clone do(
  setText("[log]\n")
  moveTo(20, 60)
  resizeTo(760, 440)
)

input := TextInputMorph clone do(
  moveTo(20, 520)
  resizeTo(760, 40)
)

world addMorph(title)
world addMorph(log)
world addMorph(input)

// Personas
brick := Telos personaCodex get("BRICK") loadPersonaContext
alfred := Telos personaCodex get("ALFRED") loadPersonaContext
robin := Telos personaCodex get("ROBIN") loadPersonaContext

appendLog := method(s,
  log setText(log text .. s .. "\n")
)

// On submit: route to BRICK, then ALFRED comment, then ROBIN UI proposal
input setOnSubmit(block(
  msg := call args at(0)
  appendLog("[you] " .. msg)
  resp := brick converse(msg)
  appendLog("[BRICK] " .. resp)
  meta := alfred commentOn(brick, resp)
  appendLog("[ALFRED] " .. meta)
  props := robin proposeUiChanges("Make the chat easier to read")
  appendLog("[ROBIN] proposal: " .. props)
))

// Kick a self-test submission
input appendInput("What is our first living slice today?")
input submit

Telos draw
// End of sample
