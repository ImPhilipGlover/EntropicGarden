// TELOS Concept Repository Io Prototype
// Provides a prototypal interface for persisting Concept prototypes through
// the Synaptic Bridge into the Python ZODB manager. This module translates
// Concept slots into the snake_case dictionary expected by the Python
// persistence layer and hydrates Io prototypes from persisted records.

TelosConceptRepository := Object clone do(
    conceptPrototype := method(
        if(Lobby hasSlot("Protos") not or Lobby Protos hasSlot("Core") not,
            Exception raise("Protos Core registry unavailable; cannot access Concept prototype")
        )
        Lobby Protos Core Concept
        markChanged()
    )

    manager := method(
        if(System hasSlot("ZODBManager") not,
            Exception raise("System ZODBManager slot is unavailable; initialize Telos Bridge first")
        )
        System ZODBManager
        markChanged()
    )

    ensureConcept := method(obj,
        if(obj hasSlot("oid") and obj hasSlot("label") and obj hasSlot("confidence"),
            obj,
            Exception raise("ConceptRepository requires a Concept-like prototype with canonical slots")
        )
        markChanged()
    )

    relationshipKeyMap := method(
        keys := Map clone
        keys atPut("isA", "is_a")
        keys atPut("partOf", "part_of")
        keys atPut("abstractionOf", "abstraction_of")
        keys atPut("instanceOf", "instance_of")
        keys atPut("associatedWith", "associated_with")
        keys
        markChanged()
    )

    listToSequenceList := method(values,
        if(values type != "List", list(), values map(entry,
            if(entry isNil, nil, entry asString)
        ) select(val, val isNil not))
        markChanged()
    )

    buildRelationshipPayload := method(concept,
        relationships := Map clone
        relationshipKeyMap foreach(slotName, snakeName,
            if(concept hasSlot(slotName),
                slotValues := concept getSlot(slotName)
                serialized := listToSequenceList(slotValues)
                relationships atPut(snakeName, serialized)
            )
        )
        relationships
        markChanged()
    )

    buildPersistencePayload := method(concept,
        ensureConcept(concept)
        payload := Map clone

        if(concept oid isNil not,
            payload atPut("oid", concept oid asString)
        )
        if(concept label isNil not,
            payload atPut("label", concept label)
        )
        if(concept confidence isNil not,
            payload atPut("confidence", concept confidence)
        )
        if(concept usageCount isNil not,
            payload atPut("usage_count", concept usageCount)
        )
        if(concept source isNil not,
            payload atPut("source", concept source)
        )
        if(concept symbolicHypervectorName isNil not,
            payload atPut("symbolic_hypervector_name", concept symbolicHypervectorName)
        )
        if(concept geometricEmbeddingName isNil not,
            payload atPut("geometric_embedding_name", concept geometricEmbeddingName)
        )

        relationships := buildRelationshipPayload(concept)
        if(relationships,
            payload atPut("relationships", relationships)
        )

        payload
        markChanged()
    )

    normalizeSequenceList := method(value,
        if(value isNil,
            list(),
            if(value type == "List",
                normalized := list()
                value foreach(entry,
                    if(entry isNil,
                        nil,
                        normalized append(entry asString)
                    )
                )
                normalized,
                list()
            )
        )
        markChanged()
    )

    applyRelationships := method(concept, payload)
        relationships := payload at("relationships")
        if(relationships type != "Map",
            return concept
        )
        relationshipKeys := Map clone
        relationshipKeys atPut("is_a", "isA")
        relationshipKeys atPut("part_of", "partOf")
        relationshipKeys atPut("abstraction_of", "abstractionOf")
        relationshipKeys atPut("instance_of", "instanceOf")
        relationshipKeys atPut("associated_with", "associatedWith")

        relationshipKeys foreach(snakeKey, camelKey,
            values := relationships at(snakeKey)
            if(values type == "List",
                concept setSlot(camelKey, normalizeSequenceList(values))
            )
        )
        concept
        markChanged()
    )

    hydrateConcept := method(payload,
        if(payload type != "Map",
            Exception raise("hydrateConcept expects a Map payload")
        )
        target := conceptPrototype clone

        target oid = payload at("oid")
        target label = payload at("label")
        value := payload at("confidence")
        if(value isNil,
            target confidence = target confidence,
            target confidence = value asNumber
        )
        usage := payload at("usage_count")
        if(usage isNil,
            target usageCount = target usageCount,
            target usageCount = usage asNumber
        )
        if(payload hasKey("source"), target source = payload at("source"))
        if(payload hasKey("symbolic_hypervector_name"),
            target symbolicHypervectorName = payload at("symbolic_hypervector_name")
        )
        if(payload hasKey("geometric_embedding_name"),
            target geometricEmbeddingName = payload at("geometric_embedding_name")
        )
        if(payload hasKey("created_at"), target createdAt = payload at("created_at"))
        if(payload hasKey("last_modified"), target lastModified = payload at("last_modified"))

        applyRelationships(target, payload)
        target
        markChanged()
    )

    refreshPrototype := method(concept, payload)
        ensureConcept(concept)
        if(payload type != "Map",
            Exception raise("refreshPrototype expects a Map payload")
        )

        if(payload hasKey("oid"), concept oid = payload at("oid"))
        if(payload hasKey("label"), concept label = payload at("label"))

        if(payload hasKey("confidence"),
            confidenceValue := payload at("confidence")
            concept confidence = confidenceValue asNumber
        )

        if(payload hasKey("usage_count"),
            concept usageCount = payload at("usage_count") asNumber
        )

        if(payload hasKey("source"), concept source = payload at("source"))
        if(payload hasKey("symbolic_hypervector_name"),
            concept symbolicHypervectorName = payload at("symbolic_hypervector_name")
        )
        if(payload hasKey("geometric_embedding_name"),
            concept geometricEmbeddingName = payload at("geometric_embedding_name")
        )
        if(payload hasKey("created_at"), concept createdAt = payload at("created_at"))
        if(payload hasKey("last_modified"), concept lastModified = payload at("last_modified"))

        applyRelationships(concept, payload)
        concept
        markChanged()
    )

    persistConcept := method(concept, options,
        ensureConcept(concept)
        payload := buildPersistencePayload(concept)
        response := manager storeConcept(payload, options)
        storedOid := response at("oid")
        if(concept oid isNil and storedOid isNil not,
            concept oid = storedOid
        )

        reload := manager loadConcept(concept oid asString, options)
        conceptData := reload at("concept")
        if(conceptData type == "Map",
            refreshPrototype(concept, conceptData)
        )
        response
        markChanged()
    )

    loadConcept := method(oid, options,
        if(oid isNil,
            Exception raise("loadConcept requires an oid")
        )
        response := manager loadConcept(oid asString, options)
        conceptData := response at("concept")
        if(conceptData type != "Map",
            Exception raise("Concept not found: " .. oid)
        )
        hydrateConcept(conceptData)
        markChanged()
    )

    hydrateExisting := method(concept, options,
        ensureConcept(concept)
        if(concept oid isNil,
            Exception raise("hydrateExisting requires the concept to have an oid")
        )
        response := manager loadConcept(concept oid asString, options)
        conceptData := response at("concept")
        if(conceptData type != "Map",
            Exception raise("Concept not found for oid: " .. concept oid)
        )
        refreshPrototype(concept, conceptData)
        markChanged()
    )

    deleteConcept := method(conceptOrOid, options,
        oid := if(conceptOrOid type == "Sequence" or conceptOrOid type == "Symbol", conceptOrOid asString,
            if(conceptOrOid hasSlot("oid") and conceptOrOid oid isNil not,
                conceptOrOid oid asString,
                nil
            )
        )
        if(oid isNil,
            Exception raise("deleteConcept requires an oid or Concept prototype")
        )
        response := manager deleteConcept(oid, options)
        if(conceptOrOid hasSlot("oid"),
            conceptOrOid oid = nil
        )
        response
        markChanged()
    )

    listConcepts := method(limit, offset, options,
        manager listConcepts(limit, offset, options)
        markChanged()
    )
)

TelosConceptRepository hydrate := method(payload,
    TelosConceptRepository hydrateConcept(payload)
)
