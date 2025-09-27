// TELOS Federated Memory Benchmark Harness
// Exercises the benchmark pipeline through the Synaptic Bridge and
// validates that metrics and history records are surfaced to Io callers.

TelosFederatedMemoryBenchmarkHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosFederatedMemoryBenchmarkHarness assertion failed: " .. message)
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
        l1 atPut("eviction_threshold", 0.8)
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

    validateBenchmarkResult := method(result, expectedConcepts,
        assert(result type == "Map", "benchmark response must be a Map")
        assert(result at("success") == true, "benchmark should report success")
        workload := result at("workload")
        assert(workload type == "Map", "benchmark workload payload missing")
        assert(workload at("concepts_created") >= expectedConcepts, "concepts_created below expected threshold")
        metrics := result at("metrics")
        assert(metrics type == "Map", "benchmark metrics payload missing")
        creation := metrics at("creation")
        assert(creation type == "Map", "creation metrics missing")
        assert(creation at("count") >= expectedConcepts, "creation count should cover all inserted concepts")
        latency := metrics at("hybrid_query_latency")
        assert(latency type == "Map", "hybrid query latency summary missing")
        assert(latency at("count") >= 0, "latency count should be non-negative")
        outbox := metrics at("outbox")
        assert(outbox type == "Map", "outbox metrics missing")
        result
    )

    validateHistory := method(limit,
        historyResponse := Telos FederatedMemory benchmarkHistory(limit)
        assert(historyResponse type == "Map", "benchmark history response must be a Map")
        historyList := historyResponse at("history")
        assert(historyList type == "List", "benchmark history must include history list")
        assert(historyList size >= 1, "benchmark history should contain at least one entry")
        latest := historyList at(0)
        assert(latest type == "Map", "benchmark history entry should be a Map")
        latestResult := latest at("result")
        assert(latestResult type == "Map", "benchmark history entry missing result payload")
        assert(latestResult at("success") == true, "latest benchmark entry should be successful")
        historyResponse
    )

    validateSummary := method(limit, expectedRuns,
        summaryResponse := Telos FederatedMemory benchmarkSummary(limit)
        assert(summaryResponse type == "Map", "benchmark summary response must be a Map")
        summaryPayload := summaryResponse at("summary")
        assert(summaryPayload type == "Map", "benchmark summary payload missing")
        runsConsidered := summaryPayload at("runs_considered")
        assert(runsConsidered >= expectedRuns, "summary should consider at least expected runs")
        l3Series := summaryPayload at("l3_tps")
        assert(l3Series type == "Map", "benchmark summary missing l3_tps aggregate")
        assert(l3Series at("samples") >= 1, "benchmark summary should include l3 samples")
        creationSeries := summaryPayload at("creation_latency_ms")
        assert(creationSeries type == "Map", "benchmark summary missing creation latency aggregate")
        assert(creationSeries at("operations") >= expectedRuns, "creation latency aggregate should account for benchmark runs")
        summaryPayload
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        storagePath := "telos_federated_memory_benchmark.h5"
        conceptCount := 8

        operation := try(
            assert(Telos start(1), "Telos start failed")

            config := buildConfig(storagePath)
            initResponse := Telos FederatedMemory initialize(config)
            assert(initResponse at("success"), "federated memory initialize should succeed")

            options := Map clone
            options atPut("concept_count", conceptCount)
            options atPut("vector_dim", 8)
            options atPut("include_updates", false)
            searchOptions := Map clone
            searchOptions atPut("ratio", 0.5)
            searchOptions atPut("k", 2)
            searchOptions atPut("tiers", list("L1", "L2"))
            options atPut("search", searchOptions)

            benchmarkResult := Telos FederatedMemory runBenchmark(options)
            validateBenchmarkResult(benchmarkResult, conceptCount)

            historyResponse := validateHistory(3)
            history := historyResponse at("history")
            latest := history at(0)
            assert(latest at("timestamp") isNil not, "benchmark history entry must include timestamp")

            daemonConfig := Map clone
            daemonConfig atPut("interval_seconds", 0.15)
            daemonConfig atPut("concept_count", 4)
            daemonConfig atPut("vector_dim", 8)
            daemonConfig atPut("include_updates", false)

            startDaemon := Telos FederatedMemory startBenchmarkDaemon(daemonConfig)
            assert(startDaemon at("success"), "start benchmark daemon should report success")

            System sleep(0.4)

            statusResponse := Telos FederatedMemory benchmarkDaemonStatus
            assert(statusResponse type == "Map", "benchmark daemon status response must be a Map")
            status := statusResponse at("status")
            assert(status type == "Map", "benchmark daemon status payload missing")
            assert(status at("running") == true, "benchmark daemon should be running")
            runsBefore := status at("runs")
            assert(runsBefore >= 1, "benchmark daemon should execute at least one run")

            triggerOptions := Map clone
            triggerOptions atPut("concept_count", 3)
            triggerOptions atPut("interval_seconds", 0.12)
            triggerResponse := Telos FederatedMemory triggerBenchmarkRun(triggerOptions)
            assert(triggerResponse at("success"), "trigger benchmark run should succeed")

            System sleep(0.35)

            statusAfterTrigger := Telos FederatedMemory benchmarkDaemonStatus
            assert(statusAfterTrigger type == "Map", "benchmark daemon status response after trigger must be a Map")
            statusMap := statusAfterTrigger at("status")
            assert(statusMap type == "Map", "benchmark daemon status map missing after trigger")
            runsAfter := statusMap at("runs")
            assert(runsAfter >= runsBefore + 1, "benchmark daemon should increase run count after trigger")

            summaryPayload := validateSummary(nil, runsAfter)
            assert(summaryPayload at("successful_runs") >= 1, "summary should record successful runs")
            limitedSummary := Telos FederatedMemory benchmarkSummary(1)
            assert(limitedSummary at("summary") at("runs_considered") >= 1, "limited summary should report at least one run")

            alertConfig := Map clone
            alertConfig atPut("history_window", 3)
            thresholds := Map clone

            l3Threshold := Map clone
            l3Threshold atPut("warning", 25)
            l3Threshold atPut("critical", 12)
            thresholds atPut("l3_tps_min", l3Threshold)

            replicationThreshold := Map clone
            replicationThreshold atPut("warning", 1.0)
            replicationThreshold atPut("critical", 0.5)
            thresholds atPut("replication_lag_p95_ms", replicationThreshold)

            hybridThreshold := Map clone
            hybridThreshold atPut("warning", 1.0)
            hybridThreshold atPut("critical", 0.25)
            thresholds atPut("hybrid_query_latency_p95_ms", hybridThreshold)

            alertConfig atPut("thresholds", thresholds)

            configureResponse := Telos FederatedMemory configureBenchmarkAlerts(alertConfig)
            assert(configureResponse at("success") == true, "configureBenchmarkAlerts should succeed")
            evalPayload := configureResponse at("evaluation")
            assert(evalPayload type == "Map", "configure response should include evaluation payload")
            assert(evalPayload at("severity") != "ok", "aggressive thresholds should trigger alert severity")

            alertsResponse := Telos FederatedMemory benchmarkAlerts(nil)
            assert(alertsResponse at("success") == true, "benchmarkAlerts should return success")
            alertsPayload := alertsResponse at("alerts")
            assert(alertsPayload type == "Map", "alerts snapshot payload missing")
            historyList := alertsPayload at("history")
            assert(historyList type == "List", "alerts history must be a List")
            assert(historyList size >= 1, "alerts history should contain at least one entry")
            firstAlert := historyList at(0)
            assert(firstAlert at("severity") == "critical", "alert severity should be critical for the configured thresholds")

            refreshRequest := Map clone
            refreshRequest atPut("refresh", true)
            refreshResponse := Telos FederatedMemory benchmarkAlerts(refreshRequest)
            assert(refreshResponse at("success") == true, "refresh benchmarkAlerts should succeed")

            manualEvalOptions := Map clone
            manualEvalOptions atPut("limit", 2)
            manualEvaluation := Telos FederatedMemory evaluateBenchmarkAlerts(manualEvalOptions)
            assert(manualEvaluation at("success") == true, "evaluateBenchmarkAlerts should return success")
            assert(manualEvaluation at("severity") type == "Sequence", "manual evaluation should include severity string")

            recommendationsResponse := Telos FederatedMemory benchmarkRecommendations(nil)
            assert(recommendationsResponse at("success") == true, "benchmarkRecommendations should return success")
            recommendationList := recommendationsResponse at("recommendations")
            assert(recommendationList type == "List", "recommendation response must include recommendation list")
            assert(recommendationList size >= 1, "alerts should enqueue at least one recommendation")
            firstRecommendation := recommendationList at(0)
            assert(firstRecommendation at("id") type == "Sequence", "recommendation should provide an identifier")
            assert(firstRecommendation at("actions") type == "List", "recommendation should include action list")

            applyOptions := Map clone
            applyOptions atPut("ids", list(firstRecommendation at("id")))
            applyResponse := Telos FederatedMemory applyBenchmarkRecommendations(applyOptions)
            assert(applyResponse at("success") == true, "applyBenchmarkRecommendations should report success")
            appliedSummary := applyResponse at("applied")
            assert(appliedSummary type == "List", "apply response should include applied summary list")
            assert(appliedSummary size >= 1, "apply response should summarize applied recommendations")
            firstApplied := appliedSummary at(0)
            assert(firstApplied at("status") type == "Sequence", "applied summary should include status string")

            recommendationsAfterApply := applyResponse at("recommendations")
            assert(recommendationsAfterApply type == "List", "apply response should include refreshed recommendation list")
            if(recommendationsAfterApply size >= 1,
                updatedFirst := recommendationsAfterApply at(0)
                assert(updatedFirst at("status") != "processing", "applied recommendation status should finalize")
            )

            clearOptions := Map clone
            clearOptions atPut("ids", list(firstRecommendation at("id")))
            clearedRecommendations := Telos FederatedMemory clearBenchmarkRecommendations(clearOptions)
            assert(clearedRecommendations at("success") == true, "clearBenchmarkRecommendations should report success")
            clearedList := clearedRecommendations at("recommendations")
            assert(clearedList type == "List", "clear response should include recommendation list")

            clearResponse := Telos FederatedMemory clearBenchmarkAlerts
            assert(clearResponse at("success") == true, "clearBenchmarkAlerts should report success")
            clearedAlerts := clearResponse at("alerts")
            assert(clearedAlerts type == "Map", "clear response should include alerts snapshot")
            clearedHistory := clearedAlerts at("history")
            assert(clearedHistory type == "List", "cleared alerts history should be a List")
            assert(clearedHistory size == 0, "alert history should be empty after clear")

            stopDaemon := Telos FederatedMemory stopBenchmarkDaemon(nil)
            assert(stopDaemon at("success"), "stop benchmark daemon should report success")

            finalStatus := Telos FederatedMemory benchmarkDaemonStatus
            assert(finalStatus type == "Map", "final daemon status response must be a Map")
            finalStatusMap := finalStatus at("status")
            assert(finalStatusMap type == "Map", "final daemon status payload missing")
            assert(finalStatusMap at("running") == false, "benchmark daemon should report stopped state")

            shutdownResponse := Telos FederatedMemory shutdown
            assert(shutdownResponse at("success"), "shutdown should report success")

            Map clone atPut("success", true)
        )

        Telos stop
        Telos Bridge clearError

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

result := try(TelosFederatedMemoryBenchmarkHarness run)
if(result type == "Exception",
    System log("TelosFederatedMemoryBenchmarkHarness failure: " .. result message)
    result pass,
    System log("TelosFederatedMemoryBenchmarkHarness completed successfully")
)
