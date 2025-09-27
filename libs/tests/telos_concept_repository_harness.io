// Telos Concept Repository Io Harness
// Validates Concept prototype persistence through the TelosConceptRepository veneer.

TelosConceptRepositoryHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosConceptRepositoryHarness assertion failed: " .. message)
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

    ensureList := method(value, label,
        assert(value type == "List", label .. " must be a List, received " .. value type)
        value
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        outcome := try(
            assert(Telos start(1), "Telos failed to start for concept repository harness")

            initResponse := Telos ZODB initialize(Map clone atPut("mode", "ephemeral"))
            ensureMap(initResponse, "initialize response")
            assert(initResponse at("success"), "ZODB initialize reported failure")

            concept := Protos Core Concept clone
            concept label = "Repository Harness Concept"
            concept confidence = 0.84
            concept source = "concept_repository_harness"
            concept init

            persistResponse := concept persist
            ensureMap(persistResponse, "persist response")
            assert(concept oid isNil not, "Concept persist did not assign oid")

            related := Protos Core Concept clone
            related label = "Repository Harness Related"
            related confidence = 0.73
            related source = "concept_repository_harness"
            related init
            relatedPersist := related persist
            ensureMap(relatedPersist, "related persist response")
            assert(related oid isNil not, "Related concept persist did not assign oid")

            loadedConcept := Telos ConceptRepository loadConcept(concept oid)
            assert(loadedConcept hasSlot("label"), "Loaded concept missing label slot")
            assert(loadedConcept label == concept label, "Loaded concept label mismatch")
            assert(loadedConcept confidence asNumber >= 0, "Loaded confidence missing or invalid")

            concept label = "Harness Concept Updated"
            concept confidence = 0.92
            updatedResponse := concept persist
            ensureMap(updatedResponse, "updated persist response")

            concept isA append(related oid asString)
            concept associatedWith append(related oid asString)
            concept partOf append(related oid asString)
            relationshipsResponse := concept persist
            ensureMap(relationshipsResponse, "relationships persist response")

            commitResponse := Telos ZODB commit
            ensureMap(commitResponse, "commit response")
            assert(commitResponse at("success"), "commit response did not indicate success")

            refreshedConcept := Telos ConceptRepository loadConcept(concept oid)
            assert(refreshedConcept label == "Harness Concept Updated", "Updated concept label not persisted")
            assert(refreshedConcept isA contains(related oid asString), "isA relationship missing after reload")
            assert(refreshedConcept associatedWith contains(related oid asString), "associatedWith relationship missing after reload")
            assert(refreshedConcept partOf contains(related oid asString), "partOf relationship missing after reload")

            concept reload
            assert(concept isA contains(related oid asString), "Concept reload missing isA relationship")
            assert(concept associatedWith contains(related oid asString), "Concept reload missing associatedWith relationship")

            concept isA = list()
            concept associatedWith = list()
            concept partOf = list()
            clearResponse := concept persist
            ensureMap(clearResponse, "clear relationships persist response")

            commitAfterClear := Telos ZODB commit
            ensureMap(commitAfterClear, "post-clear commit response")
            assert(commitAfterClear at("success"), "post-clear commit failed")

            cleared := Telos ConceptRepository loadConcept(concept oid)
            assert(cleared isA size == 0, "Cleared concept isA not empty")
            assert(cleared associatedWith size == 0, "Cleared concept associatedWith not empty")
            assert(cleared partOf size == 0, "Cleared concept partOf not empty")

            listResponse := Telos ConceptRepository listConcepts(10, 0)
            ensureMap(listResponse, "list response")
            oids := ensureList(listResponse at("oids"), "oids list")
            assert(oids contains(concept oid asString), "Persisted oid missing in list response")

            deleteResponse := concept delete
            ensureMap(deleteResponse, "delete response")
            assert(deleteResponse at("success"), "delete response did not indicate success")

            deleteRelated := related delete
            ensureMap(deleteRelated, "related delete response")
            assert(deleteRelated at("success"), "related delete response did not indicate success")

            shutdownResponse := Telos ZODB shutdown
            ensureMap(shutdownResponse, "shutdown response")
            assert(shutdownResponse at("success"), "shutdown response did not indicate success")

            "ok"
        )

        Telos stop
        Telos Bridge clearError

        if(outcome type == "Exception",
            outcome pass,
            outcome
        )
    )
)

result := try(TelosConceptRepositoryHarness run)
if(result type == "Exception",
    System log("TelosConceptRepositoryHarness failure: " .. result message)
    result pass
)

System log("TelosConceptRepositoryHarness success")
