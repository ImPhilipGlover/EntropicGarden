// TelOS Commands Module - System Commands and Interactive Operations  
// Part of the modular TelOS architecture - handles command processing
// Follows prototypal purity: all parameters are objects, all variables are slots

// === COMMANDS FOUNDATION ===
TelosCommands := Object clone
TelosCommands version := "1.0.0 (modular-prototypal)"
TelosCommands loadTime := Date clone now

// Load message
TelosCommands load := method(
    writeln("TelOS Commands: Interactive command processing module loaded - execution ready")
    self
)

// === COMMAND SYSTEM ===

Command := Object clone
Command name := "default"
Command description := "Default command"
Command handler := nil
Command args := List clone
Command context := Map clone

Command clone := method(
    newCommand := resend
    newCommand args := List clone
    newCommand context := Map clone
    newCommand
)

Command with := method(nameObj, descriptionObj, handlerObj,
    // Prototypal parameter handling
    commandAnalyzer := Object clone
    commandAnalyzer name := nameObj
    commandAnalyzer description := descriptionObj
    commandAnalyzer handler := handlerObj
    commandAnalyzer nameStr := if(commandAnalyzer name == nil, "default", commandAnalyzer name asString)
    commandAnalyzer descStr := if(commandAnalyzer description == nil, "No description", commandAnalyzer description asString)

    commandCreator := Object clone
    commandCreator newCommand := Command clone
    commandCreator newCommand name := commandAnalyzer nameStr
    commandCreator newCommand description := commandAnalyzer descStr
    commandCreator newCommand handler := commandAnalyzer handler

    // Return the configured command prototype
    commandCreator newCommand
)

Command execute := method(argsObj, contextObj,
    // Prototypal parameter handling
    executionAnalyzer := Object clone
    executionAnalyzer args := argsObj
    executionAnalyzer context := contextObj
    executionAnalyzer argsList := if(executionAnalyzer args == nil, List clone, executionAnalyzer args)
    executionAnalyzer contextMap := if(executionAnalyzer context == nil, Map clone, executionAnalyzer context)
    
    // Set command state
    self args := executionAnalyzer argsList
    self context := executionAnalyzer contextMap
    
    // Execute handler if available
    if(self handler != nil,
        executionProcessor := Object clone
        executionProcessor command := self
        executionProcessor result := try(
            executionProcessor command handler call(executionProcessor command, executionAnalyzer argsList, executionAnalyzer contextMap)
        ,  
            executionError := Object clone
            executionError message := "Command execution failed: " .. self name
            TelosLogging logError(executionError message, self name)
            executionError message
        )
        
        executionReporter := Object clone
        executionReporter message := "Command executed: " .. self name
        TelosLogging logEvent("command.execute", executionReporter message, self name)
        
        return executionProcessor result
    ,
        noHandlerError := Object clone
        noHandlerError message := "No handler defined for command: " .. self name
        TelosLogging logError(noHandlerError message, self name)
        return noHandlerError message
    )
)

Command describe := method(
    descriptionBuilder := Object clone
    descriptionBuilder parts := List clone
    descriptionBuilder parts append("Command: " .. self name)
    descriptionBuilder parts append("Description: " .. self description)
    descriptionBuilder parts append("Handler: " .. if(self handler != nil, "defined", "undefined"))
    
    descriptionBuilder parts join("\n")
)

// === COMMAND REGISTRY ===

CommandRegistry := Object clone
CommandRegistry commands := Map clone

CommandRegistry register := method(commandObj,
    // Prototypal parameter handling
    registryAnalyzer := Object clone
    registryAnalyzer command := commandObj
    
    if(registryAnalyzer command == nil,
        errorReporter := Object clone
        errorReporter message := "CommandRegistry: Cannot register nil command"
        TelosLogging logError(errorReporter message, "registry")
        return errorReporter message
    )
    
    registrar := Object clone
    registrar command := registryAnalyzer command
    registrar name := registrar command name
    self commands atPut(registrar name, registrar command)
    
    registrationReporter := Object clone
    registrationReporter message := "CommandRegistry: Registered command '" .. registrar name .. "'"
    TelosLogging logSystem(registrationReporter message, "registry")
    registrationReporter message
)

CommandRegistry get := method(nameObj,
    // Prototypal parameter handling
    lookupAnalyzer := Object clone
    lookupAnalyzer name := nameObj
    lookupAnalyzer nameStr := if(lookupAnalyzer name == nil, "", lookupAnalyzer name asString)
    
    retriever := Object clone
    retriever name := lookupAnalyzer nameStr
    retriever command := self commands at(retriever name)
    retriever command
)

