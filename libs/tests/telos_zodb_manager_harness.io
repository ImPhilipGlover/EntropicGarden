// Telos ZODB Manager Io Harness
// Validates the TelosZODBManager veneer using the canonical Telos namespace.

TelosZODBManagerHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosZODBManagerHarness assertion failed: " .. message)
        )
    )

    ensureBridge := method(
        doRelativeFile("../Telos/io/TelosBridge.io")
        Telos ensureActive
        Telos Bridge
    )

    ensureMap := method(value, label,
        assert(value type == "Map", label .. " must be a Map, received " .. value type)
        value
    )

    ensureSequence := method(value, label,
        assert(value type == "Sequence", label .. " must be a Sequence")
        value
    )

    buildConceptPayload := method(labelText,
        payload := Map clone
        payload atPut("label", labelText)
        payload atPut("confidence", 0.91)
        payload atPut("source", "io_harness")
        payload atPut("relationships", Map clone atPut("associated_with", list()))
        payload
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        operation := try(
            assert(Telos start(1), "Telos failed to start")

            initResponse := Telos ZODB initialize(Map clone atPut("mode", "ephemeral"))
            ensureMap(initResponse, "initialize response")
            assert(initResponse at("success"), "ZODB initialize reported failure")
            ensureSequence(initResponse at("storage_path"), "initialize storage path")

            originalLabel := "Harness Concept"
            conceptPayload := buildConceptPayload(originalLabel)
            storeResponse := Telos ZODB storeConcept(conceptPayload)
            ensureMap(storeResponse, "store response")
            oid := storeResponse at("oid")
            ensureSequence(oid, "stored oid")

            loadResponse := Telos ZODB loadConcept(oid)
            ensureMap(loadResponse, "load response")
            loadedConcept := ensureMap(loadResponse at("concept"), "loaded concept")
            ensureSequence(loadedConcept at("label"), "loaded label")
            assert(loadedConcept at("label") == originalLabel, "Loaded label mismatch")

            conceptPrototype := Protos Core Concept clone
            conceptPrototype oid = oid
            conceptPrototype init
            conceptPrototype markChanged

            updates := Map clone atPut("label", "Harness Concept Updated")
            updateResponse := Telos ZODB updateConcept(oid, updates)
            ensureMap(updateResponse, "update response")
            assert(updateResponse at("success"), "Update concept reported failure")

            commitResponse := Telos ZODB commit
            ensureMap(commitResponse, "commit response")
            assert(commitResponse at("success"), "Commit transaction failed")

            reloaded := Telos ZODB loadConcept(oid)
            ensureMap(reloaded, "reload response")
            conceptAfter := ensureMap(reloaded at("concept"), "reloaded concept")
            assert(conceptAfter at("label") == "Harness Concept Updated", "Update not persisted")

            listResponse := Telos ZODB listConcepts(10, 0)
            ensureMap(listResponse, "list response")
            oids := listResponse at("oids")
            assert(oids type == "List" and oids contains(oid), "List concepts missing stored oid")

            stats := Telos ZODB statistics
            ensureMap(stats, "statistics response")
            assert(stats at("statistics") type == "Map", "Statistics payload missing")

            markResponse := Telos ZODB markObjectChanged(oid)
            ensureMap(markResponse, "mark changed response")
            assert(markResponse at("success"), "markObjectChanged reported failure")

            deleteResponse := Telos ZODB deleteConcept(oid)
            ensureMap(deleteResponse, "delete response")
            assert(deleteResponse at("deleted"), "deleteConcept did not delete")

            shutdownResponse := Telos ZODB shutdown
            ensureMap(shutdownResponse, "shutdown response")
            assert(shutdownResponse at("success"), "shutdown reported failure")

            assert(System hasSlot("ZODBManager"), "System ZODBManager slot not installed")
            assert(System ZODBManager == Telos ZODB, "System ZODBManager should reference Telos ZODB veneer")

            "ok"
        )

        Telos stop
        Telos Bridge clearError

        if(operation type == "Exception",
            operation pass,
            operation
        )
    )
)

result := try(TelosZODBManagerHarness run)
if(result type == "Exception",
    System log("TelosZODBManagerHarness failure: " .. result message)
    result pass
)

System log("TelosZODBManagerHarness success")
