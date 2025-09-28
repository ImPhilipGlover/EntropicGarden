// TELOS ZODB Manager Io Prototype
// Provides prototypal helpers for interacting with the Python ZODB persistence
// layer through the Synaptic Bridge, including initialization, CRUD helpers,
// transaction control, and persistence covenant support.

TelosZODBManager := Object clone do(
    bridge := method(
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace is unavailable; persistence access requires Telos Bridge")
        )
        Telos ensureActive
        Telos Bridge
        markChanged
    )

    escapeString := method(value,
        rendered := value asString
        rendered = rendered replaceSeq("\\", "\\\\")
        rendered = rendered replaceSeq("\"", "\\\"")
        rendered
        markChanged
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
        markChanged
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
        markChanged
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
        markChanged
    )

    buildRequest := method(action, config,
        configJson := if(config isNil, "{}", encodeValue(config))
        "{\"operation\":\"zodb_manager\",\"action\":\"" .. escapeString(action) .. "\",\"config\":" .. configJson .. "}"
        markChanged
    )

    submit := method(action, config, bufferSize,
        payload := buildRequest(action, config)
        requested := if(bufferSize isNil, 16384, bufferSize)
        bridge submitTask(payload, requested)
        markChanged
    )

    ensureSuccess := method(response,
        if(response type != "Map",
            Exception raise("ZODB manager response must be a Map; received " .. response type)
        )
        if(response at("success"),
            response,
            errorMessage := response at("error")
            message := if(errorMessage isNil, "unknown error", errorMessage asString)
            Exception raise("ZODB manager request failed: " .. message)
        )
        markChanged
    )

    buildManagerConfig := method(options,
        if(options isNil,
            nil,
            options clone
        )
        markChanged
    )

    initialize := method(options,
        config := Map clone
        config atPut("manager", buildManagerConfig(options))
        ensureSuccess(submit("initialize", config, 4096))
        markChanged
    )

    shutdown := method(
        ensureSuccess(submit("shutdown", Map clone, 2048))
        markChanged
    )

    storeConcept := method(concept, options,
        if(concept type != "Map",
            Exception raise("storeConcept expects a Map payload")
        )
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        config atPut("concept", concept)
        ensureSuccess(submit("store_concept", config, 18432))
        markChanged
    )

    loadConcept := method(oid, options,
        if(oid isNil,
            Exception raise("loadConcept requires an oid")
        )
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        config atPut("oid", oid asString)
        ensureSuccess(submit("load_concept", config, 12288))
        markChanged
    )

    updateConcept := method(oid, updates, options,
        if(oid isNil,
            Exception raise("updateConcept requires an oid")
        )
        if(updates type != "Map",
            Exception raise("updateConcept expects updates Map")
        )
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        config atPut("oid", oid asString)
        config atPut("updates", updates)
        ensureSuccess(submit("update_concept", config, 12288))
        markChanged
    )

    deleteConcept := method(oid, options,
        if(oid isNil,
            Exception raise("deleteConcept requires an oid")
        )
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        config atPut("oid", oid asString)
        ensureSuccess(submit("delete_concept", config, 8192))
        markChanged
    )

    listConcepts := method(limit, offset, options,
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        if(limit isNil not,
            config atPut("limit", limit)
        )
        if(offset isNil not,
            config atPut("offset", offset)
        )
        ensureSuccess(submit("list_concepts", config, 12288))
        markChanged
    )

    statistics := method(options,
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        ensureSuccess(submit("get_statistics", config, 8192))
        markChanged
    )

    markObjectChanged := method(oid, options,
        if(oid isNil,
            Exception raise("markObjectChanged requires an oid")
        )
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        config atPut("oid", oid asString)
        ensureSuccess(submit("mark_changed", config, 4096))
        markChanged
    )

    commit := method(options,
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        ensureSuccess(submit("commit_transaction", config, 4096))
        markChanged
    )

    abort := method(options,
        config := Map clone
        if(options isNil not,
            config atPut("manager", buildManagerConfig(options))
        )
        ensureSuccess(submit("abort_transaction", config, 4096))
        markChanged
    )
)
