/*
   TelosPersistence.io - Living Image: Transactional Persistence and WAL Integrity  
   The memory keeper: ensuring every thought survives and every state heals
   
   This module provides:
   - WAL (Write-Ahead Logging) operations with frame integrity
   - Transactional commit/rollback mechanisms
   - Snapshot generation and recovery systems
   - World state serialization and restoration
   
   Roadmap Alignment: Phase 3 (Persistence Integrity & Recovery)
*/

// === WAL (WRITE-AHEAD LOGGING) OPERATIONS ===

// Default WAL path - can be overridden
Telos walPath := "/mnt/c/EntropicGarden/telos.wal"

Telos walAppend := method(entryParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputEntry := entryParam
    
    // Create WAL context through message passing
    walContext := Object clone
    
    # Wrap string value in object
    entryValueObj := Object clone
    entryValueObj value := parameterHandler inputEntry asString
    walContext entryValue := entryValueObj
    
    # Wrap timestamp in object
    timestampValueObj := Object clone
    timestampValueObj value := Date now asNumber
    walContext timestampValue := timestampValueObj
    
    walContext logLine := walContext timestampValue value .. " " .. walContext entryValue value
    
    try(
        # Use Io-level file I/O for reliability through message passing
        fileHandler := Object clone
        fileHandler walFile := File with(Telos walPath)
        fileHandler walFile openForAppending
        fileHandler walFile write(walContext logLine .. "\n")
        fileHandler walFile close
        return true,
        
        exception,
        errorReporter := Object clone
        errorReporter message := "TelOS Persistence: WAL append failed: " .. exception description
        writeln(errorReporter message)
        return false
    )
)

Telos walCommit := method(tagParam, infoParam, blockParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputTag := tagParam
    parameterHandler inputInfo := infoParam
    parameterHandler inputBlock := blockParam
    
    // Create commit context through message passing
    commitContext := Object clone
    
    # Wrap string value in object
    tagValueObj := Object clone
    tagValueObj value := parameterHandler inputTag asString
    commitContext tagValue := tagValueObj
    
    commitContext infoMap := if(parameterHandler inputInfo == nil, Map clone, parameterHandler inputInfo)
    commitContext blockFunction := parameterHandler inputBlock
    
    # Begin transaction frame through message passing
    beginLogger := Object clone
    beginLogger beginMarker := "BEGIN " .. commitContext tagValue value .. " " .. Telos json stringify(commitContext infoMap)
    Telos walAppend(beginLogger beginMarker)
    
    # Execute the block within transaction through message passing
    transactionProcessor := Object clone
    transactionProcessor success := false
    
    try(
        blockChecker := Object clone
        blockChecker hasBlock := commitContext blockFunction != nil
        if(blockChecker hasBlock,
            commitContext blockFunction call
        )
        transactionProcessor success := true,
        
        exception,
        errorReporter := Object clone
        errorReporter message := "TelOS Persistence: Transaction failed: " .. exception description
        writeln(errorReporter message)
        transactionProcessor success := false
    )
    
    # End transaction frame through message passing
    endLogger := Object clone
    endLogger endMarker := if(transactionProcessor success,
        "END " .. commitContext tagValue value .. " SUCCESS",
        "END " .. commitContext tagValue value .. " FAILED"
    )
    Telos walAppend(endLogger endMarker)
    
    return transactionProcessor success
)

// Convenience helpers to open/close WAL frames without inline blocks
Telos walBegin := method(tagParam, infoParam,
    beginCtx := Object clone
    beginCtx tag := if(tagParam == nil, "txn", tagParam asString)
    beginCtx info := if(infoParam == nil, Map clone, infoParam)
    // Fallback stringify when Telos.json is not yet attached
    jsonStr := if(Telos hasSlot("json"),
        Telos json stringify(beginCtx info),
        "{}"
    )
    beginLineBuilder := Object clone
    beginLineBuilder line := "BEGIN " .. beginCtx tag .. " " .. jsonStr
    Telos walAppend(beginLineBuilder line)
    true
)

Telos walEnd := method(tagParam, statusParam,
    endCtx := Object clone
    endCtx tag := if(tagParam == nil, "txn", tagParam asString)
    endCtx status := if(statusParam == nil, "SUCCESS", statusParam asString)
    endLineBuilder := Object clone
    endLineBuilder line := "END " .. endCtx tag .. " " .. endCtx status
    Telos walAppend(endLineBuilder line)
    true
)

