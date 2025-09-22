// Interactive Morphic UI for Live Inter/Intra Persona Cognition
// Allows users to send messages and see live LLM responses

// Load the live inter/intra persona cognition system
doFile("inter_intra_persona_cognition.io")

// Interactive Persona Cognition Canvas
InteractivePersonaCognitionCanvas := Morph clone do(
    // UI State
    queryInputField := nil
    sendButton := nil
    responseArea := nil
    facetDisplays := List clone
    dialogueDisplay := nil
    currentQuery := nil
    isProcessing := false
    
    // Personas for live interaction
    brickPersona := nil
    robinPersona := nil
    dialogue := nil
    
    // Initialize interactive UI
    initialize := method(
        self color := Color white
        self extent := Point clone x(1400) y(900)
        self position := Point clone x(50) y(50)
        
        // Initialize personas
        self initializePersonas
        
        // Setup UI components
        self setupInputArea
        self setupPersonaDisplays  
        self setupDialogueDisplay
        self setupControlButtons
        
        self
    )
    
    // Initialize live personas with facets
    initializePersonas := method(
        self brickPersona := BrickPersona clone
        self brickPersona initializeFacets
        
        self robinPersona := RobinPersona clone
        self robinPersona initializeFacets
        
        self dialogue := SocraticContrapunto clone
        self dialogue initializeDialogue(self brickPersona, self robinPersona, nil, nil)
        
        "Personas initialized with live Ollama integration!" println
    )
    
    // Setup input area for user queries
    setupInputArea := method(
        // Title
        titleMorph := TextMorph clone
        titleMorph contents := "Interactive Inter/Intra Persona Cognition System - Live LLM Integration"
        titleMorph position := Point clone x(20) y(20)
        titleMorph color := Color black
        self addMorph(titleMorph)
        
        // Query input field
        inputLabel := TextMorph clone
        inputLabel contents := "Your Message:"
        inputLabel position := Point clone x(20) y(50)
        inputLabel color := Color darkGray
        self addMorph(inputLabel)
        
        self queryInputField := TextInputMorph clone
        self queryInputField extent := Point clone x(800) y(30)
        self queryInputField position := Point clone x(20) y(75)
        self queryInputField color := Color white
        self queryInputField borderWidth := 2
        self queryInputField borderColor := Color black
        self queryInputField text := "How can we create AI systems that are both creative and reliable?"
        self addMorph(self queryInputField)
        
        // Send button
        self sendButton := ButtonMorph clone
        self sendButton extent := Point clone x(120) y(35)
        self sendButton position := Point clone x(850) y(73)
        self sendButton color := Color blue lighter
        self sendButton borderWidth := 2
        self sendButton borderColor := Color blue
        self sendButton label := "Send to Personas"
        self sendButton action := method(sender, 
            sender owner processUserQuery
        )
        self addMorph(self sendButton)
        
        // Status display
        self statusDisplay := TextMorph clone
        self statusDisplay contents := "Ready - Click 'Send to Personas' to begin live dialogue"
        self statusDisplay position := Point clone x(20) y(115)
        self statusDisplay color := Color darkGreen
        self addMorph(self statusDisplay)
    )
    
    // Setup persona display areas
    setupPersonaDisplays := method(
        // BRICK persona display
        brickDisplay := InteractivePersonaDisplay clone
        brickDisplay extent := Point clone x(650) y(300)
        brickDisplay position := Point clone x(20) y(150)
        brickDisplay personaName := "BRICK"
        brickDisplay personaColor := Color blue lighter
        brickDisplay initialize
        
        // ROBIN persona display
        robinDisplay := InteractivePersonaDisplay clone
        robinDisplay extent := Point clone x(650) y(300)
        robinDisplay position := Point clone x(720) y(150)
        robinDisplay personaName := "ROBIN"
        robinDisplay personaColor := Color red lighter
        robinDisplay initialize
        
        self addMorph(brickDisplay)
        self addMorph(robinDisplay)
        
        self facetDisplays append(brickDisplay)
        self facetDisplays append(robinDisplay)
    )
    
    // Setup dialogue display
    setupDialogueDisplay := method(
        self dialogueDisplay := InteractiveDialogueDisplay clone
        self dialogueDisplay extent := Point clone x(1350) y(200)
        self dialogueDisplay position := Point clone x(20) y(470)
        self dialogueDisplay initialize
        
        self addMorph(self dialogueDisplay)
    )
    
    // Setup control buttons
    setupControlButtons := method(
        // Clear button
        clearButton := ButtonMorph clone
        clearButton extent := Point clone x(100) y(30)
        clearButton position := Point clone x(20) y(690)
        clearButton color := Color yellow lighter
        clearButton label := "Clear All"
        clearButton action := method(sender,
            sender owner clearAllDisplays
        )
        self addMorph(clearButton)
        
        // Demo button
        demoButton := ButtonMorph clone
        demoButton extent := Point clone x(150) y(30)
        demoButton position := Point clone x(140) y(690)
        demoButton color := Color green lighter
        demoButton label := "Run Quick Demo"
        demoButton action := method(sender,
            sender owner runQuickDemo
        )
        self addMorph(demoButton)
    )
    
    // Process user query with live LLM calls
    processUserQuery := method(
        if(self isProcessing,
            "Processing in progress, please wait..." println
            return
        )
        
        queryText := self queryInputField text
        if(queryText size == 0,
            self updateStatus("Please enter a message first!")
            return
        )
        
        self isProcessing := true
        self sendButton color := Color gray
        self updateStatus("Processing with live LLM calls...")
        
        // Create query object
        self currentQuery := Object clone
        self currentQuery queryText := queryText
        self currentQuery topicName := "User Query"
        
        ("=== Live Inter/Intra Persona Cognition ===") println
        ("User Query: " .. queryText) println
        
        // Process with live Ollama calls
        try(
            // BRICK internal monologue with live LLM
            self updateStatus("BRICK analyzing with live Ollama...")
            brickResult := self brickPersona conductInternalMonologue(self currentQuery)
            self displayPersonaResult("BRICK", brickResult)
            
            // ROBIN internal monologue with live LLM
            self updateStatus("ROBIN synthesizing with live Ollama...")
            robinDialogueQuery := Object clone
            robinDialogueQuery queryText := "Provide empathetic resonance and synthesis for: " .. queryText .. "\n\nBRICK's analysis: " .. brickResult response
            robinDialogueQuery topicName := "Synthesis Response"
            
            robinResult := self robinPersona conductInternalMonologue(robinDialogueQuery)
            self displayPersonaResult("ROBIN", robinResult)
            
            // Inter-persona dialogue
            self updateStatus("Conducting inter-persona dialogue...")
            dialogueResult := self dialogue conductDialogue(self currentQuery)
            self dialogueDisplay displayLiveDialogue(dialogueResult)
            
            self updateStatus("Live dialogue complete! Models: " .. brickResult model .. " & " .. robinResult model)
            
        ,
            // Error handling
            self updateStatus("Error during live LLM processing: " .. call sender)
            ("Error in live LLM processing: " .. call sender) println
        )
        
        self isProcessing := false
        self sendButton color := Color blue lighter
    )
    
    // Display persona result in UI
    displayPersonaResult := method(personaName, result,
        personaDisplay := self facetDisplays detect(display,
            display personaName == personaName
        )
        
        if(personaDisplay,
            personaDisplay displayLiveResult(result)
        )
    )
    
    // Update status message
    updateStatus := method(message,
        self statusDisplay contents := message
        self statusDisplay changed
        
        // Process UI events to update display
        self world doOneCycle
    )
    
    // Clear all displays
    clearAllDisplays := method(
        self facetDisplays foreach(display,
            display clearDisplay
        )
        self dialogueDisplay clearDisplay
        self updateStatus("Displays cleared - ready for new query")
    )
    
    // Run quick demo
    runQuickDemo := method(
        self queryInputField text := "What is the most important quality for AI systems?"
        self processUserQuery
    )
    
    // Handle mouse events
    handleMouseDown := method(event,
        // Let child morphs handle their events first
        resend(event)
    )
)

