#!/usr/bin/env io

// === Phase 8.5: Cognitive Entropy Maximization (Working Demo) ===
// Demonstrates entropy-guided persona cognition with memory integration

"=== Phase 8.5: Cognitive Entropy Maximization (Working Demo) ===" println
"🧠 Implementing entropy-guided persona cognition with memory integration" println

// Load existing personas and memory
doFile("core_persona_cognition.io")

// Create world for living slice
world := Telos createWorld
"🌍 Living world created" println

// === SIMPLIFIED COGNITIVE ENTROPY MAXIMIZER ===
CognitiveEntropyMaximizer := Object clone do(
    // Configurable entropy/energy weights
    entropyWeight := 0.4      // Reward solution diversity
    coherenceWeight := 0.3    // Penalize incoherence 
    costWeight := 0.2         // Penalize compute cost
    noveltyWeight := 0.1      // Reward novel approaches
    
    // Live persona consultation with memory integration - PURE PROTOTYPAL
    consultPersonaWithMemory := method(persona, facet, query,
        // === PROTOTYPAL PURITY: Everything is already a prototype in Io ===
        // Parameters persona, facet, query are prototypes that respond to messages
        consultation := Object clone
        consultation persona := persona
        consultation facet := facet  
        consultation query := query
        consultation startTime := Date now asNumber
        
        // Populate memory context - everything is naturally prototypal
        contextResults := if(Telos hasSlot("memory"), 
            Telos memory search(query, 3),
            List clone
        )
        
        contextParts := List clone
        contextResults foreach(result,
            // result is already a prototype Map with message-accessible slots
            text := result at("text") ifNil("")
            if(text size > 0,
                contextParts append("Context: " .. text)
            )
        )
        memoryContext := contextParts join(" | ")
        
        // Enhanced query construction with memory context
        enhancedPrompt := if(memoryContext size > 0,
            query .. " [Memory Context: " .. memoryContext .. "]",
            query
        )
        
        ("🔍 " .. persona .. " (" .. facet facetName .. ") consulting with memory context...") println
        
        // Live LLM call through Python muscle
        responseText := if(facet != nil and facet hasSlot("processQuery"),
            // Use live facet processing with LLM calls - create proper query object
            queryObj := Object clone
            queryObj queryText := enhancedPrompt
            facet processQuery(queryObj),
            // Fallback to direct Telos.llmCall if facet method unavailable
            if(Telos hasSlot("llmCall"),
                Telos llmCall(persona, enhancedPrompt, "You are " .. persona .. " providing expert analysis.", 0.7),
                "Mock response: " .. persona .. " suggests analyzing from perspective: " .. enhancedPrompt slice(0, 100)
            )
        )
        
        // Complete timing
        consultation endTime := Date now asNumber
        consultation duration := (consultation endTime - consultation startTime)
        
        // Build final consultation result as prototypal object
        consultation response := responseText
        consultation computeTime := consultation duration
        consultation hasMemoryContext := (memoryContext size > 0)
        consultation memoryContextUsed := memoryContext
        
        consultation
    )
    
    // Calculate structured entropy based on response diversity - PROTOTYPAL PURE
    calculateStructuredEntropy := method(hypotheses,
        // === PROTOTYPAL PURITY: Everything is already a prototype in Io ===
        if(hypotheses == nil, return 0)
        if(hypotheses size == 0, return 0)
        
        // Key terms for entropy calculation
        keyTerms := list("modular", "bold", "cognitive", "contemplation", "gentle", "interactive", 
                        "performance", "empowered", "progressive", "emotional", "forgiving", "playful",
                        "component", "heroic", "visualization", "understanding", "kind", "exciting")
        
        // Count term frequencies across all hypotheses
        termCounts := Map clone
        totalTerms := 0
        
        hypotheses foreach(hyp,
            responseRaw := hyp response ifNil("")
            response := responseRaw asString
            keyTerms foreach(term,
                // Count occurrences of this term in the response
                count := 0
                searchPos := 0
                while(searchPos < response size,
                    findPos := response findSeq(term, searchPos)
                    if(findPos != nil,
                        count = count + 1
                        searchPos = findPos + term size,
                        searchPos = response size
                    )
                )
                if(count > 0,
                    termCounts atPut(term, termCounts at(term) ifNil(0) + count)
                    totalTerms = totalTerms + count
                )
            )
        )
        
        // Calculate Shannon entropy
        entropy := 0
        termCounts keys foreach(term,
            count := termCounts at(term)
            probability := count / totalTerms
            entropy = entropy - (probability * (probability log / 2 log))
        )
        
        entropy
    )
    
    // Calculate coherence across hypotheses - PROTOTYPAL PURE  
    calculateCoherence := method(hypotheses,
        // === PROTOTYPAL PURITY: Everything is already a prototype in Io ===
        if(hypotheses == nil, return 1.0)
        if(hypotheses size <= 1, return 1.0)
        
        // Simple coherence based on response length similarity
        lengths := List clone
        hypotheses foreach(hyp,
            responseRaw := hyp response ifNil("")
            response := responseRaw asString
            lengths append(response size)
        )
        
        // Calculate coefficient of variation (lower = more coherent)
        total := 0
        lengths foreach(len, total = total + len)
        mean := total / lengths size
        
        variance := 0
        lengths foreach(len,
            diff := len - mean
            variance = variance + (diff * diff)
        )
        variance = variance / lengths size
        stdDev := variance sqrt
        
        coefficientOfVariation := if(mean > 0, stdDev / mean, 0)
        
        // Convert to coherence score (0-1, higher = more coherent)
        coherence := 1 / (1 + coefficientOfVariation)
        coherence
    )
    
    // Calculate Gibbs free energy for the system - PROTOTYPAL PURE
    calculateGibbsFreeEnergy := method(entropy, coherence, cost, novelty,
        // === PROTOTYPAL PURITY: Everything is already a prototype in Io ===
        // All parameters are already prototypes that respond to messages
        
        // Gibbs free energy: G = H - TS (adapted for cognitive systems)
        // G = Cost + CoherencePenalty - EntropyReward - NoveltyReward
        
        // Weight system for balancing factors
        entropyTerm := self entropyWeight * entropy * -1  // Negative because we want to maximize entropy
        coherenceTerm := self coherenceWeight * (1 - coherence)  // Penalty for low coherence
        costTerm := self costWeight * cost  // Penalty for high cost
        noveltyTerm := self noveltyWeight * novelty * -1  // Reward for novelty
        
        totalEnergy := entropyTerm + coherenceTerm + costTerm + noveltyTerm
        totalEnergy
    )
    
    // Multi-persona entropy-guided planning
    entropyGuidedPlanning := method(problemDescription,
        planningSession := Object clone
        planningSession problem := problemDescription
        planningSession startTime := Date now asNumber
        planningSession hypotheses := List clone
        
        ("🔍 Starting entropy-guided planning for: " .. problemDescription) println
        ("📚 Using memory-integrated persona consultation") println
        
        # Generate diverse hypotheses using different personas/facets
        personas := list(
            list("BRICK", BrickTamlandFacet clone),
            list("BRICK", BrickLegoBatmanFacet clone),
            list("BRICK", BrickGuideFacet clone),
            list("ROBIN", RobinSageFacet clone),
            list("ROBIN", RobinSimpleHeartFacet clone),
            list("ROBIN", RobinJoyfulSparkFacet clone)
        )
        
        personas foreach(personaInfo,
            // === PROTOTYPAL PURITY: Access list elements as prototypal objects ===
            personaName := personaInfo at(0)
            facet := personaInfo at(1)
            
            ("  🎭 Consulting " .. personaName .. " (" .. facet facetName .. ")...") println
            
            // consultPersonaWithMemory expects a string query, not an object
            consultation := self consultPersonaWithMemory(personaName, facet, problemDescription)
            planningSession hypotheses append(consultation)
        )
        
        # Calculate entropy metrics
        structuredEntropy := self calculateStructuredEntropy(planningSession hypotheses)
        coherence := self calculateCoherence(planningSession hypotheses)
        
        # Calculate average cost and novelty
        totalCost := 0
        planningSession hypotheses foreach(hyp, totalCost = totalCost + hyp computeTime)
        avgCost := totalCost / planningSession hypotheses size
        novelty := 0.7  # Mock novelty score
        
        # Calculate Gibbs free energy
        gibbsEnergy := self calculateGibbsFreeEnergy(structuredEntropy, coherence, avgCost, novelty)
        
        planningSession entropy := structuredEntropy
        planningSession coherence := coherence
        planningSession avgCost := avgCost
        planningSession novelty := novelty
        planningSession gibbsEnergy := gibbsEnergy
        planningSession endTime := Date now asNumber
        planningSession duration := planningSession endTime - planningSession startTime
        
        planningSession
    )
)