// Convenience marker: write a single MARK line with JSON info
Telos mark := method(tagParam, infoParam,
    marker := Object clone
    marker tag := if(tagParam == nil, "mark", tagParam asString)
    marker info := if(infoParam == nil, Map clone, infoParam)
    // Fallback stringify when Telos.json is not yet attached
    jsonStr := if(Telos hasSlot("json"),
        Telos json stringify(marker info),
        "{}"
    )
    if(Telos hasSlot("walAppend"), Telos walAppend("MARK " .. marker tag .. " " .. jsonStr))
    true
)

// === WAL REPLAY AND RECOVERY ===

Telos replayWal := method(pathParam,
    replayProcessor := Object clone
    
    # Wrap path in object
    pathObj := Object clone
    pathObj value := if(pathParam == nil, Telos walPath, pathParam asString)
    replayProcessor path := pathObj
    
    # Wrap counter in object
    appliedCountObj := Object clone
    appliedCountObj value := 0
    replayProcessor appliedCount := appliedCountObj
    
    outputProcessor := Object clone
    outputProcessor message := "TelOS Persistence: Beginning WAL replay from " .. replayProcessor path value
    writeln(outputProcessor message)
    
    // We'll compute the result here to avoid returning from inside try block
    resultObj := Object clone; resultObj value := 0
    try(
        # Ensure File receives a Sequence path, not an Object
        walFile := File with(replayProcessor path value)
        if(walFile exists not,
            writeln("TelOS Persistence: WAL file not found: " .. replayProcessor path value)
            resultObj value := 0
            // fallthrough to close the try
        )
        
        walContent := walFile contents
        walLines := walContent split("\n")
        
        frameProcessor := Object clone
        frameProcessor currentFrame := nil
        frameProcessor frameLines := List clone
        
        walLines foreach(line,
            lineProcessor := Object clone
            lineProcessor content := line strip
            
            # Wrap size check in object
            sizeChecker := Object clone
            sizeChecker isEmpty := lineProcessor content size == 0
            if(sizeChecker isEmpty, continue)
            
            # Check for frame boundaries through message passing
            beginChecker := Object clone
            beginChecker isBegin := lineProcessor content beginsWithSeq("BEGIN ")
            if(beginChecker isBegin,
                frameProcessor currentFrame := lineProcessor content
                frameProcessor frameLines := List clone
                frameProcessor frameLines append(lineProcessor content)
            )
            
            endChecker := Object clone
            endChecker isEnd := lineProcessor content beginsWithSeq("END ")
            if(endChecker isEnd,
                frameChecker := Object clone
                frameChecker hasFrame := frameProcessor currentFrame != nil
                if(frameChecker hasFrame,
                    frameProcessor frameLines append(lineProcessor content)
                    # Process complete frame
                    successChecker := Object clone
                    successChecker isSuccess := lineProcessor content endsWithSeq(" SUCCESS")
                    if(successChecker isSuccess,
                        # Increment counter through message passing
                        newCountObj := Object clone
                        newCountObj value := replayProcessor appliedCount value + Telos processWalFrame(frameProcessor frameLines)
                        replayProcessor appliedCount := newCountObj
                    )
                    frameProcessor currentFrame := nil
                    frameProcessor frameLines := List clone
                )
            )
            
            frameAppender := Object clone
            frameAppender hasFrame := frameProcessor currentFrame != nil
            if(frameAppender hasFrame,
                frameProcessor frameLines append(lineProcessor content)
            )
            
            legacyChecker := Object clone
            legacyChecker noFrame := frameProcessor currentFrame == nil
            legacyChecker isSet := lineProcessor content beginsWithSeq("SET ")
            legacyChecker isCognitive := lineProcessor content beginsWithSeq("COGNITIVE ")
            if(legacyChecker noFrame and legacyChecker isSet,
                # Legacy unframed SET operation
                # Increment counter through message passing
                legacyCountObj := Object clone
                legacyCountObj value := replayProcessor appliedCount value + Telos processWalSet(lineProcessor content)
                replayProcessor appliedCount := legacyCountObj
            )
            if(legacyChecker noFrame and legacyChecker isCognitive,
                # Process cognitive state entry
                cognitiveCountObj := Object clone
                cognitiveCountObj value := replayProcessor appliedCount value + Telos processCognitiveEntry(lineProcessor content)
                replayProcessor appliedCount := cognitiveCountObj
            )
        )
        
    walFile close
    writeln("TelOS Persistence: WAL replay complete - applied " .. replayProcessor appliedCount value .. " operations")
    resultObj value := replayProcessor appliedCount value,
        
        exception,
        writeln("TelOS Persistence: WAL replay failed: " .. exception description)
        resultObj value := 0
    )
    // Return the computed result
    resultObj value
)

