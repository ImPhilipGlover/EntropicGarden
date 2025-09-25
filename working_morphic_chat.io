// Working Morphic Chat Interface with SDL2 and Ollama
// Following proper Io syntax from guides

// Create world first
world := Telos createWorld
Telos openWindow

// Chat Interface Morph
ChatInterface := Object clone
ChatInterface x := 50
ChatInterface y := 50
ChatInterface width := 600
ChatInterface height := 400
ChatInterface messageHistory := List clone

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
    
    // Send to Ollama using TelosOllama
    response := TelosOllama sendToOllama("telos/alfred:latest", userInput)
    
    if(response hasSlot("success") and response success,
        self addMessage("Alfred", response response)
    ,
        self addMessage("System", "Unable to reach Ollama service")
    )
    
    self
)

// Input field morph
InputField := Object clone
InputField x := 60
InputField y := 380
InputField width := 400
InputField height := 30
InputField text := ""
InputField placeholder := "Ask about consciousness, AI, or neural networks..."

InputField setText := method(newText,
    self text := newText
    self
)

// Send button morph
SendButton := Object clone
SendButton x := 470
SendButton y := 380
SendButton width := 80
SendButton height := 30
SendButton label := "Send"

SendButton onClick := method(
    userInput := InputField text
    if(userInput size > 0,
        ChatInterface processQuery(userInput)
        InputField setText("")
    )
    self
)

// Demo buttons for quick queries
DemoButton1 := Object clone
DemoButton1 x := 670
DemoButton1 y := 100
DemoButton1 width := 120
DemoButton1 height := 40
DemoButton1 label := "Consciousness"

DemoButton1 onClick := method(
    InputField setText("What is the nature of consciousness?")
    SendButton onClick
    self
)

DemoButton2 := Object clone
DemoButton2 x := 670
DemoButton2 y := 160
DemoButton2 width := 120
DemoButton2 height := 40
DemoButton2 label := "Neural Networks"

DemoButton2 onClick := method(
    InputField setText("How do artificial neural networks learn?")
    SendButton onClick
    self
)

// Add morphs to world
Telos addMorph(ChatInterface)
Telos addMorph(InputField)
Telos addMorph(SendButton)
Telos addMorph(DemoButton1)
Telos addMorph(DemoButton2)

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

// Keep SDL2 window open
"SDL2 window is open. Close window or press Ctrl+C to exit." println
Telos displayFor(20)

"Demo completed." println