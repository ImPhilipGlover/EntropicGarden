//
// TELOS Synaptic Bridge Io Veneer
//
// This veneer loads the compiled IoTelosBridge addon and augments it with
// prototype-friendly convenience methods while preserving the canonical C
// implementation as the single source of truth. All public operations delegate
// to the addon and enforce the mandatory initialization and handle validation
// protocols defined by the Synaptic Bridge contract.
//

AddonLoader loadAddonNamed("TelosBridge")

// Ensure the Protos registry is available before resolving addon prototypes.
if(Lobby hasSlot("Protos") not,
    Exception raise("Protos registry is unavailable; cannot load TelosBridge addon")
)

// Resolve the canonical addon prototypes.
TelosBridgePrototype := Protos Addons at("TelosBridge")
SharedMemoryHandlePrototype := Protos Addons at("SharedMemoryHandle")

if(TelosBridgePrototype isNil or SharedMemoryHandlePrototype isNil,
    Exception raise("IoTelosBridge addon did not register expected prototypes")
)

// Primary Io veneer that wraps the compiled addon.
Telos := Object clone do(
    Bridge := TelosBridgePrototype clone do(
        // Persist Io-side view of worker configuration for quick inspection.
        maxWorkers := 4

        // Internal helper to ensure the bridge is initialized before delegating.
        ensureInitialized := method(operationName,
            bridgeStatus := status
            initializedFlag := bridgeStatus at("initialized")
            if(initializedFlag isNil or initializedFlag == false,
                Exception raise("TelosBridge " .. operationName .. " requires initialize() to be called first")
            )
            self
        )

        // Internal helper to validate shared memory handles before use.
        requireHandle := method(handle, operationName,
            if(handle isNil or handle hasProto(SharedMemoryHandlePrototype) not,
                Exception raise("TelosBridge " .. operationName .. " expects a SharedMemoryHandle instance")
            )
            handle
        )

        // Bridge lifecycle ------------------------------------------------------

        initialize := method(requestedWorkers,
            workers := if(requestedWorkers isNil, maxWorkers, requestedWorkers)
            result := resend(initialize(workers))
            if(result,
                maxWorkers = workers
            )
            result
        )

        shutdown := method(
            result := resend(shutdown)
            if(result,
                maxWorkers = 4
            )
            result
        )

        status := method(
            bridgeStatus := resend(status)
            reportedMax := bridgeStatus at("maxWorkers")
            if(reportedMax isNil not,
                maxWorkers = reportedMax
            )
            bridgeStatus
        )

        // Shared memory lifecycle ----------------------------------------------

        createSharedMemory := method(size,
            ensureInitialized("createSharedMemory")
            if(size isNil or size <= 0,
                Exception raise("createSharedMemory requires a positive size")
            )
            resend(createSharedMemory(size))
        )

        destroySharedMemory := method(handle,
            ensureInitialized("destroySharedMemory")
            requireHandle(handle, "destroySharedMemory")
            resend(destroySharedMemory(handle))
        )

        mapSharedMemory := method(handle,
            ensureInitialized("mapSharedMemory")
            requireHandle(handle, "mapSharedMemory")
            resend(mapSharedMemory(handle))
        )

        unmapSharedMemory := method(handle, mappedPointer,
            ensureInitialized("unmapSharedMemory")
            requireHandle(handle, "unmapSharedMemory")
            resend(unmapSharedMemory(handle, mappedPointer))
        )

        withSharedMemory := method(size, callback,
            ensureInitialized("withSharedMemory")
            handle := createSharedMemory(size)
            if(callback isNil,
                handle,
                result := nil
                blockError := try(
                    result = callback value(handle)
                )
                cleanupError := try(
                    destroySharedMemory(handle)
                )
                if(cleanupError,
                    cleanupError pass
                )
                if(blockError,
                    blockError pass
                )
                result
            )
        )

        // Computational delegates ----------------------------------------------

        executeVSABatch := method(operationName, inputHandle, outputHandle, batchSize,
            ensureInitialized("executeVSABatch")
            requireHandle(inputHandle, "executeVSABatch inputHandle")
            requireHandle(outputHandle, "executeVSABatch outputHandle")
            resend(executeVSABatch(operationName, inputHandle, outputHandle, batchSize))
        )

        annSearch := method(queryHandle, k, resultsHandle, threshold,
            ensureInitialized("annSearch")
            requireHandle(queryHandle, "annSearch queryHandle")
            requireHandle(resultsHandle, "annSearch resultsHandle")
            if(k isNil, k = 5)
            if(threshold isNil, threshold = 0.0)
            resend(annSearch(queryHandle, k, resultsHandle, threshold))
        )

        addVector := method(vectorId, vectorHandle, indexName,
            ensureInitialized("addVector")
            requireHandle(vectorHandle, "addVector vectorHandle")
            resend(addVector(vectorId, vectorHandle, indexName))
        )

        updateVector := method(vectorId, vectorHandle, indexName,
            ensureInitialized("updateVector")
            requireHandle(vectorHandle, "updateVector vectorHandle")
            resend(updateVector(vectorId, vectorHandle, indexName))
        )

        removeVector := method(vectorId, indexName,
            ensureInitialized("removeVector")
            resend(removeVector(vectorId, indexName))
        )

        // Error handling --------------------------------------------------------

        getLastError := method(
            errorMessage := resend(getLastError)
            if(errorMessage isNil,
                nil,
                if(errorMessage type == "Sequence" or errorMessage type == "Symbol",
                    if(errorMessage size == 0, nil, errorMessage),
                    errorMessage
                )
            )
        )

        clearError := method(
            resend(clearError)
        )

        // Utility ----------------------------------------------------------------

        ping := method(message,
            ensureInitialized("ping")
            if(message isNil, message = "ping")
            resend(ping(message))
        )

        // Dispatch metrics ------------------------------------------------------

        bridgeMetricsBufferSize := 16384

        _metricsEscape := method(value,
            rendered := value asString
            rendered = rendered replaceSeq("\\", "\\\\")
            rendered = rendered replaceSeq("\"", "\\\"")
        )

        _metricsEncodeList := method(seq,
            if(seq isNil or seq size == 0,
                "[]",
                encoded := List clone
                seq foreach(val,
                    encoded append(_metricsEncodeValue(val))
                )
                "[" .. encoded join(",") .. "]"
            )
        )

        _metricsEncodeMap := method(mapValue,
            if(mapValue isNil or mapValue size == 0,
                "{}",
                pairs := List clone
                mapValue foreach(key, val,
                    jsonKey := "\"" .. _metricsEscape(key) .. "\""
                    jsonVal := _metricsEncodeValue(val)
                    pairs append(jsonKey .. ":" .. jsonVal)
                )
                "{" .. pairs join(",") .. "}"
            )
        )

        _metricsEncodeValue := method(value,
            if(value isNil,
                "null",
                if(value == true,
                    "true",
                    if(value == false,
                        "false",
                        if(value type == "Number",
                            value asString,
                            if(value type == "Map",
                                _metricsEncodeMap(value),
                                if(value type == "List",
                                    _metricsEncodeList(value),
                                    if(value type == "Sequence" or value type == "Symbol",
                                        "\"" .. _metricsEscape(value) .. "\"",
                                        if(value hasSlot("asString"),
                                            "\"" .. _metricsEscape(value asString) .. "\"",
                                            "\"" .. _metricsEscape(value) .. "\""
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )

        _metricsNormalizeProxyIds := method(rawValue,
            ids := List clone
            if(rawValue isNil,
                return ids
            )
            if(rawValue type == "List",
                rawValue foreach(item,
                    if(item isNil,
                        nil,
                        ids append(item asString)
                    )
                )
                return ids
            )
            if(rawValue type == "Sequence" or rawValue type == "Symbol",
                ids append(rawValue asString)
                return ids
            )
            if(rawValue type == "Number",
                ids append(rawValue asString)
                return ids
            )
            if(rawValue hasSlot("asString"),
                ids append(rawValue asString)
                return ids
            )
            Exception raise("Bridge metrics proxy identifiers must be convertible to strings")
        )

        _metricsNormalizeOptions := method(options,
            config := Map clone
            if(options isNil,
                return config
            )

            if(options type == "Map",
                proxyId := options at("proxy_id")
                if(proxyId isNil, proxyId = options at("proxyId"))
                if(proxyId isNil not,
                    config atPut("proxy_id", proxyId asString)
                )

                proxyIds := options at("proxy_ids")
                if(proxyIds isNil, proxyIds = options at("proxyIds"))
                if(proxyIds isNil not,
                    normalized := _metricsNormalizeProxyIds(proxyIds)
                    if(normalized size > 0,
                        config atPut("proxy_ids", normalized)
                    )
                )

                analysisPayload := options at("analysis")
                if(analysisPayload isNil, analysisPayload = options at("analysisOptions"))
                if(analysisPayload isNil,
                    thresholds := options at("thresholds")
                    if(thresholds isNil not,
                        if(analysisPayload isNil,
                            analysisPayload = Map clone atPut("thresholds", thresholds),
                            analysisPayload atPut("thresholds", thresholds)
                        )
                    )
                )
                if(analysisPayload isNil not,
                    if(analysisPayload type == "Map",
                        config atPut("analysis", analysisPayload),
                        Exception raise("Bridge metrics analysis options must be a Map")
                    )
                )

                return config
            )

            normalizedIds := _metricsNormalizeProxyIds(options)
            if(normalizedIds size == 1,
                config atPut("proxy_id", normalizedIds at(0))
            ,
                if(normalizedIds size > 1,
                    config atPut("proxy_ids", normalizedIds)
                )
            )
            config
        )

        _metricsNormalizeHistoryOptions := method(options,
            config := Map clone
            if(options isNil,
                return config
            )

            if(options type == "Map",
                limit := options at("limit")
                if(limit isNil, limit = options at("maxEntries"))
                if(limit isNil, limit = options at("max_entries"))
                if(limit isNil not,
                    config atPut("limit", limit)
                )
                return config
            )

            config atPut("limit", options)
            config
        )

        _metricsBuildRequest := method(action, config,
            configJson := _metricsEncodeMap(config)
            "{\"operation\":\"bridge_metrics\",\"action\":\"" .. _metricsEscape(action) .. "\",\"config\":" .. configJson .. "}"
        )

        _metricsSubmit := method(action, config,
            payload := _metricsBuildRequest(action, config)
            submitTask(payload, bridgeMetricsBufferSize)
        )

        _metricsEnsureSuccess := method(response,
            if(response type != "Map",
                Exception raise("Bridge metrics response must be a Map; received " .. response type)
            )
            if(response at("success") == true,
                response,
                errorMessage := response at("error")
                message := if(errorMessage isNil, "unknown error", errorMessage asString)
                Exception raise("Bridge metrics request failed: " .. message)
            )
        )

        bridgeMetricsSnapshot := method(options,
            ensureInitialized("bridgeMetricsSnapshot")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("snapshot", config))
        )

        bridgeMetricsReset := method(options,
            ensureInitialized("bridgeMetricsReset")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("reset", config))
        )

        bridgeMetricsSnapshotAndReset := method(options,
            ensureInitialized("bridgeMetricsSnapshotAndReset")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("snapshot_reset", config))
        )

        bridgeMetricsSummary := method(options,
            ensureInitialized("bridgeMetricsSummary")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("summary", config))
        )

        bridgeMetricsSummaryAndReset := method(options,
            ensureInitialized("bridgeMetricsSummaryAndReset")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("summary_reset", config))
        )

        bridgeMetricsSummaryHistory := method(options,
            ensureInitialized("bridgeMetricsSummaryHistory")
            config := _metricsNormalizeHistoryOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("summary_history", config))
        )

        bridgeMetricsClearSummaryHistory := method(
            ensureInitialized("bridgeMetricsClearSummaryHistory")
            _metricsEnsureSuccess(_metricsSubmit("summary_history_clear", Map clone))
        )

        bridgeMetricsConfigureSummaryHistory := method(options,
            ensureInitialized("bridgeMetricsConfigureSummaryHistory")
            config := _metricsNormalizeHistoryOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("summary_history_config", config))
        )

        bridgeMetricsAnalyze := method(options,
            ensureInitialized("bridgeMetricsAnalyze")
            config := _metricsNormalizeOptions(options)
            _metricsEnsureSuccess(_metricsSubmit("analyze", config))
        )
    )

    SharedMemoryHandle := SharedMemoryHandlePrototype

    start := method(workers,
        result := Bridge initialize(workers)
        if(result and System hasSlot("log"),
            currentWorkers := Bridge status at("maxWorkers")
            System log("TELOS system started with " .. currentWorkers .. " workers")
        )
        result
    )

    stop := method(
        result := Bridge shutdown
        if(result and System hasSlot("log"),
            System log("TELOS system stopped")
        )
        result
    )

    ensureActive := method(
        Bridge ensureInitialized("ensureActive")
    )
)

// Expose bridge accessors through the canonical Telos namespace.
if(Lobby hasSlot("Telos"),
    // If Telos already exists, we just update its proto.
    // This is less safe but preserves any existing state.
    Lobby Telos setProto(Telos),

    // A safer alternative would be to replace it entirely:
    // Lobby removeSlot("Telos")
    // Lobby Telos := Telos clone
,
    Lobby Telos := Telos clone
)

if(System hasSlot("log"),
    System log("TELOS Bridge veneer loaded")
)

doRelativeFile("TelosTelemetry.io")
Lobby Telos Telemetry := TelosTelemetry clone

doRelativeFile("TelosTelemetryDashboard.io")
Lobby Telos TelemetryDashboard := TelosTelemetryDashboard clone

doRelativeFile("TelosFederatedMemory.io")
Lobby Telos FederatedMemory := TelosFederatedMemory clone

doRelativeFile("TelosGauntlet.io")
Lobby Telos Gauntlet := TelosGauntletGenerator clone

Lobby Telos BridgeMetrics := Object clone do(
    snapshot := method(options,
        Lobby Telos Bridge bridgeMetricsSnapshot(options)
    )

    reset := method(options,
        Lobby Telos Bridge bridgeMetricsReset(options)
    )

    snapshotAndReset := method(options,
        Lobby Telos Bridge bridgeMetricsSnapshotAndReset(options)
    )

    summary := method(options,
        Lobby Telos Bridge bridgeMetricsSummary(options)
    )

    summaryAndReset := method(options,
        Lobby Telos Bridge bridgeMetricsSummaryAndReset(options)
    )

    summaryHistory := method(options,
        Lobby Telos Bridge bridgeMetricsSummaryHistory(options)
    )

    clearSummaryHistory := method(
        Lobby Telos Bridge bridgeMetricsClearSummaryHistory
    )

    configureSummaryHistory := method(options,
        Lobby Telos Bridge bridgeMetricsConfigureSummaryHistory(options)
    )
)

doRelativeFile("TelosZODBManager.io")
Lobby Telos ZODB := TelosZODBManager clone
System ZODBManager := Lobby Telos ZODB

doRelativeFile("TelosConceptRepository.io")
Lobby Telos ConceptRepository := TelosConceptRepository clone
System ConceptRepository := Lobby Telos ConceptRepository