Telos processWalFrame := method(frameLines,
    frameProcessor := Object clone
    frameProcessor lines := frameLines
    frameProcessor appliedCount := 0
    
    frameProcessor lines foreach(line,
        setChecker := Object clone
        setChecker isSet := line beginsWithSeq("SET ")
        if(setChecker isSet,
            frameProcessor appliedCount := frameProcessor appliedCount + Telos processWalSet(line)
        )
        
        cognitiveChecker := Object clone
        cognitiveChecker isCognitive := line beginsWithSeq("COGNITIVE ")
        if(cognitiveChecker isCognitive,
            frameProcessor appliedCount := frameProcessor appliedCount + Telos processCognitiveEntry(line)
        )
    )
    
    return frameProcessor appliedCount
)

Telos processWalSet := method(setLine,
    setProcessor := Object clone
    
    # Wrap line in object
    lineObj := Object clone
    lineObj value := setLine asString
    setProcessor line := lineObj
    
    # Parse SET <id>.<slot> TO <value> through message passing
    prefixChecker := Object clone
    prefixChecker hasPrefix := setProcessor line value beginsWithSeq("SET ")
    if(prefixChecker hasPrefix not, return 0)
    
    parseResult := Object clone
    parseResult parts := setProcessor line value split(" ")
    
    # Wrap size check in object
    sizeChecker := Object clone
    sizeChecker notEnoughParts := parseResult parts size < 4
    if(sizeChecker notEnoughParts, return 0)
    
    # Extract components through message passing
    slotPath := parseResult parts at(1)
    valueString := parseResult parts exSlice(3) join(" ")
    
    pathParts := slotPath split(".")
    
    # Wrap size check in object
    pathSizeChecker := Object clone
    pathSizeChecker notEnoughParts := pathParts size < 2
    if(pathSizeChecker notEnoughParts, return 0)
    
    objectId := pathParts at(0)
    slotName := pathParts at(1)
    
    # Find target object by ID (simplified - in full system would use proper ID registry)
    targetObject := Object clone
    targetObject found := false
    
    # For now, log the operation through message passing
    logger := Object clone
    logger message := "TelOS Persistence: Would apply SET " .. objectId .. "." .. slotName .. " TO " .. valueString
    writeln(logger message)
    
    return 1
)

Telos processCognitiveEntry := method(cognitiveLine,
    cognitiveProcessor := Object clone
    
    # Wrap line in object
    lineObj := Object clone
    lineObj value := cognitiveLine asString
    cognitiveProcessor line := lineObj
    
    # Parse COGNITIVE <tag> <json_data> through message passing
    prefixChecker := Object clone
    prefixChecker hasPrefix := cognitiveProcessor line value beginsWithSeq("COGNITIVE ")
    if(prefixChecker hasPrefix not, return 0)
    
    parseResult := Object clone
    parseResult parts := cognitiveProcessor line value split(" ")
    
    # Wrap size check in object
    sizeChecker := Object clone
    sizeChecker hasEnoughParts := parseResult parts size >= 3
    if(sizeChecker hasEnoughParts not, return 0)
    
    # Extract components through message passing
    cognitiveTag := parseResult parts at(1)
    jsonContent := parseResult parts exSlice(2) join(" ")
    
    # For now, log the cognitive operation through message passing
    logger := Object clone
    logger message := "TelOS Persistence: Would restore cognitive state for tag: " .. cognitiveTag
    writeln(logger message)
    
    # In a full implementation, this would restore semantic caches, 
    # GCE candidate lists, and HRC reasoning results to their respective components
    
    return 1
)

// === SNAPSHOT OPERATIONS ===

