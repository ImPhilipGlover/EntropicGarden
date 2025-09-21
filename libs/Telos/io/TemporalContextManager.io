//
// Enhanced Temporal Context Management - BAT OS Pattern Integration
// Foundation: Exponential decay + Trust-based retention
// Integration: Dynamic temporal weighting with presentism principles
// Compliance: Pure prototypal programming with immediate usability
//

// Core Temporal Context Manager
TemporalContextManager := Object clone

// Initialize temporal weighting system
TemporalContextManager initialize := method(
    contextManager := Object clone
    contextManager recentContext := List clone  # Exponential decay
    contextManager foundationalContext := Map clone  # Trust-based retention
    contextManager associativeMemory := Map clone  # Hebbian connections
    
    # Temporal parameters (configurable)
    contextManager decayParameter := 0.1  # α for exponential decay
    contextManager trustThreshold := 0.8  # Minimum trust for retention
    contextManager maxRecentItems := 100  # Memory bounds
    contextManager cleanupFrequency := 50  # Items before cleanup
    
    # Tracking statistics
    contextManager totalItemsProcessed := 0
    contextManager decayedItemsCount := 0
    contextManager retainedItemsCount := 0
    
    contextManager
)

// Core temporal weighting function: weight = e^(-α * Δt)
TemporalContextManager calculateTemporalWeight := method(contextItem, currentTime,
    weightCalculator := Object clone
    weightCalculator item := contextItem
    weightCalculator now := currentTime
    
    # Calculate time delta (in seconds for precise weighting)
    weightCalculator deltaTime := weightCalculator now secondsSince(weightCalculator item timestamp)
    
    # Apply exponential decay: weight = e^(-α * Δt)
    import := getSlot("import")
    mathModule := import("math")
    
    weightCalculator rawWeight := mathModule exp(-self decayParameter * weightCalculator deltaTime)
    
    # Ensure weight is in valid range [0.0, 1.0]
    if(weightCalculator rawWeight < 0.0, weightCalculator rawWeight := 0.0)
    if(weightCalculator rawWeight > 1.0, weightCalculator rawWeight := 1.0)
    
    weightCalculator rawWeight
)

// Trust score calculation for foundational retention
TemporalContextManager calculateTrustScore := method(contextObj,
    trustAnalyzer := Object clone
    trustAnalyzer context := contextObj
    trustAnalyzer baseScore := 0.3  # Default trust level
    
    # Increase trust for frequently referenced content
    referenceCount := self getReferenceCount(trustAnalyzer context)
    trustAnalyzer referenceBonus := referenceCount * 0.1
    
    # Increase trust for coherent, well-structured content
    coherenceScore := self assessContentCoherence(trustAnalyzer context)
    trustAnalyzer coherenceBonus := coherenceScore * 0.2
    
    # Increase trust for content that enables other capabilities
    enablementScore := self assessEnablementPotential(trustAnalyzer context)
    trustAnalyzer enablementBonus := enablementScore * 0.3
    
    # Calculate composite trust score
    trustScore := trustAnalyzer baseScore + 
                 trustAnalyzer referenceBonus + 
                 trustAnalyzer coherenceBonus + 
                 trustAnalyzer enablementBonus
    
    # Clamp to [0.0, 1.0] range
    if(trustScore > 1.0, trustScore := 1.0)
    if(trustScore < 0.0, trustScore := 0.0)
    
    trustScore
)

