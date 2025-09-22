#!/usr/bin/env io

/*
=======================================================================================
  PERSONA PRIMING SYSTEM: Curate → Summarize → Pack → Converse Pipeline
=======================================================================================

Implementation of the complete persona priming pipeline as specified in TelOS roadmap Phase 9.5:
- Curate: Filter and prepare knowledge for persona conditioning
- Summarize: Condense information into persona-digestible formats  
- Pack: Generate system prompts with persona-specific conditioning
- Converse: Enable enhanced dialogue with primed personas

Integrates with Enhanced BABS WING Loop for systematic knowledge processing.
*/

writeln("🎭 Loading Persona Priming System...")

// Persona Priming System
PersonaPrimingSystem := Object clone

PersonaPrimingSystem initialize := method(configObj,
    configAnalyzer := Object clone
    configAnalyzer config := configObj
    
    # Configuration with prototypal object wrapping
    primerConfig := Object clone
    if(configAnalyzer config != nil,
        primerConfig maxKnowledgeItems := configAnalyzer config getSlot("maxKnowledgeItems")
        primerConfig summaryDepth := configAnalyzer config getSlot("summaryDepth")  
        primerConfig personaContextWindow := configAnalyzer config getSlot("personaContextWindow")
        primerConfig enableProvenanceTracking := configAnalyzer config getSlot("enableProvenanceTracking")
    ,
        # Default configuration wrapped in objects
        maxItemsObj := Object clone; maxItemsObj value := 50; primerConfig maxKnowledgeItems := maxItemsObj value
        depthObj := Object clone; depthObj value := 3; primerConfig summaryDepth := depthObj value
        windowObj := Object clone; windowObj value := 2000; primerConfig personaContextWindow := windowObj value
        provenanceObj := Object clone; provenanceObj value := true; primerConfig enableProvenanceTracking := provenanceObj value
    )
    
    self config := primerConfig
    self curatedKnowledge := List clone
    self summaryCache := Map clone
    self systemPrompts := Map clone
    self conversationHistory := Map clone
    self provenanceMap := Map clone
    
    writeln("  ✓ Max knowledge items: ", self config maxKnowledgeItems)
    writeln("  ✓ Summary depth: ", self config summaryDepth)
    writeln("  ✓ Context window: ", self config personaContextWindow)
    writeln("  ✓ Provenance tracking: ", self config enableProvenanceTracking)
    
    self
)