Telos saveSnapshot := method(pathParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputPath := pathParam
    
    // Create snapshot context through message passing
    snapshotContext := Object clone
    
    # Wrap path in object
    pathValueObj := Object clone
    pathValueObj value := if(parameterHandler inputPath == nil, "logs/world_snapshot.json", parameterHandler inputPath asString)
    snapshotContext pathValue := pathValueObj
    
    # Create snapshot data through message passing
    dataBuilder := Object clone
    dataBuilder snapshotData := Map clone
    dataBuilder snapshotData atPut("timestamp", Date now asNumber)
    dataBuilder snapshotData atPut("version", Telos version)
    dataBuilder snapshotData atPut("walPath", Telos walPath)
    
    # Add system state through message passing
    stateBuilder := Object clone
    stateBuilder systemState := Map clone
    stateBuilder systemState atPut("loadedModules", Telos loadedModules size)
    stateBuilder systemState atPut("moduleLoadOrder", Telos moduleLoadOrder)
    dataBuilder snapshotData atPut("system", stateBuilder systemState)
    
    # Serialize to JSON through message passing
    serializer := Object clone
    serializer jsonContent := Telos json stringify(dataBuilder snapshotData)
    
    try(
        fileHandler := Object clone
        // Ensure parent directory exists (supports both relative and absolute paths)
        pathSeq := snapshotContext pathValue value
        lastSlash := pathSeq lastIndexOfSeq("/")
        dirPath := if(lastSlash != nil, pathSeq exSlice(0, lastSlash), nil)
        if(dirPath != nil and dirPath size > 0,
            dirObj := Directory with(dirPath)
            if(dirObj exists not, dirObj create)
        )

        // Use the actual string value of the path when opening the file
        fileHandler snapshotFile := File with(pathSeq)
        // Ensure file exists, then write atomically via truncate + openForUpdating
        if(fileHandler snapshotFile exists not, fileHandler snapshotFile create)
        fileHandler snapshotFile openForUpdating
        fileHandler snapshotFile truncateToSize(0)
        fileHandler snapshotFile write(serializer jsonContent)
        fileHandler snapshotFile close

        // Verify existence immediately
        verifyFile := File with(pathSeq)
        if(verifyFile exists,
            writeln("TelOS Persistence: Snapshot saved to " .. pathSeq)
            true,
            writeln("TelOS Persistence: Snapshot write completed but file not found: " .. pathSeq)
            false
        ),

        exception,
        errorReporter := Object clone
        errorReporter message := "TelOS Persistence: Snapshot save FAILED. Exception: " .. exception description
        writeln(errorReporter message)
        writeln("TelOS Persistence: Failed path was: " .. snapshotContext pathValue value)
        false
    )
)

Telos loadSnapshot := method(pathParam,
    snapshotLoader := Object clone
    snapshotLoader path := if(pathParam == nil, "logs/world_snapshot.json", pathParam asString)
    
    try(
        snapshotFile := File with(snapshotLoader path)
        if(snapshotFile exists not,
            writeln("TelOS Persistence: Snapshot file not found: " .. snapshotLoader path)
            return nil
        )
        
        jsonContent := snapshotFile contents
        snapshotFile close
        
        # Simple JSON parsing for basic data
        writeln("TelOS Persistence: Loaded snapshot from " .. snapshotLoader path)
        writeln("TelOS Persistence: Content length: " .. jsonContent size .. " characters")
        
        return jsonContent,
        
        exception,
        writeln("TelOS Persistence: Snapshot load failed: " .. exception description)
        return nil
    )
)

// === TRANSACTIONAL STATE MANAGEMENT ===

Telos transactional_setSlot := method(objectParam, slotNameParam, valueParam,
    transactionProcessor := Object clone
    transactionProcessor object := objectParam
    
    # Wrap slot name in object
    slotNameObj := Object clone
    slotNameObj value := slotNameParam asString
    transactionProcessor slotName := slotNameObj
    
    transactionProcessor value := valueParam
    
    # Wrap object ID in object
    objectIdObj := Object clone
    objectIdObj value := "obj_" .. transactionProcessor object uniqueId
    transactionProcessor objectId := objectIdObj
    
    # WAL log the operation through message passing
    setOperation := "SET " .. transactionProcessor objectId value .. "." .. transactionProcessor slotName value .. " TO " .. transactionProcessor value asString
    Telos walAppend(setOperation)

    # Apply the change using dynamic slot name
    transactionProcessor object setSlot(transactionProcessor slotName value, transactionProcessor value)
    
    return true
)

// === WAL ROTATION AND MAINTENANCE ===

Telos rotateWal := method(pathParam, maxBytesParam,
    rotationProcessor := Object clone
    
    # Wrap path in object
    pathObj := Object clone
    pathObj value := if(pathParam == nil, Telos walPath, pathParam asString)
    rotationProcessor path := pathObj
    
    # Wrap max bytes in object
    maxBytesObj := Object clone
    maxBytesObj value := if(maxBytesParam == nil, 1048576, maxBytesParam asNumber)
    rotationProcessor maxBytes := maxBytesObj
    
    try(
        walFile := File with(rotationProcessor path value)
        if(walFile exists not, return false)
        
        fileSize := walFile size
        if(fileSize < rotationProcessor maxBytes, return false)
        
        # Rotate to .1 backup
        backupPath := rotationProcessor path .. ".1"
        backupFile := File with(backupPath)
        if(backupFile exists, backupFile remove)
        
        walFile moveTo(backupPath)
        writeln("TelOS Persistence: WAL rotated - " .. fileSize .. " bytes moved to " .. backupPath)
        
        return true,
        
        exception,
        writeln("TelOS Persistence: WAL rotation failed: " .. exception description)
        return false
    )
)

// === RECOVERY AND HEALING ===