// Add or update context with temporal weighting
TemporalContextManager updateContext := method(contextObj, explicitTrustScore,
    contextProcessor := Object clone
    contextProcessor content := contextObj
    contextProcessor timestamp := Date now
    contextProcessor contextId := System uniqueId
    
    # Calculate trust score (use explicit if provided)
    contextProcessor trustScore := if(explicitTrustScore != nil,
        explicitTrustScore,
        self calculateTrustScore(contextProcessor content)
    )
    
    # Create temporal context wrapper
    temporalContext := Object clone
    temporalContext content := contextProcessor content
    temporalContext timestamp := contextProcessor timestamp
    temporalContext trust := contextProcessor trustScore
    temporalContext contextId := contextProcessor contextId
    temporalContext accessCount := 1
    temporalContext lastAccessed := contextProcessor timestamp
    
    # Route based on trust level
    if(temporalContext trust >= self trustThreshold,
        # Foundational knowledge - permanent retention
        self foundationalContext atPut(temporalContext contextId, temporalContext)
        self retainedItemsCount := self retainedItemsCount + 1
        
        writeln("[Temporal] Foundational retention: " .. temporalContext content asString slice(0, 50) .. "...")
        
        # Update associative connections for foundational content
        self updateAssociativeConnections(temporalContext)
    ,
        # Recent context - exponential decay
        self recentContext append(temporalContext)
        
        writeln("[Temporal] Recent context added: " .. temporalContext content asString slice(0, 50) .. "...")
        
        # Apply decay and cleanup if needed
        if(self recentContext size >= self cleanupFrequency,
            self applyExponentialDecay
        )
    )
    
    self totalItemsProcessed := self totalItemsProcessed + 1
    
    # Log temporal context update
    Telos writeWAL("TEMPORAL_CONTEXT_UPDATE:" .. temporalContext contextId .. ":trust:" .. temporalContext trust)
    
    temporalContext
)

// Apply exponential decay to recent context
TemporalContextManager applyExponentialDecay := method(
    decayProcessor := Object clone
    decayProcessor now := Date now
    decayProcessor survivingContexts := List clone
    decayProcessor decayThreshold := 0.01  # Minimum weight to survive
    
    writeln("[Temporal] Applying exponential decay to " .. self recentContext size .. " recent contexts")
    
    self recentContext foreach(contextItem,
        # Calculate current temporal weight
        currentWeight := self calculateTemporalWeight(contextItem, decayProcessor now)
        
        if(currentWeight >= decayProcessor decayThreshold,
            # Context survives - update weight
            contextItem currentWeight := currentWeight
            contextItem lastDecayCheck := decayProcessor now
            decayProcessor survivingContexts append(contextItem)
        ,
            # Context decayed below threshold - remove
            self decayedItemsCount := self decayedItemsCount + 1
            writeln("[Temporal] Decayed context: " .. contextItem content asString slice(0, 30) .. "...")
        )
    )
    
    # Update recent context with survivors
    self recentContext := decayProcessor survivingContexts
    
    writeln("[Temporal] Decay complete: " .. decayProcessor survivingContexts size .. " contexts survived")
    
    # Log decay statistics
    Telos writeWAL("TEMPORAL_DECAY:survived:" .. decayProcessor survivingContexts size .. ":decayed:" .. (self recentContext size - decayProcessor survivingContexts size))
)

// Update Hebbian-style associative connections
TemporalContextManager updateAssociativeConnections := method(contextItem,
    associationProcessor := Object clone
    associationProcessor context := contextItem
    associationProcessor contextHash := associationProcessor context content hash
    
    # Find related contexts based on content similarity
    relatedContexts := self findRelatedContexts(associationProcessor context)
    
    # Strengthen connections between co-occurring contexts
    relatedContexts foreach(relatedContext,
        connectionKey := associationProcessor contextHash .. "-" .. relatedContext content hash
        
        # Get or initialize connection strength
        currentStrength := self associativeMemory at(connectionKey) ifNil(0.0)
        
        # Apply Hebbian strengthening: "fire together, wire together"
        newStrength := currentStrength + 0.1
        if(newStrength > 1.0, newStrength := 1.0)
        
        self associativeMemory atPut(connectionKey, newStrength)
        
        writeln("[Temporal] Strengthened association: " .. connectionKey .. " -> " .. newStrength)
    )
)

