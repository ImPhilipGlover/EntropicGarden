// TELOS Transactional Outbox Io-driven harness
// Exercises the Python transactional outbox through the Synaptic Bridge
// to ensure end-to-end reliability semantics remain intact.

TelosOutboxHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosOutboxHarness assertion failed: " .. message)
        )
    )

    ensureBridge := method(
        doRelativeFile("../Telos/io/TelosBridge.io")
        bridge := Telos Bridge
        if(bridge isNil,
            Exception raise("Unable to resolve Telos Bridge prototype")
        )
        bridge
    )

    buildScenarioPayload := method(
        Map clone atPut("operation", "transactional_outbox")
            atPut("action", "run_scenario")
            atPut("config", Map clone atPut("timeout", 3.0))
    )

    buildDlqPayload := method(
        payloads := List clone
        payloads append(Map clone atPut("payload", Map clone atPut("mode", "ok")))
        payloads append(Map clone atPut("payload", Map clone atPut("mode", "fail")) atPut("metadata", Map clone atPut("label", "expected_dlq")))

        config := Map clone
        config atPut("payloads", payloads map(value, value at("payload")))
        config atPut("metadata", payloads map(value, value at("metadata")))
        config atPut("timeout", 4.0)

        Map clone atPut("operation", "transactional_outbox")
            atPut("action", "dlq_snapshot")
            atPut("config", config)
    )

    encodeJson := method(map,
        Telos FederatedMemory encodeValue(map) // reuse JSON encoder
    )

    validateScenario := method(response,
        assert(response type == "Map", "submitTask should return a Map")
        assert(response at("success"), "Transactional outbox scenario reported failure")

        okId := response at("ok_id")
        failId := response at("fail_id")
        processed := response at("processed")
        deadLetters := response at("dead_letters")

        assert(okId isNil not, "Response missing ok_id")
        assert(failId isNil not, "Response missing fail_id")
        assert(processed type == "List", "processed should be a List")
        assert(deadLetters type == "List", "dead_letters should be a List")
        assert(processed contains(okId), "Processed list missing ok_id")
        assert(deadLetters contains(failId), "Dead letters list missing fail_id")

        stats := response at("stats")
        assert(stats type == "Map", "Statistics payload missing")
        assert(stats at("processed") == 1, "Processed count mismatch")
        assert(stats at("dlq") == 1, "DLQ count mismatch")

        true
    )

    validateDlqSnapshot := method(response,
        assert(response type == "Map", "DLQ snapshot response must be a Map")
        assert(response at("success"), "DLQ snapshot reported failure")

        dlqEntries := response at("dlq_entries")
        assert(dlqEntries type == "List", "DLQ entries should be a List")
        assert(dlqEntries size >= 1, "Expected at least one DLQ entry")

        entry := dlqEntries at(0)
        assert(entry type == "Map", "DLQ entry must be a Map")
        assert(entry at("id") isNil not, "DLQ entry missing id")

        stats := response at("statistics")
        assert(stats at("dlq") >= 1, "Statistics should report DLQ count")

        requeued := response at("requeued")
        assert(requeued type == "List", "Requeued list missing")

        true
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        operation := try(
            assert(Telos start(1), "Telos start failed")
            scenarioJson := encodeJson(buildScenarioPayload)
            scenarioResponse := bridge submitTask(scenarioJson, 12288)
            validateScenario(scenarioResponse)

            dlqJson := encodeJson(buildDlqPayload)
            dlqResponse := bridge submitTask(dlqJson, 16384)
            validateDlqSnapshot(dlqResponse)
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

result := try(TelosOutboxHarness run)
if(result type == "Exception",
    System log("TelosOutboxHarness failure: " .. result message)
    result pass
)

System log("TelosOutboxHarness success")