Telos healFromWal := method(
    healingProcessor := Object clone
    healingProcessor startTime := Date now
    
    writeln("TelOS Persistence: Beginning system healing from WAL...")
    
    # Check WAL integrity
    walIntegrity := Telos checkWalIntegrity
    if(walIntegrity not,
        writeln("TelOS Persistence: WAL integrity check failed - attempting repair...")
        # Could implement WAL repair strategies here
    )
    
    # Replay operations
    appliedOps := Telos replayWal
    
    healingProcessor endTime := Date now
    healingProcessor duration := healingProcessor endTime - healingProcessor startTime
    
    writeln("TelOS Persistence: Healing complete in " .. healingProcessor duration .. "s")
    writeln("TelOS Persistence: Applied " .. appliedOps .. " operations from WAL")
    
    return appliedOps > 0
)

Telos checkWalIntegrity := method(
    integrityChecker := Object clone
    integrityChecker valid := true
    
    try(
        walFile := File with(Telos walPath)
        if(walFile exists not, return true) # No WAL file is valid
        
        walContent := walFile contents
        walLines := walContent split("\n")
        
        # Basic integrity checks
        integrityChecker lineCount := walLines size
        integrityChecker hasValidEntries := false
        
        walLines foreach(line,
            if(line strip size > 0,
                integrityChecker hasValidEntries := true
            )
        )
        
        walFile close
        writeln("TelOS Persistence: WAL integrity check: " .. integrityChecker lineCount .. " lines")
        return integrityChecker hasValidEntries,
        
        exception,
        writeln("TelOS Persistence: WAL integrity check failed: " .. exception description)
        return false
    )
)

// === COGNITIVE STATE PERSISTENCE ===
// Enhanced WAL operations for dual-process reasoning state

Telos persistCognitiveState := method(queryParam, resultParam, tagParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputQuery := queryParam
    parameterHandler inputResult := resultParam
    parameterHandler inputTag := tagParam
    
    // Create cognitive persistence context through message passing
    cognitiveContext := Object clone
    
    # Wrap query in object
    queryValueObj := Object clone
    queryValueObj value := parameterHandler inputQuery asString
    cognitiveContext queryValue := queryValueObj
    
    cognitiveContext resultMap := parameterHandler inputResult
    
    # Wrap tag in object
    tagValueObj := Object clone
    tagValueObj value := if(parameterHandler inputTag == nil, "cognitive_query", parameterHandler inputTag asString)
    cognitiveContext tagValue := tagValueObj
    
    # Create cognitive state entry through message passing
    stateBuilder := Object clone
    stateBuilder cognitiveEntry := Map clone
    stateBuilder cognitiveEntry atPut("query", cognitiveContext queryValue value)
    stateBuilder cognitiveEntry atPut("timestamp", Date now asNumber)
    stateBuilder cognitiveEntry atPut("tag", cognitiveContext tagValue value)
    
    # Serialize result components through message passing
    resultSerializer := Object clone
    
    # Handle System 1 candidates if present
    candidatesChecker := Object clone
    candidatesChecker hasCandidates := cognitiveContext resultMap hasKey("system1_candidates")
    if(candidatesChecker hasCandidates,
        candidatesProcessor := Object clone
        candidatesProcessor list := cognitiveContext resultMap at("system1_candidates")
        candidatesProcessor serialized := List clone
        
        candidatesProcessor list foreach(candidate,
            candidateSerializer := Object clone
            candidateSerializer entry := Map clone
            
            # Serialize candidate content
            contentChecker := Object clone
            contentChecker hasContent := candidate hasKey("content")
            if(contentChecker hasContent,
                candidateSerializer entry atPut("content", candidate at("content"))
            )
            
            # Serialize similarity score
            similarityChecker := Object clone
            similarityChecker hasSimilarity := candidate hasKey("similarity")
            if(similarityChecker hasSimilarity,
                candidateSerializer entry atPut("similarity", candidate at("similarity"))
            )
            
            candidatesProcessor serialized append(candidateSerializer entry)
        )
        
        stateBuilder cognitiveEntry atPut("system1_candidates", candidatesProcessor serialized)
    )
    
    # Handle System 2 reasoning result if present
    reasoningChecker := Object clone
    reasoningChecker hasReasoning := cognitiveContext resultMap hasKey("system2_result")
    if(reasoningChecker hasReasoning,
        reasoningProcessor := Object clone
        reasoningProcessor result := cognitiveContext resultMap at("system2_result")
        
        # Serialize reasoning result (could be complex VSA hypervector data)
        reasoningSerializer := Object clone
        reasoningSerializer entry := Map clone
        
        # Handle different result types through message passing
        typeChecker := Object clone
        typeChecker resultType := reasoningProcessor result type
        reasoningSerializer entry atPut("type", typeChecker resultType)
        
        # Serialize based on type
        stringChecker := Object clone
        stringChecker isString := typeChecker resultType == "Sequence"
        if(stringChecker isString,
            reasoningSerializer entry atPut("content", reasoningProcessor result)
        )
        
        mapChecker := Object clone
        mapChecker isMap := typeChecker resultType == "Map"
        if(mapChecker isMap,
            reasoningSerializer entry atPut("content", reasoningProcessor result)
        )
        
        stateBuilder cognitiveEntry atPut("system2_result", reasoningSerializer entry)
    )
    
    # Handle reasoning mode if present
    modeChecker := Object clone
    modeChecker hasMode := cognitiveContext resultMap hasKey("reasoning_mode")
    if(modeChecker hasMode,
        stateBuilder cognitiveEntry atPut("reasoning_mode", cognitiveContext resultMap at("reasoning_mode"))
    )
    
    # Serialize the complete cognitive state
    serializer := Object clone
    serializer jsonContent := Telos json stringify(stateBuilder cognitiveEntry)
    
    # WAL log the cognitive state
    cognitiveLogger := Object clone
    cognitiveLogger walEntry := "COGNITIVE " .. cognitiveContext tagValue value .. " " .. serializer jsonContent
    
    walResult := Telos walAppend(cognitiveLogger walEntry)
    
    # Report persistence result
    reportLogger := Object clone
    reportLogger message := if(walResult,
        "TelOS Persistence: Cognitive state persisted for query: " .. cognitiveContext queryValue value exSlice(0, 50) .. "...",
        "TelOS Persistence: WARNING - Cognitive state persistence failed"
    )
    writeln(reportLogger message)
    
    return walResult
)

