// Morphic UI Demo for Inter/Intra Persona Cognition Systems
// Live visualization of cognitive facets and persona dialogues

// Load the inter/intra persona cognition system
doFile("inter_intra_persona_cognition.io")

// Morphic Canvas for Persona Cognition Visualization
PersonaCognitionCanvas := Morph clone do(
    // Use proper bounds setting for Morphic
    // bounds will be set in initialize method
    
    // Visualization state
    activePersona := nil
    activeDialogue := nil
    facetDisplays := List clone
    dialogueDisplays := List clone
    
    // Initialize visualization
    initialize := method(
        self color := Color white
        self extent := Point clone x(1200) y(800)
        self position := Point clone x(50) y(50)
        self setupPersonaDisplays
        self setupDialogueDisplays
        self
    )
    
    // Setup persona display areas
    setupPersonaDisplays := method(
        // BRICK persona display area
        brickDisplay := PersonaDisplay clone
        brickDisplay extent := Point clone x(520) y(320)
        brickDisplay position := Point clone x(10) y(10)
        brickDisplay personaName := "BRICK"
        brickDisplay personaColor := Color blue lighter
        brickDisplay initialize
        
        // ROBIN persona display area
        robinDisplay := PersonaDisplay clone
        robinDisplay extent := Point clone x(520) y(320)
        robinDisplay position := Point clone x(570) y(10)
        robinDisplay personaName := "ROBIN"  
        robinDisplay personaColor := Color red lighter
        robinDisplay initialize
        
        self addMorph(brickDisplay)
        self addMorph(robinDisplay)
        
        self facetDisplays append(brickDisplay)
        self facetDisplays append(robinDisplay)
    )
    
    // Setup dialogue display area
    setupDialogueDisplays := method(
        // Inter-persona dialogue display
        dialogueDisplay := DialogueDisplay clone
        dialogueDisplay extent := Point clone x(1080) y(320)
        dialogueDisplay position := Point clone x(10) y(370)
        dialogueDisplay initialize
        
        self addMorph(dialogueDisplay)
        self dialogueDisplays := dialogueDisplay
    )
    
    // Visualize persona internal monologue
    visualizePersonaMonologue := method(personaName, queryObj, facetResults,
        // Find corresponding display
        personaDisplay := self facetDisplays detect(display,
            display personaName == personaName
        )
        
        if(personaDisplay,
            personaDisplay displayInternalMonologue(queryObj, facetResults)
        )
    )
    
    // Visualize inter-persona dialogue
    visualizeDialogue := method(dialogueResult,
        self dialogueDisplays displayDialogue(dialogueResult)
    )
    
    // Handle mouse clicks to trigger cognition demos
    handleMouseDown := method(event,
        // Trigger demo cognition cycle
        self runPersonaCognitionDemo
    )
    
    // Run complete persona cognition demonstration
    runPersonaCognitionDemo := method(
        // Create test query
        demoQuery := Object clone
        demoQuery queryText := "How can we build AI systems that balance creativity with reliability?"
        demoQuery topicName := "Creative AI Design"
        
        // Create personas for demo
        brick := BrickPersona clone
        robin := RobinPersona clone
        brick initializeFacets
        robin initializeFacets
        
        // Demonstrate BRICK internal monologue
        self visualizeDemoPersonaMonologue("BRICK", demoQuery, brick)
        
        // Wait briefly for visualization
        self world doOneCycle
        
        // Demonstrate ROBIN internal monologue  
        self visualizeDemoPersonaMonologue("ROBIN", demoQuery, robin)
        
        // Demonstrate inter-persona dialogue
        dialogue := SocraticContrapunto clone
        dialogue initializeDialogue(brick, robin, nil, nil)
        dialogueResult := self createMockDialogueResult(demoQuery)
        
        self visualizeDialogue(dialogueResult)
    )
    
    // Visualize demo persona monologue with mock facet results
    visualizeDemoPersonaMonologue := method(personaName, queryObj, personaObj,
        // Create mock facet consultation results for visualization
        facetResults := self createMockFacetResults(personaName, queryObj)
        self visualizePersonaMonologue(personaName, queryObj, facetResults)
    )
    
    // Create mock facet results for demonstration
    createMockFacetResults := method(personaName, queryObj,
        facetResults := List clone
        
        if(personaName == "BRICK",
            // Mock BRICK facet results
            tamlandResult := Object clone
            tamlandResult facetName := "TamlandEngine"
            tamlandResult response := "AI systems have components. Creativity is output variation. Reliability is consistent performance. These are measurable properties."
            tamlandResult parameters := Object clone do(temperature := 0.1; top_p := 0.7)
            
            batmanResult := Object clone  
            batmanResult facetName := "LegoBatman"
            batmanResult response := "This is a mission to build the Creative-Reliability Synthesizer 3000! We must defeat the forces of boring predictability!"
            batmanResult parameters := Object clone do(temperature := 0.7; top_p := 0.9)
            
            guideResult := Object clone
            guideResult facetName := "HitchhikersGuide" 
            guideResult response := "The Infinite Improbability Drive, according to galactic engineers, operates on the principle that improbable events become probable given infinite computational resources. Towels remain essential."
            guideResult parameters := Object clone do(temperature := 0.6; top_p := 0.8)
            
            facetResults append(tamlandResult)
            facetResults append(batmanResult)
            facetResults append(guideResult)
        )
        
        if(personaName == "ROBIN",
            // Mock ROBIN facet results
            sageResult := Object clone
            sageResult facetName := "AlanWattsSage"
            sageResult response := "The paradox of controlling creativity reveals the wisdom of insecurity. True innovation emerges when we accept uncertainty as the ground of being."
            sageResult parameters := Object clone do(temperature := 0.8; top_p := 0.9)
            
            heartResult := Object clone
            heartResult facetName := "WinniePoohHeart"
            heartResult response := "Sometimes the best AI is like a good friend - reliable when you need them, surprising in delightful ways, and always kind."
            heartResult parameters := Object clone do(temperature := 0.6; top_p := 0.8)
            
            sparkResult := Object clone
            sparkResult facetName := "LegoRobinSpark"
            sparkResult response := "This is SO EXCITING! We're going to build the most amazing creative AND reliable AI ever! It'll be like having a super-smart buddy who's also really dependable!"
            sparkResult parameters := Object clone do(temperature := 0.9; top_p := 0.95)
            
            facetResults append(sageResult)
            facetResults append(heartResult)
            facetResults append(sparkResult)
        )
        
        facetResults
    )
    
    // Create mock dialogue result for demonstration
    createMockDialogueResult := method(queryObj,
        dialogueResult := Object clone
        dialogueResult topic := queryObj
        dialogueResult brickAnalysis := "Analysis complete: Creative AI requires controlled randomness + reliability constraints + measurable output validation. The Batman-Approved Creative-Reliability Protocol activated."
        dialogueResult robinSynthesis := "What beautiful complexity emerges when we embrace both structure and spontaneity! Like a jazz musician who knows the scales perfectly but plays from the heart - technical mastery serving authentic expression."
        dialogueResult
    )
)