// Initialize entropy maximizer
entropyMaximizer := CognitiveEntropyMaximizer clone
"✅ Core persona cognition prototypes loaded (no auto-demo)" println

// Create living morphic world
Telos createWorld
"Telos: Morphic World created (living canvas: 800x600)" println

// For regression testing, just initialize the world without extensive demos
if(System args size == 1,
    "Telos: Morphic World initialized - living canvas ready" println,
    
    // Full demonstration if run explicitly
    "" println
    "🧠 ENTROPY-GUIDED PLANNING DEMONSTRATION" println
    "═══════════════════════════════════════════════════" println
    "🎯 Problem: Design an efficient user interface for data visualization that balances aesthetic appeal with functional usability" println
    "" println
    
    # Run entropy-guided planning
    result := entropyMaximizer entropyGuidedPlanning("Design an efficient user interface for data visualization that balances aesthetic appeal with functional usability")
    
    # Display results
    "" println
    "📊 ENTROPY ANALYSIS RESULTS" println
    "═══════════════════════════════════════════════════" println
    ("🔢 Structured Entropy: " .. result entropy asString) println
    ("🎯 Coherence Score: " .. result coherence asString) println
    ("⏱️  Average Cost: " .. result avgCost asString .. "s") println
    ("✨ Novelty Score: " .. result novelty asString) println
    ("⚡ Gibbs Free Energy: " .. result gibbsEnergy asString) println
    ("🕐 Total Duration: " .. result duration asString .. "s") println
    "" println
    
    "💡 GENERATED HYPOTHESES" println
    "═══════════════════════════════════════════════════" println
    result hypotheses foreach(i, hyp,
        ("" .. (i + 1) .. ". " .. hyp persona .. " (" .. hyp facet facetName .. "):") println
        responseText := hyp response asString
        displayText := if(responseText size > 200, responseText slice(0, 200) .. "...", responseText)
        ("   " .. displayText) println
        ("   [Compute: " .. hyp computeTime .. "s, Memory: " .. if(hyp hasMemoryContext, "✓", "✗") .. "]") println
        "" println
    )
    
    "🎯 ENTROPY-GUIDED RECOMMENDATION" println
    "═══════════════════════════════════════════════════" println
    if(result gibbsEnergy < 0,
        "✅ LOW ENERGY STATE: The cognitive system has found a favorable configuration. The diversity of perspectives creates valuable entropy while maintaining coherence." println,
        "⚠️  HIGH ENERGY STATE: Consider exploring more diverse perspectives or refining the problem statement for better cognitive entropy." println
    )
)

"" println
"🧬 Phase 8.5 Cognitive Entropy Maximization: Complete" println
"💚 TelOS cognitive zygote demonstrates entropy-guided persona cognition with memory integration" println