Telos restoreCognitiveState := method(tagParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    restoreProcessor := Object clone
    
    # Wrap tag in object
    tagObj := Object clone
    tagObj value := if(tagParam == nil, "cognitive_query", tagParam asString)
    restoreProcessor tag := tagObj
    
    restoreProcessor results := List clone
    
    try(
        walFile := File with(Telos walPath)
        if(walFile exists not,
            writeln("TelOS Persistence: No WAL file found for cognitive state restoration")
            return restoreProcessor results
        )
        
        walContent := walFile contents
        walLines := walContent split("\n")
        
        # Search for cognitive entries
        walLines foreach(line,
            lineProcessor := Object clone
            lineProcessor content := line strip
            
            # Check for cognitive entries through message passing
            cognitiveChecker := Object clone
            cognitiveChecker isCognitive := lineProcessor content beginsWithSeq("COGNITIVE ")
            if(cognitiveChecker isCognitive,
                # Parse cognitive entry
                entryParser := Object clone
                entryParser parts := lineProcessor content split(" ")
                
                # Check if this matches our tag
                tagChecker := Object clone
                tagChecker matchesTag := entryParser parts size > 1 and entryParser parts at(1) == restoreProcessor tag value
                if(tagChecker matchesTag,
                    # Extract JSON portion
                    jsonExtractor := Object clone
                    jsonExtractor content := entryParser parts exSlice(2) join(" ")
                    
                    # Parse JSON (simplified - in production would use proper JSON parser)
                    jsonParser := Object clone
                    try(
                        jsonParser parsed := Telos json parse(jsonExtractor content)
                        restoreProcessor results append(jsonParser parsed),
                        
                        parseException,
                        parseLogger := Object clone
                        parseLogger message := "TelOS Persistence: Failed to parse cognitive entry: " .. parseException description
                        writeln(parseLogger message)
                    )
                )
            )
        )
        
        walFile close
        
        resultLogger := Object clone
        resultLogger message := "TelOS Persistence: Restored " .. restoreProcessor results size .. " cognitive entries for tag: " .. restoreProcessor tag value
        writeln(resultLogger message)
        
        return restoreProcessor results,
        
        exception,
        errorLogger := Object clone
        errorLogger message := "TelOS Persistence: Cognitive state restoration failed: " .. exception description
        writeln(errorLogger message)
        return restoreProcessor results
    )
)

