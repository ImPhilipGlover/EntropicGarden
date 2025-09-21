#!/usr/bin/env io

// Final Interactive Morphic UI Demo - Live Persona Cognition
// Complete interactive system with live LLM calls and real-time visualization

"=== TelOS Interactive Persona Cognition Demo ===" println
"🎯 Live LLM Integration with Morphic UI" println
"" println

// Enable live LLM integration
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")
"✅ Ollama integration enabled" println

// Load core persona system
doFile("core_persona_cognition.io")

// Interactive Morphic Canvas for Live Persona Messaging
LivePersonaCanvas := Morph clone do(
    // UI State
    queryInput := nil
    submitButton := nil
    responseDisplay := nil
    statusLabel := nil
    currentQuery := nil
    
    // Persona result displays
    brickDisplay := nil
    robinDisplay := nil
    dialogueDisplay := nil
    
    // Initialize canvas
    setup := method(
        self backgroundColor := Color gray
        self extent := Point clone set(800, 600)
        
        // Create input area
        inputLabel := TextMorph clone
        inputLabel text := "💬 Message to Persona System:"
        inputLabel textColor := Color white
        inputLabel position := Point clone set(20, 20)
        self addMorph(inputLabel)
        
        queryInput := TextFieldMorph clone
        queryInput extent := Point clone set(600, 30)
        queryInput position := Point clone set(20, 50)
        queryInput backgroundColor := Color darkGray
        queryInput textColor := Color white
        queryInput text := "What is the nature of creativity?"
        self addMorph(queryInput)
        
        submitButton := ButtonMorph clone
        submitButton label := "🚀 Send to Personas"
        submitButton extent := Point clone set(150, 35)
        submitButton position := Point clone set(630, 48)
        submitButton backgroundColor := Color green
        submitButton action := method(owner processQuery)
        self addMorph(submitButton)
        
        // Status display
        statusLabel := TextMorph clone
        statusLabel text := "Ready for live persona interaction..."
        statusLabel textColor := Color green
        statusLabel position := Point clone set(20, 95)
        self addMorph(statusLabel)
        
        // Response displays
        self createResponseDisplays
        
        "✅ Interactive canvas ready - enter query and click 'Send to Personas'" println
    )
    
    createResponseDisplays := method(
        // BRICK response area
        brickLabel := TextMorph clone
        brickLabel text := "🧱 BRICK (Literal Analysis):"
        brickLabel textColor := Color orange
        brickLabel position := Point clone set(20, 130)
        self addMorph(brickLabel)
        
        brickDisplay := TextMorph clone
        brickDisplay text := "Awaiting live LLM response..."
        brickDisplay textColor := Color white
        brickDisplay position := Point clone set(20, 155)
        brickDisplay extent := Point clone set(750, 100)
        brickDisplay backgroundColor := Color darkGray
        self addMorph(brickDisplay)
        
        // ROBIN response area
        robinLabel := TextMorph clone
        robinLabel text := "🐦 ROBIN (Philosophical Synthesis):"
        robinLabel textColor := Color cyan
        robinLabel position := Point clone set(20, 270)
        self addMorph(robinLabel)
        
        robinDisplay := TextMorph clone
        robinDisplay text := "Awaiting live LLM response..."
        robinDisplay textColor := Color white
        robinDisplay position := Point clone set(20, 295)
        robinDisplay extent := Point clone set(750, 100)
        robinDisplay backgroundColor := Color darkGray
        self addMorph(robinDisplay)
        
        // Dialogue synthesis area
        dialogueLabel := TextMorph clone
        dialogueLabel text := "🔄 Inter-Persona Dialogue Synthesis:"
        dialogueLabel textColor := Color magenta
        dialogueLabel position := Point clone set(20, 410)
        self addMorph(dialogueLabel)
        
        dialogueDisplay := TextMorph clone
        dialogueDisplay text := "Awaiting persona dialogue..."
        dialogueDisplay textColor := Color white
        dialogueDisplay position := Point clone set(20, 435)
        dialogueDisplay extent := Point clone set(750, 120)
        dialogueDisplay backgroundColor := Color darkGray
        self addMorph(dialogueDisplay)
    )
    
    processQuery := method(
        queryText := queryInput text
        if(queryText isEmpty, return)
        
        statusLabel text := "🔄 Processing query with live LLM calls..."
        statusLabel textColor := Color yellow
        
        // Create query object
        queryObj := Object clone
        queryObj queryText := queryText
        queryObj topicName := "Live User Query"
        
        // Test BRICK facet
        try(
            statusLabel text := "🧱 BRICK analyzing query..."
            tamlandFacet := BrickTamlandFacet clone
            brickResult := tamlandFacet processQuery(queryObj)
            
            brickText := "Model: " .. brickResult model .. "\n"
            brickText = brickText .. "Facet: " .. brickResult facetName .. "\n\n"
            brickText = brickText .. brickResult response
            brickDisplay text := brickText
            
            ("✅ BRICK response received (" .. brickResult response size .. " chars)") println
        ,
            brickDisplay text := "❌ Error in BRICK processing: " .. call sender
            ("❌ BRICK error: " .. call sender) println
        )
        
        // Test ROBIN facet
        try(
            statusLabel text := "🐦 ROBIN synthesizing wisdom..."
            sageFacet := RobinSageFacet clone
            robinResult := sageFacet processQuery(queryObj)
            
            robinText := "Model: " .. robinResult model .. "\n"
            robinText = robinText .. "Facet: " .. robinResult facetName .. "\n\n"
            robinText = robinText .. robinResult response
            robinDisplay text := robinText
            
            ("✅ ROBIN response received (" .. robinResult response size .. " chars)") println
        ,
            robinDisplay text := "❌ Error in ROBIN processing: " .. call sender
            ("❌ ROBIN error: " .. call sender) println
        )
        
        // Create dialogue synthesis
        try(
            statusLabel text := "🔄 Synthesizing inter-persona dialogue..."
            
            dialogueText := "Query: '" .. queryText .. "'\n\n"
            dialogueText = dialogueText .. "BRICK (Literal): " .. brickResult response slice(0, 100) .. "...\n\n"
            dialogueText = dialogueText .. "ROBIN (Wisdom): " .. robinResult response slice(0, 100) .. "...\n\n"
            dialogueText = dialogueText .. "🎯 Dialogue demonstrates live LLM integration with parameter differentiation:\n"
            dialogueText = dialogueText .. "  • BRICK uses telos/brick model with T=0.1 (literal precision)\n"
            dialogueText = dialogueText .. "  • ROBIN uses telos/robin model with T=0.8 (philosophical wisdom)"
            
            dialogueDisplay text := dialogueText
            
            statusLabel text := "✅ Live persona cognition complete!"
            statusLabel textColor := Color green
            
            ("🎯 Live inter-persona dialogue complete!") println
        ,
            dialogueDisplay text := "❌ Error in dialogue synthesis: " .. call sender
            ("❌ Dialogue error: " .. call sender) println
        )
    )
)

// Launch the interactive canvas
canvas := LivePersonaCanvas clone
canvas setup
World addMorph(canvas)
canvas center

"" println
"🎯 LIVE INTERACTIVE PERSONA COGNITION READY!" println
"📝 Enter a query in the text field and click 'Send to Personas'" println  
"🔄 Watch live LLM responses with parameter differentiation:" println
"   • BRICK: telos/brick model (T=0.1) - Literal, declarative analysis" println
"   • ROBIN: telos/robin model (T=0.8) - Philosophical, wisdom synthesis" println
"" println
"✨ This demonstrates complete live LLM integration with Morphic UI!" println