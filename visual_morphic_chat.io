#!/usr/bin/env io

// Visual Morphic Chat Interface with Real Components
// Creates actual text fields, buttons, and message display areas

"Creating Visual Morphic Chat Interface..." println

// Load TelOS core
doFile("libs/Telos/io/TelosCore.io")

// Create world and open window
world := Telos createWorld
Telos openWindow

// Visual Chat Interface
VisualChatInterface := Object clone do(
    world := nil
    inputField := nil
    messageDisplay := nil
    sendButton := nil
    messageHistory := list()
    
    initialize := method(worldObj,
        self world := worldObj
        self createVisualComponents
        self
    )
    
    createVisualComponents := method(
        "Creating visual chat components..." println
        
        // Create input field (rectangle at bottom)
        self inputField := RectangleMorph clone
        self inputField width := 500
        self inputField height := 40
        self inputField x := 70
        self inputField y := 400
        self inputField color := list(0.9, 0.9, 0.9, 1.0)  // Light gray
        self inputField id := "chat_input"
        
        // Create input field label
        inputLabel := TextMorph clone
        inputLabel text := "Type your message here..."
        inputLabel x := 75
        inputLabel y := 410
        inputLabel color := list(0.3, 0.3, 0.3, 1.0)  // Dark gray text
        inputLabel id := "input_label"
        
        // Create send button
        self sendButton := RectangleMorph clone
        self sendButton width := 80
        self sendButton height := 40
        self sendButton x := 580
        self sendButton y := 400
        self sendButton color := list(0.2, 0.7, 0.2, 1.0)  // Green
        self sendButton id := "send_button"
        
        // Send button label
        sendLabel := TextMorph clone
        sendLabel text := "Send"
        sendLabel x := 600
        sendLabel y := 410
        sendLabel color := list(1.0, 1.0, 1.0, 1.0)  // White text
        sendLabel id := "send_label"
        
        // Create message display area (larger rectangle at top)
        self messageDisplay := RectangleMorph clone
        self messageDisplay width := 590
        self messageDisplay height := 320
        self messageDisplay x := 70
        self messageDisplay y := 50
        self messageDisplay color := list(1.0, 1.0, 1.0, 1.0)  // White background
        self messageDisplay id := "message_display"
        
        // Message display title
        displayTitle := TextMorph clone
        displayTitle text := "TelOS Chat - Ollama Integration"
        displayTitle x := 80
        displayTitle y := 20
        displayTitle color := list(0.2, 0.2, 0.8, 1.0)  // Blue
        displayTitle id := "chat_title"
        
        // Add all morphs to world
        self world addMorph(self inputField)
        self world addMorph(inputLabel)
        self world addMorph(self sendButton)
        self world addMorph(sendLabel)
        self world addMorph(self messageDisplay)
        self world addMorph(displayTitle)
        
        "✓ Visual chat components created and added to world" println
        self
    )
    
    sendMessage := method(messageText,
        if(messageText == nil or messageText size == 0,
            "Empty message - nothing to send" println
            return self
        )
        
        ("Sending: " .. messageText) println
        
        # Send to Ollama (will work once llama3.2 is pulled or use gemma3:4b)
        response := TelosOllama sendToOllama("gemma3:4b", messageText)
        
        if(response success,
            ("✓ AI Response: " .. response response) println
        ,
            errorMsg := if(response hasSlot("error"), response error, "Unknown error")
            ("✗ Error: " .. errorMsg) println
        )
        
        self
    )
    
    testChat := method(
        "=== Testing Chat with Visual Interface ===" println
        
        # Test with a simple message
        self sendMessage("Hello, please respond briefly")
        
        self
    )
)

# Initialize the visual chat interface
"Initializing visual chat interface..." println
chatInterface := VisualChatInterface clone
chatInterface initialize(world)

"✓ Visual chat interface created!" println
"You should see:"  println
"- Input field (gray rectangle at bottom)" println  
"- Send button (green rectangle)" println
"- Message display area (white rectangle at top)" println
"- Title text" println

# Test the chat functionality
chatInterface testChat

"Chat interface ready. Window should show visual components..." println

# Keep window open
Telos displayFor(20)