// Working Morphic Chat Interface with SDL2 and Ollama
// Following proper Io syntax from guides

// Create world first
world := Telos createWorld
Telos openWindow

// Chat Interface Morph - simplified to avoid recursion
ChatInterface := Morph clone do(
    bounds := Object clone do(
        x := 50
        y := 50
        width := 600
        height := 400
    )
    
    color := Object clone do(
        r := 0.9  // Light gray background
        g := 0.9
        b := 0.9
        a := 1.0
    )
    
    id := "chat-interface"
    type := "ChatInterface"
    messageHistory := List clone
)

// Add message method
ChatInterface addMessage := method(sender, text,
    message := Object clone
    message sender := sender
    message text := text
    message timestamp := Date now asNumber
    self messageHistory append(message)
    
    // Display in console for now
    ("[" .. sender .. "] " .. text) println
    self
)

// Process query with Ollama
ChatInterface processQuery := method(userInput,
    self addMessage("User", userInput)
    
    // For testing: simulate a response instead of calling Ollama
    response := "This is a simulated response to: " .. userInput
    self addMessage("AI Assistant", response)
    
    self
)

// Input field morph - simplified
InputField := Morph clone do(
    bounds := Object clone do(
        x := 60
        y := 380
        width := 400
        height := 30
    )
    
    color := Object clone do(
        r := 1.0  // White background
        g := 1.0
        b := 1.0
        a := 1.0
    )
    
    id := "input-field"
    type := "InputField"
    text := ""
    placeholder := "Ask about consciousness, AI, or neural networks..."
)

InputField setText := method(newText,
    self text := newText
    self
)

// Send button morph - simplified
SendButton := Morph clone do(
    bounds := Object clone do(
        x := 470
        y := 380
        width := 80
        height := 30
    )
    
    color := Object clone do(
        r := 0.7  // Light blue-gray
        g := 0.7
        b := 0.9
        a := 1.0
    )
    
    id := "send-button"
    type := "SendButton"
    label := "Send"
)

SendButton onClick := method(
    userInput := InputField text
    if(userInput size > 0,
        ChatInterface processQuery(userInput)
        InputField setText("")
    )
    self
)

// Demo buttons for quick queries
DemoButton1 := Morph clone do(
    bounds := Object clone do(
        x := 670
        y := 100
        width := 120
        height := 40
    )
    
    color := Object clone do(
        r := 0.8  // Light green
        g := 0.9
        b := 0.8
        a := 1.0
    )
    
    id := "demo-button-1"
    type := "DemoButton"
    label := "Consciousness"
)

DemoButton1 onClick := method(
    InputField setText("What is the nature of consciousness?")
    SendButton onClick
    self
)

DemoButton2 := Morph clone do(
    bounds := Object clone do(
        x := 670
        y := 160
        width := 120
        height := 40
    )
    
    color := Object clone do(
        r := 0.8  // Light blue
        g := 0.8
        b := 0.9
        a := 1.0
    )
    
    id := "demo-button-2"
    type := "DemoButton"
    label := "Neural Networks"
)

DemoButton2 onClick := method(
    InputField setText("How do artificial neural networks learn?")
    SendButton onClick
    self
)

// Add morphs to world directly (like working rectangles demo)
world := Telos world
if(world submorphs == nil,
    world submorphs := List clone
)

world submorphs append(ChatInterface)
world submorphs append(InputField)
world submorphs append(SendButton)
world submorphs append(DemoButton1)
world submorphs append(DemoButton2)

writeln("Added 5 morphs to world submorphs")
writeln("World now has " .. world submorphs size .. " submorphs")

// Display interface info
"=== Morphic Chat Interface Ready ===" println
"Chat Interface: " print; ChatInterface println
"Input Field: " print; InputField println 
"Send Button: " print; SendButton println

// Test the interface
"Testing chat interface..." println
DemoButton1 onClick
System sleep(2)

DemoButton2 onClick
System sleep(2)

// Custom query test
InputField setText("Explain the relationship between consciousness and AI")
SendButton onClick
System sleep(2)

// Draw the world and display
writeln("Drawing world with chat interface...")
Telos drawWorld

// Draw text labels immediately after drawWorld
writeln("Drawing text labels...")

// Draw Send button label
Telos Telos_rawDrawText("Send", 485, 390, 0.0, 0.0, 0.0, 1.0)

// Draw demo button labels  
Telos Telos_rawDrawText("Consciousness", 680, 115, 0.0, 0.0, 0.0, 1.0)
Telos Telos_rawDrawText("Neural Networks", 675, 175, 0.0, 0.0, 0.0, 1.0)

// Draw input field placeholder
Telos Telos_rawDrawText("Ask about consciousness...", 65, 390, 0.5, 0.5, 0.5, 1.0)

// Draw chat title
Telos Telos_rawDrawText("TelOS Chat Interface", 55, 60, 0.0, 0.0, 0.0, 1.0)

// Draw some sample chat messages
Telos Telos_rawDrawText("[User] What is consciousness?", 60, 90, 0.0, 0.0, 0.6, 1.0)
Telos Telos_rawDrawText("[AI] Consciousness is the subjective", 60, 110, 0.6, 0.0, 0.0, 1.0)
Telos Telos_rawDrawText("experience of being aware...", 60, 130, 0.6, 0.0, 0.0, 1.0)

// Present the frame with text overlays
writeln("Presenting frame with morphs and text...")
Telos presentFrame

// Display for 10 seconds using sleep instead of displayFor
writeln("Displaying chat interface for 10 seconds...")
System sleep(10)

writeln("Demo completed!")