// Find contexts related to current context (content similarity)
TemporalContextManager findRelatedContexts := method(targetContext,
    relatedFinder := Object clone
    relatedFinder target := targetContext
    relatedFinder related := List clone
    relatedFinder targetWords := relatedFinder target content asString split(" ") select(word, word size > 3)
    
    # Check foundational contexts for similarity
    self foundationalContext values foreach(foundationalContext,
        similarity := self calculateContentSimilarity(relatedFinder target, foundationalContext)
        
        if(similarity > 0.3,  # Similarity threshold
            relatedFinder related append(foundationalContext)
        )
    )
    
    # Check recent contexts for similarity
    self recentContext foreach(recentContext,
        similarity := self calculateContentSimilarity(relatedFinder target, recentContext)
        
        if(similarity > 0.3,  # Similarity threshold
            relatedFinder related append(recentContext)
        )
    )
    
    relatedFinder related
)

// Calculate content similarity between contexts
TemporalContextManager calculateContentSimilarity := method(context1, context2,
    similarityCalculator := Object clone
    similarityCalculator text1 := context1 content asString lowercase split(" ")
    similarityCalculator text2 := context2 content asString lowercase split(" ")
    
    # Calculate word overlap (Jaccard similarity)
    similarityCalculator words1Set := Set with(similarityCalculator text1)
    similarityCalculator words2Set := Set with(similarityCalculator text2)
    
    similarityCalculator intersection := similarityCalculator words1Set intersection(similarityCalculator words2Set)
    similarityCalculator union := similarityCalculator words1Set union(similarityCalculator words2Set)
    
    if(similarityCalculator union size > 0,
        similarity := similarityCalculator intersection size / similarityCalculator union size
    ,
        similarity := 0.0
    )
    
    similarity
)

// Content coherence assessment (for trust calculation)
TemporalContextManager assessContentCoherence := method(contextObj,
    coherenceAnalyzer := Object clone
    coherenceAnalyzer content := contextObj
    coherenceAnalyzer text := coherenceAnalyzer content asString
    
    # Simple coherence heuristics
    coherenceScore := 0.0
    
    # Length coherence (not too short, not too long)
    if(coherenceAnalyzer text size > 20 and coherenceAnalyzer text size < 1000,
        coherenceScore := coherenceScore + 0.3
    )
    
    # Structure coherence (contains meaningful words)
    meaningfulWords := coherenceAnalyzer text split(" ") select(word, word size > 3)
    if(meaningfulWords size > 3,
        coherenceScore := coherenceScore + 0.4
    )
    
    # Consistency coherence (not contradictory)
    if(coherenceAnalyzer text containsSeq("implementation") or 
       coherenceAnalyzer text containsSeq("pattern") or 
       coherenceAnalyzer text containsSeq("principle"),
        coherenceScore := coherenceScore + 0.3
    )
    
    coherenceScore
)

// Enablement potential assessment (for trust calculation)
TemporalContextManager assessEnablementPotential := method(contextObj,
    enablementAnalyzer := Object clone
    enablementAnalyzer content := contextObj
    enablementAnalyzer text := enablementAnalyzer content asString
    
    # Enablement score based on content that enables other capabilities
    enablementScore := 0.0
    
    # Check for foundational concepts
    foundationalTerms := list("prototype", "pattern", "architecture", "algorithm", "system", "method", "framework")
    foundationalCount := foundationalTerms select(term, enablementAnalyzer text containsSeq(term)) size
    enablementScore := enablementScore + (foundationalCount * 0.1)
    
    # Check for implementation guidance
    implementationTerms := list("implementation", "example", "code", "function", "procedure", "step")
    implementationCount := implementationTerms select(term, enablementAnalyzer text containsSeq(term)) size
    enablementScore := enablementScore + (implementationCount * 0.15)
    
    # Clamp to [0.0, 1.0]
    if(enablementScore > 1.0, enablementScore := 1.0)
    
    enablementScore
)

// Get reference count for trust calculation
TemporalContextManager getReferenceCount := method(contextObj,
    # Simplified reference counting (could be enhanced with actual usage tracking)
    contextObj hash % 10  # Placeholder - returns 0-9 based on content hash
)

