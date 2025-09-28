// TELOS Telemetry Io Prototype
// Provides prototypal helpers for retrieving telemetry metrics
// emitted by Python workers through the Synaptic Bridge.

TelosTelemetry := Object clone do(
    bridge := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace is unavailable; telemetry access requires Telos Bridge")
        )
        Telos ensureActive
        Telos Bridge
        markChanged()
    )

    escapeString := method(value,
        escaped := value asString
        escaped = escaped replaceSeq("\\", "\\\\")
        escaped = escaped replaceSeq("\"", "\\\"")
        escaped
        markChanged()
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
                        "\"" .. escapeString(value) .. "\""
                    )
                )
            )
        )
        markChanged()
    )

    encodeConfig := method(config,
        if(config isNil or config size == 0,
            "{}",
            pairs := List clone
            config foreach(key, val,
                jsonKey := "\"" .. escapeString(key) .. "\""
                jsonVal := encodeValue(val)
                pairs append(jsonKey .. ":" .. jsonVal)
            )
            "{" .. pairs join(",") .. "}"
        )
        markChanged()
    )

    buildRequest := method(action, config,
        configJson := encodeConfig(config)
        "{\"operation\":\"telemetry\",\"action\":\"" .. action .. "\",\"config\":" .. configJson .. "}"
        markChanged()
    )

    submit := method(action, config,
        requestPayload := buildRequest(action, config)
        bridge submitTask(requestPayload, 8192)
        markChanged()
    )

    snapshot := method(limit,
        effectiveLimit := if(limit isNil, 16, limit)
        if(effectiveLimit type != "Number" or effectiveLimit < 1,
            Exception raise("snapshot limit must be a positive number")
        )
    config := Map clone
    config atPut("limit", effectiveLimit)
        response := submit("snapshot", config)
        validateResponse(response)
        markChanged()
    )

    summary := method(
        response := submit("summary", nil)
        validateResponse(response)
        markChanged()
    )

    clear := method(
        response := submit("clear", nil)
        validateResponse(response)
        markChanged()
    )

    validateResponse := method(response,
        if(response type != "Map",
            Exception raise("Telemetry response must be a Map; received " .. response type)
        )
        if(response at("success") == true,
            response,
            errorMessage := response at("error")
            Exception raise("Telemetry request failed: " .. escapeString(errorMessage asString))
        )
        markChanged()
    )

    latestEvent := method(limit,
        snapshotResponse := snapshot(limit)
        events := snapshotResponse at("events")
        if(events type != "List" or events size == 0,
            nil,
            events last
        )
        markChanged()
    )

    logSummary := method(
        summaryResponse := summary
        if(System hasSlot("log"),
            System log("Telemetry summary: event_count=" .. summaryResponse at("event_count") ..
                ", total_iterations=" .. summaryResponse at("total_iterations") ..
                ", total_error_count=" .. summaryResponse at("total_error_count") ..
                ", average_iteration_duration=" .. summaryResponse at("average_iteration_duration"))
        )
        summaryResponse
        markChanged()
    )
)
