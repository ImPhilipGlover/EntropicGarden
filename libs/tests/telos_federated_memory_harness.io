// TELOS Federated Memory Io-driven harness
// Validates that the federated memory fabric can be initialized through the
// Synaptic Bridge and that L2 telemetry metrics surface to Io consumers.

TelosFederatedMemoryHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosFederatedMemoryHarness assertion failed: " .. message)
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

    buildConfig := method(storagePath,
        config := Map clone
        l1 := Map clone
        l1 atPut("max_size", 32)
        l1 atPut("vector_dim", 8)
        l1 atPut("index_type", "Flat")
        l1 atPut("eviction_threshold", 0.75)
        l1 atPut("promotion_threshold", 2)
        l1 atPut("promotion_requeue_step", 2)
        config atPut("l1", l1)

        l2 := Map clone
        l2 atPut("storage_path", storagePath)
        l2 atPut("max_size", 64)
        l2 atPut("vector_dim", 8)
        config atPut("l2", l2)

        coordinator := Map clone
        coordinator atPut("enable_l1", true)
        coordinator atPut("enable_l2", true)
        coordinator atPut("enable_l3", false)
        coordinator atPut("workers", 0)
        l1Coordinator := Map clone
        l1Coordinator atPut("max_size", 32)
        l1Coordinator atPut("vector_dim", 8)
        l1Coordinator atPut("promotion_threshold", 2)
        coordinator atPut("l1_config", l1Coordinator)
        config atPut("coordinator", coordinator)

        bridgeCfg := Map clone
        bridgeCfg atPut("workers", 0)
        config atPut("bridge", bridgeCfg)

        config
    )

    encodeVector := method(numbers,
        rendered := numbers map(v, v asNumber asString)
        "[" .. rendered join(",") .. "]"
    )

    buildVectorConfigure := method(
        "{\"operation\":\"vector_operations\",\"action\":\"configure\",\"config\":{\"max_size\":32,\"vector_dim\":8,\"eviction_threshold\":0.75,\"index_type\":\"Flat\",\"promotion_threshold\":2,\"promotion_requeue_step\":2}}"
    )

    buildVectorPut := method(oid, vectorList,
        "{\"operation\":\"vector_operations\",\"action\":\"put\",\"config\":{\"oid\":\"" .. oid .. "\",\"vector\":" .. encodeVector(vectorList) .. ",\"metadata\":{\"label\":\"" .. oid .. "\"}}}"
    )

    buildVectorGet := method(oid,
        "{\"operation\":\"vector_operations\",\"action\":\"get\",\"config\":{\"oid\":\"" .. oid .. "\",\"include_vector\":false}}"
    )

    validateInitialize := method(response,
        assert(response type == "Map", "initialize response must be a Map")
        assert(response at("success"), "initialize should report success")
        status := response at("status")
        assert(status type == "Map", "initialize response missing status")
        assert(status at("initialized") == true, "fabric should report initialized=true")
        components := status at("components")
        assert(components type == "Map", "status components missing")
        l2Component := components at("L2")
        assert(l2Component type == "Map", "L2 component telemetry missing from status")
        response
    )

    validateTelemetry := method(response,
        assert(response type == "Map", "telemetry response must be a Map")
        telemetry := response at("telemetry")
        assert(telemetry type == "Map", "telemetry payload missing")
        searchMetrics := telemetry at("search_metrics")
        assert(searchMetrics type == "Map", "search_metrics payload missing")
        queries := searchMetrics at("queries")
        assert(queries isNil not, "search_metrics.queries missing")
        assert(queries type == "Number", "search_metrics.queries should be numeric")
        diskannMetrics := telemetry at("diskann_metrics")
        assert(diskannMetrics type == "Map", "diskann_metrics payload missing")
        eviction := telemetry at("eviction_history")
        assert(eviction type == "List", "eviction_history should be a List")
        telemetry
    )

    validateStatistics := method(response,
        assert(response type == "Map", "statistics response must be a Map")
        stats := response at("statistics")
        assert(stats type == "Map", "statistics payload missing")
        l2Stats := stats at("L2")
        assert(l2Stats type == "Map", "L2 statistics missing")
        assert(l2Stats at("max_size") type == "Number", "L2 statistics missing max_size")
        stats
    )

    validateOutboxStatus := method(response,
        assert(response type == "Map", "outbox status response must be a Map")
        status := response at("status")
        assert(status type == "Map", "outbox status payload missing")
        metrics := status at("metrics")
        assert(metrics type == "Map", "outbox status metrics missing")
        runtime := status at("runtime")
        assert(runtime type == "Map", "outbox status runtime missing")
        status
    )

    validateOutboxAnalytics := method(response, expectSamples,
        assert(response type == "Map", "outbox analytics response must be a Map")
        analytics := response at("analytics")
        assert(analytics type == "Map", "outbox analytics payload missing")
        summary := analytics at("summary")
        assert(summary type == "Map", "outbox analytics summary missing")
        rates := analytics at("rates")
        assert(rates type == "Map", "outbox analytics rates missing")
        latency := analytics at("latency")
        assert(latency type == "Map", "outbox analytics latency missing")
        latencySummary := latency at("summary")
        assert(latencySummary type == "Map", "outbox analytics latency summary missing")
        if(expectSamples,
            samples := latency at("samples_ms")
            assert(samples type == "List", "outbox analytics latency samples should be a List")
        )
        actions := analytics at("actions")
        assert(actions type == "Map", "outbox analytics actions missing")
        failures := analytics at("failures")
        assert(failures type == "Map", "outbox analytics failures missing")
        backlog := analytics at("backlog")
        assert(backlog type == "Map", "outbox analytics backlog missing")
        recent := analytics at("recent")
        assert(recent type == "Map", "outbox analytics recent metadata missing")
        snapshot := analytics at("status_snapshot")
        assert(snapshot type == "Map", "outbox analytics status snapshot missing")
        analytics
    )

    validatePromotionResult := method(response, expectedOid,
        assert(response type == "Map", "promotion response must be a Map")
        assert(response at("success"), "promotion should report success")
        promoted := response at("promoted")
        assert(promoted type == "Number", "promotion response missing promoted count")
        assert(promoted >= 1, "promotion should promote at least one candidate")
        promotedOids := response at("promoted_oids")
        assert(promotedOids type == "List", "promotion response should include promoted_oids list")
        assert(promotedOids contains(expectedOid), "expected oid not present in promoted list")
        response
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        storagePath := "telos_federated_memory_cache.h5"
        vectorA := list(0.12, 0.21, 0.31, 0.41, 0.51, 0.61, 0.71, 0.81)
        conceptOid := "concept/promotion"

        operation := try(
            assert(Telos start(1), "Telos start failed")

            config := buildConfig(storagePath)
            initResponse := Telos FederatedMemory initialize(config)
            validateInitialize(initResponse)

            configureResponse := bridge submitTask(buildVectorConfigure, 4096)
            assert(configureResponse at("success"), "vector configure should succeed")

            putResponse := bridge submitTask(buildVectorPut(conceptOid, vectorA), 8192)
            assert(putResponse at("success"), "vector put should succeed")

            repeat := 0
            while(repeat < 3,
                getResponse := bridge submitTask(buildVectorGet(conceptOid), 4096)
                assert(getResponse at("success"), "vector get should succeed")
                repeat = repeat + 1
            )

            promotionResponse := Telos FederatedMemory promoteL1(5)
            validatePromotionResult(promotionResponse, conceptOid)

            telemetryResponse := Telos FederatedMemory l2Telemetry
            validateTelemetry(telemetryResponse)

            statisticsResponse := Telos FederatedMemory cacheStatistics
            stats := validateStatistics(statisticsResponse)
            l2Stats := stats at("L2")
            assert(l2Stats at("current_size") >= 1, "L2 cache should contain promoted vector")
            promotionMetrics := stats at("promotion_metrics")
            assert(promotionMetrics type == "Map", "promotion metrics missing from cache statistics")
            assert(promotionMetrics at("total_promoted") >= 1, "promotion metrics should record promoted entries")

            outboxStatus := Telos FederatedMemory outboxStatus
            outboxState := validateOutboxStatus(outboxStatus)
            outboxMetrics := outboxState at("metrics")
            assert(outboxMetrics at("enqueued") type == "Number", "outbox metrics should include enqueued counter")

            analyticsResponse := Telos FederatedMemory outboxAnalytics(nil)
            analyticsPayload := validateOutboxAnalytics(analyticsResponse, false)
            rates := analyticsPayload at("rates")
            assert(rates hasKey("failure_rate"), "outbox analytics rates should include failure_rate")

            sampleOptions := Map clone
            sampleOptions atPut("include_latency_samples", true)
            analyticsWithSamples := Telos FederatedMemory outboxAnalytics(sampleOptions)
            analyticsSamplePayload := validateOutboxAnalytics(analyticsWithSamples, true)
            window := analyticsSamplePayload at("latency") at("window")
            assert(window type == "Number", "outbox analytics latency window should be numeric")

            failureVector := list(0.31, 0.41, 0.51, 0.61, 0.71, 0.81, 0.91, 1.01)
            failureOid := "concept/promotionFailure"
            failurePut := bridge submitTask(buildVectorPut(failureOid, failureVector), 8192)
            assert(failurePut at("success"), "failure vector put should succeed")

            repeatFailure := 0
            while(repeatFailure < 3,
                failureGet := bridge submitTask(buildVectorGet(failureOid), 4096)
                assert(failureGet at("success"), "failure vector get should succeed")
                repeatFailure = repeatFailure + 1
            )

            failureSim := Telos FederatedMemory simulateCoordinatorFailure(true)
            assert(failureSim at("success") == true, "simulateCoordinatorFailure should report success")
            assert(failureSim at("stopped") == true, "simulateCoordinatorFailure should stop the coordinator when requested")

            failureConfig := Map clone
            failureConfig atPut("include_vectors", true)
            failureConfig atPut("notify_coordinator", true)
            failureResponse := Telos FederatedMemory submit("promote_l1", failureConfig)
            assert(failureResponse at("success") == false, "promotion should fail when coordinator is offline")
            failureReasons := failureResponse at("failure_reasons")
            assert(failureReasons type == "Map", "failure response should include failure_reasons map")
            failedCount := 0
            failedValue := failureReasons at("coordinator_put_failed")
            if(failedValue isNil not,
                failedCount = failedCount + failedValue asNumber
            )
            rejectedValue := failureReasons at("coordinator_put_rejected")
            if(rejectedValue isNil not,
                failedCount = failedCount + rejectedValue asNumber
            )
            assert(failedCount >= 1, "failure reasons should include coordinator failures")
            requeuedValue := failureResponse at("requeued")
            requeuedCount := if(requeuedValue isNil, 0, requeuedValue asNumber)
            assert(requeuedCount >= 1, "failed promotion should be requeued")

            postFailureStats := Telos FederatedMemory cacheStatistics
            postMetrics := postFailureStats at("promotion_metrics")
            requeuedTotalValue := postMetrics at("requeued_after_failure")
            requeuedTotal := if(requeuedTotalValue isNil, 0, requeuedTotalValue asNumber)
            assert(requeuedTotal >= 1, "promotion metrics should record requeued failures")
            metricReasons := postMetrics at("failure_reasons")
            assert(metricReasons type == "Map", "promotion metrics should expose failure reasons map")
            metricFailed := metricReasons at("coordinator_put_failed")
            metricRejected := metricReasons at("coordinator_put_rejected")
            metricSum := 0
            if(metricFailed isNil not,
                metricSum = metricSum + metricFailed asNumber
            )
            if(metricRejected isNil not,
                metricSum = metricSum + metricRejected asNumber
            )
            assert(metricSum >= 1, "metrics should retain coordinator failure counts")

            shutdownResponse := Telos FederatedMemory shutdown
            assert(shutdownResponse at("success"), "shutdown should report success")

            "ok"
        )

        Telos stop
        Telos Bridge clearError

        // Attempt to clean up generated storage artifacts.
        cleanup := try(
            if(System hasSlot("removeFile"),
                System removeFile(storagePath)
            )
        )
        if(cleanup type == "Exception",
            cleanup pass
        )

        if(operation type == "Exception",
            operation pass,
            operation
        )
    )
)

result := try(TelosFederatedMemoryHarness run)
if(result type == "Exception",
    System log("TelosFederatedMemoryHarness failure: " .. result message)
    result pass,
    System log("TelosFederatedMemoryHarness completed successfully")
)
