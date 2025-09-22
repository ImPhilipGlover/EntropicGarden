// Morphic Memory Browser - Visual Interface for VSA-RAG Memory Substrate
// Direct manipulation of vectors, concepts, and semantic relationships

doFile("libs/Telos/io/VSAMemory.io")

// Visual Memory Browser Prototype
MemoryBrowser := Object clone do(
    // UI State
    canvas := nil
    memory := nil
    selectedConcept := nil
    searchQuery := ""
    displayMode := "graph"  // "graph", "list", "cluster"
    
    // Visual Elements
    conceptMorphs := Map clone
    relationshipLines := List clone
    searchBox := nil
    resultsList := nil
    
    initialize := method(canvasObj,
        writeln("MemoryBrowser: Initializing visual memory interface...")
        
        // Setup UI infrastructure
        canvasHandler := Object clone
        canvasHandler canvas := canvasObj
        self canvas = canvasHandler canvas
        
        // Initialize memory substrate
        self memory = VSAMemory clone
        self memory initialize
        
        // Create UI components
        self createInterface
        
        writeln("MemoryBrowser: Visual interface ready")
        self
    )
    
    createInterface := method(
        // Create search interface
        searchInterface := Object clone
        searchInterface x := 10
        searchInterface y := 10
        searchInterface width := 300
        searchInterface height := 30
        
        searchBoxMorph := RectangleMorph clone
        searchBoxMorph position = List clone append(searchInterface x, searchInterface y)
        searchBoxMorph size = List clone append(searchInterface width, searchInterface height)
        searchBoxMorph color = "lightgray"
        searchBoxMorph id = "searchBox"
        
        self canvas world addSubmorph(searchBoxMorph)
        self searchBox = searchBoxMorph
        
        // Create results display area
        resultsArea := Object clone
        resultsArea x := 10
        resultsArea y := 50
        resultsArea width := 780
        resultsArea height := 540
        
        resultsContainer := RectangleMorph clone
        resultsContainer position = List clone append(resultsArea x, resultsArea y)
        resultsContainer size = List clone append(resultsArea width, resultsArea height)
        resultsContainer color = "white"
        resultsContainer id = "resultsContainer"
        
        self canvas world addSubmorph(resultsContainer)
        self resultsList = resultsContainer
        
        // Create control panel
        controlPanel := Object clone
        controlPanel x := 320
        controlPanel y := 10
        controlPanel width := 200
        controlPanel height := 30
        
        controlMorph := RectangleMorph clone
        controlMorph position = List clone append(controlPanel x, controlPanel y)
        controlMorph size = List clone append(controlPanel width, controlPanel height)
        controlMorph color = "lightblue"
        controlMorph id = "controlPanel"
        
        self canvas world addSubmorph(controlMorph)
        
        self
    )
    
    addConcept := method(contentObj, metadataObj,
        // Add concept to memory and visualize
        conceptProcessor := Object clone
        conceptProcessor content := contentObj
        conceptProcessor metadata := if(metadataObj, metadataObj, Map clone)
        
        // Store in memory substrate
        conceptProcessor storageResult := self memory store(conceptProcessor content, conceptProcessor metadata)
        
        // Create visual representation
        conceptProcessor visualMorph := self createConceptMorph(conceptProcessor storageResult)
        
        // Add to display
        self resultsList addSubmorph(conceptProcessor visualMorph)
        self conceptMorphs atPut(conceptProcessor storageResult vectorId, conceptProcessor visualMorph)
        
        conceptProcessor storageResult
    )
    
    createConceptMorph := method(conceptObj,
        // Create visual morph for a concept
        visualizer := Object clone
        visualizer concept := conceptObj
        visualizer morphWidth := 120
        visualizer morphHeight := 80
        
        // Calculate position (simple grid layout for now)
        visualizer conceptCount := self conceptMorphs size
        visualizer row := (visualizer conceptCount / 6) floor
        visualizer col := visualizer conceptCount % 6
        visualizer x := 20 + (visualizer col * 130)
        visualizer y := 70 + (visualizer row * 90)
        
        // Create concept morph
        conceptMorph := RectangleMorph clone
        conceptMorph position = List clone append(visualizer x, visualizer y)
        conceptMorph size = List clone append(visualizer morphWidth, visualizer morphHeight)
        conceptMorph color = "lightyellow"
        conceptMorph id = "concept_" .. visualizer concept vectorId
        
        // Add text label
        textMorph := TextMorph clone
        textMorph position = List clone append(visualizer x + 5, visualizer y + 5)
        textMorph text = visualizer concept content asString slice(0, 40) .. "..."
        textMorph id = "text_" .. visualizer concept vectorId
        
        conceptMorph addSubmorph(textMorph)
        
        // Add click handler for selection
        conceptMorph onClick = method(event,
            browser := self getSlot("memoryBrowser")
            if(browser,
                browser selectConcept(self getSlot("concept"))
            )
        )
        morphSetter := Object clone
        morphSetter target := conceptMorph
        morphSetter concept := visualizer concept
        morphSetter browser := self
        // Use message passing instead of setSlot
        morphSetter target doString("concept := " .. morphSetter concept asString)
        morphSetter target doString("memoryBrowser := " .. morphSetter browser asString)
        
        conceptMorph
    )
    
    selectConcept := method(conceptObj,
        // Handle concept selection
        selector := Object clone
        selector concept := conceptObj
        selector previousSelected := self selectedConcept
        
        writeln("MemoryBrowser: Selected concept " .. selector concept vectorId)
        
        // Update selection state
        self selectedConcept = selector concept
        
        // Visual feedback
        if(selector previousSelected,
            previousMorph := self conceptMorphs at(selector previousSelected vectorId)
            if(previousMorph,
                previousMorph color = "lightyellow"
            )
        )
        
        selectedMorph := self conceptMorphs at(selector concept vectorId)
        if(selectedMorph,
            selectedMorph color = "lightgreen"
        )
        
        // Show related concepts
        self showRelatedConcepts(selector concept)
        
        self
    )
    
    showRelatedConcepts := method(conceptObj,
        // Display concepts related to the selected one
        relationProcessor := Object clone
        relationProcessor concept := conceptObj
        relationProcessor searchOptions := Map clone
        relationProcessor searchOptions atPut("k", 3)
        
        // Search for similar concepts
        relationProcessor queryVector := self memory embed(relationProcessor concept content)
        relationProcessor relatedConcepts := self memory search(relationProcessor queryVector, relationProcessor searchOptions)
        
        writeln("MemoryBrowser: Found " .. relationProcessor relatedConcepts size .. " related concepts")
        
        // Highlight related concepts
        relationProcessor relatedConcepts foreach(i, related,
            if(related hasSlot("vectorId"),
                relatedMorph := self conceptMorphs at(related vectorId)
                if(relatedMorph,
                    relatedMorph color = "lightcyan"
                )
            )
        )
        
        self
    )
    
    search := method(queryObj,
        // Perform visual search in memory
        searchProcessor := Object clone
        searchProcessor query := queryObj
        searchProcessor queryStr := searchProcessor query asString
        
        writeln("MemoryBrowser: Searching for '" .. searchProcessor queryStr .. "'")
        
        // Update search box
        self searchQuery = searchProcessor queryStr
        
        // Perform memory search
        searchProcessor searchOptions := Map clone
        searchProcessor searchOptions atPut("k", 10)
        searchProcessor results := self memory search(searchProcessor query, searchProcessor searchOptions)
        
        // Clear previous highlights
        self clearHighlights
        
        // Highlight search results
        searchProcessor results foreach(i, result,
            if(result hasSlot("vectorId"),
                resultMorph := self conceptMorphs at(result vectorId)
                if(resultMorph,
                    resultMorph color = "lightcoral"
                )
            )
        )
        
        writeln("MemoryBrowser: Search returned " .. searchProcessor results size .. " results")
        searchProcessor results
    )
    
    clearHighlights := method(
        // Reset all concept colors
        self conceptMorphs values foreach(morph,
            morph color = "lightyellow"
        )
        self
    )
    
    addSampleConcepts := method(
        // Add sample concepts for demonstration
        writeln("MemoryBrowser: Adding sample concepts...")
        
        sampleConcepts := List clone
        sampleConcepts append("Consciousness emerges from complex information integration")
        sampleConcepts append("Fractal patterns reveal self-similar structures across scales") 
        sampleConcepts append("Autopoietic systems maintain organization through self-production")
        sampleConcepts append("Vector symbolic architectures enable compositional reasoning")
        sampleConcepts append("Neuro-symbolic integration combines neural and symbolic computation")
        sampleConcepts append("Direct manipulation interfaces provide immediate feedback")
        sampleConcepts append("Living images persist dynamic state across system evolution")
        sampleConcepts append("Morphic UI enables visual programming through object manipulation")
        
        sampleConcepts foreach(i, concept,
            metadataCreator := Object clone
            metadataCreator metadata := Map clone
            metadataCreator metadata atPut("category", "cognitive_science")
            metadataCreator metadata atPut("index", i)
            metadataCreator metadata atPut("source", "sample_data")
            
            self addConcept(concept, metadataCreator metadata)
        )
        
        writeln("MemoryBrowser: Added " .. sampleConcepts size .. " sample concepts")
        self
    )
    
    stats := method(
        // Return memory browser statistics
        statsCollector := Object clone
        statsCollector timestamp := Date now
        statsCollector conceptCount := self conceptMorphs size
        statsCollector selectedConcept := if(self selectedConcept, self selectedConcept vectorId, nil)
        statsCollector searchQuery := self searchQuery
        statsCollector displayMode := self displayMode
        statsCollector memoryStats := self memory stats
        
        statsCollector
    )
)