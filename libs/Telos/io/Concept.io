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
            System log("Concept state changed for OID: " .. oid .. ". Persistence marked.")
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