// Interactive Persona Display for live results
InteractivePersonaDisplay := Morph clone do(
    personaName := "DefaultPersona"
    personaColor := Color gray
    titleMorph := nil
    resultArea := nil
    facetResultsArea := nil
    
    initialize := method(
        self color := self personaColor
        self borderWidth := 2
        self borderColor := Color black
        
        // Title
        self titleMorph := TextMorph clone  
        self titleMorph contents := self personaName .. " - Live Internal Monologue"
        self titleMorph position := Point clone x(10) y(10)
        self titleMorph color := Color black
        self addMorph(self titleMorph)
        
        // Result area
        self resultArea := TextMorph clone
        self resultArea contents := "Awaiting live LLM response..."
        self resultArea position := Point clone x(10) y(40)
        self resultArea color := Color darkBlue
        self addMorph(self resultArea)
        
        // Facet results area
        self facetResultsArea := TextMorph clone
        self facetResultsArea contents := "Cognitive facets not yet consulted"
        self facetResultsArea position := Point clone x(10) y(80)
        self facetResultsArea color := Color purple
        self addMorph(self facetResultsArea)
        
        self
    )
    
    // Display live LLM result
    displayLiveResult := method(result,
        // Update main result
        if(result response,
            self resultArea contents := "Response: " .. result response
        else,
            self resultArea contents := "Response: " .. result asString
        )
        
        // Show model used
        if(result model,
            self resultArea contents := self resultArea contents .. "\n\nModel: " .. result model
        )
        
        self resultArea changed
        self changed
    )
    
    // Clear display
    clearDisplay := method(
        self resultArea contents := "Awaiting live LLM response..."
        self facetResultsArea contents := "Cognitive facets not yet consulted"
        self changed
    )
)

