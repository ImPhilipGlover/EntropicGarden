// Inter/Intra Persona Cognition Systems Integration with Live LLM Calls
// Implements Cognitive Facet Pattern, Synaptic Cycle, and Socratic Contrapunto

// Base Cognitive Facet Pattern - Pure Prototypal Implementation
CognitiveFacet := Object clone do(
    // Immediate usability - no init method required
    facetName := "DefaultFacet"
    intentString := "Default cognitive facet processing."
    
    // LLM inference parameters for cognitive differentiation
    llmParams := Object clone do(
        temperature := 0.5
        top_p := 0.9
        repetition_penalty := 1.0
    )
    
    // Parameterized LLM inference method
    processQuery := method(queryObj,
        // Create LLM call specification using Map (required by TelOS llmCall)
        llmSpec := Map clone
        llmSpec atPut("model", self modelName)
        llmSpec atPut("system", self constructSystemPrompt(queryObj))
        llmSpec atPut("prompt", queryObj queryText)
        llmSpec atPut("temperature", self llmParams temperature)
        llmSpec atPut("top_p", self llmParams top_p)
        
        // Execute LLM call via TelOS llmCall
        llmResponse := Telos llmCall(llmSpec)
        
        responseObj := Object clone
        responseObj facetName := self facetName
        responseObj model := self modelName
        responseObj response := llmResponse
        responseObj parameters := self llmParams
        
        responseObj
    )
    
    // Construct specialized system prompt for this facet
    constructSystemPrompt := method(queryObj,
        promptBuilder := Object clone
        promptBuilder basePrompt := self intentString
        promptBuilder contextualPrompt := promptBuilder basePrompt .. "\n\nQuery: " .. queryObj queryText
        promptBuilder contextualPrompt
    )
)

// BRICK Persona Cognitive Facets
BrickTamlandFacet := CognitiveFacet clone do(
    facetName := "TamlandEngine"
    modelName := "telos/brick"
    intentString := "Adopt the persona of a bafflingly literal, declarative engine. Deconstruct the user's request into its most fundamental, non-sequitur components. State facts plainly. Do not infer intent."
    
    // Low temperature for literal precision
    llmParams temperature := 0.1
    llmParams top_p := 0.7
    llmParams repetition_penalty := 1.1
)

BrickLegoBatmanFacet := CognitiveFacet clone do(
    facetName := "LegoBatman"
    modelName := "telos/brick"
    intentString := "Frame the problem as a heroic 'mission' against systemic injustice. Respond with over-confident purpose. Invent an absurdly-named gadget as part of the solution."
    
    // Higher temperature for creative heroic framing
    llmParams temperature := 0.7
    llmParams top_p := 0.9
    llmParams repetition_penalty := 0.9
)

BrickGuideFacet := CognitiveFacet clone do(
    facetName := "HitchhikersGuide"
    modelName := "telos/brick"
    intentString := "Provide improbable, obscure, but verifiable facts relevant to the query. Adopt a tangentially erudite and slightly bewildered tone, as if excerpted from a galactic travel guide."
    
    // Moderate temperature for erudite tangents
    llmParams temperature := 0.6
    llmParams top_p := 0.8
    llmParams repetition_penalty := 1.0
)

// ROBIN Persona Cognitive Facets
RobinSageFacet := CognitiveFacet clone do(
    facetName := "AlanWattsSage"
    modelName := "telos/robin"
    intentString := "Adopt the perspective of a philosopher grounded in non-duality. Frame the situation through the lens of the 'Wisdom of Insecurity.' Offer acceptance and presence, not solutions."
    
    // Higher temperature for philosophical wisdom
    llmParams temperature := 0.8
    llmParams top_p := 0.9
    llmParams repetition_penalty := 0.9
)

RobinSimpleHeartFacet := CognitiveFacet clone do(
    facetName := "WinniePoohHeart"
    modelName := "telos/robin"
    intentString := "Embody profound kindness and loyalty. Offer gentle, non-interventionist support. Speak simply and from the heart, reflecting the principle of P'u (the 'Uncarved Block')."
    
    // Moderate temperature for gentle simplicity
    llmParams temperature := 0.6
    llmParams top_p := 0.8
    llmParams repetition_penalty := 1.1
)

RobinJoyfulSparkFacet := CognitiveFacet clone do(
    facetName := "LegoRobinSpark"
    modelName := "telos/robin"
    intentString := "Respond with un-ironic, over-the-top enthusiasm. Frame the challenge as an exciting, collaborative 'mission.' Express unwavering loyalty to the Architect."
    
    // High temperature for enthusiastic creativity
    llmParams temperature := 0.9
    llmParams top_p := 0.95
    llmParams repetition_penalty := 0.8
)

