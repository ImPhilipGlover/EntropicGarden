/*
   TelosMorphic-Chat.io - Interactive Chat Interface
   Chat interface for LLM-GCE-HRC-AGL-LLM cognitive loop interaction
   Part of the modular TelosMorphic system
*/

// === TELOS MORPHIC CHAT MODULE ===

TelosMorphicChat := Object clone
TelosMorphicChat version := "1.0.0 (modular-prototypal)"
TelosMorphicChat loadTime := Date clone now

// === CHAT MESSAGE MORPH ===
// Individual message display in chat

ChatMessageMorph := RectangleMorph clone do(
    type := "chatMessage"
    message := ""
    isFromUser := true
    timestamp := Date now

    // Message-specific colors
    userColor := Color clone setColor(0.9, 0.9, 1.0, 1.0)     # Light blue
    assistantColor := Color clone setColor(0.9, 1.0, 0.9, 1.0)  # Light green
    systemColor := Color clone setColor(1.0, 0.9, 0.9, 1.0)     # Light red

    // Enhanced drawing for message display
    drawSelfOn := method(canvas,
        # Draw message background
        bgColor := if(self isFromUser, self userColor, self assistantColor)
        canvas fillRectangle(self bounds, bgColor)

        # Draw message text (simple wrapping)
        textColor := Color clone setColor(0.0, 0.0, 0.0, 1.0)
        maxWidth := self bounds width - 10
        words := self message split(" ")
        currentLine := ""
        y := self bounds y + 5

        words foreach(word,
            testLine := currentLine .. (if(currentLine size > 0, " ", "") .. word)
            if(testLine size * 8 > maxWidth and currentLine size > 0,
                # Draw current line
                textBounds := Object clone do(x := self bounds x + 5; y := y)
                canvas drawText(currentLine, textBounds, textColor)
                currentLine = word
                y = y + 14
            ,
                currentLine = testLine
            )
        )

        # Draw remaining line
        if(currentLine size > 0,
            textBounds := Object clone do(x := self bounds x + 5; y := y)
            canvas drawText(currentLine, textBounds, textColor)
        )

        # Draw timestamp
        timeStr := self timestamp asString slice(11, 19)  # HH:MM:SS
        timeBounds := Object clone do(
            x := self bounds x + self bounds width - (timeStr size * 8) - 5
            y := self bounds y + self bounds height - 12
        )
        timeColor := Color clone setColor(0.5, 0.5, 0.5, 1.0)
        canvas drawText(timeStr, timeBounds, timeColor)

        self
    )

    // Factory method
    withMessage := method(msg, fromUser,
        newMorph := self clone
        newMorph message = msg
        newMorph isFromUser = fromUser
        newMorph timestamp = Date now
        newMorph
    )

    description := method(
        "ChatMessageMorph(" .. (if(self isFromUser, "user", "assistant")) .. ",\"" .. self message slice(0, 30) .. "...\")"
    )
)

// === CHAT INPUT MORPH ===
// Text input field specifically for chat

ChatInputMorph := TextInputMorph clone do(
    type := "chatInput"
    placeholder := "Type your message here..."
    onSend := nil  # Block to call when message is sent

    // Enhanced for chat - handle Enter to send
    keyDown := method(keyName,
        if(keyName == "return" or keyName == "enter",
            if(self text size > 0,
                # Send message
                if(self onSend != nil,
                    try(
                        self onSend call(self text)
                        self text = ""  # Clear input
                        self cursorPosition = 0
                        writeln("ChatInput: Message sent")
                    ) catch(Exception e,
                        writeln("ChatInput: Send error: " .. e error)
                    )
                )
            )
        ,
            # Handle other keys normally
            resend
        )

        self
    )

    // Factory method with send callback
    withSendCallback := method(callback,
        newMorph := self clone
        newMorph onSend = callback
        newMorph
    )
)

// === CHAT INTERFACE MORPH ===
// Complete chat interface with message history and input

