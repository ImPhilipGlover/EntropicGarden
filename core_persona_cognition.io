// Core Inter/Intra Persona Cognition Systems - No Auto Demo
// Pure prototypal implementation for live testing

// Base Cognitive Facet Pattern - Pure Prototypal Implementation
CognitiveFacet := Object clone do(
    // Immediate usability - no init method required
    facetName := "DefaultFacet"
    modelName := "telos/robin"
    intentString := "Default cognitive facet intent"
    llmParams := Object clone do(
        temperature := 0.7
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

"✅ Core persona cognition prototypes loaded (no auto-demo)" println