CommandRegistry execute := method(nameObj, argsObj, contextObj,
    // Prototypal parameter handling
    executionAnalyzer := Object clone
    executionAnalyzer name := nameObj
    executionAnalyzer args := argsObj
    executionAnalyzer context := contextObj
    executionAnalyzer nameStr := if(executionAnalyzer name == nil, "", executionAnalyzer name asString)
    executionAnalyzer argsList := if(executionAnalyzer args == nil, List clone, executionAnalyzer args)
    executionAnalyzer contextMap := if(executionAnalyzer context == nil, Map clone, executionAnalyzer context)
    
    commandExecutor := Object clone
    commandExecutor name := executionAnalyzer nameStr
    commandExecutor command := self get(commandExecutor name)
    
    if(commandExecutor command != nil,
        commandExecutor result := commandExecutor command execute(executionAnalyzer argsList, executionAnalyzer contextMap)
        return commandExecutor result
    ,
        notFoundError := Object clone
        notFoundError message := "Command not found: " .. commandExecutor name
        TelosLogging logError(notFoundError message, "registry")
        return notFoundError message
    )
)

CommandRegistry list := method(
    lister := Object clone
    lister names := self commands keys
    lister count := lister names size
    
    listReporter := Object clone
    listReporter message := "CommandRegistry: " .. lister count .. " registered commands"
    TelosLogging logSystem(listReporter message, "registry")
    
    lister names
)

CommandRegistry help := method(nameObj,
    // Prototypal parameter handling
    helpAnalyzer := Object clone
    helpAnalyzer name := nameObj
    helpAnalyzer nameStr := if(helpAnalyzer name == nil, "", helpAnalyzer name asString)
    
    if(helpAnalyzer nameStr size > 0,
        // Help for specific command
        helpProvider := Object clone
        helpProvider command := self get(helpAnalyzer nameStr)
        
        if(helpProvider command != nil,
            return helpProvider command describe
        ,
            helpError := Object clone
            helpError message := "Help: Command not found: " .. helpAnalyzer nameStr
            return helpError message
        )
    ,
        // General help - list all commands
        generalHelp := Object clone
        generalHelp commandList := self list
        generalHelp helpText := "Available commands:\n" .. generalHelp commandList join("\n")
        return generalHelp helpText
    )
)

// === STANDARD SYSTEM COMMANDS ===

TelosCommands createSystemCommands := method(
    // Status command
    statusCommand := Command with("status", "Show system status", method(cmd, args, context,
        statusCollector := Object clone
        statusCollector report := List clone
        
        // System info
        statusCollector report append("TelOS System Status:")
        statusCollector report append("Version: " .. if(Telos hasSlot("version"), Telos version, "unknown"))
        statusCollector report append("Architecture: " .. if(Telos hasSlot("architecture"), Telos architecture, "unknown"))
        
        // Module status
        if(Telos hasSlot("modules"),
            statusCollector report append("Modules loaded: " .. Telos modules size)
        )
        
        // Memory status
        if(TelosMemory != nil,
            memoryStatus := TelosMemory status
            statusCollector report append("Memory: " .. memoryStatus)
        )
        
        // Persona status  
        if(PersonaCodex != nil,
            personaStatus := PersonaCodex status
            statusCollector report append("Personas: " .. personaStatus)
        )
        
        statusCollector report join("\n")
    ))
    CommandRegistry register(statusCommand)
    
    // Help command
    helpCommand := Command with("help", "Show command help", method(cmd, args, context,
        helpProcessor := Object clone
        helpProcessor targetCommand := if(args size > 0, args at(0) asString, nil)
        CommandRegistry help(helpProcessor targetCommand)
    ))
    CommandRegistry register(helpCommand)
    
    // List command  
    listCommand := Command with("list", "List available commands", method(cmd, args, context,
        listProcessor := Object clone
        listProcessor commands := CommandRegistry list
        listProcessor count := listProcessor commands size
        listProcessor result := "Available commands (" .. listProcessor count .. "):\n" .. listProcessor commands join("\n")
        listProcessor result
    ))
    CommandRegistry register(listCommand)
    
    // Clear command
    clearCommand := Command with("clear", "Clear system state", method(cmd, args, context,
        clearProcessor := Object clone
        clearProcessor target := if(args size > 0, args at(0) asString, "screen")
        
        if(clearProcessor target == "memory" and TelosMemory != nil,
            TelosMemory initVSA(nil)
            return "Memory cleared"
        )
        
        if(clearProcessor target == "personas" and PersonaCodex != nil,
            PersonaCodex registry = Map clone
            PersonaCodex activePersona = nil
            return "Personas cleared"
        )
        
        if(clearProcessor target == "screen",
            return "\n\n\n\n\n\n\n\n\n\n--- Screen cleared ---\n"
        )
        
        "Clear target not recognized: " .. clearProcessor target
    ))
    CommandRegistry register(clearCommand)
    
    // Version command
    versionCommand := Command with("version", "Show version information", method(cmd, args, context,
        versionCollector := Object clone
        versionCollector info := List clone
        
        // Safe version access with nil checking
        versionCollector safeVersion := method(moduleName,
            if(Lobby hasSlot(moduleName) and Lobby getSlot(moduleName) hasSlot("version"),
                Lobby getSlot(moduleName) version,
                "not loaded"
            )
        )
        
        versionCollector info append("TelOS Core: " .. versionCollector safeVersion("TelosCore"))
        versionCollector info append("TelosFFI: " .. versionCollector safeVersion("TelosFFI"))
        versionCollector info append("TelosPersistence: " .. versionCollector safeVersion("TelosPersistence"))
        versionCollector info append("TelosMorphic: " .. versionCollector safeVersion("TelosMorphic"))
        versionCollector info append("TelosMemory: " .. versionCollector safeVersion("TelosMemory"))
        versionCollector info append("TelosPersona: " .. versionCollector safeVersion("TelosPersona"))
        versionCollector info append("TelosQuery: " .. versionCollector safeVersion("TelosQuery"))
        versionCollector info append("TelosLogging: " .. versionCollector safeVersion("TelosLogging"))
        versionCollector info append("TelosCommands: " .. versionCollector safeVersion("TelosCommands"))
        versionCollector info join("\n")
    ))
    CommandRegistry register(versionCommand)
    
    creationReporter := Object clone
    creationReporter message := "TelOS Commands: Created system commands (status, help, list, clear, version)"
    TelosLogging logSystem(creationReporter message, "commands")
    creationReporter message
)