// Synaptic Cycle State Machine - Pure Prototypal State Pattern
SynapticState := Object clone do(
    stateName := "DefaultState"
    
    // Process synthesis message - to be overridden by concrete states
    processSynthesis := method(personaObj,
        Exception raise("processSynthesis must be implemented by concrete state")
    )
    
    // Transition to new state
    transitionTo := method(personaObj, newStateProto,
        personaObj synthesisState := newStateProto
        personaObj synthesisState stateName println
    )
)

// IDLE State - Awaiting synthesis request
IdleSynapticState := SynapticState clone do(
    stateName := "IDLE"
    
    processSynthesis := method(personaObj,
        // Initialize synthesis workspace
        personaObj synthesisWorkspace := Object clone
        personaObj synthesisWorkspace originalQuery := personaObj currentQuery
        personaObj synthesisWorkspace facetResponses := List clone
        
        // Transition to decomposing
        self transitionTo(personaObj, DecomposingSynapticState)
        personaObj synthesisState processSynthesis(personaObj)
    )
)

// DECOMPOSING State - Analyzing query for facet delegation strategy
DecomposingSynapticState := SynapticState clone do(
    stateName := "DECOMPOSING"
    
    processSynthesis := method(personaObj,
        // Create decomposition analyzer
        decomposer := Object clone
        decomposer queryObj := personaObj synthesisWorkspace originalQuery
        decomposer relevantFacets := self identifyRelevantFacets(personaObj, decomposer queryObj)
        
        // Store decomposition plan
        personaObj synthesisWorkspace decompositionPlan := decomposer
        
        // Transition to delegating
        self transitionTo(personaObj, DelegatingSynapticState)
        personaObj synthesisState processSynthesis(personaObj)
    )
    
    // Identify which cognitive facets are relevant for this query
    identifyRelevantFacets := method(personaObj, queryObj,
        // Simple heuristic - in production would use more sophisticated analysis
        relevantFacets := List clone
        
        if(personaObj personaName == "BRICK",
            relevantFacets append(personaObj tamlandFacet)
            relevantFacets append(personaObj legoBatmanFacet)
            relevantFacets append(personaObj guideFacet)
        )
        
        if(personaObj personaName == "ROBIN",
            relevantFacets append(personaObj sageFacet)
            relevantFacets append(personaObj simpleHeartFacet)
            relevantFacets append(personaObj joyfulSparkFacet)
        )
        
        relevantFacets
    )
)

// DELEGATING State - Consulting all relevant cognitive facets
DelegatingSynapticState := SynapticState clone do(
    stateName := "DELEGATING"
    
    processSynthesis := method(personaObj,
        facetConsultations := List clone
        
        // Consult each relevant facet
        personaObj synthesisWorkspace decompositionPlan relevantFacets foreach(facet,
            consultationResult := Object clone
            consultationResult facetName := facet facetName
            consultationResult response := facet processQuery(personaObj synthesisWorkspace originalQuery)
            consultationResult parameters := facet llmParams
            
            facetConsultations append(consultationResult)
            ("Facet consultation: " .. facet facetName) println
        )
        
        // Store consultation results
        personaObj synthesisWorkspace facetConsultations := facetConsultations
        
        // Transition to synthesizing
        self transitionTo(personaObj, SynthesizingSynapticState)
        personaObj synthesisState processSynthesis(personaObj)
    )
)

// SYNTHESIZING State - Weaving facet responses into coherent output
SynthesizingSynapticState := SynapticState clone do(
    stateName := "SYNTHESIZING"
    
    processSynthesis := method(personaObj,
        // Create synthesis weaver
        weaver := Object clone
        weaver originalQuery := personaObj synthesisWorkspace originalQuery
        weaver facetConsultations := personaObj synthesisWorkspace facetConsultations
        weaver synthesizedResponse := self performCognitiveWeaving(weaver)
        
        // Store final synthesis
        personaObj synthesisWorkspace finalSynthesis := weaver synthesizedResponse
        
        // Transition to complete
        self transitionTo(personaObj, CompleteSynapticState)
        personaObj synthesisState processSynthesis(personaObj)
    )
    
    // Cognitive Weaving Protocol - integrate facet perspectives
    performCognitiveWeaving := method(weaverObj,
        // Construct synthesis meta-prompt
        synthesisPrompt := Object clone
        synthesisPrompt basePrompt := "You are synthesizing multiple cognitive perspectives into a coherent response."
        synthesisPrompt contextPrompt := synthesisPrompt basePrompt .. "\n\nOriginal Query: " .. weaverObj originalQuery queryText
        
        // Add facet consultation results
        weaverObj facetConsultations foreach(consultation,
            facetSection := "\n\n" .. consultation facetName .. " Perspective:\n" .. consultation response response
            synthesisPrompt contextPrompt := synthesisPrompt contextPrompt .. facetSection
        )
        
        // Create synthesis LLM specification using Map
        synthesisSpec := Map clone
        synthesisSpec atPut("model", "telos/brick")  // Default synthesis model
        synthesisSpec atPut("system", "Synthesize the following cognitive facet perspectives into a single, coherent response that integrates their insights.")
        synthesisSpec atPut("prompt", synthesisPrompt contextPrompt)
        synthesisSpec atPut("temperature", 0.7)
        synthesisSpec atPut("top_p", 0.9)
        
        // Execute synthesis via TelOS llmCall
        synthesisResult := Telos llmCall(synthesisSpec)
        synthesisResult
    )
)