// Individual Persona Display Morph
PersonaDisplay := Morph clone do(
    personaName := "DefaultPersona"
    personaColor := Color gray
    facetMorphs := List clone
    queryDisplay := nil
    
    initialize := method(
        self color := self personaColor
        self borderWidth := 2
        self borderColor := Color black
        
        // Create persona title
        titleMorph := TextMorph clone
        titleMorph contents := self personaName .. " - Internal Monologue"
        titleMorph position := Point clone x(10) y(10)
        titleMorph color := Color black
        self addMorph(titleMorph)
        
        // Create facet display areas
        self setupFacetDisplays
        
        self
    )
    
    // Setup facet display morphs
    setupFacetDisplays := method(
        facetYOffset := 40
        facetHeight := 80
        facetSpacing := 85
        
        3 repeat(i,
            facetMorph := FacetDisplay clone
            facetMorph extent := Point clone x(500) y(facetHeight)
            facetMorph position := Point clone x(10) y(facetYOffset + (i * facetSpacing))
            facetMorph initialize
            
            self addMorph(facetMorph)
            self facetMorphs append(facetMorph)
        )
    )
    
    // Display internal monologue results
    displayInternalMonologue := method(queryObj, facetResults,
        // Update query display if exists
        if(self queryDisplay,
            self queryDisplay contents := "Query: " .. queryObj queryText
        else,
            self queryDisplay := TextMorph clone
            self queryDisplay contents := "Query: " .. queryObj queryText
            self queryDisplay position := Point clone x(10) y(280)
            self queryDisplay color := Color darkGray
            self addMorph(self queryDisplay)
        )
        
        // Update facet displays
        facetResults size min(self facetMorphs size) repeat(i,
            facetResult := facetResults at(i)
            facetMorph := self facetMorphs at(i)
            facetMorph displayFacetResult(facetResult)
        )
        
        // Request redraw
        self changed
    )
)

