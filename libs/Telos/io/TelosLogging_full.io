// TelOS Logging Module - Comprehensive Logging and Event Tracking
// Part of the modular TelOS architecture - handles all logging operations
// Follows prototypal purity: all parameters are objects, all variables are slots

// === LOGGING FOUNDATION ===
TelosLogging := Object clone
TelosLogging version := "1.0.0 (modular-prototypal)"
TelosLogging loadTime := Date clone now

// Load message
TelosLogging load := method(
    writeln("TelOS Logging: Event tracking and audit trail module loaded - recording ready")
    self
)

// === LOGGING PROTOTYPES ===

Logger := Object clone
Logger name := "default"
Logger level := "info"
Logger outputs := List clone
Logger buffer := List clone
Logger maxBufferSize := 1000

Logger clone := method(
    newLogger := resend
    newLogger outputs := List clone
    newLogger buffer := List clone
    newLogger
)

Logger with := method(nameObj, levelObj,
    // Prototypal parameter handling
    loggerAnalyzer := Object clone
    loggerAnalyzer name := nameObj
    loggerAnalyzer level := levelObj
    loggerAnalyzer nameStr := if(loggerAnalyzer name == nil, "default", loggerAnalyzer name asString)
    loggerAnalyzer levelStr := if(loggerAnalyzer level == nil, "info", loggerAnalyzer level asString)
    
    loggerCreator := Object clone
    loggerCreator newLogger := Logger clone
    loggerCreator newLogger name := loggerAnalyzer nameStr
    loggerCreator newLogger level := loggerAnalyzer levelStr
    
    loggerCreator newLogger
)

Logger log := method(levelObj, messageObj, contextObj,
    // Prototypal parameter handling
    logAnalyzer := Object clone
    logAnalyzer level := levelObj
    logAnalyzer message := messageObj
    logAnalyzer context := contextObj
    logAnalyzer levelStr := if(logAnalyzer level == nil, "info", logAnalyzer level asString)
    logAnalyzer messageStr := if(logAnalyzer message == nil, "", logAnalyzer message asString)
    logAnalyzer contextStr := if(logAnalyzer context == nil, "", logAnalyzer context asString)
    
    // Create log entry
    entryCreator := Object clone
    entryCreator timestamp := Date clone now asString
    entryCreator entry := Object clone
    entryCreator entry timestamp := entryCreator timestamp
    entryCreator entry level := logAnalyzer levelStr
    entryCreator entry logger := self name
    entryCreator entry message := logAnalyzer messageStr
    entryCreator entry context := logAnalyzer contextStr
    entryCreator entry thread := "main"
    
    // Format log entry
    entryFormatter := Object clone
    entryFormatter entry := entryCreator entry
    entryFormatter formatted := entryFormatter entry timestamp .. " [" .. entryFormatter entry level .. "] " .. 
                               entryFormatter entry logger .. ": " .. entryFormatter entry message
    if(entryFormatter entry context size > 0,
        entryFormatter formatted := entryFormatter formatted .. " (" .. entryFormatter entry context .. ")"
    )
    
    // Add to buffer
    self buffer append(entryCreator entry)
    
    // Maintain buffer size
    if(self buffer size > self maxBufferSize,
        self buffer := self buffer slice(-self maxBufferSize, -1)
    )
    
    // Output to all configured outputs
    self outputs foreach(output,
        outputProcessor := Object clone
        outputProcessor output := output
        outputProcessor formatted := entryFormatter formatted
        outputProcessor output write(outputProcessor formatted)
    )
    
    entryCreator entry
)

Logger debug := method(messageObj, contextObj,
    self log("debug", messageObj, contextObj)
)

Logger info := method(messageObj, contextObj,
    self log("info", messageObj, contextObj)
)

Logger warn := method(messageObj, contextObj,
    self log("warn", messageObj, contextObj)
)

Logger error := method(messageObj, contextObj,
    self log("error", messageObj, contextObj)
)

Logger addOutput := method(outputObj,
    // Prototypal parameter handling
    outputAnalyzer := Object clone
    outputAnalyzer output := outputObj
    
    if(outputAnalyzer output != nil,
        self outputs append(outputAnalyzer output)
        
        outputReporter := Object clone
        outputReporter message := "Logger " .. self name .. " added output: " .. outputAnalyzer output type
        writeln(outputReporter message)
    )
    
    self
)

Logger getHistory := method(limitObj,
    // Prototypal parameter handling
    historyAnalyzer := Object clone
    historyAnalyzer limit := limitObj
    historyAnalyzer limitNum := if(historyAnalyzer limit == nil, 10, historyAnalyzer limit asNumber)
    
    historyProcessor := Object clone
    historyProcessor entries := self buffer
    historyProcessor recent := if(historyAnalyzer limitNum >= historyProcessor entries size,
        historyProcessor entries,
        historyProcessor entries slice(-historyAnalyzer limitNum, -1)
    )
    
    historyProcessor recent
)