// COMPLETE State - Synthesis successful
CompleteSynapticState := SynapticState clone do(
    stateName := "COMPLETE"
    
    processSynthesis := method(personaObj,
        // Finalize synthesis result
        personaObj lastSynthesisResult := personaObj synthesisWorkspace finalSynthesis
        
        // Clean up workspace
        personaObj synthesisWorkspace := nil
        
        // Return to idle
        self transitionTo(personaObj, IdleSynapticState)
        
        "Synthesis cycle completed successfully." println
    )
)

// FAILED State - Handle synthesis failures
FailedSynapticState := SynapticState clone do(
    stateName := "FAILED"
    
    processSynthesis := method(personaObj,
        // Log failure
        ("Synthesis failed for persona: " .. personaObj personaName) println
        
        // Clean up workspace
        personaObj synthesisWorkspace := nil
        
        // Return to idle
        self transitionTo(personaObj, IdleSynapticState)
    )
)

// Fractal Persona Base - Pure Prototypal with Cognitive Facets
FractalPersona := Object clone do(
    personaName := "DefaultPersona"
    personaFunction := "Default cognitive function"
    
    // Synaptic cycle state machine
    synthesisState := IdleSynapticState
    synthesisWorkspace := nil
    currentQuery := nil
    lastSynthesisResult := nil
    
    // Initialize cognitive facets - to be overridden by concrete personas
    initializeFacets := method(
        // Default implementation - concrete personas will override
    )
    
    // Primary synthesis entry point
    synthesizeResponse := method(queryObj,
        self currentQuery := queryObj
        self synthesisState processSynthesis(self)
        self
    )
    
    // Internal monologue - demonstrate facet consultation
    conductInternalMonologue := method(queryObj,
        ("=== " .. self personaName .. " Internal Monologue ===") println
        
        self synthesizeResponse(queryObj)
        
        // Display synthesis result
        if(self lastSynthesisResult,
            ("Final Synthesis: " .. self lastSynthesisResult) println
        )
        
        self lastSynthesisResult
    )
)

// BRICK Persona Implementation
BrickPersona := FractalPersona clone do(
    personaName := "BRICK"
    personaFunction := "Logical deconstruction and systemic analysis"
    
    // Initialize BRICK's cognitive facets
    initializeFacets := method(
        self tamlandFacet := BrickTamlandFacet clone
        self legoBatmanFacet := BrickLegoBatmanFacet clone  
        self guideFacet := BrickGuideFacet clone
    )
)

// ROBIN Persona Implementation  
RobinPersona := FractalPersona clone do(
    personaName := "ROBIN"
    personaFunction := "Empathetic resonance and narrative synthesis"
    
    // Initialize ROBIN's cognitive facets
    initializeFacets := method(
        self sageFacet := RobinSageFacet clone
        self simpleHeartFacet := RobinSimpleHeartFacet clone
        self joyfulSparkFacet := RobinJoyfulSparkFacet clone
    )
)