// Interactive Dialogue Display
InteractiveDialogueDisplay := Morph clone do(
    titleMorph := nil
    dialogueArea := nil
    
    initialize := method(
        self color := Color lightGray
        self borderWidth := 2
        self borderColor := Color black
        
        // Title
        self titleMorph := TextMorph clone
        self titleMorph contents := "Socratic Contrapunto - Live Inter-Persona Dialogue"
        self titleMorph position := Point clone x(10) y(10)
        self titleMorph color := Color black
        self addMorph(self titleMorph)
        
        // Dialogue area
        self dialogueArea := TextMorph clone
        self dialogueArea contents := "Inter-persona dialogue not yet started..."
        self dialogueArea position := Point clone x(10) y(40)
        self dialogueArea color := Color darkGreen
        self addMorph(self dialogueArea)
        
        self
    )
    
    // Display live dialogue result
    displayLiveDialogue := method(dialogueResult,
        dialogueText := "BRICK Analysis:\n" .. dialogueResult brickAnalysis .. "\n\n"
        dialogueText := dialogueText .. "ROBIN Synthesis:\n" .. dialogueResult robinSynthesis
        
        self dialogueArea contents := dialogueText
        self dialogueArea changed
        self changed
    )
    
    // Clear display
    clearDisplay := method(
        self dialogueArea contents := "Inter-persona dialogue not yet started..."
        self changed
    )
)

// Create enhanced TextInputMorph for user input
TextInputMorph := Morph clone do(
    text := ""
    cursor := 0
    isActive := false
    
    initialize := method(
        self color := Color white
        self
    )
    
    // Handle key input
    handleKeyDown := method(event,
        key := event key
        
        if(key == "Return",
            // Trigger send action
            if(self owner respondsTo("processUserQuery"),
                self owner processUserQuery
            )
            return
        )
        
        if(key == "Backspace",
            if(self text size > 0,
                self text := self text slice(0, self text size - 1)
                self changed
            )
            return
        )
        
        // Add character to text
        if(key size == 1,
            self text := self text .. key
            self changed
        )
    )
    
    // Handle mouse clicks
    handleMouseDown := method(event,
        self isActive := true
        self borderColor := Color blue
        self changed
    )
    
    // Draw method to show text
    draw := method(
        resend
        // Text is displayed by the Morphic system
    )
)

// Enhanced ButtonMorph for interactions
ButtonMorph := Morph clone do(
    label := "Button"
    action := nil
    
    initialize := method(
        self color := Color lightGray
        self borderWidth := 1
        self borderColor := Color black
        self
    )
    
    // Handle clicks
    handleMouseDown := method(event,
        if(self action,
            self action call(self)
        )
    )
    
    // Draw method
    draw := method(
        resend
        // Label is handled by Morphic system
    )
)

// Launch the interactive live demo
launchInteractiveLiveDemo := method(
    "=== Launching Interactive Live Persona Cognition Demo ===" println
    "This demo uses live Ollama calls to TelOS persona models!" println
    
    // Create interactive canvas
    canvas := InteractivePersonaCognitionCanvas clone
    canvas initialize
    
    // Open in world  
    canvas openInWorld
    
    // Instructions
    "" println
    "🎯 INTERACTIVE LIVE DEMO READY!" println
    "• Enter your message in the text field" println
    "• Click 'Send to Personas' to trigger live LLM calls" println
    "• Watch BRICK and ROBIN conduct internal monologues with real Ollama models" println
    "• See the Socratic Contrapunto dialogue unfold with live responses" println
    "• Models used: telos/brick (BRICK) and telos/robin (ROBIN)" println
    "" println
    
    canvas
)

// Launch the interactive demo
interactiveCanvas := launchInteractiveLiveDemo