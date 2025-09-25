/*
   TelosCore.io - Core Prototypal Foundation and System Initialization
   The zygote's first breath: establishing prototypal purity and system harmony
   
   This module provides:
   - Base Telos prototype establishment with immediate prototypal purity
   - Prototypal purity enforcement system 
   - Fundamental utilities (JSON, helpers, maps, lists)
   - System initialization and module loading coordination
   
   Roadmap Alignment: Phase 0-1 (Baseline Health, Autoload)
*/

// === PROTOTYPAL PURITY ENFORCEMENT SYSTEM ===
// CRITICAL FOUNDATION: Everything is an object accessed through message passing
// - Variables are messages sent to slots
// - Parameters are objects, not simple values  
// - No class-like static references allowed
// - All data flows through prototypal cloning and message sending

PrototypalPurityEnforcer := Object clone
PrototypalPurityEnforcer validateObjectAccess := method(value, context,
    # Wrap type check in object for prototypal purity
    typeChecker := Object clone
    typeChecker valueType := value type
    typeChecker isSequence := typeChecker valueType == "Sequence"
    
    if(typeChecker isSequence,
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

// === FOUNDATIONAL UTILITIES ===

// Provide a minimal global map(...) fallback (no-arg support) for this environment
map := method(
    mapObj := Map clone
    // Note: Named-argument parsing not implemented; acts as empty Map literal.
    mapObj
)

// Provide helpers on Map and List for safe access with defaults
Map atIfAbsent := method(key, default,
    valueObj := Object clone
    valueObj requested := self at(key)
    
    # Wrap nil check in object for prototypal purity
    nilChecker := Object clone
    nilChecker isNil := valueObj requested == nil
    if(nilChecker isNil, default, valueObj requested)
)

List atIfAbsent := method(index, default,
    indexObj := Object clone
    indexObj value := index
    
    # Wrap nil check in object
    nilChecker := Object clone
    nilChecker isNil := indexObj value isNil
    if(nilChecker isNil, return default)
    
    # Wrap comparison in object
    negativeChecker := Object clone
    negativeChecker isNegative := indexObj value < 0
    if(negativeChecker isNegative, return default)
    
    # Wrap size comparison in object
    sizeChecker := Object clone
    sizeChecker exceedsSize := self size <= indexObj value
    if(sizeChecker exceedsSize, return default)
    
    self at(indexObj value)
)

// === TELOS CORE PROTOTYPE ===

// Adopt the C-level Telos as prototype (registered on Lobby Protos)
Telos := Lobby Protos Telos clone

// Core system information and versioning
Telos version := "1.0.0"
Telos architecture := "modular-prototypal"
Telos buildDate := Date now
Telos modules := List clone
Telos selfCheck := true  // Enable prototypal purity checks by default

// === JSON UTILITIES ===
// Pure prototypal JSON handling with proper object message passing

Telos json := Object clone
Telos json escape := method(stringParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputString := stringParam
    
    // Create escape context through message passing
    escapeContext := Object clone
    escapeContext targetString := parameterHandler inputString asString
    escapeContext mutableString := escapeContext targetString asMutable
    
    // Apply escapes through message passing
    escapeContext mutableString replaceSeq("\\", "\\\\")
    escapeContext mutableString replaceSeq("\"", "\\\"")
    escapeContext mutableString replaceSeq("\n", "\\n")
    
    return escapeContext mutableString
)

Telos json stringify := method(valueParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputValue := valueParam
    
    // Create stringify context through message passing
    stringifyContext := Object clone
    stringifyContext targetValue := parameterHandler inputValue
    
    nullChecker := Object clone
    nullChecker isNull := stringifyContext targetValue == nil
    if(nullChecker isNull, return "null")
    
    // Type analysis through message passing
    typeAnalyzer := Object clone
    typeAnalyzer valueType := stringifyContext targetValue type
    
    if(typeAnalyzer valueType == "Number", return stringifyContext targetValue asString)
    if(typeAnalyzer valueType == "Sequence", 
        escapeProcessor := Object clone
        escapeProcessor escapedContent := Telos json escape(stringifyContext targetValue)
        return "\"" .. escapeProcessor escapedContent .. "\""
    )
    if(typeAnalyzer valueType == "List",
        listProcessor := Object clone
        listProcessor parts := stringifyContext targetValue map(item, Telos json stringify(item))
        return "[" .. listProcessor parts join(",") .. "]"
    )
    if(typeAnalyzer valueType == "Map",
        mapProcessor := Object clone
        mapProcessor parts := List clone
        stringifyContext targetValue foreach(keyItem, valueItem, 
            keyEscaper := Object clone
            keyEscaper escapedKey := Telos json escape(keyItem)
            valueStringifier := Object clone
            valueStringifier stringifiedValue := Telos json stringify(valueItem)
            pairAssembler := Object clone
            pairAssembler pairString := "\"" .. keyEscaper escapedKey .. "\":" .. valueStringifier stringifiedValue
            mapProcessor parts append(pairAssembler pairString)
        )
        return "{" .. mapProcessor parts join(",") .. "}"
    )
    if(stringifyContext targetValue == true, return "true")
    if(stringifyContext targetValue == false, return "false")
    
    // fallback through message passing
    fallbackProcessor := Object clone
    fallbackProcessor stringValue := stringifyContext targetValue asString
    escapeProcessor := Object clone
    escapeProcessor escapedContent := Telos json escape(fallbackProcessor stringValue)
    return "\"" .. escapeProcessor escapedContent .. "\""
)

// === MODULE LOADING SYSTEM ===

Telos loadedModules := Map clone
Telos moduleLoadOrder := List clone

// CRITICAL FIX: The C-level `loadModule` is the one we need to back up.
// The Io-level one is defined *after* this, so we were backing up nil.
TelosCore_loadModuleBackup := Telos getSlot("loadModule")

// DIAGNOSTIC: Confirm what we've actually backed up.
writeln("TelOS Core: Backing up initial loadModule method. Type: " .. TelosCore_loadModuleBackup type)

// WORKAROUND: Store the working loadModule method in a backup location
// TelosCore_loadModuleBackup := method(moduleNameParam,
// This is the definition of the Io-level loadModule, which we will assign later.
// We need to separate the backup from the definition.
Telos_Io_loadModule := method(moduleNameParam,
    // PROTOTYPAL PURITY: Parameters are objects accessed through message passing
    parameterHandler := Object clone
    parameterHandler inputModuleName := moduleNameParam
    
    // DIAGNOSTIC: Method entry point
    entryLogger := Object clone
    entryLogger message := "TelOS Core: loadModule ENTRY for '" .. parameterHandler inputModuleName .. "'"
    writeln(entryLogger message)
    
    // Create module loading context through message passing
    moduleContext := Object clone
    moduleContext moduleName := parameterHandler inputModuleName asString
    moduleContext modulePath := "/mnt/c/EntropicGarden/libs/Telos/io/" .. moduleContext moduleName .. ".io"
    
    // Check if already loaded through message passing
    loadChecker := Object clone
    loadChecker alreadyLoaded := Telos loadedModules hasSlot(moduleContext moduleName)
    
    // DIAGNOSTIC: Already loaded check
    alreadyLogger := Object clone
    alreadyLogger checkMessage := "TelOS Core: Already loaded check for '" .. moduleContext moduleName .. "' - result: " .. loadChecker alreadyLoaded
    writeln(alreadyLogger checkMessage)
    
    if(loadChecker alreadyLoaded,
        outputProcessor := Object clone
        outputProcessor message := "TelOS Core: Module '" .. moduleContext moduleName .. "' already loaded"
        writeln(outputProcessor message)
        
        # CRITICAL FIX: Verify the module actually extended Telos, if not, reload it
        verificationContext := Object clone
        verificationContext needsReload := false
        
        # Check for key methods from each module to verify actual loading
        if(moduleContext moduleName == "TelosPersistence",
            verificationContext needsReload := Telos hasSlot("walAppend") not
        )
        if(moduleContext moduleName == "TelosFFI", 
            verificationContext needsReload := Telos hasSlot("pyEval") not
        )
        if(moduleContext moduleName == "TelosMorphic",
            verificationContext needsReload := Telos hasSlot("createWorld") not
        )
        
        if(verificationContext needsReload,
            outputProcessor forceMessage := "TelOS Core: Module '" .. moduleContext moduleName .. "' marked loaded but missing methods - forcing reload"
            writeln(outputProcessor forceMessage)
        ,
            return true
        )
    )
    
    outputProcessor := Object clone
    outputProcessor loadMessage := "TelOS Core: Loading module '" .. moduleContext moduleName .. "'..."
    writeln(outputProcessor loadMessage)
    
    // Track success/failure through message passing
    successTracker := Object clone
    successTracker loadSuccess := false
    
    try(
        // Attempt to load the module file through message passing
        fileLoader := Object clone
        fileLoader moduleFile := File with(moduleContext modulePath)
        fileChecker := Object clone
        fileChecker exists := fileLoader moduleFile exists
        
        if(fileChecker exists,
            outputProcessor loadFileMessage := "TelOS Core: Loading file: " .. moduleContext modulePath
            writeln(outputProcessor loadFileMessage)
            doFile(moduleContext modulePath)
            outputProcessor loadedMessage := "TelOS Core: File loaded successfully for " .. moduleContext moduleName
            writeln(outputProcessor loadedMessage)
            
            // ARCHITECTURAL FIX: TelOS modules extend Telos prototype, not create global objects
            // Check if module created a global object OR extended Telos (correct approach)
            moduleLocator := Object clone
            moduleLocator moduleObj := Lobby getSlot(moduleContext moduleName)
            
            validationChecker := Object clone
            validationChecker hasGlobalObject := moduleLocator moduleObj != nil
            validationChecker hasLoadMethod := validationChecker hasGlobalObject and moduleLocator moduleObj hasSlot("load")
            validationChecker isTelosExtension := true  # Assume successful if file loaded without exception
            
            if(validationChecker hasLoadMethod,
                outputProcessor callMessage := "TelOS Core: Calling load method for " .. moduleContext moduleName
                writeln(outputProcessor callMessage)
                moduleLocator moduleObj load
                outputProcessor completeMessage := "TelOS Core: Load method completed for " .. moduleContext moduleName
                writeln(outputProcessor completeMessage)
            ,
                if(validationChecker hasGlobalObject,
                    outputProcessor objectMessage := "TelOS Core: Module " .. moduleContext moduleName .. " created global object (no load method)"
                    writeln(outputProcessor objectMessage)
                ,
                    outputProcessor extensionMessage := "TelOS Core: Module " .. moduleContext moduleName .. " extended Telos prototype (modular design)"
                    writeln(outputProcessor extensionMessage)
                )
            )
            
            Telos loadedModules atPut(moduleContext moduleName, true)
            Telos moduleLoadOrder append(moduleContext moduleName)
            outputProcessor successMessage := "TelOS Core: Successfully loaded module '" .. moduleContext moduleName .. "'"
            writeln(outputProcessor successMessage)
            successTracker loadSuccess := true
        ,
            outputProcessor notFoundMessage := "TelOS Core: Module file not found: " .. moduleContext modulePath
            writeln(outputProcessor notFoundMessage)
            successTracker loadSuccess := false
        )
    ,
        exception,
        errorReporter := Object clone
        errorReporter errorMessage := "TelOS Core: EXCEPTION loading module '" .. moduleContext moduleName .. "': " .. exception error
        writeln(errorReporter errorMessage)
        errorReporter typeMessage := "TelOS Core: Exception type: " .. exception type
        writeln(errorReporter typeMessage)
        
        errorChecker := Object clone
        errorChecker hasError := exception hasSlot("error")
        if(errorChecker hasError,
            errorReporter errorDetail := "TelOS Core: Exception error: " .. exception error
            writeln(errorReporter errorDetail)
        )
        
        messageChecker := Object clone
        messageChecker hasMessage := exception hasSlot("message")
        if(messageChecker hasMessage,
            errorReporter messageDetail := "TelOS Core: Exception message: " .. exception message
            writeln(errorReporter messageDetail)
        )
        
        caughtChecker := Object clone
        caughtChecker hasCaught := exception hasSlot("caughtMessage")
        if(caughtChecker hasCaught,
            errorReporter caughtDetail := "TelOS Core: Exception caughtMessage: " .. exception caughtMessage
            writeln(errorReporter caughtDetail)
        )
        
        # CRITICAL FIX: Return structured exception info instead of suppressing with false
        exceptionInfo := Object clone
        exceptionInfo success := false
        exceptionInfo exception := exception
        exceptionInfo moduleName := moduleContext moduleName
        exceptionInfo description := exception error
        exceptionInfo type := exception type
        
        writeln("TelOS Core: Returning structured exception info for: " .. moduleContext moduleName)
        return exceptionInfo
    )
    
    # DIAGNOSTIC ENHANCEMENT: Return success state for debugging
    debugReporter := Object clone
    debugReporter successState := successTracker loadSuccess
    debugReporter message := "TelOS Core: Final loadModule state for " .. moduleContext moduleName .. " - success: " .. debugReporter successState
    writeln(debugReporter message)
    
    if(successTracker loadSuccess,
        successInfo := Object clone
        successInfo success := true
        successInfo moduleName := moduleContext moduleName
        return successInfo
    ,
    failureInfo := Object clone
    failureInfo success := false
    failureInfo moduleName := moduleContext moduleName
    failureInfo reason := "File loading failed or no successful completion"
    // Provide fields often expected by legacy printers
    failureInfo type := "ModuleLoadFailure"
    failureInfo description := failureInfo reason
    return failureInfo
    )
)

// WORKAROUND: Restore the working loadModule method if it gets corrupted
writeln("TelOS Core: Restoring loadModule method...")
writeln("TelOS Core: TelosCore_loadModuleBackup type: " .. TelosCore_loadModuleBackup type)

# Force explicit method assignment (assign the Block, do not execute)
Telos setSlot("loadModule", getSlot("Telos_Io_loadModule"))

// DIAGNOSTIC: Verify method restoration
writeln("TelOS Core: loadModule method restored - type: " .. Telos getSlot("loadModule") type)
writeln("TelOS Core: Telos hasSlot loadModule: " .. Telos hasSlot("loadModule"))

Telos loadAllModules := method(
    moduleNames := list(
        "TelosPersistence",
        "TelosFFI",
        "TelosCognition",
        "TelosMorphic",
        "TelosMemory",
        "TelosPersona",
        "TelosQuery",
        "TelosLogging",
        "TelosCommands",
        "TelosOllama",
        "EnhancedBABSWINGLoop",
        "PersonaPrimingSystem"
    )
    
    loadTracker := Object clone
    loadTracker successCount := 0
    loadTracker totalCount := moduleNames size
    
    writeln("TelOS Core: Beginning sequential module loading...")
    
    // Force truly sequential loading with explicit error handling  
    loadTracker index := 0
    while(loadTracker index < moduleNames size,
        moduleName := moduleNames at(loadTracker index)
        writeln("TelOS Core: Processing module " .. (loadTracker index + 1) .. "/" .. moduleNames size .. ": " .. moduleName)
        
        # DIAGNOSTIC: Check moduleName type and value before loadModule call
        moduleNameAnalyzer := Object clone
        moduleNameAnalyzer nameValue := moduleName
        moduleNameAnalyzer nameType := moduleName type
        moduleNameAnalyzer nameString := moduleName asString
        writeln("TelOS Core: About to call loadModule with name: '" .. moduleNameAnalyzer nameString .. "' (type: " .. moduleNameAnalyzer nameType .. ")")
        
        moduleResult := Telos loadModule(moduleName)
        writeln("TelOS Core: loadModule returned: " .. moduleResult .. " for " .. moduleName)
        
        # DIAGNOSTIC ENHANCEMENT: Check if result is structured exception info
        resultAnalyzer := Object clone
        resultAnalyzer isStructuredResult := moduleResult hasSlot("success")
        
        if(resultAnalyzer isStructuredResult,
            if(moduleResult success,
                loadTracker successCount := loadTracker successCount + 1
                writeln("TelOS Core: Module " .. moduleName .. " completed successfully")
            ,
                writeln("TelOS Core: Module " .. moduleName .. " FAILED to load")
                // Guarded prints for optional slots
                if(moduleResult hasSlot("type"), writeln("TelOS Core: Exception type: " .. moduleResult type))
                if(moduleResult hasSlot("description"), writeln("TelOS Core: Exception description: " .. moduleResult description))
            )
        ,
            # Legacy boolean result handling
            if(moduleResult,
                loadTracker successCount := loadTracker successCount + 1
                writeln("TelOS Core: Module " .. moduleName .. " completed successfully")
            ,
                writeln("TelOS Core: Module " .. moduleName .. " FAILED to load (no diagnostic info)")
            )
        )
        
        loadTracker index := loadTracker index + 1
        
        // Explicit synchronization - ensure each step completes before next
        System sleep(0.1)
        yield
    )
    
    writeln("TelOS Core: Module loading complete: " .. loadTracker successCount .. "/" .. loadTracker totalCount .. " modules loaded")
    return loadTracker successCount == loadTracker totalCount
)

// === SYSTEM INITIALIZATION ===
// Prototypal system startup - no init methods, immediate initialization

initializeSystem := method(
    initProcessor := Object clone
    initProcessor startTime := Date now
    
    writeln("TelOS Core: System initialization beginning...")
    writeln("TelOS Core: Version " .. Telos version .. " (" .. Telos architecture .. ")")
    
    // Initialize core prototypal purity enforcement
    writeln("TelOS Core: Activating prototypal purity enforcement...")
    
    // Load all modules in dependency order
    moduleLoadSuccess := Telos loadAllModules
    
    initProcessor endTime := Date now
    initProcessor duration := initProcessor endTime - initProcessor startTime
    
    if(moduleLoadSuccess,
        writeln("TelOS Core: System initialization complete in " .. initProcessor duration .. "s")
        writeln("TelOS Core: All modules loaded successfully - system ready")
        return true
    ,
        writeln("TelOS Core: System initialization completed with warnings in " .. initProcessor duration .. "s")
        writeln("TelOS Core: Some modules failed to load - system partially ready")
        return false
    )
)

// === MODULE HEALTH MONITORING ===

Telos checkModuleHealth := method(
    healthChecker := Object clone
    healthChecker report := Map clone
    
    Telos loadedModules foreach(moduleName, status,
        healthChecker report atPut(moduleName, status)
    )
    
    healthChecker report atPut("coreReady", true)
    healthChecker report atPut("totalModules", Telos loadedModules size)
    healthChecker report
)

Telos listModules := method(
    moduleReporter := Object clone
    moduleReporter totalCount := Telos loadedModules size
    
    writeln("TelOS Loaded Modules (" .. moduleReporter totalCount .. " total):")
    writeln("═" repeated(50))
    
    Telos loadedModules foreach(moduleName, status,
        statusIndicator := Object clone
        statusIndicator symbol := if(status, "✓", "✗")
        statusIndicator color := if(status, "[OK]", "[FAIL]")
        
        writeln("  " .. statusIndicator symbol .. " " .. moduleName .. " " .. statusIndicator color)
    )
    
    writeln("═" repeated(50))
    writeln("System Status: " .. if(Telos loadedModules size == 11, "All modules operational", "Some modules missing"))
)

// === LLM INTERFACE FORWARDING ===

Telos llmCall := method(spec,
    // Forward LLM calls to TelosOllama module with proper prototypal handling
    llmProcessor := Object clone
    llmProcessor spec := spec
    
    // Extract parameters from spec using prototypal message passing
    paramExtractor := Object clone
    specAccessor := Object clone
    specAccessor spec := llmProcessor spec
    specAccessor getModel := method(spec getSlot("model"))
    specAccessor getPrompt := method(spec getSlot("prompt"))
    specAccessor getSystem := method(spec getSlot("system"))
    
    paramExtractor model := if(specAccessor getModel != nil, specAccessor getModel, "llama3.2:latest")
    paramExtractor prompt := if(specAccessor getPrompt != nil, specAccessor getPrompt, "")
    paramExtractor system := if(specAccessor getSystem != nil, specAccessor getSystem, "")
    
    // Combine system and prompt if both exist
    fullPromptBuilder := Object clone
    fullPromptBuilder combined := if(paramExtractor system isEmpty,
        paramExtractor prompt,
        paramExtractor system .. "\n\n" .. paramExtractor prompt
    )
    
    // Call TelosOllama with proper parameters
    result := TelosOllama sendToOllama(paramExtractor model, fullPromptBuilder combined)
    
    result
)

// === COGNITIVE SYSTEM VALIDATION ===

Telos validateCognition := method(
    validationProcessor := Object clone
    validationProcessor success := true
    validationProcessor details := Map clone
    
    writeln("TelOS Core: Beginning cognitive system validation...")
    
    # Check if cognition module was loaded
    cognitionChecker := Object clone
    cognitionChecker hasCognition := Telos hasSlot("cognition")
    validationProcessor details atPut("cognitionModuleLoaded", cognitionChecker hasCognition)
    
    if(cognitionChecker hasCognition not,
        writeln("TelOS Core: Cognition module not loaded - attempting initialization...")
        initResult := Telos initializeCognition
        if(initResult not,
            validationProcessor success := false
            writeln("TelOS Core: Cognition initialization failed")
            return validationProcessor details
        )
    )
    
    # Test System 1 (GCE) functionality
    gceChecker := Object clone
    gceChecker hasGCE := Telos cognition hasSlot("gce")
    validationProcessor details atPut("system1Available", gceChecker hasGCE)
    
    if(gceChecker hasGCE,
        try(
            # Add test content to semantic space
            testContent := "artificial intelligence reasoning system"
            Telos cognition gce addToSemanticSpace("test_concept", testContent)
            
            # Test retrieval
            testQuery := "intelligence"
            retrievalResult := Telos cognition gce retrieve(testQuery, nil)
            gceTestResult := (retrievalResult type == "List")
            validationProcessor details atPut("system1Working", gceTestResult)
            writeln("TelOS Core: System 1 (GCE) test - " .. if(gceTestResult, "PASSED", "FAILED"))
        ,
            exception,
            validationProcessor details atPut("system1Working", false)
            writeln("TelOS Core: System 1 (GCE) test failed: " .. exception description)
        )
    )
    
    # Test System 2 (HRC) functionality  
    hrcChecker := Object clone
    hrcChecker hasHRC := Telos cognition hasSlot("hrc")
    validationProcessor details atPut("system2Available", hrcChecker hasHRC)
    
    if(hrcChecker hasHRC,
        try(
            # Test reasoning with mock candidates
            testQuery := "bind concepts together"
            mockCandidates := List clone
            mockCandidate := Object clone
            mockCandidate vector := List clone; i := 0; while(i < 100, mockCandidate vector append(0.5); i := i + 1)
            mockCandidates append(mockCandidate)
            
            reasoningResult := Telos cognition hrc reason(testQuery, nil, mockCandidates)
            hrcTestResult := (reasoningResult type == "Map")
            validationProcessor details atPut("system2Working", hrcTestResult)
            writeln("TelOS Core: System 2 (HRC) test - " .. if(hrcTestResult, "PASSED", "FAILED"))
        ,
            exception,
            validationProcessor details atPut("system2Working", false)
            writeln("TelOS Core: System 2 (HRC) test failed: " .. exception description)
        )
    )
    
    # Test dual-process coordination
    coordinatorChecker := Object clone
    coordinatorChecker hasCoordinator := Telos hasSlot("cognitiveQuery")
    validationProcessor details atPut("dualProcessAvailable", coordinatorChecker hasCoordinator)
    
    if(coordinatorChecker hasCoordinator,
        try(
            testQuery := "reasoning test query"
            coordinationResult := Telos cognitiveQuery(testQuery, nil)
            coordinationTestResult := (coordinationResult type == "Map") and (coordinationResult hasSlot("system1_candidates")) and (coordinationResult hasSlot("system2_result"))
            validationProcessor details atPut("dualProcessWorking", coordinationTestResult)
            writeln("TelOS Core: Dual-Process Coordination test - " .. if(coordinationTestResult, "PASSED", "FAILED"))
        ,
            exception,
            validationProcessor details atPut("dualProcessWorking", false)
            writeln("TelOS Core: Dual-Process Coordination test failed: " .. exception description)
        )
    )
    
    # Overall validation result
    validationSummary := Object clone
    validationSummary system1OK := validationProcessor details atIfAbsent("system1Working", false)
    validationSummary system2OK := validationProcessor details atIfAbsent("system2Working", false)
    validationSummary coordinationOK := validationProcessor details atIfAbsent("dualProcessWorking", false)
    validationProcessor success := validationSummary system1OK and validationSummary system2OK and validationSummary coordinationOK
    
    statusLogger := Object clone
    statusLogger message := "TelOS Core: Cognitive validation " .. if(validationProcessor success, "COMPLETED SUCCESSFULLY", "FAILED - system may need attention")
    writeln(statusLogger message)
    
    writeln("TelOS Core: Cognitive System Status:")
    writeln("  System 1 (GCE): " .. if(validationSummary system1OK, "✓ ACTIVE", "✗ FAILED"))
    writeln("  System 2 (HRC): " .. if(validationSummary system2OK, "✓ ACTIVE", "✗ FAILED"))
    writeln("  Coordination: " .. if(validationSummary coordinationOK, "✓ ACTIVE", "✗ FAILED"))
    
    return validationProcessor details
)

// === GRACEFUL ERROR HANDLING ===

Telos handleError := method(errorParam, contextParam,
    errorProcessor := Object clone
    errorProcessor error := errorParam
    errorProcessor context := if(contextParam == nil, "unknown", contextParam asString)
    
    writeln("TelOS Core Error [" .. errorProcessor context .. "]: " .. errorProcessor error asString)
    
    // Attempt recovery based on error type
    recoveryAttempt := Object clone
    recoveryAttempt success := false
    
    // Basic recovery strategies can be added here
    
    return recoveryAttempt success
)

// === SLOT INITIALIZATION ===
// Initialize expected slots that may be accessed before modules define them

// Initialize core slots for graceful module loading
if(Telos hasSlot("morphs") not,
    Telos morphs := List clone
)

if(Telos hasSlot("walPath") not,
    Telos walPath := "/mnt/c/EntropicGarden/telos.wal"
)

if(Telos hasSlot("world") not,
    Telos world := Object clone
    Telos world submorphs := List clone
)

// === FULL SYSTEM INITIALIZATION AND VALIDATION ===

Telos initializeFullSystem := method(
    systemInitializer := Object clone
    systemInitializer success := true
    
    writeln("\n====================================================")
    writeln("    TelOS Full System Initialization Starting")
    writeln("====================================================\n")
    
    # Step 1: Core module loading
    writeln("Step 1: Loading core modules...")
    moduleResult := self loadAllModules
    if(moduleResult not,
        writeln("ERROR: Core module loading failed")
        return false
    )
    writeln("✓ Core modules loaded successfully\n")
    
    # Step 2: FFI initialization (if available)
    writeln("Step 2: Checking Foreign Function Interface...")
    ffiChecker := Object clone
    ffiChecker available := self hasSlot("ffi")
    if(ffiChecker available,
        writeln("✓ FFI system available\n")
    ,
        writeln("⚠ FFI system not yet available - continuing with core functionality\n")
    )
    
    # Step 3: Persistence system validation
    writeln("Step 3: Validating persistence system...")
    if(self hasSlot("persistence"),
        persistenceTest := try(
            # Test transaction functionality
            testResult := Telos persistence safeTransaction(block(
                return true
            ))
            testResult
        ) ifError(
            false
        )
        
        if(persistenceTest,
            writeln("✓ Persistence system operational\n")
        ,
            writeln("⚠ Persistence system may need attention\n")
        )
    ,
        writeln("⚠ Persistence module not loaded\n")
    )
    
    # Step 4: Cognitive system validation
    writeln("Step 4: Validating cognitive architecture...")
    cognitiveValidation := self validateCognition
    cognitiveResult := cognitiveValidation atIfAbsent("dualProcessWorking", false)
    
    if(cognitiveResult not,
        writeln("⚠ Cognitive system validation incomplete - continuing with basic functionality\n")
    )
    
    # Step 5: Final system status
    writeln("Step 5: System status summary...")
    statusChecker := Object clone
    statusChecker coreOK := true
    statusChecker ffiOK := ffiChecker available
    statusChecker persistenceOK := if(self hasSlot("persistence"), true, false)
    statusChecker cognitiveOK := cognitiveResult
    
    writeln("\n====================================================")
    writeln("    TelOS System Status Report")
    writeln("====================================================")
    writeln("Core Modules:     " .. if(statusChecker coreOK, "✓ ACTIVE", "✗ FAILED"))
    writeln("FFI Bridge:       " .. if(statusChecker ffiOK, "✓ ACTIVE", "⚠ PENDING"))
    writeln("Persistence:      " .. if(statusChecker persistenceOK, "✓ ACTIVE", "⚠ PENDING"))
    writeln("Cognition:        " .. if(statusChecker cognitiveOK, "✓ ACTIVE", "⚠ PARTIAL"))
    writeln("====================================================")
    
    overallStatus := statusChecker coreOK
    writeln("Overall Status:   " .. if(overallStatus, "OPERATIONAL - Living Image Ready", "NEEDS ATTENTION"))
    writeln("====================================================\n")
    
    if(overallStatus,
        writeln("🧠 TelOS is ready for Living Image development!")
        writeln("📝 Use 'Telos inspect' to examine the system state.")
        writeln("🔍 Use 'Telos cognitiveQuery(\"your query\")' to test reasoning.")
        writeln("⚡ Use 'Telos initializeFullSystem' to re-run this validation.")
        writeln("🎯 The Living Image awaits your prototypal creations!\n")
    )
    
    return overallStatus
)



// Automatic initialization when module loads - prototypal style
writeln("TelOS Core: Foundation module loaded - starting full system initialization...")
writeln("           Use 'Telos initializeFullSystem' for complete validation anytime.")
initializeSystem