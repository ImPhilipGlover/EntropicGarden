/*
   TelosCore.io - Core Prototypal Foundation and System Initialization
   The zygote's first breath: establishing prototypal purity and system harmony
   
   This module provides:
   - Base Telos prototype establishment with immediate usability
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
    if(valueObj requested == nil, default, valueObj requested)
)

List atIfAbsent := method(index, default,
    indexObj := Object clone
    indexObj value := index
    if(indexObj value isNil, return default)
    if(indexObj value < 0, return default)
    if(self size <= indexObj value, return default)
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

// === JSON UTILITIES ===
// Pure prototypal JSON handling with proper object message passing

Telos json := Object clone
Telos json escape := method(stringParam,
    // Parameters are objects: create stringProcessor for the input
    stringProcessor := Object clone
    stringProcessor input := stringParam asString
    stringProcessor mutable := stringProcessor input asMutable
    stringProcessor mutable replaceSeq("\\", "\\\\")
    stringProcessor mutable replaceSeq("\"", "\\\"")
    stringProcessor mutable replaceSeq("\n", "\\n")
    stringProcessor mutable
)

Telos json stringify := method(valueParam,
    valueProcessor := Object clone
    valueProcessor target := valueParam
    
    if(valueProcessor target == nil, return "null")
    
    typeAnalyzer := Object clone
    typeAnalyzer targetType := valueProcessor target type
    
    if(typeAnalyzer targetType == "Number", return valueProcessor target asString)
    if(typeAnalyzer targetType == "Sequence", 
        escapedContent := Telos json escape(valueProcessor target)
        return "\"" .. escapedContent .. "\""
    )
    if(typeAnalyzer targetType == "List",
        listProcessor := Object clone
        listProcessor parts := valueProcessor target map(item, Telos json stringify(item))
        return "[" .. listProcessor parts join(",") .. "]"
    )
    if(typeAnalyzer targetType == "Map",
        mapProcessor := Object clone
        mapProcessor parts := List clone
        valueProcessor target foreach(keyItem, valueItem, 
            keyEscaped := Telos json escape(keyItem)
            valueStringified := Telos json stringify(valueItem)
            mapProcessor parts append("\"" .. keyEscaped .. "\":" .. valueStringified)
        )
        return "{" .. mapProcessor parts join(",") .. "}"
    )
    if(valueProcessor target == true, return "true")
    if(valueProcessor target == false, return "false")
    
    // fallback: string representation
    fallbackContent := Telos json escape(valueProcessor target asString)
    return "\"" .. fallbackContent .. "\""
)

// === MODULE LOADING SYSTEM ===

Telos loadedModules := Map clone
Telos moduleLoadOrder := List clone

Telos loadModule := method(moduleNameParam,
    moduleLoader := Object clone
    moduleLoader name := moduleNameParam asString
    moduleLoader path := "libs/Telos/io/" .. moduleLoader name .. ".io"
    
    // Check if already loaded
    if(Telos loadedModules hasSlot(moduleLoader name),
        writeln("TelOS Core: Module '" .. moduleLoader name .. "' already loaded")
        return true
    )
    
    writeln("TelOS Core: Loading module '" .. moduleLoader name .. "'...")
    
    // Track success/failure
    loadSuccess := false
    
    try(
        // Attempt to load the module file
        moduleFile := File with(moduleLoader path)
        if(moduleFile exists,
            writeln("TelOS Core: Loading file: " .. moduleLoader path)
            doFile(moduleLoader path)
            writeln("TelOS Core: File loaded successfully for " .. moduleLoader name)
            
            // Call the module's load method if it exists (optional)
            moduleObj := Lobby getSlot(moduleLoader name)
            if(moduleObj != nil and moduleObj hasSlot("load"),
                writeln("TelOS Core: Calling load method for " .. moduleLoader name)
                moduleObj load
                writeln("TelOS Core: Load method completed for " .. moduleLoader name)
            ,
                writeln("TelOS Core: Module " .. moduleLoader name .. " loaded (no main object or load method)")
            )
            
            Telos loadedModules atPut(moduleLoader name, true)
            Telos moduleLoadOrder append(moduleLoader name)
            writeln("TelOS Core: Successfully loaded module '" .. moduleLoader name .. "'")
            writeln("TelOS Core: Setting loadSuccess to true for " .. moduleLoader name)
            loadSuccess := true
            writeln("TelOS Core: loadSuccess is now: " .. loadSuccess .. " for " .. moduleLoader name)
        ,
            writeln("TelOS Core: Module file not found: " .. moduleLoader path)
            loadSuccess := false
        )
    ,
        exception,
        writeln("TelOS Core: EXCEPTION loading module '" .. moduleLoader name .. "': " .. exception description)
        writeln("TelOS Core: Exception type: " .. exception type)
        if(exception hasSlot("error"),
            writeln("TelOS Core: Exception error: " .. exception error)
        )
        if(exception hasSlot("message"),
            writeln("TelOS Core: Exception message: " .. exception message)
        )
        if(exception hasSlot("caughtMessage"),
            writeln("TelOS Core: Exception caughtMessage: " .. exception caughtMessage)
        )
        loadSuccess := false
    )
    
    return loadSuccess
)

Telos loadAllModules := method(
    moduleNames := list(
        "TelosFFI",
        "TelosPersistence", 
        "TelosMorphic",
        "TelosMemory",
        "TelosPersona",
        "TelosQuery",
        "TelosLogging",
        "TelosCommands"
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
        
        moduleSuccess := Telos loadModule(moduleName)
        writeln("TelOS Core: loadModule returned: " .. moduleSuccess .. " for " .. moduleName)
        if(moduleSuccess,
            loadTracker successCount := loadTracker successCount + 1
            writeln("TelOS Core: Module " .. moduleName .. " completed successfully")
        ,
            writeln("TelOS Core: Module " .. moduleName .. " FAILED to load")
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

// Automatic initialization when module loads - prototypal style
writeln("TelOS Core: Foundation module loaded - initializing system...")
initializeSystem