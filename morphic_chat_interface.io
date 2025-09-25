#!/usr/bin/env io
/*
   TelOS Morphic Chat Interface for Ollama LLMs
   Interactive chat UI with text input, message history, and send controls
*/

"=== TelOS Morphic Chat Interface Loading ===" println

// === CHAT INTERFACE MORPHS ===

// InputMorph - Text input field for user messages
InputMorph := RectangleMorph clone
InputMorph do(
    text := ""
    placeholder := "Type your message here..."
    isActive := false
    cursor := "|"
    showCursor := true
    showCursor := true
    
    clone := method(
        newMorph := resend
        newMorph text := ""
        newMorph isActive := false
        newMorph showCursor := true
        newMorph
    )
    
    init := method(
        self width := 600
        self height := 40
        self color := list(0.95, 0.95, 0.95, 1.0)  // Light gray
        self id := "inputField"
        self
    )
    
    activate := method(
        self isActive := true
        self color := list(1.0, 1.0, 1.0, 1.0)  // White when active
        self showCursor := true
        "Input field activated" println
    )
    
    deactivate := method(
        self isActive := false
        self color := list(0.95, 0.95, 0.95, 1.0)  // Light gray when inactive
        self showCursor := false
        "Input field deactivated" println
    )
    
    addText := method(newText,
        self text := self text .. newText
        self refresh
    )
    
    backspace := method(
        if(self text size > 0,
            self text := self text slice(0, self text size - 1)
            self refresh
        )
    )
    
    clear := method(
        self text := ""
        self refresh
    )
    
    getText := method(
        self text
    )
)

// MessageMorph - Individual chat message display
MessageMorph := RectangleMorph clone
MessageMorph do(
    messageText := ""
    sender := "User"
    timestamp := nil
    textMorph := nil
    
    clone := method(
        newMorph := resend
        newMorph messageText := ""
        newMorph sender := "User"
        newMorph timestamp := nil
        newMorph textMorph := nil
        newMorph
    )
    
    initWithMessage := method(text, from, time,
        self messageText := text
        self sender := from
        self timestamp := if(time == nil, Date now, time)
        
        self width := 580
        self height := 60  // Base height, will expand for long messages
        
        // Color based on sender
        if(self sender == "User",
            self color := list(0.2, 0.6, 1.0, 0.8)  // Blue for user
        ,
            self color := list(0.2, 0.8, 0.2, 0.8)  // Green for AI
        )
        
        self id := "message_" .. self timestamp asString
        
        // Create text display
        self textMorph := TextMorph clone
        self textMorph text := self formatMessage
        self textMorph x := self x + 10
        self textMorph y := self y + 5
        self textMorph width := self width - 20
        self textMorph height := self height - 10
        self textMorph color := list(1.0, 1.0, 1.0, 1.0)  // White text
        self textMorph id := "text_" .. self id
        
        self
    )
    
    formatMessage := method(
        senderLabel := "[" .. self sender .. "] "
        # Wrap long messages (simple wrapping)
        if(self messageText size > 80,
            wrapped := self messageText slice(0, 77) .. "..."
            senderLabel .. wrapped
        ,
            senderLabel .. self messageText
        )
    )
    
    updatePosition := method(newX, newY,
        self x := newX
        self y := newY
        if(self textMorph != nil,
            self textMorph x := newX + 10
            self textMorph y := newY + 5
        )
    )
)

// ButtonMorph - Interactive send button
ButtonMorph := RectangleMorph clone
ButtonMorph do(
    label := "Send"
    isPressed := false
    onClickAction := nil
    
    clone := method(
        newMorph := resend
        newMorph label := "Send"
        newMorph isPressed := false
        newMorph onClickAction := nil
        newMorph
    )
    
    init := method(
        self width := 100
        self height := 40
        self color := list(0.2, 0.8, 0.2, 1.0)  // Green
        self id := "sendButton"
        self
    )
    
    press := method(
        self isPressed := true
        self color := list(0.1, 0.6, 0.1, 1.0)  // Darker green when pressed
        if(self onClickAction != nil,
            self onClickAction call
        )
        self
    )
    
    release := method(
        self isPressed := false
        self color := list(0.2, 0.8, 0.2, 1.0)  // Normal green
        self
    )
    
    click := method(
        self press
        # Simulate brief press visual feedback
        self release
        "Send button clicked!" println
    )
)

// === MAIN CHAT INTERFACE ===

