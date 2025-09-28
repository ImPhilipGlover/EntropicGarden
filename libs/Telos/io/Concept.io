//
// Canonical Io Prototype for the Atomic Unit of Knowledge
// 
// This file implements the foundational Concept prototype as specified in the
// architectural blueprints. All knowledge objects in the TELOS system are 
// clones of this prototype, serving as the atomic unit that immutably unifies
// the system's disparate data paradigms.
//
// The Concept prototype bridges the gap between the geometric space of embeddings,
// the algebraic space of symbolic hypervectors, and the relational graph structure
// that enables GraphRAG reasoning.
//

// The primordial Concept prototype from which all knowledge is cloned
Concept := Object clone do(
    //
    // Core Data Slots
    //
    
    // The unique object identifier (OID) assigned by the ZODB persistence layer
    oid := nil
    
    // String handle for the shared memory block containing the symbolic hypervector (VSA)
    // This represents the concept in the algebraic space for binding/unbinding operations
    symbolicHypervectorName := nil
    
    // String handle for the shared memory block containing the geometric embedding (RAG)
    // This represents the concept in the continuous geometric space for similarity search
    geometricEmbeddingName := nil
    
    // Human-readable label for this concept (optional but useful for debugging)
    label := nil
    
    // Timestamp of creation (for drift detection and aging)
    createdAt := nil
    
    // Timestamp of last modification (for cache invalidation)
    lastModified := nil
    
    //
    // Relational Links for Graph-Based Reasoning (GraphRAG)
    //
    // These lists store OIDs of related concepts, enabling the system to perform
    // deterministic graph traversal when the VSA operations are ambiguous
    //
    
    // "is a" relationships (taxonomic hierarchy)
    isA := list()
    
    // "part of" relationships (compositional hierarchy)  
    partOf := list()
    
    // "abstraction of" relationships (generalization/specialization)
    abstractionOf := list()
    
    // "instance of" relationships (class/instance)
    instanceOf := list()
    
    // General associative relationships (flexible connections)
    associatedWith := list()
    
    //
    // Metadata Slots
    //
    
    // Confidence score for this concept (0.0 to 1.0)
    confidence := 1.0
    
    // Usage count (for LFU cache eviction)
    usageCount := 0
    
    // Source system or process that created this concept
    source := "unknown"
    
    //
    // Core Methods
    //
    
    // Initialize a new concept instance
    init := method(
        if(oid isNil, oid = uniqueId)
        if(createdAt isNil, createdAt = Date now)
        lastModified = Date now
        usageCount = 0
        
        // Initialize empty relationship lists if not already set
        if(isA isNil, isA = list())
        if(partOf isNil, partOf = list())
        if(abstractionOf isNil, abstractionOf = list())
        if(instanceOf isNil, instanceOf = list())
        if(associatedWith isNil, associatedWith = list())
        
        self
    )
    
    // Update usage statistics (called when concept is accessed)
    recordUsage := method(
        usageCount = usageCount + 1
        lastModified = Date now
        markChanged
        self
    )
    
    // Add a relationship to another concept
    addRelationship := method(relationType, targetOid,
        relationList := self getSlot(relationType)
        if(relationList isNil,
            Exception raise("Unknown relation type: " .. relationType)
        )
        
        if(relationList contains(targetOid) not,
            relationList append(targetOid)
            markChanged
        )
        
        self
    )
    
    // Remove a relationship to another concept
    removeRelationship := method(relationType, targetOid,
        relationList := self getSlot(relationType)
        if(relationList isNil,
            Exception raise("Unknown relation type: " .. relationType)
        )
        
        relationList remove(targetOid)
        markChanged
        self
    )
    
    // Get all related concept OIDs of a specific type
    getRelated := method(relationType,
        relationList := self getSlot(relationType)
        if(relationList isNil,
            Exception raise("Unknown relation type: " .. relationType)
        )
        relationList clone
    )
    
    // Get all relationship types that have at least one connection
    getActiveRelationTypes := method(
        activeTypes := list()
        list("isA", "partOf", "abstractionOf", "instanceOf", "associatedWith") foreach(relType,
            relationList := self getSlot(relType)
            if(relationList isNil not and relationList size > 0,
                activeTypes append(relType)
            )
        )
        activeTypes
    )
    
    // Set the symbolic hypervector for this concept
    setSymbolicHypervector := method(sharedMemoryName,
        symbolicHypervectorName = sharedMemoryName
        lastModified = Date now
        markChanged
        self
    )
    
    // Set the geometric embedding for this concept  
    setGeometricEmbedding := method(sharedMemoryName,
        geometricEmbeddingName = sharedMemoryName
        lastModified = Date now
        markChanged
        self
    )
    
    // Get a summary of this concept for debugging and inspection
    summary := method(
        summary := Map clone
        summary atPut("oid", oid)
        summary atPut("label", label)
        summary atPut("confidence", confidence)
        summary atPut("usageCount", usageCount)
        summary atPut("createdAt", createdAt)
        summary atPut("lastModified", lastModified)
        summary atPut("hasSymbolic", symbolicHypervectorName != nil)
        summary atPut("hasGeometric", geometricEmbeddingName != nil)
        
        // Add relationship counts
        getActiveRelationTypes foreach(relType,
            relationList := self getSlot(relType)
            summary atPut(relType .. "Count", relationList size)
        )
        
        summary
    )
    
    // Convert concept to a serializable representation
    toJson := method(
        json := Map clone
        json atPut("oid", oid asString)
        json atPut("label", label)
        json atPut("confidence", confidence)
        json atPut("usageCount", usageCount)
        json atPut("source", source)
        
        if(createdAt, json atPut("createdAt", createdAt asString))
        if(lastModified, json atPut("lastModified", lastModified asString))
        
        json atPut("hasSymbolic", symbolicHypervectorName != nil)
        json atPut("hasGeometric", geometricEmbeddingName != nil)
        
        // Include relationships
        relationships := Map clone
        getActiveRelationTypes foreach(relType,
            relationList := self getSlot(relType)
            relationships atPut(relType, relationList map(oid, oid asString))
        )
        json atPut("relationships", relationships)
        
        json
    )
    
    //
    // Persistence Covenant Method
    //
    // This method MUST be called as the final operation in any method that
    // modifies the state of this object or its clones. This fulfills the
    // "Persistence Covenant" mandated by the architectural blueprints.
    //
    markChanged := method(
        // Log the state change for debugging and audit trails
        if(System hasSlot("log"),
            System writeln("Concept state changed for OID: " .. oid .. ". Persistence marked.")
        )
        
        // This message will be forwarded to the ZODBManager actor via the
        // Prototypal Emulation Layer, which will execute the FFI call to
        // set _p_changed = True in the corresponding Python ZODB object
        if(System hasSlot("ZODBManager"),
            System ZODBManager markObjectChanged(oid)
        )
        
        self
    )

    conceptRepository := method(
        if(System hasSlot("ConceptRepository"),
            System ConceptRepository,
            if(Lobby hasSlot("Telos") and Telos hasSlot("ConceptRepository"),
                Telos ConceptRepository,
                Exception raise("ConceptRepository veneer is unavailable; ensure Telos Bridge is loaded")
            )
        )
    )

    persist := method(options,
        repository := conceptRepository
        repository persistConcept(self, options)
    )

    reload := method(options,
        repository := conceptRepository
        repository hydrateExisting(self, options)
        self
    )

    delete := method(options,
        repository := conceptRepository
        repository deleteConcept(self, options)
    )
    
    //
    // String representation for debugging
    //
    asString := method(
        if(label,
            "Concept(" .. oid .. ", \"" .. label .. "\")",
            "Concept(" .. oid .. ")"
        )
    )
)