# PHASE 1: CURATE - Filter and prepare knowledge
PersonaPrimingSystem curateKnowledge := method(knowledgeSourcesObj, criteriaObj,
    curationAnalyzer := Object clone
    curationAnalyzer sources := knowledgeSourcesObj
    curationAnalyzer criteria := criteriaObj
    curationAnalyzer curatedItems := List clone
    
    writeln("  📚 CURATE: Filtering knowledge from ", curationAnalyzer sources size, " sources")
    
    # Process each knowledge source
    curationAnalyzer sources foreach(source,
        sourceProcessor := Object clone
        sourceProcessor source := source
        sourceProcessor items := self extractKnowledgeFromSource(sourceProcessor source)
        
        # Apply curation criteria
        sourceProcessor items foreach(item,
            itemAnalyzer := Object clone
            itemAnalyzer item := item
            itemAnalyzer meetsQualityCriteria := self evaluateKnowledgeQuality(itemAnalyzer item, curationAnalyzer criteria)
            
            qualityChecker := Object clone
            qualityChecker meets := itemAnalyzer meetsQualityCriteria
            if(qualityChecker meets,
                # Add provenance and metadata
                curatedItem := Object clone
                curatedItem content := itemAnalyzer item content
                curatedItem source := sourceProcessor source
                curatedItem timestamp := Date now
                curatedItem quality := itemAnalyzer meetsQualityCriteria
                curatedItem type := "curated_knowledge"
                curatedItem id := "curated_" .. Date now asString hash
                
                curationAnalyzer curatedItems append(curatedItem)
                
                if(self config enableProvenanceTracking,
                    self provenanceMap atPut(curatedItem id, Map clone
                        atPut("source", sourceProcessor source)
                        atPut("curation_criteria", curationAnalyzer criteria)
                        atPut("timestamp", Date now)
                    )
                )
            )
        )
    )
    
    # Store curated knowledge
    self curatedKnowledge := curationAnalyzer curatedItems
    
    # Cap at maximum items through prototypal message passing
    itemCounter := Object clone
    itemCounter count := self curatedKnowledge size
    itemCounter max := self config maxKnowledgeItems
    
    if(itemCounter count > itemCounter max,
        cappingAnalyzer := Object clone
        cappingAnalyzer items := self curatedKnowledge
        cappingAnalyzer limit := itemCounter max
        cappingAnalyzer capped := cappingAnalyzer items slice(0, cappingAnalyzer limit)
        self curatedKnowledge := cappingAnalyzer capped
    )
    
    writeln("    ✓ Curated ", self curatedKnowledge size, " knowledge items")
    
    # Persist curation results
    if(Telos hasSlot("appendJSONL"),
        Telos appendJSONL("logs/persona_priming/curation.jsonl", Map clone
            atPut("session", "persona_priming")
            atPut("sources_processed", curationAnalyzer sources size)
            atPut("items_curated", self curatedKnowledge size)
            atPut("criteria", curationAnalyzer criteria)
            atPut("timestamp", Date now)
        )
    )
    
    curationResult := Object clone
    curationResult itemsCurated := self curatedKnowledge size
    curationResult sourcesProcessed := curationAnalyzer sources size
    curationResult items := self curatedKnowledge
    curationResult
)

# Extract knowledge items from a source
PersonaPrimingSystem extractKnowledgeFromSource := method(sourceObj,
    extractor := Object clone
    extractor source := sourceObj
    extractor items := List clone
    
    # Handle different source types through prototypal message passing
    sourceTypeAnalyzer := Object clone
    sourceTypeAnalyzer source := extractor source
    sourceTypeAnalyzer type := sourceTypeAnalyzer source getSlot("type")
    
    # Context fractal source
    if(sourceTypeAnalyzer type == "context_fractal",
        contextItem := Object clone
        contextItem content := extractor source content
        contextItem type := "context_knowledge"
        contextItem metadata := extractor source
        extractor items append(contextItem)
    )
    
    # Concept fractal source  
    if(sourceTypeAnalyzer type == "concept_fractal",
        conceptItem := Object clone
        conceptItem content := extractor source description
        conceptItem type := "concept_knowledge"
        conceptItem metadata := extractor source
        extractor items append(conceptItem)
    )
    
    # Memory search results
    if(sourceTypeAnalyzer type == "memory_search",
        extractor source results foreach(result,
            memoryItem := Object clone
            memoryItem content := result text
            memoryItem type := "memory_knowledge"
            memoryItem metadata := result
            extractor items append(memoryItem)
        )
    )
    
    # Mock extraction for demonstration
    if(extractor items size == 0,
        mockItem := Object clone
        mockItem content := "Mock knowledge from source: " .. extractor source asString
        mockItem type := "mock_knowledge"
        mockItem metadata := extractor source
        extractor items append(mockItem)
    )
    
    extractor items
)

