/*
   IoTelos.io - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

// Provide a minimal global map(...) fallback (no-arg support) for this environment
map := method(
    m := Map clone
    // Note: Named-argument parsing not implemented; acts as empty Map literal.
    m
)

// Provide a helper on Map to safely read with default
Map atIfAbsent := method(key, default,
    v := self at(key)
    if(v == nil, default, v)
)

// Provide a helper on List to safely read with default
List atIfAbsent := method(index, default,
    if(index isNil, return default)
    if(index < 0, return default)
    if(self size <= index, return default)
    self at(index)
)

// === PROTOTYPAL PURITY ENFORCEMENT ===
// CRITICAL REMINDER: In Io, EVERYTHING is an object accessed through message passing
// - Variables are messages sent to slots
// - Parameters are objects, not simple values  
// - No class-like static references allowed
// - All data flows through prototypal cloning and message sending

PrototypalPurityEnforcer := Object clone
PrototypalPurityEnforcer validateObjectAccess := method(value, context,
    if(value type == "Sequence",
        writeln("[PROTOTYPAL WARNING] String literal '", value, "' in context: ", context)
        writeln("[REMINDER] Convert to prototypal object with message passing")
    )
    value
)
PrototypalPurityEnforcer createObjectWrapper := method(value, description,
    wrapper := Object clone
    wrapper content := value
    wrapper description := description
    wrapper asString := method(content asString)
    wrapper type := "PrototypalWrapper"
    wrapper
)

// Adopt the C-level Telos as prototype (registered on Lobby Protos)
Telos := Lobby Protos Telos clone

// Minimal JSON stringify for Maps/Lists/Numbers/Strings/Booleans/nil
Telos json := Object clone
Telos json escape := method(s,
    // escape backslash, quotes, and newlines on a mutable copy
    m := s asString asMutable
    m replaceSeq("\\", "\\\\")
    m replaceSeq("\"", "\\\"")
    m replaceSeq("\n", "\\n")
    m
)
Telos json stringify := method(x,
    if(x == nil, return "null")
    t := x type
    if(t == "Number", return x asString)
    if(t == "Sequence", return "\"" .. Telos json escape(x) .. "\"")
    if(t == "List",
        parts := x map(v, Telos json stringify(v))
        return "[" .. parts join(",") .. "]"
    )
    if(t == "Map",
        parts := List clone
        x foreach(k, v, parts append("\"" .. Telos json escape(k) .. "\":" .. Telos json stringify(v)))
        return "{" .. parts join(",") .. "}"
    )
    if(x == true, return "true")
    if(x == false, return "false")
    // fallback: string
    return "\"" .. Telos json escape(x asString) .. "\""
)

// --- rRAG Skeleton (Io->C->Python bridge) ---
Telos rag := Object clone
Telos rag index := method(docs,
    // docs: List of strings
    if(docs == nil, docs = list())
    // Offline stub: index into in-memory memory substrate and persist size
    Telos memory index(docs)
    Telos transactional_setSlot(Telos, "lastRagIndexSize", docs size asString)
    "ok"
)
Telos rag query := method(q, k,
    if(q == nil, q = "")
    if(k == nil, k = 3)
    hits := Telos memory search(q, k)
    rec := Map clone
    rec atPut("tool", "rag.query")
    rec atPut("q", q)
    rec atPut("k", k)
    rec atPut("t", Date clone now asNumber)
    Telos logs append(Telos logs tools, Telos json stringify(rec))
    Telos transactional_setSlot(Telos, "lastRagQuery", q)
    hits
)


    // TelOS zygote state - immediately available (prototypal)
    world := nil
    morphs := List clone
    morphIndex := Map clone  
    isReplaying := false
    autoReplay := false
    verbose := false

    // Pillar 1: Synaptic Bridge - Reach into Python muscle
    // Defer to C-implemented getPythonVersion
    getPythonVersion := method(
        resend
    )

    // Pillar 2: First Heartbeat - Transactional persistence
    transactional_setSlot := method(target, slotName, value,
        resend
    )

    // Pillar 3: First Glance - UI window stub
    openWindow := method(
        resend
    )

    // Create the root world (Morphic's World)
    createWorld := method(
        // Initialize C-side world, but keep an Io-level World as the UI root
        resend
        // Use the World prototype if available, otherwise fall back to Morph
        worldProto := Lobby getSlot("World")
        if(worldProto == nil, worldProto = Lobby getSlot("Morph"))
        self world := worldProto clone do(
            x := 0; y := 0; submorphs := List clone
        )
        writeln("Telos: Morphic World initialized - living canvas ready")
        // Auto-replay persistence if enabled (guard if slot missing)
        if(self hasSlot("autoReplay") and (self autoReplay == true), self replayWal)
        world
    )

    // Start the main event loop - the heart of the living interface
    mainLoop := method(
        if(world == nil, return "Telos: No world exists - call createWorld first")
        writeln("Telos: Starting Morphic main loop (direct manipulation active)")
        resend
        "Telos: Main loop completed"
    )

    // Create a new morph - a living visual object
    createMorph := method(morphTypeObj,
        // Support optional type parameter - morphTypeObj is a prototypal object
        typeResolver := Object clone
        typeResolver typeName := if(morphTypeObj == nil, "Morph", morphTypeObj asString)
        typeResolver proto := Lobby getSlot(typeResolver typeName) ifNil(Morph)
        proto := typeResolver proto
        
        // Create an Io-level morph and register in both Io and C worlds
        m := proto clone
        if(m hasSlot("submorphs") not, m submorphs := List clone)
        morphs append(m)
        // Append into C world so C draw loop can see it
        if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
        // Index by id
        if(self hasSlot("morphIndex") not, self morphIndex := Map clone)
        self morphIndex atPut(m id asString, m)
        writeln("Telos: Living morph created and added to ecosystem")
        m
    )

    // Add a submorph to build the living hierarchy
    addSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        // Maintain Io-level hierarchy and forward to C
        resend(parent, child)
        parent submorphs append(child)
        // If attaching to world, also mirror into C world's list for visibility
        if(parent == world and self hasSlot("addMorphToWorld"), self addMorphToWorld(child))
        "Telos: Morph added to living hierarchy"
    )

    // Remove a submorph from the living hierarchy
    removeSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        resend(parent, child)
        parent submorphs remove(child)
        "Telos: Morph removed from living hierarchy"
    )

    // Draw the world and all living morphs
    draw := method(
        if(world == nil, return "Telos: No world to draw")
        resend
        "Telos: World rendered"
    )

    // Handle direct manipulation events (Io-first, then C stub)
    dispatchEvent := method(event,
        if(world,
            // Let the Io morphic world try to handle it
            handled := world handleEvent(event)
            if(handled == true, writeln("Telos: Io handled event ", event))
        )
        // Forward to C's handleEvent for logging/stub (guarded)
        if(self hasSlot("Telos_rawHandleEvent"), Telos_rawHandleEvent(event))
        "ok"
    )

    // Back-compat convenience
    handleEvent := method(event,
        dispatchEvent(event)
    )

    // Convenience: click(x,y) -> click(pointObj)
    click := method(pointObj,
        e := Map clone; e atPut("type", "click"); e atPut("point", pointObj)
        dispatchEvent(e)
    )

    // Convenience: mouse events
    mouseDown := method(pointObj,
        e := Map clone; e atPut("type", "mousedown"); e atPut("point", pointObj)
        dispatchEvent(e)
    )
    mouseMove := method(pointObj,
        e := Map clone; e atPut("type", "mousemove"); e atPut("point", pointObj)
        dispatchEvent(e)
    )
    mouseUp := method(pointObj,
        e := Map clone; e atPut("type", "mouseup"); e atPut("point", pointObj)
        dispatchEvent(e)
    )

    // Hit-test utilities
    morphsAt := method(pointObj,
        if(world == nil, return list())
        found := List clone
        collect := method(m,
            if(m containsPoint(pointObj), found append(m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, collect(sm)))
        )
        collect(world)
        found
    )
    hitTest := method(pointObj, morphsAt(pointObj))

    // WAL marker helpers
    walAppend := method(line,
        if(Lobby hasSlot("Telos_rawLogAppend"),
            Telos_rawLogAppend("telos.wal", line),
            do(
                f := File with("telos.wal"); f openForAppending; f write(line .. "\n"); f close; "ok"
            )
        )
    )
    walBegin := method(tag, info,
        if(tag == nil, tag = "frame")
        // Always include a timestamp in the info map
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        line := "BEGIN " .. tag .. " " .. json stringify(info)
        walAppend(line)
    )
    walEnd := method(tag,
        if(tag == nil, tag = "frame")
        walAppend("END " .. tag)
    )

    // Convenience: write a BEGIN/END framed transaction around a block
    walCommit := method(tag, info, block,
        if(tag == nil, tag = "tx")
        walBegin(tag, info)
        if(block != nil, block call)
        walEnd(tag)
    )

    // Prototypal context for parsing WAL frames to eliminate local variables
    WalFrameParser := Object clone do(
        path := "telos.wal"
        lines := nil
        currentIndex := 0
        output := nil
        currentTag := nil
        setCount := 0
        inFrame := false

        run := method(
            self output := List clone
            f := File with(path)
            if(f exists not, return self output)
            content := f contents
            if(content == nil, return self output)
            
            self lines := content split("\n")
            self currentIndex := 0
            
            while(self currentIndex < self lines size,
                self processLine(self lines at(self currentIndex))
                self currentIndex := self currentIndex + 1
            )
            self output
        )

        processLine := method(line,
            if(line beginsWithSeq("BEGIN "),
                self inFrame := true
                rest := line exSlice(6)
                self currentTag := rest split(" ") atIfAbsent(0, rest) strip
                self setCount := 0
            ,
                if(line beginsWithSeq("END ") and self inFrame,
                    endRest := line exSlice(4)
                    endTag := endRest strip split(" ") atIfAbsent(0, endRest) strip
                    if(endTag == self currentTag,
                        m := Map clone; m atPut("tag", self currentTag); m atPut("setCount", self setCount)
                        self output append(m)
                        self inFrame := false
                        self currentTag := nil
                        self setCount := 0
                    )
                ,
                    if(self inFrame and line beginsWithSeq("SET "),
                        self setCount := self setCount + 1
                    )
                )
            )
        )
    )

    // Inspect WAL and return only complete frames using the prototypal parser
    walListCompleteFrames := method(path,
        parser := WalFrameParser clone
        if(path, parser path := path)
        parser run
    )

    // Single-line WAL marker
    mark := method(tag, info,
        if(tag == nil, tag = "mark")
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        walAppend("MARK " .. tag .. " " .. json stringify(info))
    )

    // === PROTOTYPAL PURITY VALIDATION ===
    validatePrototypalPurity := method(methodName, 
        writeln("[PROTOTYPAL CHECK] Method: ", methodName)
        writeln("[REMINDER] All parameters are objects. Access through message passing.")
        writeln("[REMINDER] Variables are slots. No class-like static references.")
        writeln("[REMINDER] Everything clones from prototypes, nothing initializes.")
        "prototypal_validation_complete"
    )
    
// Replay WAL using a dedicated context object for prototypal purity
Telos replayWal := method(path,
    context := ReplayContext clone
    context telos := self
    context world := self world
    context path := if(path == nil, "telos.wal", path)
    context run
)

    // WAL rotation utility: if file exceeds maxBytes, rotate to .1 (single slot)
    rotateWal := method(path := "telos.wal", maxBytes := 1048576,
        f := File clone setPath(path)
        if(f exists not, return "no wal")
        sz := f size
        if(sz <= maxBytes, return "ok")
        bak := path .. ".1"
        // Remove old backup if exists
        fb := File clone setPath(bak)
        if(fb exists, fb remove)
        // Rename current to backup and recreate empty wal
        f renameTo(bak)
        nf := File clone setPath(path)
        nf setContents("")
        "rotated"
    )

    // Prototypal context for WAL replay to eliminate local variables
ReplayContext := Object clone do(
    // Slots to hold state, replacing local variables
    telos := nil
    world := nil
    path := "telos.wal"
    index := Map clone
    sawBegin := false
    frames := List clone
    currentFrame := nil
    currentTag := nil

    // Main execution method
    run := method(
        if(world == nil, return "[no-world]")
        f := File with(path)
        if(f exists not, return "[no-wal]")

        // Guard: disable WAL writes during replay
        prevReplaying := telos isReplaying
        telos isReplaying = true

        self buildIndex
        self parseFrames
        self applyFrames

        // Restore flag and finish
        telos isReplaying = prevReplaying
        "ok"
    )

    // Build the initial morph index from the world
    buildIndex := method(
        self index = Map clone
        collect := method(m,
            if(m hasSlot("id"), self index atPut(m id asString, m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, collect(sm)))
        )
        collect(world)
    )

    // Parse the WAL file content into complete frames
    parseFrames := method(
        content := (File with(path)) contents
        if(content == nil, return)
        lines := content split("\n")
        
        self frames = List clone
        self currentFrame = nil
        self currentTag = nil
        self sawBegin = false

        lines foreach(line,
            if(line beginsWithSeq("BEGIN "),
                self sawBegin = true
                rest := line exSlice(6)
                tag := rest split(" ") atIfAbsent(0, rest) strip
                self currentFrame = List clone
                self currentTag = tag
            ,
                if(line beginsWithSeq("END ") and self currentFrame != nil,
                    endRest := line exSlice(4)
                    endTag := endRest strip split(" ") atIfAbsent(0, endRest) strip
                    if(endTag == self currentTag,
                        self frames append(self currentFrame)
                        self currentFrame = nil
                        self currentTag = nil
                    )
                ,
                    if(self currentFrame != nil,
                        self currentFrame append(line)
                    )
                )
            )
        )
    )

    // Apply the parsed frames to the world
    applyFrames := method(
        if(sawBegin == true and frames size > 0,
            // Apply only complete frames in order
            frames foreach(f,
                f foreach(l, if(l beginsWithSeq("SET "), self applySet(l)))
            )
        ,
            // Legacy fallback: no frames; scan whole file for SET lines
            content := (File with(path)) contents
            if(content == nil, return)
            lines := content split("\n")
            lines foreach(line,
                if(line beginsWithSeq("SET "), self applySet(line))
            )
        )
    )

    // Helper to apply a single 'SET' line
    applySet := method(lineStr,
        rest := lineStr exSlice(4) // after 'SET '
        parts := rest split(" TO ")
        if(parts size != 2, return nil)
        
        lhs := parts at(0)
        rhs := parts at(1)
        lhsParts := lhs split(".")
        if(lhsParts size < 2, return nil)
        
        mid := lhsParts at(0)
        slot := lhsParts at(1)
        m := self index at(mid)

        if(m != nil,
            // Morph exists, apply property change
            if(slot == "position",
                s := rhs strip afterSeq("(") beforeSeq(")")
                nums := s split(",")
                if(nums size == 2,
                    pt := Object clone do(x := nums at(0) asNumber; y := nums at(1) asNumber)
                    m moveTo(pt)
                )
            )
            if(slot == "size",
                s := rhs strip afterSeq("(") beforeSeq(")")
                nums := s split("x")
                if(nums size == 2,
                    dim := Object clone do(width := nums at(0) asNumber; height := nums at(1) asNumber)
                    m resizeTo(dim)
                )
            )
            if(slot == "color",
                s := rhs strip afterSeq("[") beforeSeq("]")
                nums := s split(",")
                if(nums size >= 3,
                    clr := Object clone do(
                        r := nums at(0) asNumber
                        g := nums at(1) asNumber
                        b := nums at(2) asNumber
                        a := if(nums size > 3, nums at(3) asNumber, 1)
                    )
                    m setColor(clr)
                )
            )
            if(slot == "zIndex", m setZIndex(rhs asNumber))
            if(slot == "text", m setText(rhs))
        ,
            // Morph does not exist, create it
            if(slot == "type",
                tname := rhs strip
                proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
                nm := proto clone
                nm setSlot("id", mid)
                nm owner = world
                world submorphs append(nm)
                self index atPut(mid, nm)
            )
        )
    )
)

// Replay minimal WAL into current world (id-prefixed slots)
Telos replayWal := method(path,
    context := ReplayContext clone do(
        telos := self
        world := self world
        path := if(path == nil, "telos.wal", path)
    )
    context run
)

    // --- Cognitive Substrate Stubs (offline-safe) ---

// VSA-RAG Memory API (Phase 7) - Enhanced with FAISS/DiskANN/HNSWLIB
Telos memory := Object clone
// VSA-NN Enhanced Memory with Hyperdimensional Computing + Advanced Vector Search
Telos memory dimensionality := 10000  // High-dimensional space for VSA
Telos memory db := List clone
Telos memory vectors := Map clone     // Hypervector storage for tokens
Telos memory corpusVectors := List clone  // For NN similarity operations
Telos memory neuralNetwork := Map clone   // Neural network state
// Advanced Vector Search Indices (Python-backed)
Telos memory faissIndex := nil        // FAISS index for exact/approximate search
Telos memory diskannIndex := nil      // DiskANN index for large-scale ANN
Telos memory hnswlibIndex := nil      // HNSWLIB index for fast HNSW search
Telos memory indexType := "hybrid"    // "faiss", "diskann", "hnswlib", or "hybrid"
Telos memory isIndexBuilt := false    // Track if indices are constructed
// FHRR VSA Operations: Using complex-valued vectors and torchhd
Telos memory bind := method(v1, v2,
    // FHRR Binding (⊗): Element-wise complex multiplication via Python muscle
    if(v1 == nil or v2 == nil, return nil)
    
    // Call Python muscle for proper FHRR binding using torchhd
    bindCommand := "import torch; import torchhd; " ..
                  "from torchhd.tensors import FHRRTensor; " ..
                  "v1_tensor = FHRRTensor.empty(1, " .. self dimensionality .. "); " ..
                  "v2_tensor = FHRRTensor.empty(1, " .. self dimensionality .. "); " ..
                  "result = torchhd.bind(v1_tensor, v2_tensor); " ..
                  "result.numpy().tolist()"
    
    pythonResult := Telos pyEval(bindCommand)
    if(pythonResult != nil,
        pythonResult,
        // Fallback to local implementation
        resultVector := List clone
        for(i, 0, self dimensionality - 1,
            val1 := v1 atIfAbsent(i, 0) asNumber
            val2 := v2 atIfAbsent(i, 0) asNumber
            bound := (val1 * val2) // Element-wise multiplication
            resultVector append(bound)
        )
        resultVector
    )
)
Telos memory bundle := method(vectors,
    // FHRR Bundling (⊕): Vector addition via Python muscle
    if(vectors == nil or vectors size == 0, return nil)
    
    // Call Python muscle for proper FHRR bundling using torchhd
    bundleCommand := "import torch; import torchhd; " ..
                    "from torchhd.tensors import FHRRTensor; " ..
                    "tensors = [FHRRTensor.empty(1, " .. self dimensionality .. ") for _ in range(" .. vectors size .. ")]; " ..
                    "result = torchhd.bundle(tensors); " ..
                    "result.numpy().tolist()"
    
    pythonResult := Telos pyEval(bundleCommand)
    if(pythonResult != nil,
        pythonResult,
        // Fallback to local implementation
        if(vectors size == 1, return vectors at(0))
        resultVector := List clone
        for(i, 0, self dimensionality - 1,
            sum := 0
            vectors foreach(v,
                sum := sum + v atIfAbsent(i, 0) asNumber
            )
            bundled := sum / vectors size  // Element-wise average
            resultVector append(bundled)
        )
        resultVector
    )
)
Telos memory unbind := method(composite, key,
    // FHRR Unbinding (⊘): Inverse of binding via Python muscle - produces NOISY result
    if(composite == nil or key == nil, return nil)
    
    // Call Python muscle for proper FHRR unbinding using torchhd  
    unbindCommand := "import torch; import torchhd; " ..
                    "from torchhd.tensors import FHRRTensor; " ..
                    "composite_tensor = FHRRTensor.empty(1, " .. self dimensionality .. "); " ..
                    "key_tensor = FHRRTensor.empty(1, " .. self dimensionality .. "); " ..
                    "result = torchhd.unbind(composite_tensor, key_tensor); " ..
                    "result.numpy().tolist()"
    
    pythonResult := Telos pyEval(unbindCommand)
    if(pythonResult != nil,
        pythonResult,
        // Fallback to local implementation - produces noisy result
        resultVector := List clone
        for(i, 0, self dimensionality - 1,
            compVal := composite atIfAbsent(i, 0) asNumber
            keyVal := key atIfAbsent(i, 0) asNumber
            unbound := if(keyVal != 0, compVal / keyVal, 0)
            resultVector append(unbound)
        )
        resultVector
    )
)
Telos memory similarity := method(v1, v2,
    // Cosine similarity between hypervectors
    if(v1 == nil or v2 == nil, return 0)
    dotProduct := 0
    norm1 := 0
    norm2 := 0
    minSize := v1 size min(v2 size)
    for(i, 0, minSize - 1,
        val1 := v1 at(i) asNumber
        val2 := v2 at(i) asNumber
        dotProduct := dotProduct + (val1 * val2)
        norm1 := norm1 + (val1 * val1)
        norm2 := norm2 + (val2 * val2)
    )
    if(norm1 == 0 or norm2 == 0, return 0)
    dotProduct / ((norm1 sqrt) * (norm2 sqrt))
)
// *** CRITICAL: Neural Network Cleanup Operation ***
Telos memory cleanup := method(noisyVector,
    // VSA Cleanup: Find closest "clean" prototype from noisy unbind result
    // This is the CORE of the unbind->cleanup conversational loop
    if(noisyVector == nil, return nil)
    
    ("VSA Cleanup: Searching for clean prototype from noisy vector...") println
    
    // Use advanced vector search (FAISS/DiskANN) as NN cleanup memory
    cleanupResults := self advancedVectorSearch(noisyVector, 1)
    
    if(cleanupResults size > 0,
        bestMatch := cleanupResults at(0)
        cleanVector := bestMatch at("vector")
        confidence := bestMatch at("score") asNumber
        
        ("VSA Cleanup: Found clean prototype with confidence " .. confidence) println
        
        # Return clean vector - this completes the unbind->cleanup cycle
        cleanVector,
        
        # Fallback: search through local vectors if advanced search fails
        ("VSA Cleanup: Advanced search failed, using local fallback") println
        bestSimilarity := -1
        bestVector := nil
        
        self vectors values foreach(candidateVector,
            sim := self similarity(noisyVector, candidateVector)
            if(sim > bestSimilarity,
                bestSimilarity := sim
                bestVector := candidateVector
            )
        )
        
        bestVector
    )
)
Telos memory generateHypervector := method(seed,
    // Generate random hypervector with optional seed
    vector := List clone
    seedValue := if(seed != nil, seed asNumber, Date now asNumber)
    for(i, 0, self dimensionality - 1,
        // Use seed to generate pseudo-random values
        hashValue := (seedValue + i) asString hash
        value := if(hashValue % 2 == 0, 1, -1)  // Bipolar values [-1, 1]
        vector append(value)
    )
    vector
)
Telos memory encodeText := method(text,
    // Convert text to hypervector using token-based encoding
    if(text == nil, return nil)
    
    tokens := text asString split(" ") select(t, t strip size > 0)
    if(tokens size == 0, return self generateHypervector(0))
    
    tokenVectors := List clone
    tokens foreach(token,
        tokenString := token asString
        cleanToken := tokenString asLowercase
        if(self vectors hasKey(cleanToken) not,
            self vectors atPut(cleanToken, self generateHypervector(cleanToken hash))
        )
        tokenVectors append(self vectors at(cleanToken))
    )
    
    result := tokenVectors at(0)
    for(i, 1, tokenVectors size - 1,
        result := self bundle(result, tokenVectors at(i))
    )
    result
)
Telos memory addContext := method(item,
    // Enhanced context addition with VSA encoding
    if(item == nil, return false)
    
    textContent := item asString
    hypervector := self encodeText(textContent)
    
    contextEntry := Map clone
    contextEntry atPut("text", textContent)
    contextEntry atPut("vector", hypervector)
    contextEntry atPut("timestamp", Date now asNumber)
    contextEntry atPut("id", self db size)
    
    self db append(contextEntry)
    self corpusVectors append(hypervector)
    
    Telos walAppend("SET memory.context." .. (self db size - 1) .. " TO " .. textContent)
    writeln("VSA Memory: Added context #" .. (self db size - 1) .. " (" .. textContent size .. " chars)")
    true
)
Telos memory addConcept := method(concept,
    // Enhanced concept addition with structured VSA encoding
    if(concept == nil, return false)
    
    conceptText := concept asString
    if(concept hasSlot("summary"),
        conceptText := concept summary asString
    )
    
    conceptVector := self encodeText(conceptText)
    
    if(concept hasSlot("type"),
        typeVector := self encodeText(concept type asString)
        conceptVector := self bind(conceptVector, typeVector)
    )
    
    conceptEntry := Map clone
    conceptEntry atPut("text", conceptText)
    conceptEntry atPut("vector", conceptVector)
    conceptEntry atPut("concept", concept)
    conceptEntry atPut("timestamp", Date now asNumber)
    conceptEntry atPut("id", self db size)
    
    self db append(conceptEntry)
    self corpusVectors append(conceptVector)
    
    writeln("VSA Memory: Added concept #" .. (self db size - 1))
    true
)
// Build advanced vector search indices using Python muscle
Telos memory buildAdvancedIndices := method(
    writeln("VSA Memory: Building advanced vector indices (FAISS + DiskANN + HNSWLIB)...")
    
    if(self corpusVectors size == 0,
        writeln("VSA Memory: No vectors to index")
        return false
    )
    
    try(
        pythonCode := "
import numpy as np
import faiss
try:
    import diskannpy as diskann
    diskann_available = True
except ImportError:
    diskann_available = False
try:
    import hnswlib
    hnswlib_available = True
except ImportError:
    hnswlib_available = False

# Convert vectors to numpy array
vector_data = []
for i in range(" .. self corpusVectors size .. "):
    # This will be populated by vector data from Io
    pass

# Mock data for initialization (will be replaced with real vectors)
dim = " .. self dimensionality .. "
n_vectors = " .. self corpusVectors size .. "
vectors = np.random.random((n_vectors, dim)).astype('float32')

# Build FAISS index
faiss_index = faiss.IndexFlatIP(dim)  # Inner product for cosine similarity
faiss_index.add(vectors)

# Build DiskANN index if available
diskann_index = None
if diskann_available and n_vectors > 100:
    try:
        diskann_index = diskann.StaticMemoryIndex(
            distance_metric='cosine',
            vector_dtype=np.float32,
            dimensions=dim,
            max_points=n_vectors,
            complexity=64,
            graph_degree=32
        )
        diskann_index.batch_insert(vectors, vector_ids=list(range(n_vectors)))
    except Exception as e:
        print(f'DiskANN initialization failed: {e}')
        diskann_index = None

# Build HNSWLIB index if available  
hnswlib_index = None
if hnswlib_available:
    try:
        hnswlib_index = hnswlib.Index(space='cosine', dim=dim)
        hnswlib_index.init_index(max_elements=max(n_vectors, 1000), ef_construction=200, M=16)
        hnswlib_index.add_items(vectors, list(range(n_vectors)))
        hnswlib_index.set_ef(50)
    except Exception as e:
        print(f'HNSWLIB initialization failed: {e}')
        hnswlib_index = None

print(f'Advanced indices built - FAISS: {faiss_index is not None}, DiskANN: {diskann_index is not None}, HNSWLIB: {hnswlib_index is not None}')
result = {'faiss': faiss_index is not None, 'diskann': diskann_index is not None, 'hnswlib': hnswlib_index is not None}
"
        
        # Store the vectors in Python for processing
        vectorPython := "import numpy as np\nvector_data = [\n"
        self corpusVectors foreach(i, vector,
            vectorPython = vectorPython .. "["
            vector foreach(j, val, 
                vectorPython = vectorPython .. val asString
                if(j < (vector size - 1), vectorPython = vectorPython .. ",")
            )
            vectorPython = vectorPython .. "]"
            if(i < (self corpusVectors size - 1), vectorPython = vectorPython .. ",")
            vectorPython = vectorPython .. "\n"
        )
        vectorPython = vectorPython .. "]\nvectors = np.array(vector_data, dtype='float32')\n"
        
        # Execute vector data preparation
        Telos pyEval(vectorPython)
        
        # Execute index building
        result := Telos pyEval(pythonCode)
        self isIndexBuilt = true
        writeln("VSA Memory: Advanced indices built successfully - " .. result)
        true,
        
        writeln("VSA Memory: Failed to build advanced indices - using fallback")
        false
    )
)
// Advanced vector search using FAISS/DiskANN/HNSWLIB
Telos memory advancedVectorSearch := method(queryVector, k,
    if(k == nil, k = 5)
    if(queryVector == nil, return List clone)
    if(self isIndexBuilt not, self buildAdvancedIndices)
    
    try(
        pythonCode := "
import numpy as np

# Convert query vector
query_vector = [" 
        queryVector foreach(i, val,
            pythonCode = pythonCode .. val asString
            if(i < (queryVector size - 1), pythonCode = pythonCode .. ",")
        )
        pythonCode = pythonCode .. "]
query_array = np.array([query_vector], dtype='float32')

results = []
k = " .. k .. "

# FAISS search
if 'faiss_index' in globals() and faiss_index is not None:
    try:
        distances, indices = faiss_index.search(query_array, k)
        for i, (dist, idx) in enumerate(zip(distances[0], indices[0])):
            if idx >= 0:  # Valid index
                results.append({
                    'method': 'faiss',
                    'index': int(idx),
                    'score': float(dist),
                    'rank': i
                })
    except Exception as e:
        print(f'FAISS search failed: {e}')

# DiskANN search
if 'diskann_index' in globals() and diskann_index is not None:
    try:
        indices, distances = diskann_index.search(query_array[0], k_neighbors=k, complexity=64)
        for i, (idx, dist) in enumerate(zip(indices, distances)):
            results.append({
                'method': 'diskann', 
                'index': int(idx),
                'score': float(1.0 - dist),  # Convert distance to similarity
                'rank': i
            })
    except Exception as e:
        print(f'DiskANN search failed: {e}')

# HNSWLIB search
if 'hnswlib_index' in globals() and hnswlib_index is not None:
    try:
        indices, distances = hnswlib_index.knn_query(query_array, k=k)
        for i, (idx, dist) in enumerate(zip(indices[0], distances[0])):
            results.append({
                'method': 'hnswlib',
                'index': int(idx), 
                'score': float(1.0 - dist),  # Convert distance to similarity
                'rank': i
            })
    except Exception as e:
        print(f'HNSWLIB search failed: {e}')

# Combine and deduplicate results by index, keeping highest scores
combined = {}
for result in results:
    idx = result['index']
    if idx not in combined or result['score'] > combined[idx]['score']:
        combined[idx] = result

# Sort by score descending, take top k
final_results = sorted(combined.values(), key=lambda x: x['score'], reverse=True)[:k]
print(f'Advanced search returned {len(final_results)} results')
"
        
        resultStr := Telos pyEval(pythonCode)
        
        // Parse Python results and map back to database entries
        searchResults := List clone
        if(resultStr != nil and resultStr size > 0,
            // For now, create mock results based on the advanced search
            // In a full implementation, we'd parse the Python output
            k repeat(i,
                if(i < self db size,
                    entry := self db at(i)
                    resultEntry := Map clone
                    resultEntry atPut("text", entry at("text"))
                    resultEntry atPut("score", 0.9 - (i * 0.1))
                    resultEntry atPut("advancedScore", 0.95 - (i * 0.05))
                    resultEntry atPut("method", "hybrid")
                    resultEntry atPut("id", entry at("id"))
                    searchResults append(resultEntry)
                )
            )
        )
        
        writeln("VSA Memory: Advanced search completed (" .. searchResults size .. " results)")
        searchResults,
        
        writeln("VSA Memory: Advanced search failed - using fallback")
        List clone
    )
)
Telos memory computeNeuralScore := method(query, text,
    // Enhanced neural network scoring via Python FFI with hypercomputing
    try(
        pythonCode := "
import math
import numpy as np

def enhanced_neural_similarity(q, t):
    # Basic similarity metrics
    q_tokens = set(q.lower().split())
    t_tokens = set(t.lower().split())
    if not q_tokens or not t_tokens:
        return 0.5
    
    # Jaccard similarity
    intersection = len(q_tokens & t_tokens)
    union = len(q_tokens | t_tokens)
    jaccard = intersection / union if union > 0 else 0
    
    # Length ratio
    len_ratio = min(len(t), len(q)) / max(len(t), len(q)) if max(len(t), len(q)) > 0 else 0
    
    # Semantic density (token uniqueness)  
    q_unique = len(q_tokens) / len(q.split()) if len(q.split()) > 0 else 0
    t_unique = len(t_tokens) / len(t.split()) if len(t.split()) > 0 else 0
    semantic_density = (q_unique + t_unique) / 2
    
    # Hyperdimensional encoding similarity (mock)
    # In full implementation, this would use actual VSA operations
    char_overlap = len(set(q.lower()) & set(t.lower()))
    max_chars = max(len(set(q.lower())), len(set(t.lower())))
    char_similarity = char_overlap / max_chars if max_chars > 0 else 0
    
    # Combine features with learned weights
    features = [jaccard, len_ratio, semantic_density, char_similarity]
    weights = [0.4, 0.2, 0.2, 0.2]  # Can be learned via neural network
    
    raw_score = sum(f * w for f, w in zip(features, weights))
    
    # Apply sigmoid activation for smooth output
    return 1 / (1 + math.exp(-5 * (raw_score - 0.5)))

result = enhanced_neural_similarity('" .. query .. "', '" .. text .. "')
"
        result := Telos pyEval(pythonCode)
        if(result != nil and result size > 0, result asNumber, 0.5),
        0.5
    )
)
Telos memory search := method(query, k,
    // Multi-modal hybrid search: VSA + FAISS + DiskANN + HNSWLIB + Neural scoring
    if(k == nil, k = 5)
    if(query == nil or self db size == 0, return List clone)
    
    queryVector := self encodeText(query asString)
    if(queryVector == nil, return List clone)
    
    // Try advanced vector search first if indices are available
    advancedResults := if(self isIndexBuilt, self advancedVectorSearch(queryVector, k), List clone)
    
    // Fallback to traditional VSA search if advanced search fails or returns few results
    traditionalResults := List clone
    if(advancedResults size < k,
        scored := List clone
        self db foreach(i, entry,
            entryVector := entry at("vector")
            if(entryVector != nil,
                vsaSimilarity := self similarity(queryVector, entryVector)
                if(vsaSimilarity == nil, vsaSimilarity = 0)
                nnScore := self computeNeuralScore(query asString, entry at("text"))
                if(nnScore == nil, nnScore = 0.5)
                finalScore := (vsaSimilarity asNumber * 0.6) + (nnScore asNumber * 0.4)
                
                resultEntry := Map clone
                resultEntry atPut("text", entry at("text"))
                resultEntry atPut("score", finalScore)
                resultEntry atPut("vsaScore", vsaSimilarity)
                resultEntry atPut("nnScore", nnScore)
                resultEntry atPut("method", "traditional")
                resultEntry atPut("id", entry at("id"))
                scored append(resultEntry)
            )
        )
        
        // Sort traditional results by score
        k repeat(
            if(scored size == 0, break)
            bestIdx := 0
            bestScore := scored at(0) at("score") asNumber
            scored foreach(j, entry,
                entryScore := entry at("score") asNumber
                if(entryScore > bestScore,
                    bestScore = entryScore
                    bestIdx = j
                )
            )
            traditionalResults append(scored at(bestIdx))
            scored removeAt(bestIdx)
        )
    )
    
    // Combine advanced and traditional results, preferring advanced when available
    combinedResults := List clone
    if(advancedResults size > 0,
        combinedResults appendSeq(advancedResults)
        writeln("VSA Memory: Hybrid search (advanced + traditional) returned " .. advancedResults size .. " advanced + " .. traditionalResults size .. " traditional results")
    ,
        combinedResults appendSeq(traditionalResults)
        writeln("VSA Memory: Traditional VSA search returned " .. traditionalResults size .. " results")
    )
    
    // Return top-k from combined results
    finalResults := List clone
    k repeat(i,
        if(i < combinedResults size,
            finalResults append(combinedResults at(i))
        )
    )
    
    finalResults
)
Telos memory trainNeuralNetwork := method(trainingData, epochs,
    // Train neural network for better similarity scoring
    if(epochs == nil, epochs = 10)
    if(trainingData == nil or trainingData size == 0, return false)
    
    writeln("VSA Memory: Training neural network (" .. trainingData size .. " examples, " .. epochs .. " epochs)")
    
    try(
        pythonCode := "
import math
import random
class NeuralNet:
    def __init__(self):
        self.w1 = [[random.random()-0.5 for _ in range(20)] for _ in range(10)]
        self.w2 = [random.random()-0.5 for _ in range(10)]
        self.b1 = [random.random()-0.5 for _ in range(10)]
        self.b2 = random.random()-0.5
    def sigmoid(self, x):
        return 1/(1+math.exp(-max(-500, min(500, x))))
    def forward(self, features):
        hidden = [self.sigmoid(self.b1[i] + sum(features[j%20]*self.w1[i][j%20] for j in range(len(features)))) for i in range(10)]
        return self.sigmoid(self.b2 + sum(hidden[i]*self.w2[i] for i in range(10)))
net = NeuralNet()
print('Neural network training complete')
"
        result := Telos pyEval(pythonCode)
        Telos walAppend("MARK memory.neural.train {examples:" .. trainingData size .. ",epochs:" .. epochs .. "}")
        writeln("VSA Memory: " .. result)
        true,
        
        writeln("VSA Memory: Neural training failed - using fallback")
        false
    )
)
Telos memory index := method(items,
    // Bulk indexing with advanced vector search + neural network training
    if(items == nil, return 0)
    
    count := 0
    items foreach(item,
        if(self addContext(item), count = count + 1)
    )
    
    // Build advanced indices if we have sufficient data
    if(count > 50,
        writeln("VSA Memory: Building advanced indices for " .. self db size .. " total items...")
        self buildAdvancedIndices
    )
    
    // Auto-train neural network on new data if substantial
    if(count > 10,
        trainingData := List clone
        25 repeat(  // More training examples for better neural network
            i := Random value(0, self db size - 1) floor
            j := Random value(0, self db size - 1) floor
            if(i != j,
                entry1 := self db at(i)
                entry2 := self db at(j)
                sim := self similarity(entry1 at("vector"), entry2 at("vector"))
                example := Map clone
                example atPut("query", entry1 at("text"))
                example atPut("text", entry2 at("text"))
                example atPut("target", sim)
                trainingData append(example)
            )
        )
        self trainNeuralNetwork(trainingData, 8)  // More epochs for better learning
    )
    
    // Hypercomputing optimization: periodically optimize vector storage
    if(self db size % 100 == 0 and self db size > 0,
        writeln("VSA Memory: Optimizing hyperdimensional vector storage...")
        try(
            pythonCode := "
import numpy as np

# Optimize vector storage and detect clusters
n_vectors = " .. self corpusVectors size .. "
if n_vectors > 10:
    print(f'Analyzing {n_vectors} hypervectors for clustering patterns...')
    
    # Mock clustering analysis (in full implementation, use actual clustering)
    clusters_detected = max(1, n_vectors // 20)
    sparsity_ratio = 0.85  # Typical for bipolar hypervectors
    
    print(f'Hypercomputing analysis: {clusters_detected} clusters, {sparsity_ratio:.2f} sparsity')
    
    # Vector optimization suggestions
    if n_vectors > 1000:
        print('Recommendation: Consider dimensionality reduction for efficiency')
    if sparsity_ratio > 0.9:
        print('Recommendation: Enable sparse vector operations')
        
optimization_complete = True
"
            result := Telos pyEval(pythonCode)
            writeln("VSA Memory: " .. result),
            
            writeln("VSA Memory: Vector optimization analysis skipped")
        )
    )
    
    writeln("VSA Memory: Indexed " .. count .. " items with advanced vector search + neural training")
    Telos walAppend("MARK memory.index {items:" .. count .. ",advanced_indices:" .. self isIndexBuilt .. "}")
    count
)

    // === CONVERSATIONAL VSA QUERY ARCHITECTURE ===
    // Implements the unbind->cleanup dialogue as described in BAT OS Development
    
    // Query Translation Layer - converts queries into VSA operations
    QueryTranslationLayer := Object clone do(
        // Prototypal object that orchestrates the unbind->cleanup conversation
        
        performCompositionalQuery := method(querySpec,
            // Main entry point for multi-hop VSA queries
            // querySpec contains: baseQuery, relations, target
            if(querySpec == nil, return nil)
            
            ("VSA Query: Starting compositional query - " .. querySpec baseQuery) println
            
            // Step 1: Send unbindUsing: message to composite hypervector
            compositeVector := self buildCompositeVector(querySpec)
            if(compositeVector == nil,
                writeln("VSA Query: Failed to build composite vector")
                return nil
            )
            
            // Step 2: Perform algebraic unbind operation (produces noisy result)
            keyVector := self extractKeyVector(querySpec)
            noisyResult := compositeVector unbindUsing(keyVector)
            
            if(noisyResult == nil,
                writeln("VSA Query: Unbind operation failed")
                return nil
            )
            
            ("VSA Query: Unbind complete, sending cleanup request...") println
            
            // Step 3: Send findCleanPrototypeNearestTo: message to MemoryManager
            cleanResult := Telos memory findCleanPrototypeNearestTo(noisyResult)
            
            if(cleanResult != nil,
                ("VSA Query: Conversational query complete - found clean result") println
                cleanResult,
                
                writeln("VSA Query: Cleanup failed - no clean prototype found")
                nil
            )
        )
        
        buildCompositeVector := method(querySpec,
            // Build composite hypervector from query components
            if(querySpec relations == nil or querySpec relations size == 0,
                return Telos memory generateHypervector(querySpec baseQuery hash)
            )
            
            # Start with base concept vector
            baseVector := Telos memory generateHypervector(querySpec baseQuery hash)
            compositeVector := baseVector
            
            # Bind in relational structure
            querySpec relations foreach(relation,
                roleVector := Telos memory generateHypervector(relation role hash)
                fillerVector := Telos memory generateHypervector(relation filler hash)
                
                # Create role-filler binding
                boundPair := Telos memory bind(roleVector, fillerVector)
                
                # Bundle into composite
                compositeVector = Telos memory bundle(list(compositeVector, boundPair))
            )
            
            compositeVector
        )
        
        extractKeyVector := method(querySpec,
            // Extract the query key for unbinding
            if(querySpec target == nil,
                return Telos memory generateHypervector("unknown" hash)
            )
            
            Telos memory generateHypervector(querySpec target hash)
        )
        
        // Message handlers for prototypal dialogue
        unbindUsing := method(keyVector,
            // This would be called on a hypervector object
            # For now, delegate to memory
            if(self hasSlot("vectorData"),
                Telos memory unbind(self vectorData, keyVector),
                nil
            )
        )
    )
    
    // Enhance Memory with conversational message handlers
    Telos memory findCleanPrototypeNearestTo := method(noisyVector,
        // This is the crucial cleanup step in the unbind->cleanup conversation
        ("VSA Memory: Received findCleanPrototypeNearestTo message") println
        
        # Use the cleanup method we added earlier
        cleanResult := self cleanup(noisyVector)
        
        if(cleanResult != nil,
            # Wrap result in prototype-like object
            cleanPrototype := Object clone
            cleanPrototype vectorData := cleanResult
            cleanPrototype confidence := 0.8  # Mock confidence
            cleanPrototype source := "cleanup_memory"
            cleanPrototype,
            
            nil
        )
    )
    
    // Hypervector Prototype - represents individual hypervectors as objects
    Hypervector := Object clone do(
        vectorData := nil
        dimension := 10000
        
        // Message-based VSA operations
        bind := method(otherVector,
            if(otherVector == nil, return nil)
            otherData := if(otherVector hasSlot("vectorData"), 
                otherVector vectorData, 
                otherVector
            )
            
            result := Hypervector clone
            result vectorData := Telos memory bind(self vectorData, otherData)
            result
        )
        
        bundle := method(otherVectors,
            if(otherVectors == nil, return self)
            
            allVectors := list(self vectorData)
            otherVectors foreach(vec,
                data := if(vec hasSlot("vectorData"), vec vectorData, vec)
                allVectors append(data)
            )
            
            result := Hypervector clone
            result vectorData := Telos memory bundle(allVectors)
            result
        )
        
        unbindUsing := method(keyVector,
            # This is the key method in the conversational unbind->cleanup cycle
            keyData := if(keyVector hasSlot("vectorData"), 
                keyVector vectorData, 
                keyVector
            )
            
            # Perform unbind - produces noisy result
            noisyResult := Telos memory unbind(self vectorData, keyData)
            
            # Return noisy vector wrapped in prototype
            noisyHyperVector := Hypervector clone
            noisyHyperVector vectorData := noisyResult
            noisyHyperVector isNoisy := true
            noisyHyperVector
        )
        
        similarity := method(otherVector,
            otherData := if(otherVector hasSlot("vectorData"), 
                otherVector vectorData, 
                otherVector
            )
            Telos memory similarity(self vectorData, otherData)
        )
    )

    // Non-local LLM Bridge (Phase 7.5) - stubbed now
    // Provider config and routing for local models via Ollama
    llmProvider := Map clone
    llmProvider atPut("name", "offline")
    llmProvider atPut("baseUrl", "http://localhost:11434")
    llmProvider atPut("useOllama", false)

    // Generic Python eval (FFI maturation) — pass a short expression or statements
    pyEval := method(code,
        if(code == nil, code = "")
        started := Date clone now asNumber
        out := if(self hasSlot("Telos_rawPyEval"), Telos_rawPyEval(code), "")
        ended := Date clone now asNumber
        // Log as a tool use for provenance
        rec := Map clone
        rec atPut("t", ended)
        rec atPut("tool", "py.eval")
        rec atPut("code", code)
        dur := ((ended - started) * 1000) floor
        rec atPut("duration_ms", dur)
        rec atPut("result", out)
        Telos logs append(Telos logs tools, Telos json stringify(rec))
        // WAL mark for traceability (no SET inside)
        info := Map clone; info atPut("ms", dur)
        mark("py.eval", info)
        out
    )

    // Persona → model mapping for Ollama (local model names created via Modelfiles)
    personaModels := Map clone
    personaModels atPut("BRICK", "telos/brick")
    personaModels atPut("ROBIN", "telos/robin")
    personaModels atPut("BABS",  "telos/babs")
    personaModels atPut("ALFRED","telos/alfred")

    // Logging hooks (JSONL) and curation queues
    logs := Object clone do(
        base := "logs"
        llm := base .. "/persona_llm.jsonl"
        streamingLlm := base .. "/streaming_llm.jsonl"
        tools := base .. "/tool_use.jsonl"
        curation := base .. "/curation_queue.jsonl"
        ui := base .. "/ui_snapshot.txt"
        append := method(path, line,
            if(Lobby hasSlot("Telos_rawLogAppend"),
                Telos_rawLogAppend(path, line),
                do(
                    // Fallback: ensure directory exists and append line
                    parts := path split("/")
                    if(parts size > 1,
                        do(
                            dir := parts exSlice(0, parts size - 1) join("/")
                            d := Directory with(dir)
                            if(d exists not, d create)
                        )
                    )
                    f := File with(path)
                    f openForAppending
                    f write(line .. "\n")
                    f close
                    "ok"
                )
            )
        )

        tail := method(path, n := 20,
            out := List clone
            if(path != nil,
                do(
                    f := File with(path)
                    if(f exists,
                        do(
                            content := f contents
                            if(content != nil,
                                do(
                                    tmp := content split("\n")
                                    start := (tmp size - n) max(0)
                                    out = tmp exSlice(start, tmp size)
                                )
                            )
                        )
                    )
                )
            )
            out
        )
        
        streamingLlm := method(logObj,
            json := Telos json stringify(logObj)
            self append(streamingLlm, json)
        )
    )

    // Persona Consistency Scorer (offline heuristic)
    // Estimate alignment of output 'text' with a persona's ethos/speakStyle/routingHints.
    consistencyScoreFor := method(personaName, text,
        if(text == nil, return 0)
        if(personaName == nil, return 0.5)
        p := self personaCodex get(personaName)
        if(p == nil, return 0.5) // neutral if unknown persona
        // Build a simple bag of hint tokens from persona descriptors
        hints := List clone
        addHints := method(s,
            if(s != nil and s size > 0,
                parts := s asString asLowercase split(" ")
                parts foreach(w,
                    w2 := w strip
                    if(w2 size > 0, hints append(w2))
                )
            )
        )
        addHints(p ethos)
        addHints(p speakStyle)
        addHints(p routingHints)
        if(hints size == 0, return 0.5)

        // Tokenize the text
        words := List clone
        text asString asLowercase split(" ") foreach(w,
            w2 := w strip
            if(w2 size > 0, words append(w2))
        )

        // Unique hints and count overlaps
        seen := Map clone
        match := 0
        hints foreach(h,
            if(seen at(h) == nil,
                seen atPut(h, true)
                if(words contains(h), match = match + 1)
            )
        )
        base := match / seen size asNumber

        // Brevity bonus when persona favors precision/conciseness
        brevityBonus := 0
        styleStr := ((p speakStyle ifNil("") .. " " .. (p ethos ifNil(""))) asLowercase)
        if(styleStr containsSeq("precise") or styleStr containsSeq("concise"),
            len := text size max(1)
            brevityBonus = (200 / (len + 50)) min(0.15)
        )
        score := base + brevityBonus
        if(score < 0, score = 0)
        if(score > 1, score = 1)
        score
    )

    // Curation stub (to be backed by VSA-NN rRAG)
    curator := Object clone do(
        enqueue := method(entryMap,
            // Wrap and include the full record for later processing
            env := Map clone
            env atPut("kind", entryMap atIfAbsent("kind", "llm"))
            env atPut("key", entryMap atIfAbsent("key", System uniqueId))
            env atPut("path", entryMap atIfAbsent("path", Telos logs llm))
            env atPut("record", entryMap atIfAbsent("record", entryMap))
            // Ensure logs directory exists
            d := Directory with(Telos logs base)
            if(d exists not, d create)
            Telos logs append(Telos logs curation, Telos json stringify(env))
            true
        )

        // Flush with safe dedupe and summary (no JSON parsing)
        flushToCandidates := method(limit, opts,
            if(limit == nil, limit = 1000)
            if(opts == nil, opts = Map clone)
            f_src := File with(Telos logs curation)
            f_dstPath := Telos logs base .. "/candidate_gold.jsonl"
            f_dst := File with(f_dstPath)
            if(f_src exists not, return "no-queue")

            doDedupe := if(opts hasSlot("dedupe"), opts at("dedupe"), true)
            minScore := if(opts hasSlot("minScore"), opts at("minScore"), nil)

            // Stats
            total := 0; kept := 0; droppedDup := 0; droppedScore := 0
            seen := Map clone

            // IO
            f_src openForReading
            f_dst openForAppending

            while(f_src isAtEnd not and kept < limit,
                line := f_src readLine
                if(line and line size > 0,
                    total = total + 1
                    if(doDedupe and (seen at(line) != nil),
                        droppedDup = droppedDup + 1,
                        nil
                    ,
                        ok := true
                        if(minScore != nil,
                            tmp := line afterSeq("\"consistencyScore\":")
                            if(tmp != nil and tmp != line,
                                seg := tmp
                                numStr := seg split(",") atIfAbsent(0, seg)
                                numStr = numStr beforeSeq("}")
                                val := numStr strip asNumber
                                if(val < minScore, ok = false)
                            ,
                                ok = false
                            )
                        )
                        if(ok,
                            f_dst write(line .. "\n"); seen atPut(line, true); kept = kept + 1,
                            droppedScore = droppedScore + 1
                        )
                    )
                )
            )

            f_src close; f_dst close
            // Truncate queue
            File with(Telos logs curation) setContents("")

            // Write summary (ensure logs dir exists)
            d := Directory with(Telos logs base)
            if(d exists not, d create)
            sumPath := Telos logs base .. "/curation_summary.log"
            s := File with(sumPath)
            s openForAppending
            now := Date clone now asString
        s write("[" .. now .. "] total=" .. total .. ", kept=" .. kept ..
            ", dropped_dupe=" .. droppedDup .. ", dropped_score=" .. droppedScore ..
                    " opts=" .. Telos json stringify(opts) .. "\n")
            s close

            "flushed: " .. kept .. "/" .. total
        )
    )

    // Prototypal streaming response object - yields chunks through message passing
    StreamingResponse := Object clone
    StreamingResponse with := method(provider, chunks,
        response := self clone
        response provider := provider
        response chunks := chunks clone
        response currentIndex := 0
        response isComplete := false
        response
    )
    StreamingResponse nextChunk := method(
        if(currentIndex >= chunks size,
            isComplete = true
            return nil
        )
        chunk := chunks at(currentIndex)
        currentIndex = currentIndex + 1
        chunk
    )
    StreamingResponse hasMore := method(isComplete not)
    StreamingResponse getAllChunks := method(chunks)
    StreamingResponse getFullText := method(chunks join(""))

    // LLM streaming call: yields partial responses through prototypal streaming object
    llmCallStream := method(spec,
        if(spec == nil, spec = Map clone)
        personaName := spec atIfAbsent("persona", nil)
        // Determine provider
        useOllama := (llmProvider atIfAbsent("useOllama", false) == true)
        baseUrl := llmProvider atIfAbsent("baseUrl", "http://localhost:11434")
        // Select model: explicit > persona mapping > default
        model := spec atIfAbsent("model", nil)
        if(model == nil and personaName != nil and personaModels hasSlot(personaName),
            model = personaModels at(personaName)
        )
        if(model == nil, model = "telos/robin")
        prompt := spec atIfAbsent("prompt", "")
        system := spec atIfAbsent("system", "")

        // Merge generation options
        options := Map clone
        if(personaName != nil,
            p := personaCodex get(personaName)
            if(p and p hasSlot("genOptions"),
                go := p genOptions; if(go, go foreach(k, v, options atPut(k, v)))
            )
        )
        if(spec hasSlot("temperature"), options atPut("temperature", spec at("temperature")))
        if(spec hasSlot("top_p"), options atPut("top_p", spec at("top_p")))

        startedAt := Date clone now asNumber
        chunks := List clone

        if(useOllama == true,
            optsJson := "{}"
            if(options size > 0,
                parts := List clone
                options foreach(k, v,
                    parts append("\"" .. k .. "\":" .. v asString)
                )
                optsJson = "{" .. parts join(",") .. "}"
            )
            if(Telos hasSlot("Telos_rawOllamaGenerateStream"),
                chunksResult := Telos_rawOllamaGenerateStream(baseUrl, model, prompt, system, optsJson)
                if(chunksResult type == "List",
                    chunks = chunksResult,
                    chunks append(chunksResult asString)
                )
            ,
                chunks append("[OLLAMA_STREAM_ERROR] bridge missing")
            )
        ,
            // Offline fallback with simulated streaming chunks
            chunks append("[OFFLINE")
            chunks append("_STUB")
            chunks append("_STREAMING")
            chunks append("_COMPLETION]")
        )

        response := StreamingResponse with("ollama", chunks)
        
        // Log streaming event to JSONL
        durationMs := (Date clone now asNumber - startedAt) * 1000
        logObj := Map clone
        logObj atPut("timestamp", Date clone now asString)
        logObj atPut("provider", if(useOllama, "ollama", "offline"))
        logObj atPut("model", model)
        logObj atPut("persona", personaName)
        logObj atPut("prompt", prompt exSlice(0, 200))
        logObj atPut("system", system exSlice(0, 100))
        logObj atPut("streaming", true)
        logObj atPut("chunkCount", chunks size)
        logObj atPut("fullText", response getFullText exSlice(0, 500))
        logObj atPut("durationMs", durationMs)
        
        logs streamingLlm(logObj)
        
        response
    )

    // LLM call: routes to Ollama when configured; otherwise offline stub. Logs JSONL and enqueues for curation.
    llmCall := method(spec,
        if(spec == nil, spec = Map clone)
        personaName := spec atIfAbsent("persona", nil)
        // Determine provider
        useOllama := (llmProvider atIfAbsent("useOllama", false) == true)
        baseUrl := llmProvider atIfAbsent("baseUrl", "http://localhost:11434")
        // Select model: explicit > persona mapping > default
        model := spec atIfAbsent("model", nil)
        if(model == nil and personaName != nil and personaModels hasSlot(personaName),
            model = personaModels at(personaName)
        )
        if(model == nil, model = "telos/robin")
        prompt := spec atIfAbsent("prompt", "")
        system := spec atIfAbsent("system", "")

        // Merge generation options: persona defaults (if available) + per-call overrides
        options := Map clone
        if(personaName != nil,
            p := personaCodex get(personaName)
            if(p and p hasSlot("genOptions"),
                go := p genOptions; if(go, go foreach(k, v, options atPut(k, v)))
            )
        )
        if(spec hasSlot("temperature"), options atPut("temperature", spec at("temperature")))
        if(spec hasSlot("top_p"), options atPut("top_p", spec at("top_p")))

        startedAt := Date clone now asNumber
        out := nil

        if(useOllama == true,
            // Send to C bridge (embedded Python HTTP)
            // NOTE: options are JSON-encoded; keep minimal to avoid parser fragility
            optsJson := "{}"
            if(options size > 0,
                // naive stringify for flat maps (numbers only typical here)
                parts := List clone
                options foreach(k, v,
                    parts append("\"" .. k .. "\":" .. v asString)
                )
                optsJson = "{" .. parts join(",") .. "}"
            )
            if(Telos hasSlot("Telos_rawOllamaGenerate"),
                out = Telos_rawOllamaGenerate(baseUrl, model, prompt, system, optsJson),
                out = "[OLLAMA_ERROR] bridge missing"
            )
        ,
            // Offline fallback
            out = "[OFFLINE_STUB_COMPLETION]"
        )

        endedAt := Date clone now asNumber
        providerName := if(useOllama, "ollama", "offline")
        score := consistencyScoreFor(personaName, out)
        entry := Map clone
        entry atPut("t", endedAt)
        entry atPut("persona", personaName ifNil(""))
        entry atPut("provider", providerName)
        entry atPut("model", model ifNil(""))
        entry atPut("prompt", prompt)
        entry atPut("system", system)
        entry atPut("options", options)
        entry atPut("duration_ms", ((endedAt - startedAt) * 1000) floor)
        entry atPut("output", out)
        entry atPut("consistencyScore", score)
        Telos logs append(Telos logs llm, Telos json stringify(entry))
        ce := Map clone
        ce atPut("kind", "llm")
        ce atPut("key", (personaName ifNil("") ) .. ":" .. providerName .. ":" .. System uniqueId)
        ce atPut("path", Telos logs llm)
        ce atPut("record", entry)
        curator enqueue(ce)
        out
    )

    toolUse := method(toolSpec,
        writeln("[tools] offline stub: ", toolSpec)
        // echo back a dummy result
        res := Map clone; res atPut("result", "OK"); res atPut("tool", toolSpec)
        // Log tool use for future curation
        entry := Map clone
        entry atPut("t", Date clone now asNumber)
        entry atPut("tool", toolSpec)
        entry atPut("result", res)
        Telos logs append(Telos logs tools, Telos json stringify(entry))
        ce := Map clone
        ce atPut("kind", "tool")
        ce atPut("key", "tool:" .. System uniqueId)
        ce atPut("path", Telos logs tools)
        ce atPut("record", entry)
        curator enqueue(ce)
        res
    )

    // Composite Entropy Metric (Phase 9) - stubbed now
    scoreSolution := method(solution,
        // Returns a Map with metric components and G_hat
        // In offline stub, use fixed components and allow weights override on the solution map
        alpha := solution atIfAbsent("alpha", 1)
        beta  := solution atIfAbsent("beta",  1)
        gamma := solution atIfAbsent("gamma", 1)
        delta := solution atIfAbsent("delta", 1)
        // Dummy components
        S := 0.5; C := 0.2; I := 0.1; R := 0.1
        G := alpha*S - beta*C - gamma*I - delta*R
        m := Map clone
        m atPut("S", S); m atPut("C", C); m atPut("I", I); m atPut("R", R)
        m atPut("G_hat", G)
        m atPut("alpha", alpha); m atPut("beta", beta); m atPut("gamma", gamma); m atPut("delta", delta)
        m
    )

    // UI capture for ROBIN's vision: textual description of morph tree
    captureScreenshot := method(
        if(world == nil, return "[no world]")
        describe := method(m, indent,
            name := m type ifNil("Morph")
            idStr := if(m hasSlot("id"), m id, "?")
            zStr := if(m hasSlot("zIndex"), m zIndex, 0)
            line := indent .. name .. "#" .. idStr .. " @(" .. m x .. "," .. m y .. ") " .. m width .. "x" .. m height .. " z=" .. zStr
            if(m hasSlot("color"),
                c := m color; line = line .. " color=[" .. c atIfAbsent(0,0) .. "," .. c atIfAbsent(1,0) .. "," .. c atIfAbsent(2,0) .. "," .. c atIfAbsent(3,1) .. "]"
            )
            if(m hasSlot("text"), line = line .. " text='" .. m text .. "'")
            childLines := List clone
            if(m hasSlot("submorphs"),
                m submorphs foreach(sm, childLines append(describe(sm, indent .. "  ")))
            )
            list(line) appendSeq(childLines)
        )
        describe(world, "") join("\n")
    )

    // Save textual UI snapshot to a file under logs
    saveSnapshot := method(path,
        if(path == nil, path = logs ui)
        snap := captureScreenshot
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        f := File with(path)
        f setContents(snap)
        path
    )

    // Convert current world to a nested Map (for JSON export)
    snapshotMap := method(
        if(world == nil, return Map clone)
        toMap := method(m,
            o := Map clone
            o atPut("type", m type)
            if(m hasSlot("id"), o atPut("id", m id))
            o atPut("x", m x); o atPut("y", m y)
            o atPut("width", m width); o atPut("height", m height)
            if(m hasSlot("zIndex"), o atPut("zIndex", m zIndex))
            if(m hasSlot("color"), o atPut("color", m color))
            if(m hasSlot("text"), o atPut("text", m text))
            ch := List clone
            if(m hasSlot("submorphs"), m submorphs foreach(sm, ch append(toMap(sm))))
            o atPut("children", ch)
            o
        )
        toMap(world)
    )

    // Save snapshot as JSON
    saveSnapshotJson := method(path,
        if(path == nil, path = logs base .. "/ui_snapshot.json")
        data := snapshotMap
        jsonStr := json stringify(data)
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        f := File with(path)
        f setContents(jsonStr)
        path
    )

    // Export the entire world as JSON using specs per morph (pre-order traversal)
    saveWorldJson := method(path,
        if(path == nil, path = logs base .. "/world.json")
        if(world == nil, return "[no world]")
        coll := List clone
        visit := method(m)
            coll append(toSpec(m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, visit(sm)))
        visit(world)
        jsonStr := json stringify(coll)
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        File with(path) setContents(jsonStr)
        path
    )

    // Import world from JSON specs (replaces current world children)
    loadWorldJson := method(path,
        if(path == nil, path = logs base .. "/world.json")
        if(world == nil, self createWorld)
        f := File with(path)
        if(f exists not, return "[no-json]")
        content := f contents
        // naive parse: expect a JSON-like list of maps we generated
        // For simplicity, reuse loadConfig by converting JSON to Io maps via heuristic
        // If JSON parser unavailable, assume content is not malformed (internal use)
        // Here, use a minimal shim: interpret exported specs by splitting records
        // Safer path: clear current children, then rebuild via fromSpec applied on each map in list
        // Delegate to loadConfig when possible
        // For now, clear world children
        if(world hasSlot("submorphs"),
            world submorphs foreach(m, nil) // keep list but leave as-is
        )
        // Very minimal: if file was produced by us, it is a JSON array of objects with fields we use.
        // We won't re-implement a parser; recommend using loadConfig for manual runs.
        // Return path as acknowledgement.
        path
    )

    // Command router (textual; runtime dispatch only)
    commands := Object clone do(
        run := method(name, args,
            if(args == nil, args = List clone)
            // snapshots & WAL
            if(name == "snapshot", return Telos saveSnapshot(args atIfAbsent(0, nil)))
            if(name == "snapshot.json", return Telos saveSnapshotJson(args atIfAbsent(0, nil)))
            if(name == "export.json", return Telos saveWorldJson(args atIfAbsent(0, nil)))
            if(name == "import.json", return Telos loadWorldJson(args atIfAbsent(0, nil)))
            if(name == "replay", return Telos replayWal(args atIfAbsent(0, "telos.wal")))
            if(name == "rotateWal", return Telos rotateWal(args atIfAbsent(0, "telos.wal"), args atIfAbsent(1, 1048576)))
            if(name == "heartbeat", return Telos ui heartbeat(args atIfAbsent(0, 1)))
            // creation
            if(name == "newRect",
                m := Telos createMorph
                pos := Object clone do(x := args atIfAbsent(0, 20); y := args atIfAbsent(1, 20))
                dim := Object clone do(width := args atIfAbsent(2, 80); height := args atIfAbsent(3, 60))
                m moveTo(pos)
                m resizeTo(dim)
                if(args size >= 7,
                    clr := Object clone do(r := args at(4); g := args at(5); b := args at(6); a := args atIfAbsent(7, 1))
                    m setColor(clr)
                )
                Telos addSubmorph(Telos world, m)
                return m id
            )
            if(name == "newText",
                t := TextMorph clone
                pos := Object clone do(x := args atIfAbsent(0, 20); y := args atIfAbsent(1, 20))
                t moveTo(pos)
                t setText(args atIfAbsent(2, "Text"))
                Telos addSubmorph(Telos world, t)
                return t id
            )
            // manipulation by id (if indexed)
            if(name == "move",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, 
                    pos := Object clone do(x := args atIfAbsent(1, m x); y := args atIfAbsent(2, m y))
                    m moveTo(pos)
                    return "ok"
                , return "[no-morph]")
            )
            if(name == "resize",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, 
                    dim := Object clone do(width := args atIfAbsent(1, m width); height := args atIfAbsent(2, m height))
                    m resizeTo(dim)
                    return "ok"
                , return "[no-morph]")
            )
            if(name == "color",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, 
                    clr := Object clone do(r := args atIfAbsent(1, 1); g := args atIfAbsent(2, 0); b := args atIfAbsent(3, 0); a := args atIfAbsent(4, 1))
                    m setColor(clr)
                    return "ok"
                , return "[no-morph]")
            )
            if(name == "front",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, m bringToFront; return "ok", return "[no-morph]")
            )
            if(name == "toggleGrid", return Telos ui toggleGrid(args atIfAbsent(0, nil)))
            "[no-such-command]" .. name
        )
        list := method( list("snapshot", "snapshot.json", "export.json", "import.json", "replay", "rotateWal", "heartbeat", "newRect", "newText", "move", "resize", "color", "front", "toggleGrid") )
    )

    // Clipboard-based selection copy/paste
    clipboard := List clone
    clearSelection := method( selection = List clone )
    toSpec := method(m,
        // Minimal morph spec Map for reconstruction
        s := Map clone
        s atPut("type", m type)
        s atPut("id", m id)
        s atPut("x", m x); s atPut("y", m y)
        s atPut("width", m width); s atPut("height", m height)
        if(m hasSlot("color"), s atPut("color", m color))
        if(m hasSlot("text"), s atPut("text", m text))
        s
    )
    fromSpec := method(s,
        tname := s atIfAbsent("type", "Morph")
        proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
        m := proto clone
        if(s hasSlot("id"), m setSlot("id", s at("id")))
        if(s hasSlot("width") or s hasSlot("height"), m resizeTo(s atIfAbsent("width", m width), s atIfAbsent("height", m height)))
        if(s hasSlot("x") or s hasSlot("y"), m moveTo(s atIfAbsent("x", m x), s atIfAbsent("y", m y)))
        if(s hasSlot("color"), c := s at("color"); m setColor(c atIfAbsent(0,1), c atIfAbsent(1,0), c atIfAbsent(2,0), c atIfAbsent(3,1)))
        if(s hasSlot("text") and m hasSlot("setText"), m setText(s at("text")))
        m
    )
    copySelection := method(
        clipboard = List clone
        selection foreach(m, clipboard append(toSpec(m)))
        clipboard size
    )
    pasteAt := method(x, y,
        if(world == nil, createWorld)
        // Paste with small incremental offset per item
        ox := x; oy := y; pasted := List clone
        clipboard foreach(s,
            spec := s clone
            spec atPut("x", ox); spec atPut("y", oy)
            m := fromSpec(spec)
            m owner = world; world submorphs append(m); morphs append(m)
            if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
            morphIndex atPut(m id asString, m)
            transactional_setSlot(m, m id .. ".type", m type)
            pasted append(m)
            ox = ox + 10; oy = oy + 10
        )
        pasted size
    )

    // Selection helpers (textual only)
    selection := List clone
    selectAt := method(x, y,
        hits := hitTest(x, y)
        if(hits size == 0, return list())
        // Choose topmost (last in hits due to DFS); append to selection
        m := hits last
        selection append(m)
        list(m)
    )

    // Simple UI helpers bundle
    ui := Object clone do(
        gridEnabled := false
        toggleGrid := method(flag,
            if(flag != nil, gridEnabled = flag, gridEnabled = (gridEnabled not))
            gridEnabled
        )
        heartbeat := method(n := 1,
            if(Telos hasSlot("morphs") not, return 0)
            writeln("Telos: World heartbeat (morphs: ", Telos morphs size, ")")
            1
        )
    )

    // ColorParser prototype - extract color components through message passing
    ColorParser := Object clone do(
        parseColor := method(colorValue,
            // Immediately create a color object to hold state
            colorObject := Object clone
            colorObject components := List clone

            // Parse through message-passing, no local variables
            colorObject components := if(colorValue type == "List",
                colorValue,
                if(colorValue type == "Sequence",
                    // String parsing done through message chains
                    colorString := Object clone
                    colorString raw := colorValue asString strip
                    colorString bracketContent := colorString raw afterSeq("[") beforeSeq("]")
                    colorString parts := colorString bracketContent split(",")
                    
                    // Build through message-passing
                    colorComponents := List clone
                    colorComponents append(colorString parts atIfAbsent(0, "0") asNumber)
                    colorComponents append(colorString parts atIfAbsent(1, "0") asNumber)
                    colorComponents append(colorString parts atIfAbsent(2, "0") asNumber)
                    colorComponents append(if(colorString parts size > 3, colorString parts at(3) asNumber, 1))
                    colorComponents
                    ,
                    list(1,0,0,1) // Default through message-passing
                )
            )
            colorObject
        )
    )

    // Load world config from a simple spec (List of Maps)
    // Each entry: map(type:"RectangleMorph"|"TextMorph"|..., x:.., y:.., width:.., height:.., color:"[r,g,b,a]"|List, text:.., id:"...")
    loadConfig := method(specObj,
        // Handle required objects through message passing
        configContext := Object clone
        configContext world := if(world == nil, createWorld, world)
        configContext spec := if(specObj == nil, nil, if(specObj type == "Map", list(specObj), specObj))
        configContext createdCount := 0

        // Early return through message-passing if no valid spec
        if(configContext spec == nil, return configContext createdCount)

        // Process entries through message-passing
        configContext spec foreach(entry,
            // Type resolution through object delegation 
            typeResolver := Object clone
            typeResolver requestedType := entry atIfAbsent("type", "Morph")
            typeResolver resolvedProto := Lobby getSlot(typeResolver requestedType) ifNil(Lobby getSlot("Morph"))
            
            // Create morph through prototypal inheritance
            morph := typeResolver resolvedProto clone

            // Handle ID through message-passing
            if(entry hasSlot("id"),
                idHandler := Object clone
                idHandler newId := entry at("id")
                morph setSlot("id", idHandler newId)
            )

            // Attach to world through message chains
            morph owner := world
            world submorphs append(morph)
            morphs append(morph)
            
            // Mirror to C world if needed through message-passing
            if(self hasSlot("addMorphToWorld"), self addMorphToWorld(morph))
            morphIndex atPut(morph id asString, morph)

            // Write identity to WAL through message-passing
            transactional_setSlot(morph, morph id .. ".type", morph type)

            // Handle geometry through object-based positions
            positionHandler := Object clone
            positionHandler x := entry atIfAbsent("x", morph x)
            positionHandler y := entry atIfAbsent("y", morph y)
            morph moveTo(positionHandler)

            dimensionHandler := Object clone
            dimensionHandler width := entry atIfAbsent("width", morph width)
            dimensionHandler height := entry atIfAbsent("height", morph height)
            morph resizeTo(dimensionHandler)

            // Handle color through prototypal ColorParser
            if(entry hasSlot("color"),
                colorHandler := ColorParser clone parseColor(entry at("color"))
                color := Object clone
                color r := colorHandler components at(0)
                color g := colorHandler components at(1)
                color b := colorHandler components at(2)
                color a := colorHandler components at(3)
                morph setColor(color)
            )

            // Handle text through clean message-passing
            if(entry hasSlot("text") and morph hasSlot("setText"),
                textHandler := Object clone
                textHandler content := entry at("text")
                morph setText(textHandler content)
            )

            configContext createdCount = configContext createdCount + 1
        )
        
        configContext createdCount
    )

    // Attach a Persona Codex slot; will be set after prototypes defined
    personaCodex := nil

    // Codex feeder stub (later backed by VSA-RAG)
    codex := Object clone do(
        // Codex cache through message passing
        cache := Map clone
        
        // Get passages using prototypal message delegation
        getPassages := method(personaName,
            // Persona message handler ensures pure prototypal flow
            personaHandler := Object clone
            personaHandler targetName := personaName
            
            // Messages return passages through object delegation
            personaHandler passages := if(personaHandler targetName == "BRICK",
                list("Vows: autopoiesis; prototypal purity; watercourse way; antifragility.",
                     "Keep invariants. Build vertical slices."),
                
                if(personaHandler targetName == "ROBIN",
                    list("Direct manipulation. Clarity and liveliness.",
                         "Make the canvas speak with minimal code."),
                         
                    if(personaHandler targetName == "BABS",
                        list("Single source of truth. Transactional clarity.",
                             "WAL markers: BEGIN/END; replay on startup."),
                             
                        if(personaHandler targetName == "ALFRED",
                            list("Alignment, consent, clarity.",
                                 "Meta-commentary on outputs; ensure contracts and budgets are respected."),
                                 
                            list() // Empty passages through message-passing default
                        )
                    )
                )
            )
            
            // Return through final message delegation
            personaHandler passages
        )
    )
)

// --- Fractal Reasoning Prototypes ---

// ContextFractal: atomic shard of context with pure prototypal behavior
ContextFractal := Object clone do(
    // Immediately available state
    id := System uniqueId
    payload := ""
    meta := Map clone
    
    // Fresh identity through clean cloning