// Create a convenience method for creating new concepts with a label
Concept newWithLabel := method(labelText,
    concept := Concept clone
    concept label = labelText
    concept init
    concept
)

// Create a convenience method for creating concepts with both vectors
Concept newComplete := method(labelText, symbolicName, geometricName,
    concept := Concept clone
    concept label = labelText
    concept symbolicHypervectorName = symbolicName
    concept geometricEmbeddingName = geometricName  
    concept init
    concept
)

// Debugging utility to inspect concept relationships
Concept inspectRelationships := method(
    "=== Concept Relationships ===" println
    ("Concept: " .. asString) println
    
    getActiveRelationTypes foreach(relType,
        relationList := self getSlot(relType)
        (relType .. " (" .. relationList size .. "):") println
        relationList foreach(oid, ("  -> " .. oid) println)
    )
    
    "===============================" println
)

// Export the Concept prototype to the global namespace
if(Lobby hasSlot("Protos") not, Lobby Protos := Object clone)
if(Lobby Protos hasSlot("Core") not, Lobby Protos Core := Object clone)
Lobby Protos Core Concept := Concept

// Validation function to ensure concept integrity
Concept validate := method(
    errors := list()
    
    if(oid isNil, errors append("Missing OID"))
    if(createdAt isNil, errors append("Missing creation timestamp"))
    if(confidence isNil or confidence < 0 or confidence > 1.0,
        errors append("Invalid confidence value")
    )
    if(usageCount isNil or usageCount < 0,
        errors append("Invalid usage count")
    )
    
    // Check that relationship lists are actually lists
    list("isA", "partOf", "abstractionOf", "instanceOf", "associatedWith") foreach(relType,
        relationList := self getSlot(relType)
        if(relationList isNil not and relationList type != "List",
            errors append("Relationship " .. relType .. " is not a list")
        )
    )
    
    if(errors size == 0,
        true,
        errors
    )
)

