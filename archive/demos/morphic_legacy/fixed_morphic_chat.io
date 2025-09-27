// Fixed Morphic Chat Interface following proper Io syntax
// Based on Io Programming Guide principles

"Initializing TelOS Chat Interface..." println

// Create world first
world := Telos createWorld
Telos openWindow

// Chat Interface prototype
ChatInterface := Object clone do(
    messageHistory := list()
    
    addMessage := method(messageSender, messageText,
        message := Object clone
        message sender := messageSender
        message text := messageText
        message timestamp := Date now asNumber
        
        messageHistory append(message)
        
        // Display in console 
        ("[" .. messageSender .. "] " .. messageText) println
        self
    )
    
    processQuery := method(userInput,
        self addMessage("User", userInput)
        
        // Send to Ollama using working TelosOllama integration with gemma3:4b
        response := TelosOllama sendToOllama("gemma3:4b", userInput)
        
        if(response hasSlot("success") and response success,
            self addMessage("AI", response response)
        ,
            errorMsg := if(response hasSlot("error"), response error, "Unknown error")
            self addMessage("System", "Unable to reach Ollama service: " .. errorMsg)
        )
        
        self
    )
)

// Input Field prototype  
InputField := Object clone do(
    text := ""
    placeholder := "Ask about consciousness, AI, or neural networks..."
    
    setText := method(newText,
        text = newText
        self
    )
    
    getText := method(
        text
    )
)

// Send Button prototype
SendButton := Object clone do(
    label := "Send"
    
    onClick := method(
        userInput := InputField getText
        if(userInput size > 0,
            ChatInterface processQuery(userInput)
            InputField setText("")
        )
        self
    )
)

// Demo buttons for quick queries
DemoButton1 := Object clone do(
    label := "Consciousness"
    
    onClick := method(
        InputField setText("What is the nature of consciousness?")
        SendButton onClick
        self
    )
)

DemoButton2 := Object clone do(
    label := "Neural Networks"
    
    onClick := method(
        InputField setText("How do artificial neural networks learn?")
        SendButton onClick
        self
    )
)

// Display interface info
"=== Morphic Chat Interface Ready ===" println
"Components created:" println
"- ChatInterface: " print; ChatInterface type println  
"- InputField: " print; InputField type println
"- SendButton: " print; SendButton type println

// Test the interface
"Testing chat interface..." println

// Test 1: Consciousness query
"Testing consciousness query..." println
DemoButton1 onClick
System sleep(2)

// Test 2: Neural networks query  
"Testing neural networks query..." println
DemoButton2 onClick
System sleep(2)

// Test 3: Custom query
"Testing custom query..." println
InputField setText("Explain the relationship between consciousness and AI")
SendButton onClick
System sleep(2)

// Display final status
"Chat interface demonstration completed." println
"Message history has " print; ChatInterface messageHistory size print; " messages" println

// Keep SDL2 window open for user interaction
"SDL2 window is open. You can interact with the morphic interface using mouse and keyboard." println
"Press ESC or close the window to exit." println

// Manual event loop instead of displayFor which doesn't exist
startTime := Date now asNumber
duration := 30  // 30 seconds
shouldExit := false

while(shouldExit not and ((Date now asNumber - startTime) < duration),
    // Handle SDL2 events  
    Telos Telos_rawHandleEvent
    
    // Check if exit was requested via window close or ESC
    if(Telos hasSlot("shouldExit") and Telos shouldExit,
        shouldExit = true
        "User requested exit via window close or ESC key." println
    )
    
    // Draw the world
    Telos Telos_rawDraw
    
    // Small delay to prevent 100% CPU usage (~60 FPS)
    System sleep(0.016)
)

if(shouldExit not,
    "Display timeout reached after " print; duration print; " seconds." println
,
    "Window closed by user interaction." println
)

"Demo session ended." println