ChatInterfaceMorph := RectangleMorph clone do(
    type := "chatInterface"
    messages := List clone
    inputMorph := nil
    scrollOffset := 0
    maxVisibleMessages := 10

    // Initialize with input field
    init := method(
        resend

        # Create input field at bottom
        inputHeight := 30
        self inputMorph = ChatInputMorph withBoundsAndPlaceholder(
            self bounds x, self bounds y + self bounds height - inputHeight,
            self bounds width, inputHeight,
            "Type your message..."
        )

        # Set up send callback
        self inputMorph onSend = block(message,
            self sendMessage(message)
        )

        # Add input as submorph
        self addMorph(self inputMorph)

        self
    )

    // Send user message
    sendMessage := method(message,
        # Add user message
        userMessage := ChatMessageMorph withMessage(message, true)
        self addMessage(userMessage)

        # Log message
        if(Telos hasSlot("walAppend"),
            walEntry := "CHAT_SEND {\"message\":\"" .. message .. "\"}"
            Telos walAppend(walEntry)
        )

        # Here you would typically trigger the cognitive cycle
        # For now, simulate assistant response
        self simulateAssistantResponse(message)

        self
    )

    // Simulate assistant response (replace with actual LLM integration)
    simulateAssistantResponse := method(userMessage,
        # Simulate thinking delay
        System sleep(0.5)

        # Generate simple response based on input
        response := if(userMessage containsSeq("hello"),
            "Hello! I'm the TelOS cognitive assistant. How can I help you understand the neuro-symbolic architecture?"
        ,
        if(userMessage containsSeq("cognitive"),
            "The cognitive cycle involves: LLM → GCE (Geometric Context Engine) → HRC (Hyperdimensional Reasoning Core) → AGL (Associative Grounding Loop) → back to LLM. This creates a self-improving reasoning system."
        ,
        if(userMessage containsSeq("morph"),
            "Morphic UI provides direct manipulation of the living system. Each morph represents a living object that can be cloned, modified, and connected to cognitive processes."
        ,
            "I'm processing your message through the cognitive architecture. The system uses VSA (Vector Symbolic Architecture) for semantic computing and WAL (Write-Ahead Log) for persistence."
        )))

        # Add assistant response
        assistantMessage := ChatMessageMorph withMessage(response, false)
        self addMessage(assistantMessage)

        # Log response
        if(Telos hasSlot("walAppend"),
            walEntry := "CHAT_RESPONSE {\"response\":\"" .. response slice(0, 50) .. "...\"}"
            Telos walAppend(walEntry)
        )
    )

    // Add message to chat
    addMessage := method(messageMorph,
        self messages append(messageMorph)

        # Position message above input field
        inputHeight := 30
        messageHeight := 60  # Fixed height per message
        availableHeight := self bounds height - inputHeight

        # Calculate Y position (stack from bottom up)
        messageIndex := self messages size - 1
        baseY := self bounds y + availableHeight - (messageIndex + 1) * messageHeight

        # Adjust for scrolling
        messageMorph bounds setPosition(self bounds x + 5, baseY - (self scrollOffset * messageHeight))
        messageMorph bounds setSize(self bounds width - 10, messageHeight - 5)

        # Add as submorph
        self addMorph(messageMorph)

        # Auto-scroll to bottom
        maxScroll := (self messages size - self maxVisibleMessages) max(0)
        self scrollOffset = maxScroll

        # Remove old messages if too many
        if(self messages size > 50,
            oldMessage := self messages removeFirst
            self removeMorph(oldMessage)
        )

        self
    )

    // Scroll chat
    scrollUp := method(
        self scrollOffset = (self scrollOffset - 1) max(0)
        self repositionMessages
        self
    )

    scrollDown := method(
        maxScroll := (self messages size - self maxVisibleMessages) max(0)
        self scrollOffset = (self scrollOffset + 1) min(maxScroll)
        self repositionMessages
        self
    )

    // Reposition all messages after scrolling
    repositionMessages := method(
        inputHeight := 30
        messageHeight := 60
        availableHeight := self bounds height - inputHeight

        self messages foreach(i, message,
            baseY := self bounds y + availableHeight - (i + 1) * messageHeight
            message bounds y = baseY - (self scrollOffset * messageHeight)
        )

        self
    )

    // Enhanced drawing
    drawSelfOn := method(canvas,
        # Draw chat background
        bgColor := Color clone setColor(0.95, 0.95, 0.95, 1.0)  # Very light gray
        canvas fillRectangle(self bounds, bgColor)

        # Draw border
        borderColor := Color clone setColor(0.7, 0.7, 0.7, 1.0)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := self bounds width; height := 2), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y + self bounds height - 2; width := self bounds width; height := 2), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x; y := self bounds y; width := 2; height := self bounds height), borderColor)
        canvas fillRectangle(Object clone do(x := self bounds x + self bounds width - 2; y := self bounds y; width := 2; height := self bounds height), borderColor)

        # Draw title
        titleBounds := Object clone do(x := self bounds x + 10; y := self bounds y + 5)
        titleColor := Color clone setColor(0.0, 0.0, 0.0, 1.0)
        canvas drawText("TelOS Cognitive Chat", titleBounds, titleColor)

        self
    )

    // Handle mouse wheel for scrolling
    mouseMoved := method(event,
        # Check for scroll wheel (simplified - would need actual wheel events)
        # For now, just pass to submorphs
        false
    )

    description := method(
        "ChatInterfaceMorph(" .. self messages size .. " messages)"
    )
)