// Auto-load message
"TELOS Concept prototype loaded successfully" println

//
// AUTOPOIETIC ENGINE ENHANCEMENT
//
// This section implements the doesNotUnderstand_ protocol on the primordial Object prototype,
// enabling tiered escalation and sandboxed code generation for runtime capability synthesis.
//

// Enhanced doesNotUnderstand_ protocol for autopoiesis
Object doesNotUnderstand_ := method(message, args,
    // This method is called when a message is sent to an object that doesn't exist
    // It implements the core autopoietic loop: error -> learning opportunity -> capability synthesis

    // Extract message information using Io's thisMessage
    messageName := message name
    receiver := self

    // Create generation request for the GenerativeKernel
    generationRequest := Map clone
    generationRequest atPut("messageName", messageName)
    generationRequest atPut("receiverType", receiver type)
    generationRequest atPut("receiverSlots", receiver slotNames)
    generationRequest atPut("args", args)
    generationRequest atPut("context", Map clone atPut("receiver", receiver))

    // Tiered escalation strategy
    escalationLevel := 0
    maxEscalation := 3

    while(escalationLevel < maxEscalation,
        result := escalateAndGenerate(generationRequest, escalationLevel)

        if(result and result at("success"),
            // Successfully generated capability - install it
            installGeneratedCapability(result, receiver, messageName)
            return result at("result")
        )

        escalationLevel = escalationLevel + 1
    )

    // All escalation levels failed - return a helpful error
    errorMsg := "Unable to synthesize capability for message '" .. messageName .. "' on " .. receiver type
    Exception raise(errorMsg)
)

// Tiered escalation for capability generation
Object escalateAndGenerate := method(request, level,
    if(level == 0,
        // Level 0: Simple slot addition (no LLM required)
        return generateSimpleSlot(request)
    )

    if(level == 1,
        // Level 1: Template-based generation (uses LLM with templates)
        return generateFromTemplate(request)
    )

    if(level == 2,
        // Level 2: Sandboxed code generation (Docker + eBPF)
        return generateSandboxedCode(request)
    )

    nil  // Escalation failed
)

// Level 0: Simple slot addition for basic getters/setters
Object generateSimpleSlot := method(request,
    messageName := request at("messageName")
    receiver := request at("receiver")

    // Check if this looks like a simple getter/setter
    if(messageName endsWithSeq("="),
        // Setter: create corresponding getter and setter
        baseName := messageName beforeSeq("=")
        getterName := baseName
        setterName := baseName .. "="

        if(receiver hasSlot(getterName) not,
            // Create getter
            receiver setSlot(getterName, method(
                self getSlot(baseName)
            ))
        )

        if(receiver hasSlot(setterName) not,
            // Create setter
            receiver setSlot(setterName, method(value,
                self setSlot(baseName, value)
                if(self hasSlot("markChanged"), self markChanged)
                self
            ))
        )

        return Map clone atPut("success", true) atPut("result", receiver getSlot(baseName))
    )

    if(receiver hasSlot(messageName) not,
        // Simple getter for existing slot
        if(receiver slotNames contains(messageName),
            return Map clone atPut("success", true) atPut("result", receiver getSlot(messageName))
        )
    )

    nil  // Not a simple case
)