// === LOG OUTPUT DESTINATIONS ===

ConsoleOutput := Object clone
ConsoleOutput type := "console"

ConsoleOutput write := method(messageObj,
    // Prototypal parameter handling
    writeAnalyzer := Object clone
    writeAnalyzer message := messageObj
    writeAnalyzer messageStr := if(writeAnalyzer message == nil, "", writeAnalyzer message asString)
    
    writeln(writeAnalyzer messageStr)
)

FileOutput := Object clone
FileOutput type := "file"
FileOutput filename := "telos.log"
FileOutput append := true

FileOutput clone := method(
    newOutput := resend
    newOutput
)

FileOutput with := method(filenameObj,
    // Prototypal parameter handling
    fileAnalyzer := Object clone
    fileAnalyzer filename := filenameObj
    fileAnalyzer filenameStr := if(fileAnalyzer filename == nil, "telos.log", fileAnalyzer filename asString)
    
    fileCreator := Object clone
    fileCreator newOutput := FileOutput clone
    fileCreator newOutput filename := fileAnalyzer filenameStr
    
    fileCreator newOutput
)

FileOutput write := method(messageObj,
    // Prototypal parameter handling
    writeAnalyzer := Object clone
    writeAnalyzer message := messageObj
    writeAnalyzer messageStr := if(writeAnalyzer message == nil, "", writeAnalyzer message asString)
    
    // Write to file
    fileWriter := Object clone
    fileWriter filename := self filename
    fileWriter content := writeAnalyzer messageStr .. "\n"
    
    try(
        fileHandler := File clone
        fileHandler setPath(fileWriter filename)
        if(self append,
            fileHandler openForAppending
        ,
            fileHandler openForWriting
        )
        fileHandler write(fileWriter content)
        fileHandler close
    ,
        writeln("FileOutput error: Could not write to " .. fileWriter filename)
    )
)

BufferOutput := Object clone
BufferOutput type := "buffer"
BufferOutput buffer := List clone
BufferOutput maxSize := 500

BufferOutput clone := method(
    newOutput := resend
    newOutput buffer := List clone
    newOutput
)

BufferOutput write := method(messageObj,
    // Prototypal parameter handling
    writeAnalyzer := Object clone
    writeAnalyzer message := messageObj
    writeAnalyzer messageStr := if(writeAnalyzer message == nil, "", writeAnalyzer message asString)
    
    // Add to buffer
    self buffer append(writeAnalyzer messageStr)
    
    // Maintain buffer size
    if(self buffer size > self maxSize,
        self buffer := self buffer slice(-self maxSize, -1)
    )
)

BufferOutput getBuffer := method(
    self buffer
)

BufferOutput clear := method(
    self buffer := List clone
    "Buffer cleared"
)

// === SYSTEM LOGGING INTEGRATION ===

try(
    TelosLogging systemLogger := Logger with("TelOS", "info")
    TelosLogging systemLogger addOutput(ConsoleOutput clone)

    TelosLogging eventLogger := Logger with("Events", "debug")
    // Delay file output until after system is fully loaded
    TelosLogging eventLogger addOutput(ConsoleOutput clone)

    TelosLogging errorLogger := Logger with("Errors", "error")
    TelosLogging errorLogger addOutput(ConsoleOutput clone)
    // File outputs can be added later via TelosLogging initializeFileOutputs method
,
    exception,
    writeln("TelOS Logging: Logger initialization error: " .. exception description)
)

// === TELOS INTEGRATION METHODS ===

TelosLogging logSystem := method(messageObj, contextObj,
    TelosLogging systemLogger info(messageObj, contextObj)
)

TelosLogging logEvent := method(eventTypeObj, detailsObj, contextObj,
    // Prototypal parameter handling
    eventAnalyzer := Object clone
    eventAnalyzer eventType := eventTypeObj
    eventAnalyzer details := detailsObj
    eventAnalyzer context := contextObj
    eventAnalyzer eventTypeStr := if(eventAnalyzer eventType == nil, "unknown", eventAnalyzer eventType asString)
    eventAnalyzer detailsStr := if(eventAnalyzer details == nil, "", eventAnalyzer details asString)
    eventAnalyzer contextStr := if(eventAnalyzer context == nil, "", eventAnalyzer context asString)
    
    eventProcessor := Object clone
    eventProcessor message := eventAnalyzer eventTypeStr .. ": " .. eventAnalyzer detailsStr
    eventProcessor context := eventAnalyzer contextStr
    
    TelosLogging eventLogger info(eventProcessor message, eventProcessor context)
)