# Evaluate knowledge quality against criteria
PersonaPrimingSystem evaluateKnowledgeQuality := method(itemObj, criteriaObj,
    qualityAnalyzer := Object clone
    qualityAnalyzer item := itemObj
    qualityAnalyzer criteria := criteriaObj
    qualityAnalyzer score := 0
    
    # Content length check
    contentLengthAnalyzer := Object clone
    contentLengthAnalyzer content := qualityAnalyzer item content
    contentLengthAnalyzer length := contentLengthAnalyzer content size
    contentLengthAnalyzer minLength := if(qualityAnalyzer criteria hasSlot("minLength"), qualityAnalyzer criteria minLength, 20)
    
    if(contentLengthAnalyzer length >= contentLengthAnalyzer minLength,
        scoreIncrementer := Object clone
        scoreIncrementer current := qualityAnalyzer score
        scoreIncrementer increment := 1
        qualityAnalyzer score := scoreIncrementer current + scoreIncrementer increment
    )
    
    # Relevance check (mock implementation)
    relevanceAnalyzer := Object clone
    relevanceAnalyzer content := qualityAnalyzer item content
    relevanceAnalyzer keywords := if(qualityAnalyzer criteria hasSlot("keywords"), qualityAnalyzer criteria keywords, list("cognitive", "neural", "fractal"))
    relevanceAnalyzer matches := 0
    
    relevanceAnalyzer keywords foreach(keyword,
        keywordChecker := Object clone
        keywordChecker content := relevanceAnalyzer content
        keywordChecker keyword := keyword
        if(keywordChecker content containsSeq(keywordChecker keyword),
            matchIncrementer := Object clone
            matchIncrementer current := relevanceAnalyzer matches
            matchIncrementer increment := 1
            relevanceAnalyzer matches := matchIncrementer current + matchIncrementer increment
        )
    )
    
    if(relevanceAnalyzer matches > 0,
        relevanceScoreIncrementer := Object clone
        relevanceScoreIncrementer current := qualityAnalyzer score
        relevanceScoreIncrementer increment := 2
        qualityAnalyzer score := relevanceScoreIncrementer current + relevanceScoreIncrementer increment
    )
    
    # Quality threshold
    qualityThreshold := Object clone
    qualityThreshold score := qualityAnalyzer score
    qualityThreshold minimum := if(qualityAnalyzer criteria hasSlot("minQuality"), qualityAnalyzer criteria minQuality, 2)
    qualityThreshold passes := qualityThreshold score >= qualityThreshold minimum
    
    qualityThreshold passes
)

# PHASE 2: SUMMARIZE - Condense information into digestible formats
PersonaPrimingSystem summarizeKnowledge := method(personaObj,
    summaryAnalyzer := Object clone
    summaryAnalyzer persona := personaObj
    summaryAnalyzer knowledgeItems := self curatedKnowledge
    summaryAnalyzer summaries := List clone
    
    writeln("  📝 SUMMARIZE: Condensing knowledge for persona: ", summaryAnalyzer persona name)
    
    # Check cache first
    cacheChecker := Object clone
    cacheChecker persona := summaryAnalyzer persona
    cacheChecker key := cacheChecker persona name
    cacheChecker cached := self summaryCache at(cacheChecker key)
    
    if(cacheChecker cached != nil,
        writeln("    📎 Using cached summary for ", cacheChecker key)
        return cacheChecker cached
    )
    
    # Create persona-specific summaries
    summaryAnalyzer knowledgeItems foreach(item,
        itemSummarizer := Object clone
        itemSummarizer item := item
        itemSummarizer persona := summaryAnalyzer persona
        itemSummarizer summary := self createPersonaSpecificSummary(itemSummarizer item, itemSummarizer persona)
        
        summaryAnalyzer summaries append(itemSummarizer summary)
    )
    
    # Consolidate summaries
    consolidatedSummary := self consolidateSummaries(summaryAnalyzer summaries, summaryAnalyzer persona)
    
    # Cache the result
    self summaryCache atPut(summaryAnalyzer persona name, consolidatedSummary)
    
    writeln("    ✓ Generated summary with ", consolidatedSummary sections size, " sections")
    
    # Persist summary
    if(Telos hasSlot("appendJSONL"),
        Telos appendJSONL("logs/persona_priming/summaries.jsonl", Map clone
            atPut("session", "persona_priming")
            atPut("persona", summaryAnalyzer persona name)
            atPut("items_processed", summaryAnalyzer knowledgeItems size)
            atPut("sections_generated", consolidatedSummary sections size)
            atPut("timestamp", Date now)
        )
    )
    
    consolidatedSummary
)