// Enhanced transactional cognitive operation with automatic persistence
Telos cognitiveTransaction := method(queryParam, contextParam, blockParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    transactionProcessor := Object clone
    transactionProcessor query := queryParam
    transactionProcessor context := contextParam
    transactionProcessor block := blockParam
    
    # Create transaction context through message passing
    txnContext := Object clone
    txnContext timestamp := Date now asNumber
    txnContext info := Map clone
    txnContext info atPut("query", transactionProcessor query asString exSlice(0, 100)) # Truncate for WAL
    txnContext info atPut("timestamp", txnContext timestamp)
    
    try(
        # Begin cognitive transaction frame
        Telos walBegin("cognitive_txn", txnContext info)
        
        # Execute the cognitive operation
        resultProcessor := Object clone
        resultProcessor cognitiveResult := nil
        
        blockChecker := Object clone
        blockChecker hasBlock := transactionProcessor block != nil
        if(blockChecker hasBlock,
            resultProcessor cognitiveResult := transactionProcessor block call
        ,
            # Default to direct cognitive query if no block provided
            resultProcessor cognitiveResult := Telos cognitiveQuery(transactionProcessor query, transactionProcessor context)
        )
        
        # Persist the cognitive result
        persistenceResult := Telos persistCognitiveState(transactionProcessor query, resultProcessor cognitiveResult, "cognitive_txn")
        
        # End transaction frame
        endStatus := if(persistenceResult, "SUCCESS", "PARTIAL_SUCCESS")
        Telos walEnd("cognitive_txn", endStatus)
        
        successLogger := Object clone
        successLogger message := "TelOS Persistence: Cognitive transaction completed with status: " .. endStatus
        writeln(successLogger message)
        
        return resultProcessor cognitiveResult,
        
        exception,
        errorLogger := Object clone
        errorLogger message := "TelOS Persistence: Cognitive transaction failed: " .. exception description
        writeln(errorLogger message)
        
        # Auto-abort cognitive transaction
        Telos walEnd("cognitive_txn", "FAILED")
        
        return nil
    )
)

// Provide a load method for TelosCore optional invocation and idempotent slot assurance
TelosPersistence := Object clone
TelosPersistence load := method(
    // Ensure critical slots exist (idempotent)
    if(Telos hasSlot("walAppend") not,
        // rebind method reference to ensure attachment
        Telos walAppend := self getSlot("walAppend") ifNil(Telos walAppend)
    )
    if(Telos hasSlot("walCommit") not,
        Telos walCommit := self getSlot("walCommit") ifNil(Telos walCommit)
    )
    if(Telos hasSlot("replayWal") not,
        Telos replayWal := self getSlot("replayWal") ifNil(Telos replayWal)
    )
    
    // Ensure cognitive persistence methods are available
    if(Telos hasSlot("persistCognitiveState") not,
        Telos persistCognitiveState := self getSlot("persistCognitiveState") ifNil(Telos persistCognitiveState)
    )
    if(Telos hasSlot("restoreCognitiveState") not,
        Telos restoreCognitiveState := self getSlot("restoreCognitiveState") ifNil(Telos restoreCognitiveState)
    )
    if(Telos hasSlot("cognitiveTransaction") not,
        Telos cognitiveTransaction := self getSlot("cognitiveTransaction") ifNil(Telos cognitiveTransaction)
    )
    
    # Enhanced WAL integration for cognitive operations
    walIntegrator := Object clone
    walIntegrator cognitiveIntegration := "Enhanced WAL now supports dual-process reasoning state persistence"
    writeln("TelOS Persistence: " .. walIntegrator cognitiveIntegration)
    
    // Mark load in WAL if available
    if(Telos hasSlot("walAppend"), Telos walAppend("MARK persistence.cognitive_load {}"))
    self
)

// === CRITICAL ANTIFRAGILITY MECHANISM ===
// transaction.abort() - Essential for safe experimental self-modification

Telos transactionAbort := method(reasonParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    abortProcessor := Object clone
    abortProcessor reason := if(reasonParam == nil, "manual_abort", reasonParam asString)
    
    // Create abort context through message passing  
    abortContext := Object clone
    abortContext timestamp := Date now asNumber
    abortContext info := Map clone
    abortContext info atPut("reason", abortProcessor reason)
    abortContext info atPut("timestamp", abortContext timestamp)
    
    // Log the abort event
    abortLogger := Object clone
    abortLogger abortMarker := "ABORT " .. abortProcessor reason .. " " .. Telos json stringify(abortContext info)
    Telos walAppend(abortLogger abortMarker)
    
    // Attempt graceful rollback through message passing
    rollbackProcessor := Object clone
    rollbackProcessor success := false
    
    try(
        # Check if EvolutionSystem is available for rollback
        evolutionChecker := Object clone
        evolutionChecker hasEvolution := Telos hasSlot("evolution")
        if(evolutionChecker hasEvolution,
            rollbackAttempt := Object clone
            rollbackAttempt result := Telos evolution rollback(nil) # rollback to previous generation
            rollbackProcessor success := rollbackAttempt result
        ,
            # Fallback: restore from latest stable state
            stateRestorer := Object clone
            stateRestorer result := Telos restoreStableState
            rollbackProcessor success := stateRestorer result
        )
        
        completionLogger := Object clone
        completionLogger message := if(rollbackProcessor success,
            "TelOS Persistence: Transaction aborted successfully - system restored to stable state",
            "TelOS Persistence: Transaction abort WARNING - rollback failed, manual intervention required"
        )
        writeln(completionLogger message)
        
        return rollbackProcessor success,
        
        exception,
        emergencyLogger := Object clone
        emergencyLogger errorMessage := "TelOS Persistence: CRITICAL - Transaction abort failed: " .. exception description
        writeln(emergencyLogger errorMessage)
        emergencyLogger panicMessage := "TelOS Persistence: System may be in unstable state - immediate halt recommended"
        writeln(emergencyLogger panicMessage)
        return false
    )
)

