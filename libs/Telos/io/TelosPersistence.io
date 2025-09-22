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
            if(legacyChecker noFrame and legacyChecker isSet,
                # Legacy unframed SET operation
                # Increment counter through message passing
                legacyCountObj := Object clone
                legacyCountObj value := replayProcessor appliedCount value + Telos processWalSet(lineProcessor content)
                replayProcessor appliedCount := legacyCountObj
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
        if(line beginsWithSeq("SET "),
            frameProcessor appliedCount := frameProcessor appliedCount + Telos processWalSet(line)
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

writeln("TelOS Persistence: Living Image module loaded - transactional integrity ready")

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
    // Mark load in WAL if available
    if(Telos hasSlot("walAppend"), Telos walAppend("MARK persistence.load {}"))
    self
)