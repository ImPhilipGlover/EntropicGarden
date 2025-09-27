// TELOS L1 Cache Io-driven harness
// Validates L1 cache operations (configure, put/get/remove/search) through
// the Synaptic Bridge to ensure Io actors can manage the Python L1 cache layer.

TelosL1CacheHarness := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosL1CacheHarness assertion failed: " .. message)
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

    encodeVector := method(numbers,
        rendered := numbers map(v, v asNumber asString)
        "[" .. rendered join(",") .. "]"
    )

    buildConfigure := method(vectorDim,
        "{\"operation\":\"vector_operations\",\"action\":\"configure\",\"config\":{\"max_size\":16,\"vector_dim\":" .. vectorDim asString .. ",\"eviction_threshold\":0.75,\"index_type\":\"Flat\",\"promotion_threshold\":3,\"promotion_requeue_step\":3,\"eviction_batch_percent\":0.15}}"
    )

    buildPut := method(oid, vector, label,
        vectorJson := encodeVector(vector)
        "{\"operation\":\"vector_operations\",\"action\":\"put\",\"config\":{\"oid\":\"" .. oid .. "\",\"vector\":" .. vectorJson .. ",\"metadata\":{\"label\":\"" .. label .. "\"}}}"
    )

    buildGet := method(oid,
        "{\"operation\":\"vector_operations\",\"action\":\"get\",\"config\":{\"oid\":\"" .. oid .. "\",\"include_vector\":true}}"
    )

    buildSearch := method(vector, k,
        vectorJson := encodeVector(vector)
        "{\"operation\":\"vector_operations\",\"action\":\"search\",\"config\":{\"query_vector\":" .. vectorJson .. ",\"k\":" .. k asString .. ",\"include_vectors\":false}}"
    )

    buildStats := method(
        "{\"operation\":\"vector_operations\",\"action\":\"stats\"}"
    )

    buildRemove := method(oid,
        "{\"operation\":\"vector_operations\",\"action\":\"remove\",\"config\":{\"oid\":\"" .. oid .. "\"}}"
    )

    buildList := method(
        "{\"operation\":\"vector_operations\",\"action\":\"list_oids\"}"
    )

    buildClear := method(
        "{\"operation\":\"vector_operations\",\"action\":\"clear\"}"
    )

    buildDrainPromotions := method(limit, includeVectors,
        "{\"operation\":\"vector_operations\",\"action\":\"drain_promotions\",\"config\":{\"limit\":" .. limit asString .. ",\"include_vectors\":" .. (if(includeVectors, "true", "false")) .. "}}"
    )

    buildPeekPromotions := method(
        "{\"operation\":\"vector_operations\",\"action\":\"peek_promotions\"}"
    )

    validateConfigure := method(response,
        assert(response type == "Map", "configure response must be a Map")
        assert(response at("success"), "configure should report success")
        config := response at("config")
        assert(config type == "Map", "configure response missing config")
        assert(config at("vector_dim") == 4, "vector_dim should be 4")
        assert(config at("promotion_threshold") == 3, "promotion_threshold should be 3")
        stats := response at("statistics")
        assert(stats type == "Map", "configure response missing statistics")
        true
    )

    validatePut := method(response,
        assert(response type == "Map", "put response must be a Map")
        assert(response at("success"), "put should report success")
        assert(response at("stored"), "put should set stored=true")
        true
    )

    validateGet := method(response, expectedVector,
        assert(response type == "Map", "get response must be a Map")
        assert(response at("success"), "get should report success")
        vector := response at("vector")
        assert(vector type == "List", "get response should include vector list")
        assert(vector size == expectedVector size, "vector length mismatch")
        tolerance := 0.0001
        index := 0
        while(index < vector size,
            diff := (vector at(index) asNumber - expectedVector at(index) asNumber) abs
            assert(diff <= tolerance, "vector component mismatch at index " .. index asString)
            index = index + 1
        )
        stats := response at("stats")
        assert(stats type == "Map", "entry stats missing in get response")
        true
    )

    validateSearch := method(response, expectedOid,
        assert(response type == "Map", "search response must be a Map")
        assert(response at("success"), "search should report success")
        results := response at("results")
        assert(results type == "List", "search results should be a List")
        assert(results size >= 1, "search should return at least one result")
        first := results first
        assert(first at("oid") == expectedOid, "search top result should match expected oid")
        score := first at("similarity_score")
        assert(score type == "Number", "search result missing similarity score")
        true
    )

    validateStats := method(response,
        assert(response type == "Map", "stats response must be a Map")
        assert(response at("success"), "stats should report success")
        statistics := response at("statistics")
        assert(statistics type == "Map", "stats payload missing")
        assert(statistics at("current_size") >= 2, "stats should reflect cached entries")
        true
    )

    validateRemove := method(response,
        assert(response type == "Map", "remove response must be a Map")
        assert(response at("success"), "remove should report success")
        assert(response at("removed"), "remove should mark entry as removed")
        true
    )

    validateList := method(response,
        assert(response type == "Map", "list response must be a Map")
        assert(response at("success"), "list should report success")
        oids := response at("oids")
        assert(oids type == "List", "list response missing oids list")
        assert(oids size == 1, "list should contain one remaining oid")
        true
    )

    validateClearedStats := method(response,
        assert(response type == "Map", "stats response must be a Map")
        assert(response at("success"), "stats should report success")
        statistics := response at("statistics")
        assert(statistics type == "Map", "stats payload missing")
        assert(statistics at("current_size") == 0, "cache should be empty after clear")
        true
    )

    validatePromotionDrain := method(response, expectedOid,
        assert(response type == "Map", "drain response must be a Map")
        assert(response at("success"), "drain should report success")
        assert(response at("count") >= 1, "drain should return at least one candidate")
        candidates := response at("candidates")
        assert(candidates type == "List", "drain candidates should be a List")
        first := candidates first
        assert(first at("oid") == expectedOid, "promotion drain should surface expected oid")
        true
    )

    validatePromotionPeek := method(response, expectedCount,
        assert(response type == "Map", "peek response must be a Map")
        assert(response at("success"), "peek should report success")
        assert(response at("count") == expectedCount, "peek count mismatch")
        true
    )

    run := method(
        bridge := ensureBridge
        Telos Bridge clearError

        vectorDim := 4
        baseVector := list(0.1, 0.2, 0.3, 0.4)
        neighborVector := list(0.11, 0.19, 0.31, 0.39)

        operation := try(
            assert(Telos start(1), "Telos start failed")

            configureResponse := bridge submitTask(buildConfigure(vectorDim), 4096)
            validateConfigure(configureResponse)

            putAlpha := bridge submitTask(buildPut("concept/alpha", baseVector, "Alpha"), 8192)
            validatePut(putAlpha)

            putBeta := bridge submitTask(buildPut("concept/beta", neighborVector, "Beta"), 8192)
            validatePut(putBeta)

            getAlpha := bridge submitTask(buildGet("concept/alpha"), 8192)
            validateGet(getAlpha, baseVector)

            searchResponse := bridge submitTask(buildSearch(baseVector, 2), 8192)
            validateSearch(searchResponse, "concept/alpha")

            statsResponse := bridge submitTask(buildStats, 4096)
            validateStats(statsResponse)

            // Access beta multiple times to trigger promotion tracking
            repeat := 0
            lastBeta := nil
            while(repeat < 3,
                lastBeta = bridge submitTask(buildGet("concept/beta"), 8192)
                validateGet(lastBeta, neighborVector)
                repeat = repeat + 1
            )

            drainResponse := bridge submitTask(buildDrainPromotions(5, false), 8192)
            validatePromotionDrain(drainResponse, "concept/beta")

            peekResponse := bridge submitTask(buildPeekPromotions, 4096)
            validatePromotionPeek(peekResponse, 0)

            removeAlpha := bridge submitTask(buildRemove("concept/alpha"), 4096)
            validateRemove(removeAlpha)

            listResponse := bridge submitTask(buildList, 4096)
            validateList(listResponse)

            clearResponse := bridge submitTask(buildClear, 4096)
            assert(clearResponse at("success"), "clear should report success")

            clearedStats := bridge submitTask(buildStats, 4096)
            validateClearedStats(clearedStats)

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

result := try(TelosL1CacheHarness run)
if(result type == "Exception",
    System log("TelosL1CacheHarness failure: " .. result message)
    result pass
)

System log("TelosL1CacheHarness success")