# Create persona-specific summary
PersonaPrimingSystem createPersonaSpecificSummary := method(itemObj, personaObj,
    summaryCreator := Object clone
    summaryCreator item := itemObj
    summaryCreator persona := personaObj
    
    # Tailor summary to persona characteristics
    personaAnalyzer := Object clone
    personaAnalyzer persona := summaryCreator persona
    personaAnalyzer style := personaAnalyzer persona getSlot("speakStyle")
    personaAnalyzer focus := personaAnalyzer persona getSlot("role")
    
    # Create tailored summary based on persona style
    tailoredSummary := Object clone
    tailoredSummary content := summaryCreator item content
    tailoredSummary originalItem := summaryCreator item
    tailoredSummary personaStyle := personaAnalyzer style
    tailoredSummary personaFocus := personaAnalyzer focus
    tailoredSummary timestamp := Date now
    
    # Apply persona-specific filtering and emphasis
    if(personaAnalyzer style == "technical",
        technicalSummary := Object clone
        technicalSummary content := "TECHNICAL: " .. tailoredSummary content
        tailoredSummary summary := technicalSummary content
    ,
        if(personaAnalyzer style == "creative",
            creativeSummary := Object clone
            creativeSummary content := "CREATIVE: " .. tailoredSummary content
            tailoredSummary summary := creativeSummary content
        ,
            generalSummary := Object clone
            generalSummary content := "INSIGHT: " .. tailoredSummary content
            tailoredSummary summary := generalSummary content
        )
    )
    
    tailoredSummary
)

# Consolidate multiple summaries
PersonaPrimingSystem consolidateSummaries := method(summariesObj, personaObj,
    consolidator := Object clone
    consolidator summaries := summariesObj
    consolidator persona := personaObj
    consolidator sections := List clone
    
    # Group summaries by theme or type
    themeGroups := Map clone
    
    consolidator summaries foreach(summary,
        themeAnalyzer := Object clone
        themeAnalyzer summary := summary
        themeAnalyzer theme := self extractTheme(themeAnalyzer summary)
        
        # Add to theme group
        themeAccessor := Object clone
        themeAccessor theme := themeAnalyzer theme
        themeAccessor group := themeGroups at(themeAccessor theme)
        
        if(themeAccessor group == nil,
            newGroup := List clone
            themeGroups atPut(themeAccessor theme, newGroup)
            themeAccessor group := newGroup
        )
        
        themeAccessor group append(themeAnalyzer summary)
    )
    
    # Create consolidated sections
    themeGroups keys foreach(theme,
        sectionCreator := Object clone
        sectionCreator theme := theme
        sectionCreator summaries := themeGroups at(sectionCreator theme)
        
        consolidatedSection := Object clone
        consolidatedSection theme := sectionCreator theme
        consolidatedSection summaries := sectionCreator summaries
        consolidatedSection persona := consolidator persona
        consolidatedSection timestamp := Date now
        
        consolidator sections append(consolidatedSection)
    )
    
    consolidatedResult := Object clone
    consolidatedResult sections := consolidator sections
    consolidatedResult persona := consolidator persona
    consolidatedResult totalItems := consolidator summaries size
    consolidatedResult timestamp := Date now
    
    consolidatedResult
)