// === INTERACTIVE COMMAND PROCESSOR ===

InteractiveProcessor := Object clone
InteractiveProcessor prompt := "TelOS> "
InteractiveProcessor running := false
InteractiveProcessor history := List clone

InteractiveProcessor start := method(
    self running = true
    
    startReporter := Object clone
    startReporter message := "Interactive command processor started"
    TelosLogging logSystem(startReporter message, "interactive")
    writeln(startReporter message)
    
    self run
)

InteractiveProcessor run := method(
    while(self running,
        // Display prompt
        self prompt print
        
        // Read input
        inputReader := Object clone
        // Non-interactive guard: skip stdin reads when disabled
        nonInteractive := System getEnvironmentVariable("TELOS_NONINTERACTIVE")
        if(nonInteractive and nonInteractive size > 0,
            // In non-interactive mode, synthesize empty input to avoid hangs
            inputReader line := ""
        ,
            inputReader line := File standardInput readLine
        )
        
        if(inputReader line == nil,
            self stop
            break
        )
        
        inputProcessor := Object clone
        inputProcessor line := inputReader line asString strip
        
        // Skip empty lines
        if(inputProcessor line size == 0, continue)
        
        // Add to history
        self history append(inputProcessor line)
        
        // Keep history bounded
        if(self history size > 100,
            self history := self history slice(-100, -1)
        )
        
        // Process command
        commandResult := self processLine(inputProcessor line)
        
        // Display result
        if(commandResult != nil and commandResult size > 0,
            writeln(commandResult)
        )
    )
)

InteractiveProcessor processLine := method(lineObj,
    // Prototypal parameter handling
    lineAnalyzer := Object clone
    lineAnalyzer line := lineObj
    lineAnalyzer lineStr := if(lineAnalyzer line == nil, "", lineAnalyzer line asString)
    
    // Handle special commands
    if(lineAnalyzer lineStr == "exit" or lineAnalyzer lineStr == "quit",
        self stop
        return "Goodbye!"
    )
    
    if(lineAnalyzer lineStr == "history",
        historyProcessor := Object clone
        historyProcessor recent := if(self history size > 10, 
            self history slice(-10, -1), self history)
        return "Recent history:\n" .. historyProcessor recent join("\n")
    )
    
    // Parse command and arguments
    commandParser := Object clone
    commandParser parts := lineAnalyzer lineStr split(" ")
    commandParser command := if(commandParser parts size > 0, commandParser parts at(0), "")
    commandParser args := if(commandParser parts size > 1, commandParser parts slice(1, -1), List clone)
    
    // Execute command
    commandExecutor := Object clone
    commandExecutor result := CommandRegistry execute(commandParser command, commandParser args, Map clone)
    commandExecutor result
)

InteractiveProcessor stop := method(
    self running = false
    
    stopReporter := Object clone
    stopReporter message := "Interactive command processor stopped"
    TelosLogging logSystem(stopReporter message, "interactive")  
    writeln(stopReporter message)
)

// Initialize commands system when module loads
try(
    TelosCommands load()
    TelosCommands createSystemCommands()
    writeln("TelOS Commands: Interactive command consciousness operational")
,
    exception,
    writeln("TelOS Commands: Initialization error: " .. exception description)
)