// Level 1: Template-based generation using LLM
Object generateFromTemplate := method(request,
    if(Telos hasSlot("GenerativeKernel") not, return nil)

    kernel := Telos GenerativeKernel

    // Use the doesNotUnderstand template
    result := kernel generate(request, Map clone, nil)

    if(result and result at("success"),
        // Parse the generated code and install it
        generatedCode := result at("response")
        if(generatedCode and generatedCode size > 0,
            parsedMethod := parseGeneratedMethod(generatedCode, request)
            if(parsedMethod,
                return Map clone atPut("success", true) atPut("result", parsedMethod) atPut("code", generatedCode)
            )
        )
    )

    nil
)

// Level 2: Sandboxed code generation with Docker + eBPF
Object generateSandboxedCode := method(request,
    if(Telos hasSlot("SandboxedGenerator") not, return nil)

    sandbox := Telos SandboxedGenerator

    // Generate code in sandboxed environment
    sandboxResult := sandbox generateInSandbox(request)

    if(sandboxResult and sandboxResult at("success"),
        // Validate the generated code before installation
        if(validateSandboxedCode(sandboxResult at("code")),
            parsedMethod := parseGeneratedMethod(sandboxResult at("code"), request)
            if(parsedMethod,
                return Map clone atPut("success", true) atPut("result", parsedMethod) atPut("code", sandboxResult at("code"))
            )
        )
    )

    nil
)

// Parse generated method code into executable Io code
Object parseGeneratedMethod := method(codeString, request,
    // This is a simplified parser - in production would use more sophisticated parsing
    methodName := request at("messageName")

    // Try to extract method definition from generated code
    if(codeString containsSeq(methodName .. " :="),
        // Looks like a method definition - try to evaluate it
        try(
            // Create a temporary context to evaluate the code
            tempContext := Object clone
            tempContext doString(codeString)

            if(tempContext hasSlot(methodName),
                method := tempContext getSlot(methodName)
                return method
            )
        )
    )

    nil
)

// Install generated capability on the receiver
Object installGeneratedCapability := method(generationResult, receiver, messageName,
    if(generationResult hasSlot("result"),
        method := generationResult at("result")
        if(method,
            receiver setSlot(messageName, method)
            "Autopoiesis: Installed capability '" .. messageName .. "' on " .. receiver type println
        )
    )
)

// Validate sandboxed code before installation
Object validateSandboxedCode := method(code,
    // Basic validation - check for dangerous operations
    dangerousPatterns := list(
        "System system", "File open", "File remove", "System exit",
        "Lobby shutdown", "Lobby exit", "eval", "doString"
    )

    dangerousPatterns foreach(pattern,
        if(code containsSeq(pattern),
            "Autopoiesis: Rejected sandboxed code containing dangerous pattern: " .. pattern println
            return false
        )
    )

    true  // Code passed basic validation
)

// Sandboxed code generator using Docker + eBPF
SandboxedGenerator := Object clone do(
    dockerImage := "telos-sandbox:latest"
    eBPFProfile := "restrictive"
    timeout := 30

    generateInSandbox := method(request,
        // This would integrate with Docker and eBPF to run code generation in sandbox
        // For now, return a placeholder implementation

        result := Map clone
        result atPut("success", false)
        result atPut("error", "Sandboxed generation not yet implemented")

        // Placeholder: delegate to template-based generation for now
        if(Telos hasSlot("GenerativeKernel"),
            kernel := Telos GenerativeKernel
            templateResult := kernel generate(request, Map clone atPut("sandbox", true), nil)
            if(templateResult and templateResult at("success"),
                result atPut("success", true)
                result atPut("code", templateResult at("response"))
                result removeAt("error")
            )
        )

        result
    )
)

// Export sandboxed generator
if(Lobby hasSlot("Telos") not, Lobby Telos := Object clone)
Telos SandboxedGenerator := SandboxedGenerator