# Extract theme from summary
PersonaPrimingSystem extractTheme := method(summaryObj,
    themeExtractor := Object clone
    themeExtractor summary := summaryObj
    themeExtractor content := themeExtractor summary summary
    
    # Simple theme extraction through content analysis
    themeAnalyzer := Object clone
    themeAnalyzer content := themeExtractor content
    themeAnalyzer theme := "general"
    
    # Theme classification
    if(themeAnalyzer content containsSeq("TECHNICAL"),
        technicalTheme := Object clone; technicalTheme value := "technical"; themeAnalyzer theme := technicalTheme value)
    if(themeAnalyzer content containsSeq("CREATIVE"),
        creativeTheme := Object clone; creativeTheme value := "creative"; themeAnalyzer theme := creativeTheme value)
    if(themeAnalyzer content containsSeq("cognitive") or themeAnalyzer content containsSeq("neural"),
        cognitiveTheme := Object clone; cognitiveTheme value := "cognitive"; themeAnalyzer theme := cognitiveTheme value)
    if(themeAnalyzer content containsSeq("fractal") or themeAnalyzer content containsSeq("memory"),
        fractalTheme := Object clone; fractalTheme value := "fractal"; themeAnalyzer theme := fractalTheme value)
    
    themeAnalyzer theme
)

# PHASE 3: PACK - Generate system prompts with persona conditioning
PersonaPrimingSystem packSystemPrompt := method(personaObj, summaryObj,
    promptPacker := Object clone
    promptPacker persona := personaObj
    promptPacker summary := summaryObj
    
    writeln("  📦 PACK: Generating system prompt for persona: ", promptPacker persona name)
    
    # Build persona conditioning from summary
    conditioningBuilder := Object clone
    conditioningBuilder persona := promptPacker persona
    conditioningBuilder summary := promptPacker summary
    conditioningBuilder conditioning := self buildPersonaConditioning(conditioningBuilder persona, conditioningBuilder summary)
    
    # Create system prompt structure
    systemPrompt := Object clone
    systemPrompt persona := promptPacker persona
    systemPrompt conditioning := conditioningBuilder conditioning
    systemPrompt contextWindow := self config personaContextWindow
    systemPrompt timestamp := Date now
    systemPrompt id := "prompt_" .. Date now asString hash
    
    # Format system prompt content
    promptFormatter := Object clone
    promptFormatter persona := systemPrompt persona
    promptFormatter conditioning := systemPrompt conditioning
    promptFormatter formatted := self formatSystemPrompt(promptFormatter persona, promptFormatter conditioning)
    
    systemPrompt content := promptFormatter formatted
    
    # Store system prompt
    self systemPrompts atPut(promptPacker persona name, systemPrompt)
    
    writeln("    ✓ Packed system prompt (", systemPrompt content size, " chars)")
    
    # Persist system prompt
    if(Telos hasSlot("appendJSONL"),
        Telos appendJSONL("logs/persona_priming/prompts.jsonl", Map clone
            atPut("session", "persona_priming")
            atPut("persona", promptPacker persona name)
            atPut("prompt_length", systemPrompt content size)
            atPut("sections", systemPrompt conditioning size)
            atPut("timestamp", Date now)
        )
    )
    
    systemPrompt
)

# Build persona conditioning from summary
PersonaPrimingSystem buildPersonaConditioning := method(personaObj, summaryObj,
    conditioningBuilder := Object clone
    conditioningBuilder persona := personaObj
    conditioningBuilder summary := summaryObj
    conditioningBuilder conditioning := List clone
    
    # Add persona identity conditioning
    identityConditioning := Object clone
    identityConditioning type := "identity"
    identityConditioning content := "You are " .. conditioningBuilder persona name .. ", " .. conditioningBuilder persona role
    if(conditioningBuilder persona hasSlot("ethos"),
        ethosEnhancer := Object clone
        ethosEnhancer identity := identityConditioning content
        ethosEnhancer ethos := conditioningBuilder persona ethos
        identityConditioning content := ethosEnhancer identity .. ". Your core principles: " .. ethosEnhancer ethos
    )
    conditioningBuilder conditioning append(identityConditioning)
    
    # Add knowledge conditioning from summary sections
    if(conditioningBuilder summary hasSlot("sections"),
        conditioningBuilder summary sections foreach(section,
            knowledgeConditioning := Object clone
            knowledgeConditioning type := "knowledge"
            knowledgeConditioning theme := section theme
            knowledgeConditioning content := "Knowledge in " .. section theme .. ": " .. section summaries size .. " insights available"
            conditioningBuilder conditioning append(knowledgeConditioning)
        )
    )
    
    # Add behavioral conditioning
    behavioralConditioning := Object clone
    behavioralConditioning type := "behavior"
    behavioralConditioning content := "Respond in your characteristic style"
    if(conditioningBuilder persona hasSlot("speakStyle"),
        styleEnhancer := Object clone
        styleEnhancer behavior := behavioralConditioning content
        styleEnhancer style := conditioningBuilder persona speakStyle
        behavioralConditioning content := styleEnhancer behavior .. " (" .. styleEnhancer style .. ")"
    )
    conditioningBuilder conditioning append(behavioralConditioning)
    
    conditioningBuilder conditioning
)