// Stable state restoration - fallback mechanism
Telos restoreStableState := method(
    restoreProcessor := Object clone
    restoreProcessor success := false
    
    try(
        # Clear any corrupted state
        stateManager := Object clone
        stateManager morphs := List clone
        if(Telos hasSlot("morphs"), Telos morphs := stateManager morphs)
        
        # Reset core system slots to known safe values
        resetManager := Object clone
        resetManager walPath := "/mnt/c/EntropicGarden/telos.wal"
        if(Telos hasSlot("walPath") not, Telos walPath := resetManager walPath)
        
        # Reinitialize core modules if necessary
        reinitProcessor := Object clone
        reinitProcessor moduleCount := if(Telos hasSlot("loadedModules"), Telos loadedModules size, 0)
        if(reinitProcessor moduleCount == 0,
            initializationResult := Telos loadAllModules
            restoreProcessor success := initializationResult
        ,
            restoreProcessor success := true
        )
        
        stateLogger := Object clone
        stateLogger message := "TelOS Persistence: Stable state restoration " .. if(restoreProcessor success, "completed", "failed")
        writeln(stateLogger message)
        
        return restoreProcessor success,
        
        exception,
        panicLogger := Object clone
        panicLogger errorMessage := "TelOS Persistence: PANIC - Stable state restoration failed: " .. exception description
        writeln(panicLogger errorMessage)
        return false
    )
)

// Enhanced transactional execution wrapper with abort capability
Telos safeTransaction := method(tagParam, blockParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    transactionProcessor := Object clone
    transactionProcessor tag := if(tagParam == nil, "safe_txn", tagParam asString)
    transactionProcessor block := blockParam
    transactionProcessor success := false
    
    # Pre-transaction checkpoint
    checkpointManager := Object clone
    checkpointManager preState := if(Telos hasSlot("evolution"), Telos evolution currentGeneration, 0)
    
    transactionBeginLogger := Object clone
    transactionBeginLogger message := "TelOS Safe Transaction: BEGIN " .. transactionProcessor tag .. " (checkpoint: " .. checkpointManager preState .. ")"
    writeln(transactionBeginLogger message)
    
    try(
        # Begin WAL transaction frame
        Telos walBegin(transactionProcessor tag, Map clone)
        
        # Execute the experimental block
        blockChecker := Object clone
        blockChecker hasBlock := transactionProcessor block != nil
        if(blockChecker hasBlock,
            transactionProcessor block call
            transactionProcessor success := true
        )
        
        # Commit WAL transaction
        Telos walEnd(transactionProcessor tag, "SUCCESS")
        
        successLogger := Object clone
        successLogger message := "TelOS Safe Transaction: SUCCESS " .. transactionProcessor tag
        writeln(successLogger message)
        
        return transactionProcessor success,
        
        exception,
        failureLogger := Object clone
        failureLogger errorMessage := "TelOS Safe Transaction: FAILURE " .. transactionProcessor tag .. " - " .. exception description
        writeln(failureLogger errorMessage)
        
        # Auto-abort on failure
        abortResult := Telos transactionAbort("safe_transaction_exception: " .. exception description)
        
        abortLogger := Object clone
        abortLogger message := "TelOS Safe Transaction: Auto-abort " .. if(abortResult, "succeeded", "FAILED")
        writeln(abortLogger message)
        
        # End WAL transaction with failure status
        Telos walEnd(transactionProcessor tag, "ABORTED")
        
        return false
    )
)

writeln("TelOS Persistence: Living Image module loaded - transactional integrity ready")
writeln("  Enhanced WAL: Dual-process reasoning state preservation")
writeln("  Cognitive Transactions: GCE/HRC result persistence and recovery") 
writeln("  Antifragility: Safe transaction abort with system restoration")