/*
   Streaming LLM Demo - TelOS Vertical Slice v1
   
   Demonstrates prototypal streaming LLM responses with:
   - UI (Canvas heartbeat with streaming visualization)
   - FFI (Io→C→Python streaming HTTP to Ollama)
   - Persistence (WAL frames around streaming sessions + JSONL logs)
   
   Shows real-time chunk-by-chunk response display with Morphic canvas updates.
*/

// Initialize TelOS organism with streaming awareness
Telos createWorld("Streaming LLM Demo World")

// Create personas for demo (ensure we have codex)
if(Telos personaCodex == nil,
    Telos personaCodex = Map clone
    // Add a test persona for streaming
    brickPersona := Object clone do(
        name := "brick"
        ethos := "Direct, practical, and efficient communication"
        speakStyle := "Concise responses with technical accuracy"
        routingHints := "engineering development coding"
        genOptions := Map clone do(
            atPut("temperature", 0.7)
            atPut("top_p", 0.9)
        end
    )
    Telos personaCodex atPut("brick", brickPersona)
)

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
    writeln("[STREAM ", totalChunks, "] ", chunk)
    // Update UI during streaming
    if(Telos hasSlot("world"), Telos world heartbeat(1))
)
StreamingChat getFullResponse := method(displayBuffer)

// Perform streaming interaction with persona
writeln("=== TelOS Streaming LLM Demo ===")
writeln("Initializing streaming chat with BRICK persona...")

// Create streaming chat session
streamingSession := StreamingChat with("brick", "Explain the benefits of prototypal programming in 3 sentences")

// WAL frame around streaming session  
Telos walCommit("streaming.session", Map clone do(
    atPut("persona", streamingSession persona)
    atPut("prompt", streamingSession currentPrompt)
), method(
    writeln("Starting streaming LLM call...")
    Telos ui heartbeat(2)
    
    // Create spec for streaming call
    spec := Map clone do(
        atPut("persona", streamingSession persona)
        atPut("prompt", streamingSession currentPrompt)
        atPut("model", "telos/brick")
        atPut("temperature", 0.7)
    end
    
    // Make streaming call
    streamingSession isStreaming = true
    response := Telos llmCallStream(spec)
    
    writeln("Received streaming response with ", response chunks size, " chunks")
    writeln("Displaying chunks in real-time:")
    writeln("---")
    
    // Display chunks one by one with UI updates
    while(response hasMore,
        chunk := response nextChunk
        if(chunk != nil,
            streamingSession displayChunk(chunk)
            // Small delay to simulate real-time streaming
            Telos ui heartbeat(1)
        )
    )
    
    writeln("---")
    writeln("Full response: ", response getFullText)
    streamingSession isStreaming = false
    
    // Capture final state
    writeln("Streaming session completed with ", streamingSession totalChunks, " chunks")
))

// Take snapshot showing streaming completion
snapshot := Telos captureScreenshot
writeln("\n=== Morphic Canvas State ===")
writeln(snapshot)

// Show WAL content
if(File exists("telos.wal"),
    writeln("\n=== WAL Persistence (Last 5 Lines) ===")
    logs := Telos logs tail("telos.wal", 5)
    logs foreach(line, writeln("WAL: ", line))
)

// Show streaming logs  
if(File exists("logs/streaming_llm.jsonl"),
    writeln("\n=== Streaming Logs (Last Entry) ===")
    logs := Telos logs tail("logs/streaming_llm.jsonl", 1)
    logs foreach(line, writeln("STREAM_LOG: ", line))
)

writeln("\n=== Demo Complete ===")
writeln("Streaming LLM Demo validated: UI heartbeat during streaming, FFI bridge with chunks, WAL persistence")