# Format system prompt content
PersonaPrimingSystem formatSystemPrompt := method(personaObj, conditioningObj,
    promptFormatter := Object clone
    promptFormatter persona := personaObj
    promptFormatter conditioning := conditioningObj
    promptFormatter formatted := ""
    
    # Header
    headerBuilder := Object clone
    headerBuilder content := "=== PERSONA PRIMING: " .. promptFormatter persona name .. " ===\n"
    promptFormatter formatted := headerBuilder content
    
    # Add conditioning sections
    promptFormatter conditioning foreach(section,
        sectionFormatter := Object clone
        sectionFormatter section := section
        sectionFormatter type := sectionFormatter section type asUppercase
        sectionFormatter content := sectionFormatter section content
        sectionFormatter formatted := promptFormatter formatted .. "\n" .. sectionFormatter type .. ": " .. sectionFormatter content .. "\n"
        promptFormatter formatted := sectionFormatter formatted
    )
    
    # Footer with instruction
    footerBuilder := Object clone
    footerBuilder content := promptFormatter formatted .. "\nRespond as this persona with full knowledge integration.\n"
    promptFormatter formatted := footerBuilder content
    
    promptFormatter formatted
)

# PHASE 4: CONVERSE - Enable enhanced dialogue with primed personas
PersonaPrimingSystem converseWithPrimedPersona := method(personaObj, queryObj,
    conversationAnalyzer := Object clone
    conversationAnalyzer persona := personaObj
    conversationAnalyzer query := queryObj
    
    writeln("  💬 CONVERSE: Engaging primed persona: ", conversationAnalyzer persona name)
    
    # Get system prompt
    promptRetriever := Object clone
    promptRetriever persona := conversationAnalyzer persona
    promptRetriever prompt := self systemPrompts at(promptRetriever persona name)
    
    if(promptRetriever prompt == nil,
        writeln("    ⚠️  No system prompt found, using base persona")
        promptRetriever prompt := self createBasicSystemPrompt(promptRetriever persona)
    )
    
    # Build conversation context
    contextBuilder := Object clone
    contextBuilder persona := conversationAnalyzer persona
    contextBuilder prompt := promptRetriever prompt
    contextBuilder query := conversationAnalyzer query
    contextBuilder context := self buildConversationContext(contextBuilder persona, contextBuilder prompt, contextBuilder query)
    
    # Execute conversation (mock implementation for demonstration)
    conversationExecutor := Object clone
    conversationExecutor context := contextBuilder context
    conversationExecutor response := self executePersonaConversation(conversationExecutor context)
    
    # Store conversation history
    historyManager := Object clone
    historyManager persona := conversationAnalyzer persona
    historyManager history := self conversationHistory at(historyManager persona name)
    
    if(historyManager history == nil,
        newHistory := List clone
        self conversationHistory atPut(historyManager persona name, newHistory)
        historyManager history := newHistory
    )
    
    conversationEntry := Object clone
    conversationEntry query := conversationAnalyzer query
    conversationEntry response := conversationExecutor response
    conversationEntry timestamp := Date now
    conversationEntry promptUsed := promptRetriever prompt id
    
    historyManager history append(conversationEntry)
    
    writeln("    ✓ Generated response (", conversationExecutor response size, " chars)")
    
    # Persist conversation
    if(Telos hasSlot("appendJSONL"),
        Telos appendJSONL("logs/persona_priming/conversations.jsonl", Map clone
            atPut("session", "persona_priming")
            atPut("persona", conversationAnalyzer persona name)
            atPut("query_length", conversationAnalyzer query size)
            atPut("response_length", conversationExecutor response size)
            atPut("timestamp", Date now)
        )
    )
    
    conversationResult := Object clone
    conversationResult persona := conversationAnalyzer persona
    conversationResult query := conversationAnalyzer query
    conversationResult response := conversationExecutor response
    conversationResult context := contextBuilder context
    conversationResult timestamp := Date now
    
    conversationResult
)

