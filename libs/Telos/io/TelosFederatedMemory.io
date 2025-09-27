// TELOS Federated Memory Io Prototype
// Provides prototypal helpers for interacting with the Python federated memory
// fabric through the Synaptic Bridge, including initialization, status, and
// L2 telemetry retrieval.

TelosFederatedMemory := Object clone do(
    bridge := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace is unavailable; federated memory access requires Telos Bridge")
        )
        Telos ensureActive
        Telos Bridge
    )

    escapeString := method(value,
        rendered := value asString
        rendered = rendered replaceSeq("\\", "\\\\")
        rendered = rendered replaceSeq("\"", "\\\"")
        rendered
    )

    encodeValue := method(value,
        if(value isNil,
            "null",
            if(value == true,
                "true",
                if(value == false,
                    "false",
                    if(value type == "Number",
                        value asString,
                        if(value type == "Map",
                            encodeMap(value),
                            if(value type == "List",
                                encodeList(value),
                                if(value type == "Sequence" or value type == "Symbol",
                                    "\"" .. escapeString(value) .. "\"",
                                    if(value hasSlot("asString"),
                                        "\"" .. escapeString(value asString) .. "\"",
                                        "\"" .. escapeString(value) .. "\""
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )

    encodeMap := method(mapValue,
        if(mapValue isNil or mapValue size == 0,
            "{}",
            pairs := List clone
            mapValue foreach(key, val,
                jsonKey := "\"" .. escapeString(key) .. "\""
                jsonVal := encodeValue(val)
                pairs append(jsonKey .. ":" .. jsonVal)
            )
            "{" .. pairs join(",") .. "}"
        )
    )

    encodeList := method(seq,
        if(seq isNil or seq size == 0,
            "[]",
            encoded := List clone
            seq foreach(val,
                encoded append(encodeValue(val))
            )
            "[" .. encoded join(",") .. "]"
        )
    )

    buildRequest := method(action, config,
        configJson := if(config isNil, "{}", encodeValue(config))
        "{\"operation\":\"federated_memory\",\"action\":\"" .. escapeString(action) .. "\",\"config\":" .. configJson .. "}"
    )

    submit := method(action, config,
        requestPayload := buildRequest(action, config)
        bridge submitTask(requestPayload, 16384)
    )

    ensureSuccess := method(response,
        if(response type != "Map",
            Exception raise("Federated memory response must be a Map; received " .. response type)
        )
        if(response at("success") == true,
            response,
            errorMessage := response at("error")
            details := response at("details")
            message := if(errorMessage isNil, "unknown error", errorMessage asString)
            if(details isNil not,
                message = message .. " (" .. details asString .. ")"
            )
            Exception raise("Federated memory request failed: " .. message)
        )
    )

    initialize := method(config,
        payload := if(config isNil, Map clone, config)
        ensureSuccess(submit("initialize", payload))
    )

    status := method(
        ensureSuccess(submit("status", nil))
    )

    cacheStatistics := method(
        ensureSuccess(submit("cache_statistics", nil))
    )

    outboxStatus := method(
        ensureSuccess(submit("outbox_status", nil))
    )

    outboxAnalytics := method(options,
        payload := if(options isNil, nil, options)
        ensureSuccess(submit("get_outbox_analytics", payload))
    )

    l2Telemetry := method(
        ensureSuccess(submit("l2_telemetry", nil))
    )

    promoteL1 := method(limit, includeVectors, notifyCoordinator,
        include := if(includeVectors isNil, true, includeVectors)
        notify := if(notifyCoordinator isNil, true, notifyCoordinator)
        config := Map clone
        if(limit isNil not,
            config atPut("limit", limit)
        )
        config atPut("include_vectors", include)
        config atPut("notify_coordinator", notify)
        ensureSuccess(submit("promote_l1", config))
    )

    triggerPromotionCycle := method(limit,
        config := Map clone
        if(limit isNil not,
            config atPut("limit", limit)
        )
        ensureSuccess(submit("trigger_promotions", config))
    )

    promotionDaemonStatus := method(
        ensureSuccess(submit("promotion_daemon_status", nil))
    )

    simulateCoordinatorFailure := method(stopAfter,
        config := if(stopAfter isNil,
            nil,
            temp := Map clone; temp atPut("stop_after", stopAfter); temp
        )
        ensureSuccess(submit("simulate_coordinator_failure", config))
    )

    runBenchmark := method(options,
        payload := if(options isNil, Map clone, options)
        ensureSuccess(submit("run_benchmark", payload))
    )

    benchmarkHistory := method(limit,
        config := if(limit isNil,
            nil,
            temp := Map clone; temp atPut("limit", limit); temp
        )
        ensureSuccess(submit("get_benchmark_history", config))
    )

    benchmarkSummary := method(limit,
        config := if(limit isNil,
            nil,
            temp := Map clone; temp atPut("limit", limit); temp
        )
        ensureSuccess(submit("get_benchmark_summary", config))
    )

    configureBenchmarkAlerts := method(options,
        payload := if(options isNil,
            Map clone,
            options
        )
        ensureSuccess(submit("configure_benchmark_alerts", payload))
    )

    benchmarkAlerts := method(options,
        payload := if(options isNil,
            nil,
            options
        )
        ensureSuccess(submit("get_benchmark_alerts", payload))
    )

    clearBenchmarkAlerts := method(
        ensureSuccess(submit("clear_benchmark_alerts", nil))
    )

    evaluateBenchmarkAlerts := method(options,
        payload := if(options isNil,
            nil,
            options
        )
        ensureSuccess(submit("evaluate_benchmark_alerts", payload))
    )

    benchmarkRecommendations := method(options,
        payload := if(options isNil,
            nil,
            options
        )
        ensureSuccess(submit("get_benchmark_recommendations", payload))
    )

    clearBenchmarkRecommendations := method(options,
        payload := if(options isNil,
            nil,
            options
        )
        ensureSuccess(submit("clear_benchmark_recommendations", payload))
    )

    applyBenchmarkRecommendations := method(options,
        payload := if(options isNil,
            nil,
            options
        )
        ensureSuccess(submit("apply_benchmark_recommendations", payload))
    )

    startBenchmarkDaemon := method(options,
        payload := if(options isNil, Map clone, options)
        ensureSuccess(submit("start_benchmark_daemon", payload))
    )

    stopBenchmarkDaemon := method(options,
        payload := if(options isNil, nil, options)
        ensureSuccess(submit("stop_benchmark_daemon", payload))
    )

    triggerBenchmarkRun := method(options,
        payload := if(options isNil, nil, options)
        ensureSuccess(submit("trigger_benchmark_run", payload))
    )

    benchmarkDaemonStatus := method(
        ensureSuccess(submit("benchmark_daemon_status", nil))
    )

    validate := method(
        response := ensureSuccess(submit("validate", nil))
        response
    )

    shutdown := method(
        ensureSuccess(submit("shutdown", nil))
    )
)