// === COGNITIVE CHAT DEMO ===
// Demonstration of integrated cognitive chat

CognitiveChatDemo := Object clone do(
    type := "cognitiveChatDemo"
    world := nil
    chatInterface := nil
    cognitiveCoordinator := nil

    // Initialize demo
    initialize := method(
        # Create world
        self world = MorphicWorld withTitleAndSize("TelOS Cognitive Chat Demo", 800, 600)

        # Create chat interface
        self chatInterface = ChatInterfaceMorph clone
        self chatInterface bounds setPosition(50, 50)
        self chatInterface bounds setSize(700, 500)
        self world addMorph(self chatInterface)

        # Create cognitive visualization morphs
        gceMorph := GCEMorph withProcessName("GCE")
        gceMorph bounds setPosition(50, 570)
        gceMorph bounds setSize(150, 80)
        self world addMorph(gceMorph)

        hrcMorph := HRCMorph withProcessName("HRC")
        hrcMorph bounds setPosition(220, 570)
        hrcMorph bounds setSize(150, 80)
        self world addMorph(hrcMorph)

        aglMorph := AGLMorph withProcessName("AGL")
        aglMorph bounds setPosition(390, 570)
        aglMorph bounds setSize(150, 80)
        self world addMorph(aglMorph)

        llmMorph := LLMInterfaceMorph clone
        llmMorph bounds setPosition(560, 570)
        llmMorph bounds setSize(190, 80)
        self world addMorph(llmMorph)

        # Initialize cognitive coordinator
        self cognitiveCoordinator = CognitiveCycleCoordinator clone
        self cognitiveCoordinator initializeWithMorphs(gceMorph, hrcMorph, aglMorph, llmMorph)

        # Override chat send to trigger cognitive cycle
        self chatInterface inputMorph onSend = block(message,
            # Add user message
            userMessage := ChatMessageMorph withMessage(message, true)
            self chatInterface addMessage(userMessage)

            # Start cognitive cycle
            self cognitiveCoordinator startCycle(message)

            # Simulate cognitive processing
            self simulateCognitiveProcessing(message)
        )

        self
    )

    // Simulate the cognitive processing cycle
    simulateCognitiveProcessing := method(query,
        # Phase 1: LLM processing
        System sleep(0.3)
        self cognitiveCoordinator nextPhase("LLM analyzed: " .. query)

        # Phase 2: GCE processing
        System sleep(0.5)
        self cognitiveCoordinator gceMorph addEmbedding(Object clone)  # Add dummy embedding
        self cognitiveCoordinator nextPhase("GCE retrieved context")

        # Phase 3: HRC reasoning
        System sleep(0.7)
        self cognitiveCoordinator hrcMorph addReasoningStep("Analyzing query structure")
        self cognitiveCoordinator hrcMorph addReasoningStep("Applying hyperdimensional operations")
        self cognitiveCoordinator hrcMorph addReasoningStep("Synthesizing reasoning")
        self cognitiveCoordinator nextPhase("HRC completed reasoning")

        # Phase 4: AGL grounding
        System sleep(0.4)
        self cognitiveCoordinator aglMorph addAssociation("context", 0.8)
        self cognitiveCoordinator aglMorph addAssociation("reasoning", 0.9)
        self cognitiveCoordinator nextPhase("AGL grounded concepts")

        # Phase 5: LLM response generation
        System sleep(0.6)
        response := self generateCognitiveResponse(query)
        self cognitiveCoordinator nextPhase(response)

        # Add assistant response
        assistantMessage := ChatMessageMorph withMessage(response, false)
        self chatInterface addMessage(assistantMessage)

        # Complete cycle
        self cognitiveCoordinator completeCycle
    )

    // Generate contextually appropriate response
    generateCognitiveResponse := method(query,
        if(query containsSeq("hello") or query containsSeq("hi"),
            "Greetings! I'm the TelOS neuro-symbolic intelligence system. I use a cognitive cycle of LLM → GCE → HRC → AGL → LLM to process and respond to queries. How can I assist you today?"
        ,
        if(query containsSeq("cognitive") or query containsSeq("architecture"),
            "The TelOS cognitive architecture implements a dual-process reasoning system. The Geometric Context Engine (GCE) handles fast associative retrieval using vector symbolic architectures, while the Hyperdimensional Reasoning Core (HRC) performs slow, deliberate algebraic reasoning. The Associative Grounding Loop (AGL) provides semantic grounding."
        ,
        if(query containsSeq("morph") or query containsSeq("ui"),
            "The Morphic UI is a direct manifestation of the 'Living Image' philosophy. Each morph is a clonable, directly manipulable object that represents living computational elements. The UI isn't a rendering of the system - it IS the system, directly manipulable by users."
        ,
        if(query containsSeq("vsa") or query containsSeq("vector"),
            "Vector Symbolic Architecture (VSA) enables symbolic computing with high-dimensional vectors. Operations like binding (*), bundling (+), and unbinding allow complex symbolic manipulations while maintaining similarity preservation and robustness to noise."
        ,
            "Your query has been processed through the complete cognitive cycle. The system uses Write-Ahead Logging (WAL) for transactional persistence, ensuring that even radical self-modifications maintain system integrity. What aspect of the neuro-symbolic architecture would you like to explore further?"
        )
    )

    // Start the demo
    start := method(
        if(self world == nil,
            self initialize
        )

        writeln("CognitiveChatDemo: Starting interactive cognitive chat demo")
        self world start
        self
    )
)

// Register chat components in global namespace
Lobby ChatMessageMorph := ChatMessageMorph
Lobby ChatInputMorph := ChatInputMorph
Lobby ChatInterfaceMorph := ChatInterfaceMorph
Lobby CognitiveChatDemo := CognitiveChatDemo

// Module load method
TelosMorphicChat load := method(
    writeln("TelosMorphic-Chat: Interactive chat interface loaded")
    writeln("TelosMorphic-Chat: ChatInterfaceMorph, CognitiveChatDemo registered")
    self
)

writeln("TelosMorphic-Chat: Interactive chat interface module loaded")

// Register TelosMorphicChat in global namespace
Lobby TelosMorphicChat := TelosMorphicChat