# Build conversation context
PersonaPrimingSystem buildConversationContext := method(personaObj, promptObj, queryObj,
    contextBuilder := Object clone
    contextBuilder persona := personaObj
    contextBuilder prompt := promptObj
    contextBuilder query := queryObj
    
    conversationContext := Object clone
    conversationContext persona := contextBuilder persona
    conversationContext systemPrompt := contextBuilder prompt content
    conversationContext userQuery := contextBuilder query
    conversationContext timestamp := Date now
    
    conversationContext
)

# Execute persona conversation (mock implementation)
PersonaPrimingSystem executePersonaConversation := method(contextObj,
    conversationProcessor := Object clone
    conversationProcessor context := contextObj
    
    # Mock response generation based on persona characteristics
    responseGenerator := Object clone
    responseGenerator persona := conversationProcessor context persona
    responseGenerator query := conversationProcessor context userQuery
    
    # Generate persona-appropriate response
    personaAnalyzer := Object clone
    personaAnalyzer persona := responseGenerator persona
    personaAnalyzer style := personaAnalyzer persona getSlot("speakStyle")
    personaAnalyzer role := personaAnalyzer persona getSlot("role")
    
    # Mock response based on persona style
    mockResponse := Object clone
    mockResponse persona := personaAnalyzer persona name
    mockResponse style := personaAnalyzer style
    mockResponse role := personaAnalyzer role
    mockResponse query := responseGenerator query
    
    # Generate style-appropriate response
    if(mockResponse style == "technical",
        technicalResponse := Object clone
        technicalResponse content := "[PRIMED_TECHNICAL_RESPONSE] As " .. mockResponse persona .. ", I analyze: " .. mockResponse query .. ". Technical implementation requires systematic approach."
        mockResponse response := technicalResponse content
    ,
        if(mockResponse style == "creative", 
            creativeResponse := Object clone
            creativeResponse content := "[PRIMED_CREATIVE_RESPONSE] As " .. mockResponse persona .. ", I envision: " .. mockResponse query .. ". Creative synthesis reveals new possibilities."
            mockResponse response := creativeResponse content
        ,
            generalResponse := Object clone
            generalResponse content := "[PRIMED_RESPONSE] As " .. mockResponse persona .. " (" .. mockResponse role .. "), regarding: " .. mockResponse query .. ". Knowledge-enhanced response generated."
            mockResponse response := generalResponse content
        )
    )
    
    mockResponse response
)

# Create basic system prompt for unprimed persona
PersonaPrimingSystem createBasicSystemPrompt := method(personaObj,
    basicPromptCreator := Object clone
    basicPromptCreator persona := personaObj
    
    basicPrompt := Object clone
    basicPrompt persona := basicPromptCreator persona
    basicPrompt content := "You are " .. basicPromptCreator persona name .. " - " .. basicPromptCreator persona role
    basicPrompt id := "basic_" .. Date now asString hash
    basicPrompt timestamp := Date now
    
    basicPrompt
)