TelosLogging logError := method(errorObj, contextObj,
    TelosLogging errorLogger error(errorObj, contextObj)
)

TelosLogging logDebug := method(messageObj, contextObj,
    TelosLogging systemLogger debug(messageObj, contextObj)
)

// === AUDIT TRAIL SYSTEM ===

AuditTrail := Object clone
AuditTrail logger := Logger with("Audit", "info")
AuditTrail logger addOutput(FileOutput with("telos-audit.log"))
AuditTrail logger addOutput(BufferOutput clone)

AuditTrail record := method(actionObj, userObj, resourceObj, resultObj,
    // Prototypal parameter handling
    auditAnalyzer := Object clone
    auditAnalyzer action := actionObj
    auditAnalyzer user := userObj
    auditAnalyzer resource := resourceObj
    auditAnalyzer result := resultObj
    auditAnalyzer actionStr := if(auditAnalyzer action == nil, "unknown", auditAnalyzer action asString)
    auditAnalyzer userStr := if(auditAnalyzer user == nil, "system", auditAnalyzer user asString)
    auditAnalyzer resourceStr := if(auditAnalyzer resource == nil, "unknown", auditAnalyzer resource asString)
    auditAnalyzer resultStr := if(auditAnalyzer result == nil, "unknown", auditAnalyzer result asString)
    
    auditEntry := Object clone
    auditEntry action := auditAnalyzer actionStr
    auditEntry user := auditAnalyzer userStr
    auditEntry resource := auditAnalyzer resourceStr
    auditEntry result := auditAnalyzer resultStr
    auditEntry timestamp := Date clone now asString
    
    auditMessage := "AUDIT: " .. auditEntry user .. " performed " .. auditEntry action .. 
                   " on " .. auditEntry resource .. " with result: " .. auditEntry result
    
    AuditTrail logger info(auditMessage, auditEntry timestamp)
    auditEntry
)

AuditTrail getTrail := method(limitObj,
    // Prototypal parameter handling
    trailAnalyzer := Object clone
    trailAnalyzer limit := limitObj
    trailAnalyzer limitNum := if(trailAnalyzer limit == nil, 20, trailAnalyzer limit asNumber)
    
    AuditTrail logger getHistory(trailAnalyzer limitNum)
)

// === PERFORMANCE MONITORING ===

PerformanceMonitor := Object clone
PerformanceMonitor logger := Logger with("Performance", "info")
PerformanceMonitor logger addOutput(FileOutput with("telos-performance.log"))
PerformanceMonitor timers := Map clone

PerformanceMonitor startTimer := method(nameObj,
    // Prototypal parameter handling
    timerAnalyzer := Object clone
    timerAnalyzer name := nameObj
    timerAnalyzer nameStr := if(timerAnalyzer name == nil, "default", timerAnalyzer name asString)
    
    timerStarter := Object clone
    timerStarter name := timerAnalyzer nameStr
    timerStarter startTime := Date clone now asNumber
    
    self timers atPut(timerStarter name, timerStarter startTime)
    
    timerReporter := Object clone
    timerReporter message := "Performance timer started: " .. timerStarter name
    self logger debug(timerReporter message, timerStarter startTime asString)
    
    timerStarter startTime
)

PerformanceMonitor stopTimer := method(nameObj,
    // Prototypal parameter handling
    timerAnalyzer := Object clone
    timerAnalyzer name := nameObj
    timerAnalyzer nameStr := if(timerAnalyzer name == nil, "default", timerAnalyzer name asString)
    
    timerStopper := Object clone
    timerStopper name := timerAnalyzer nameStr
    timerStopper endTime := Date clone now asNumber
    timerStopper startTime := self timers at(timerStopper name)
    
    if(timerStopper startTime != nil,
        timerStopper duration := timerStopper endTime - timerStopper startTime
        
        performanceEntry := Object clone
        performanceEntry name := timerStopper name
        performanceEntry duration := timerStopper duration
        performanceEntry startTime := timerStopper startTime
        performanceEntry endTime := timerStopper endTime
        
        performanceMessage := "PERF: " .. performanceEntry name .. " completed in " .. performanceEntry duration .. "s"
        self logger info(performanceMessage, performanceEntry endTime asString)
        
        // Remove timer
        self timers removeAt(timerStopper name)
        
        return performanceEntry duration
    ,
        errorMessage := "Performance timer not found: " .. timerStopper name
        self logger error(errorMessage, timerStopper endTime asString)
        return nil
    )
)

// Initialize logging system when module loads
// Module loads automatically via TelosCore - no self-load needed
writeln("TelOS Logging: Comprehensive audit consciousness activated")