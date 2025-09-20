/*
   Streaming LLM Demo - TelOS Morphic Vertical Slice v1
   
   Demonstrates prototypal streaming LLM responses with live Morphic UI:
   - UI (Live Morphic window with streaming text visualization)
   - FFI (Io→C→Python streaming HTTP to Ollama)
   - Persistence (WAL frames around streaming sessions + JSONL logs)
   
   Shows real-time chunk-by-chunk response display as living morphs on canvas.
   This is the native way TelOS operates - through direct manipulation of live objects.
*/

// Initialize TelOS organism with Morphic window
Telos createWorld("Streaming LLM Demo")

// Create and open the Morphic window - this is our living canvas
cv := Telos openWindow(800, 600, "TelOS Streaming LLM Demo")
writeln("Morphic window opened - streaming demo will appear visually")

// Create personas for demo (ensure we have codex)
if(Telos personaCodex == nil,
    Telos personaCodex = Map clone
    // Add a test persona for streaming
    brickPersona := Object clone
    brickPersona name := "brick"
    brickPersona ethos := "Direct, practical, and efficient communication"
    brickPersona speakStyle := "Concise responses with technical accuracy"
    brickPersona routingHints := "engineering development coding"
    brickPersona genOptions := Map clone
    brickPersona genOptions atPut("temperature", 0.7)
    brickPersona genOptions atPut("top_p", 0.9)
    Telos personaCodex atPut("brick", brickPersona)
)

// Create visual morphs for streaming display
titleMorph := Telos createMorph("TextMorph")
titleMorph text := "TelOS Streaming LLM Demo"
titleMorph position := list(50, 50)
titleMorph size := list(700, 40)
titleMorph color := "blue"

statusMorph := Telos createMorph("TextMorph") 
statusMorph text := "Initializing streaming with BRICK persona..."
statusMorph position := list(50, 100)
statusMorph size := list(700, 30)
statusMorph color := "green"

// Create scrollable text area for streaming response
responseMorph := Telos createMorph("TextMorph")
responseMorph text := "[Streaming response will appear here...]"
responseMorph position := list(50, 150)
responseMorph size := list(700, 400) 
responseMorph color := "black"

// Streaming Chat Helper - prototypal pattern for managing streaming state
StreamingChat := Object clone
StreamingChat with := method(persona, initialPrompt,
    chat := self clone
    chat persona := persona
    chat currentPrompt := initialPrompt
    chat displayBuffer := ""
    chat isStreaming := false
    chat totalChunks := 0
    chat
) 
StreamingChat displayChunk := method(chunk,
    displayBuffer = displayBuffer .. chunk
    totalChunks = totalChunks + 1
    // Update the visual morph with streaming content
    responseMorph text := displayBuffer
    statusMorph text := "Streaming... chunk " .. totalChunks .. " received"
    // Refresh the Morphic canvas to show updates
    cv heartbeat(1)
    writeln("[STREAM ", totalChunks, "] ", chunk)
)
StreamingChat getFullResponse := method(displayBuffer)

// Display initial UI state
cv heartbeat(3)

// Create streaming chat session
streamingSession := StreamingChat with("brick", "Explain the benefits of prototypal programming in 3 sentences")
statusMorph text := "Created streaming session with BRICK persona"
cv heartbeat(2)

// WAL frame around streaming session  
sessionMeta := Map clone
sessionMeta atPut("persona", streamingSession persona)
sessionMeta atPut("prompt", streamingSession currentPrompt)
Telos walCommit("streaming.session", sessionMeta, method(
    statusMorph text := "Starting streaming LLM call..."
    cv heartbeat(2)
    
    // Create spec for streaming call
    spec := Map clone
    spec atPut("persona", streamingSession persona)
    spec atPut("prompt", streamingSession currentPrompt)
    spec atPut("model", "telos/brick")
    spec atPut("temperature", 0.7)
    
    // Make streaming call
    streamingSession isStreaming = true
    response := Telos llmCallStream(spec)
    
    statusMorph text := "Received streaming response with " .. response chunks size .. " chunks"
    responseMorph text := "=== Streaming Response ===\n"
    cv heartbeat(2)
    
    // Display chunks one by one with live visual updates
    while(response hasMore,
        chunk := response nextChunk
        if(chunk != nil,
            streamingSession displayChunk(chunk)
            // Visual streaming update with heartbeat
            cv heartbeat(1)
        )
    )
    
    streamingSession isStreaming = false
    statusMorph text := "Streaming completed with " .. streamingSession totalChunks .. " chunks"
    
    // Show final state in UI
    responseMorph text := responseMorph text .. "\n\n=== Stream Complete ==="
    cv heartbeat(3)
))

// Display completion status in the UI
statusMorph text := "Demo Complete - View logs below"
cv heartbeat(2)

// Create visual log display area
logMorph := Telos createMorph("TextMorph")
logMorph text := "=== Logs and Persistence ==="
logMorph position := list(50, 570)
logMorph size := list(700, 100)
logMorph color := "gray"

// Show logs in the visual interface
logText := "=== WAL Persistence ===\n"
if(File exists("telos.wal"),
    logs := Telos logs tail("telos.wal", 3)
    logs foreach(line, logText = logText .. "WAL: " .. line .. "\n")
)

if(File exists("logs/streaming_llm.jsonl"),
    logText = logText .. "\n=== Streaming Logs ===\n"
    logs := Telos logs tail("logs/streaming_llm.jsonl", 1) 
    logs foreach(line, logText = logText .. "STREAM: " .. line .. "\n")
)

logMorph text := logText
cv heartbeat(3)

// Keep window open for observation - this is the living Morphic interface
writeln("Morphic window showing streaming demo - press any key in terminal to close")
System stdin readLine

// Take final snapshot showing complete UI state
snapshot := Telos captureScreenshot
writeln("\n=== Final Morphic Canvas State ===")
writeln(snapshot)

writeln("Streaming LLM Demo completed: Live Morphic UI, FFI streaming bridge, WAL persistence")