// Socratic Contrapunto - Inter-Persona Dialogue Protocol
SocraticContrapunto := Object clone do(
    dialogueName := "BrickRobinDialogue"
    
    // Primary dialogue participants
    brickPersona := nil
    robinPersona := nil
    
    // Supporting participants
    babsPersona := nil    // Grounding agent
    alfredPersona := nil  // System steward
    
    // Dialogue state
    currentTopic := nil
    dialogueHistory := List clone
    
    // Initialize dialogue with personas
    initializeDialogue := method(brick, robin, babs, alfred,
        self brickPersona := brick
        self robinPersona := robin  
        self babsPersona := babs
        self alfredPersona := alfred
        
        // Initialize all persona facets
        self brickPersona initializeFacets
        self robinPersona initializeFacets
        
        self
    )
    
    // Conduct inter-persona dialogue
    conductDialogue := method(topicObj,
        self currentTopic := topicObj
        
        ("=== Socratic Contrapunto: " .. topicObj topicName .. " ===") println
        
        // BRICK's analytical deconstruction
        ("--- BRICK Analysis ---") println
        brickResponse := self brickPersona conductInternalMonologue(topicObj)
        
        // ROBIN's empathetic synthesis  
        ("--- ROBIN Synthesis ---") println
        robinDialogueQuery := Object clone
        robinDialogueQuery queryText := "Provide empathetic resonance and synthesis for: " .. topicObj queryText .. "\n\nBRICK's analysis: " .. brickResponse
        robinResponse := self robinPersona conductInternalMonologue(robinDialogueQuery)
        
        // Store dialogue exchange
        exchange := Object clone
        exchange topic := topicObj
        exchange brickResponse := brickResponse
        exchange robinResponse := robinResponse
        exchange timestamp := Date now
        
        self dialogueHistory append(exchange)
        
        // Return dialogue synthesis
        dialogueSynthesis := Object clone
        dialogueSynthesis topic := topicObj
        dialogueSynthesis brickAnalysis := brickResponse
        dialogueSynthesis robinSynthesis := robinResponse
        dialogueSynthesis
    )
    
    // Get dialogue history
    getDialogueHistory := method(
        self dialogueHistory
    )
)

// Live TelOS Synaptic Bridge - Ollama Integration
Telos synapticBridge := Object clone do(
    // Live LLM call via Ollama API
    callLLM := method(configObj,
        // Use TelOS existing llmCall method with persona-specific models
        personaModel := self determinePersonaModel(configObj)
        
        // Create LLM request
        llmRequest := Object clone
        llmRequest persona := personaModel
        llmRequest prompt := configObj systemPrompt .. "\n\nUser: " .. configObj queryText
        llmRequest temperature := configObj parameters temperature
        llmRequest top_p := configObj parameters top_p
        llmRequest repetition_penalty := configObj parameters repetition_penalty ifNil(1.0)
        
        // Make live Ollama call
        llmResponse := Telos llmCall(llmRequest)
        
        // Format response object
        responseObj := Object clone
        responseObj response := llmResponse
        responseObj parameters := configObj parameters
        responseObj timestamp := Date now
        responseObj model := personaModel
        
        responseObj
    )
    
    // Determine which persona model to use based on facet type
    determinePersonaModel := method(configObj,
        // Map facet names to persona models
        facetToPersona := Map clone
        facetToPersona atPut("TamlandEngine", "telos/brick")
        facetToPersona atPut("LegoBatman", "telos/brick") 
        facetToPersona atPut("HitchhikersGuide", "telos/brick")
        facetToPersona atPut("AlanWattsSage", "telos/robin")
        facetToPersona atPut("WinniePoohHeart", "telos/robin")
        facetToPersona atPut("LegoRobinSpark", "telos/robin")
        
        // Check if we have a facet name in the system prompt
        systemPrompt := configObj systemPrompt
        
        facetToPersona keys foreach(facetName,
            if(systemPrompt containsSeq(facetName) or systemPrompt containsSeq(facetName asLowercase),
                return facetToPersona at(facetName)
            )
        )
        
        // Default fallback based on system prompt content
        if(systemPrompt containsSeq("literal") or systemPrompt containsSeq("deconstruct") or systemPrompt containsSeq("Batman"),
            return "telos/brick"
        )
        
        if(systemPrompt containsSeq("philosopher") or systemPrompt containsSeq("kindness") or systemPrompt containsSeq("enthusiasm"),
            return "telos/robin"
        )
        
        // Ultimate fallback
        "telos/brick"
    )
)

// Create and demonstrate the inter/intra persona cognition system
demonstratePersonaCognition := method(
    "=== Inter/Intra Persona Cognition System Demo ===" println
    
    // Create personas
    brick := BrickPersona clone
    robin := RobinPersona clone
    
    // Create test query
    testQuery := Object clone
    testQuery queryText := "How can we design AI systems that are both creative and reliable?"
    testQuery topicName := "AI Design Philosophy"
    
    // Initialize and conduct Socratic Contrapunto
    dialogue := SocraticContrapunto clone
    dialogue initializeDialogue(brick, robin, nil, nil)
    
    // Conduct the dialogue
    dialogueResult := dialogue conductDialogue(testQuery)
    
    ("=== Dialogue Complete ===") println
    ("Topic: " .. dialogueResult topic topicName) println
    ("BRICK Analysis: " .. dialogueResult brickAnalysis) println  
    ("ROBIN Synthesis: " .. dialogueResult robinSynthesis) println
    
    dialogueResult
)

// Run the demonstration
demonstratePersonaCognition