// Query context with temporal weighting
TemporalContextManager queryContext := method(queryText, maxResults,
    queryProcessor := Object clone
    queryProcessor query := queryText
    queryProcessor maxResults := maxResults ifNil(5)
    queryProcessor results := List clone
    queryProcessor currentTime := Date now
    
    # Search foundational contexts (always available)
    self foundationalContext values foreach(foundationalContext,
        similarity := self calculateContentSimilarity(
            Object clone do(content := queryProcessor query),
            foundationalContext
        )
        
        if(similarity > 0.1,  # Minimum relevance threshold
            result := Object clone
            result content := foundationalContext content
            result relevance := similarity
            result trust := foundationalContext trust
            result type := "foundational"
            result contextId := foundationalContext contextId
            
            queryProcessor results append(result)
        )
    )
    
    # Search recent contexts with temporal weighting
    self recentContext foreach(recentContext,
        similarity := self calculateContentSimilarity(
            Object clone do(content := queryProcessor query),
            recentContext
        )
        
        if(similarity > 0.1,  # Minimum relevance threshold
            # Apply temporal weighting to relevance
            temporalWeight := self calculateTemporalWeight(recentContext, queryProcessor currentTime)
            adjustedRelevance := similarity * temporalWeight
            
            result := Object clone
            result content := recentContext content
            result relevance := adjustedRelevance
            result temporalWeight := temporalWeight
            result type := "recent"
            result contextId := recentContext contextId
            
            queryProcessor results append(result)
        )
    )
    
    # Sort by relevance and limit results
    sortedResults := queryProcessor results sortBy(block(result, 0 - result relevance))
    topResults := sortedResults slice(0, queryProcessor maxResults)
    
    writeln("[Temporal] Query '" .. queryProcessor query .. "' returned " .. topResults size .. " results")
    
    topResults
)

// Display temporal context statistics
TemporalContextManager displayStatistics := method(
    writeln("\n=== TEMPORAL CONTEXT MANAGER STATISTICS ===")
    writeln("Recent Contexts: " .. self recentContext size)
    writeln("Foundational Contexts: " .. self foundationalContext size)
    writeln("Associative Connections: " .. self associativeMemory size)
    writeln("Total Items Processed: " .. self totalItemsProcessed)
    writeln("Decayed Items: " .. self decayedItemsCount)
    writeln("Retained Items: " .. self retainedItemsCount)
    writeln("Decay Parameter (α): " .. self decayParameter)
    writeln("Trust Threshold: " .. self trustThreshold)
    
    if(self recentContext size > 0,
        writeln("\nRecent Context Samples:")
        self recentContext slice(0, 3) foreach(context,
            writeln("  - " .. context content asString slice(0, 60) .. "... (trust: " .. context trust .. ")")
        )
    )
    
    if(self foundationalContext size > 0,
        writeln("\nFoundational Context Samples:")
        self foundationalContext values slice(0, 3) foreach(context,
            writeln("  - " .. context content asString slice(0, 60) .. "... (trust: " .. context trust .. ")")
        )
    )
    
    writeln("=== END STATISTICS ===\n")
)

// Integration with TelOS
TemporalContextManager integrateWithTelOS := method(
    writeln("=== Integrating Temporal Context Manager with TelOS ===")
    
    if(Telos != nil,
        # Add temporal context management to main Telos object
        Telos temporalContext := TemporalContextManager initialize
        
        # Add convenient access methods
        Telos addContext := method(content, trust,
            Telos temporalContext updateContext(content, trust)
        )
        
        Telos queryContext := method(query, maxResults,
            Telos temporalContext queryContext(query, maxResults)
        )
        
        Telos contextStats := method(
            Telos temporalContext displayStatistics
        )
        
        writeln("[Integration] Enhanced Telos with temporal context management")
    )
    
    # Log integration completion
    Telos writeWAL("TEMPORAL_CONTEXT_INTEGRATION:complete:" .. Date now)
    
    writeln("=== Temporal Context Integration Complete ===")
)

// Auto-launch integration on load
writeln("Loading Enhanced Temporal Context Management...")
TemporalContextManager integrateWithTelOS