// Individual Facet Display Morph
FacetDisplay := Morph clone do(
    facetName := "DefaultFacet"
    responseText := ""
    parameterText := ""
    
    initialize := method(
        self color := Color white
        self borderWidth := 1
        self borderColor := Color gray
        
        // Facet name label
        nameLabel := TextMorph clone
        nameLabel contents := self facetName
        nameLabel position := Point clone x(5) y(5)
        nameLabel color := Color darkBlue
        self addMorph(nameLabel)
        
        self
    )
    
    // Display facet consultation result
    displayFacetResult := method(facetResult,
        // Clear existing displays
        self submorphs := List clone
        
        // Facet name
        nameLabel := TextMorph clone
        nameLabel contents := facetResult facetName
        nameLabel position := Point clone x(5) y(5)
        nameLabel color := Color darkBlue
        self addMorph(nameLabel)
        
        // Parameters display
        paramLabel := TextMorph clone
        paramLabel contents := "T:" .. facetResult parameters temperature .. " P:" .. facetResult parameters top_p
        paramLabel position := Point clone x(200) y(5)
        paramLabel color := Color purple
        self addMorph(paramLabel)
        
        // Response text (truncated for display)
        responseLabel := TextMorph clone
        truncatedResponse := facetResult response
        if(truncatedResponse size > 100,
            truncatedResponse := truncatedResponse slice(0, 100) .. "..."
        )
        responseLabel contents := truncatedResponse
        responseLabel position := Point clone x(5) y(25)
        responseLabel color := Color black
        self addMorph(responseLabel)
        
        self changed
    )
)

// Inter-Persona Dialogue Display Morph
DialogueDisplay := Morph clone do(
    dialogueHistory := List clone
    
    initialize := method(
        self color := Color lightGray
        self borderWidth := 2
        self borderColor := Color black
        
        // Title
        titleMorph := TextMorph clone
        titleMorph contents := "Socratic Contrapunto - Inter-Persona Dialogue"
        titleMorph position := Point clone x(10) y(10)
        titleMorph color := Color black
        self addMorph(titleMorph)
        
        self
    )
    
    // Display dialogue exchange
    displayDialogue := method(dialogueResult,
        // Clear existing dialogue displays
        self submorphs select(m, m isKindOf(TextMorph) and (m contents beginsWith("BRICK:") or m contents beginsWith("ROBIN:"))) foreach(m,
            m removeFromWorld
        )
        
        // Display BRICK analysis
        brickLabel := TextMorph clone
        brickLabel contents := "BRICK: " .. self truncateText(dialogueResult brickAnalysis, 120)
        brickLabel position := Point clone x(10) y(40)
        brickLabel color := Color blue
        self addMorph(brickLabel)
        
        // Display ROBIN synthesis
        robinLabel := TextMorph clone
        robinLabel contents := "ROBIN: " .. self truncateText(dialogueResult robinSynthesis, 120)
        robinLabel position := Point clone x(10) y(80)
        robinLabel color := Color red
        self addMorph(robinLabel)
        
        // Store in history
        self dialogueHistory append(dialogueResult)
        
        self changed
    )
    
    // Utility method to truncate text for display
    truncateText := method(text, maxLength,
        if(text size > maxLength,
            text slice(0, maxLength) .. "..."
        ,
            text
        )
    )
)

// Create and launch the Morphic UI demo
launchPersonaCognitionDemo := method(
    "=== Launching Morphic UI Demo for Inter/Intra Persona Cognition ===" println
    
    // Create main canvas
    canvas := PersonaCognitionCanvas clone
    canvas initialize
    
    // Open in world
    canvas openInWorld
    
    // Instructions for user
    "Click on the canvas to run persona cognition demonstration!" println
    "- Top panels show BRICK and ROBIN internal monologues (intra-persona)" println  
    "- Bottom panel shows inter-persona dialogue (Socratic Contrapunto)" println
    "- Each facet shows its LLM parameters (temperature, top_p) and response" println
    
    canvas
)

// Launch the demo
demoCanvas := launchPersonaCognitionDemo