# Complete persona priming pipeline
PersonaPrimingSystem runCompletePrimingPipeline := method(personaObj, knowledgeSourcesObj,
    pipelineAnalyzer := Object clone
    pipelineAnalyzer persona := personaObj
    pipelineAnalyzer sources := knowledgeSourcesObj
    pipelineAnalyzer startTime := Date now
    
    writeln("🎭 RUNNING COMPLETE PERSONA PRIMING PIPELINE")
    writeln("   Persona: ", pipelineAnalyzer persona name)
    writeln("   Sources: ", pipelineAnalyzer sources size)
    
    # Default curation criteria
    defaultCriteria := Object clone
    defaultCriteria minLength := 20
    defaultCriteria minQuality := 2
    defaultCriteria keywords := list("cognitive", "neural", "fractal", "prototypal", "morphic")
    
    # Phase 1: Curate
    curationResults := self curateKnowledge(pipelineAnalyzer sources, defaultCriteria)
    
    # Phase 2: Summarize  
    summaryResults := self summarizeKnowledge(pipelineAnalyzer persona)
    
    # Phase 3: Pack
    promptResults := self packSystemPrompt(pipelineAnalyzer persona, summaryResults)
    
    # Phase 4: Test conversation
    testQuery := "How should we approach the next development phase?"
    conversationResults := self converseWithPrimedPersona(pipelineAnalyzer persona, testQuery)
    
    pipelineResult := Object clone
    pipelineResult persona := pipelineAnalyzer persona name
    pipelineResult knowledgeItemsCurated := curationResults itemsCurated
    pipelineResult summaryGenerated := summaryResults != nil
    pipelineResult systemPromptCreated := promptResults != nil
    pipelineResult conversationTested := conversationResults != nil
    pipelineResult duration := Date now asNumber - pipelineAnalyzer startTime asNumber
    
    writeln("🎉 PERSONA PRIMING PIPELINE COMPLETE:")
    writeln("   Knowledge items curated: ", pipelineResult knowledgeItemsCurated)
    writeln("   Summary generated: ", pipelineResult summaryGenerated)
    writeln("   System prompt created: ", pipelineResult systemPromptCreated)
    writeln("   Conversation tested: ", pipelineResult conversationTested)
    writeln("   Duration: ", pipelineResult duration, " seconds")
    
    pipelineResult
)

# Get priming system status
PersonaPrimingSystem getStatus := method(
    statusCollector := Object clone
    statusCollector curated := self curatedKnowledge size
    statusCollector summaries := self summaryCache size
    statusCollector prompts := self systemPrompts size
    statusCollector conversations := 0
    
    # Count total conversations
    self conversationHistory keys foreach(persona,
        conversationCounter := Object clone
        conversationCounter history := self conversationHistory at(persona)
        conversationCounter count := conversationCounter history size
        conversationAdder := Object clone
        conversationAdder current := statusCollector conversations
        conversationAdder increment := conversationCounter count
        statusCollector conversations := conversationAdder current + conversationAdder increment
    )
    
    statusResult := Object clone
    statusResult curatedKnowledge := statusCollector curated
    statusResult summariesCached := statusCollector summaries
    statusResult systemPrompts := statusCollector prompts
    statusResult totalConversations := statusCollector conversations
    statusResult provenanceEntries := self provenanceMap size
    
    writeln("🎭 PERSONA PRIMING SYSTEM STATUS:")
    writeln("   Curated knowledge items: ", statusResult curatedKnowledge)
    writeln("   Cached summaries: ", statusResult summariesCached)
    writeln("   System prompts: ", statusResult systemPrompts)
    writeln("   Total conversations: ", statusResult totalConversations)
    writeln("   Provenance entries: ", statusResult provenanceEntries)
    
    statusResult
)

writeln("✓ Persona Priming System loaded")
writeln("  Available: PersonaPrimingSystem")
writeln("  Pipeline: Curate → Summarize → Pack → Converse")
writeln("  Features: Knowledge curation, persona conditioning, enhanced dialogue")
writeln("  Ready for persona priming operations")