TelOSChatInterface := Object clone
TelOSChatInterface do(
    world := nil
    inputField := nil
    sendButton := nil
    messageHistory := List clone
    messageMorphs := List clone
    currentModel := "llama3.2:latest"
    ollamaHost := "http://localhost:11434"
    
    initialize := method(
        "Initializing TelOS Chat Interface..." println
        
        # Create world and window
        self world := Telos createWorld
        if(self world == nil,
            "ERROR: Failed to create world" println
            return nil
        )
        
        Telos openWindow
        
        # Create UI components
        self createInputField
        self createSendButton
        self createWelcomeMessage
        
        # Layout components
        self layoutInterface
        
        # Set up event handling
        self setupEventHandling
        
        "Chat Interface initialized! Ready for Ollama communication." println
        self
    )
    
    createInputField := method(
        self inputField := InputMorph clone
        self inputField init
        self inputField x := 50
        self inputField y := 400
        self inputField activate  # Start active for immediate typing
        
        self world addMorph(self inputField)
        "Input field created" println
    )
    
    createSendButton := method(
        self sendButton := ButtonMorph clone
        self sendButton init
        self sendButton x := 670
        self sendButton y := 400
        
        # Set click action
        self sendButton onClickAction := block(
            self sendMessage
        )
        
        self world addMorph(self sendButton)
        "Send button created" println
    )
    
    createWelcomeMessage := method(
        welcomeMsg := MessageMorph clone
        welcomeMsg initWithMessage(
            "TelOS Cognitive Interface - LLM-GCE-HRC-AGL Neural Loop Active",
            "System",
            Date now
        )
        welcomeMsg updatePosition(50, 50)
        
        self messageHistory append(welcomeMsg)
        self messageMorphs append(welcomeMsg)
        self world addMorph(welcomeMsg)
        if(welcomeMsg textMorph != nil,
            self world addMorph(welcomeMsg textMorph)
        )
    )
    
    layoutInterface := method(
        # Message area: top of screen
        # Input area: bottom of screen
        # Send button: right of input
        
        messageStartY := 50
        messageSpacing := 70
        
        # Update positions of existing messages
        self messageMorphs size repeat(i,
            morph := self messageMorphs at(i)
            newY := messageStartY + (i * messageSpacing)
            morph updatePosition(50, newY)
        )
        
        "Interface layout updated" println
    )
    
    setupEventHandling := method(
        # Note: In a full implementation, we would set up keyboard event handlers here
        # For now, we'll use method calls to simulate user input
        "Event handling ready (simulated for demo)" println
    )
    
    sendMessage := method(
        userText := self inputField getText
        
        if(userText == nil or userText size == 0,
            "No message to send" println
            return
        )
        
        "Sending message: " .. userText println
        
        # Add user message to history
        userMsg := MessageMorph clone
        userMsg initWithMessage(userText, "User", Date now)
        self addMessageToDisplay(userMsg)
        
        # Clear input field
        self inputField clear
        
        # Send to TelOS cognitive cycle
        self sendToCognitiveCycle(userText)
    )
    
    addMessageToDisplay := method(messageObj,
        # Calculate position for new message
        newY := 50 + (self messageMorphs size * 70)
        messageObj updatePosition(50, newY)
        
        # Add to collections
        self messageHistory append(messageObj)
        self messageMorphs append(messageObj)
        
        # Add to world
        self world addMorph(messageObj)
        if(messageObj textMorph != nil,
            self world addMorph(messageObj textMorph)
        )
        
        # Refresh display
        self world refresh
        
        "Message added to display" println
    )
    
    sendToCognitiveCycle := method(userMessage,
        # Use TelOS cognitive cycle directly - the real LLM-GCE-HRC-AGL loop
        cognitiveResult := try(
            Telos cognitiveQuery(userMessage, "")
        ) catch(Exception,
            Map clone atPut("error", "Cognitive cycle failed: " .. exception description)
        )
        
        if(cognitiveResult hasSlot("error"),
            # Handle cognitive cycle errors
            errorMsg := MessageMorph clone
            errorMsg initWithMessage(cognitiveResult error, "System", Date now)
            self addMessageToDisplay(errorMsg)
            return
        )
        
        # Extract LLM response from cognitive result
        aiResponse := "No response available"
        if(cognitiveResult hasSlot("llm_response"),
            llmResult := cognitiveResult llm_response
            if(llmResult hasSlot("response"),
                aiResponse := llmResult response
            )
        )
        
        # Create detailed cognitive analysis message
        analysisMsg := MessageMorph clone
        gceCount := if(cognitiveResult hasSlot("gce_candidates"), 
            cognitiveResult gce_candidates size asString,
            "0"
        )
        
        analysisText := "Cognitive Analysis: Retrieved " .. gceCount .. " GCE candidates, processed through HRC"
        analysisMsg initWithMessage(analysisText, "System", Date now)
        self addMessageToDisplay(analysisMsg)
        
        # Create AI response message  
        aiMsg := MessageMorph clone
        aiMsg initWithMessage(aiResponse, "TelOS", Date now)
        self addMessageToDisplay(aiMsg)
    )
    
    showErrorMessage := method(errorText,
        errorMsg := MessageMorph clone
        errorMsg initWithMessage(errorText, "Error", Date now)
        self addMessageToDisplay(errorMsg)
    )
    
    # Simulated typing methods for testing
    simulateTyping := method(text,
        "Simulating typing: " .. text println
        self inputField text := text
        self world refresh
    )
    
    simulateSend := method(
        self sendMessage
    )
    
    # Interactive test method - demonstrate cognitive cycle
    testCognitiveCycle := method(
        # Test with consciousness question
        self simulateTyping("What is consciousness?")
        Telos displayFor(1)
        
        self simulateSend
        Telos displayFor(3)  # Wait for cognitive processing
        
        # Test with technical question  
        self simulateTyping("Explain hyperdimensional computing")
        Telos displayFor(1)
        
        self simulateSend
        Telos displayFor(3)  # Wait for cognitive processing
    )
    
    # Main run method
    runCognitiveDemo := method(
        # Keep interface running with cognitive cycle active
        if(Telos hasSlot("mainLoop"),
            Telos mainLoop
        ,
            if(Telos hasSlot("displayFor"),
                Telos displayFor(30)
            )
        )
    )
)

// Register globals  
Lobby TelOSChatInterface := TelOSChatInterface
Lobby InputMorph := InputMorph
Lobby MessageMorph := MessageMorph
Lobby ButtonMorph := ButtonMorph

"=== TelOS Chat Interface Loaded ===" println
"Ready to initialize: TelOSChatInterface clone initialize" println

// Auto-initialize and test
# Auto-initialize and test cognitive cycle
chat := TelOSChatInterface clone
chat initialize

chat testCognitiveCycle