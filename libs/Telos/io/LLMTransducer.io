//
// LLM Transducer Actor
//
// This actor implements the LLM transduction pipeline as specified in Addendum 1.3.
// It provides natural language processing capabilities through the Synaptic Bridge
// to Python workers running Ollama backends.
//

LLMTransducer := Object clone do(
    // Actor identity and state
    oid := uniqueId
    createdAt := Date now
    lastActivity := Date now

    // Bridge reference for task submission
    bridge := nil

    // Initialize the transducer with bridge reference
    init := method(
        self oid := uniqueId
        self createdAt := Date now
        self lastActivity := Date now
        self bridge := Telos Bridge
        self
    )

    // Ensure bridge is available and initialized
    ensureBridge := method(
        if(bridge isNil,
            Exception raise("LLMTransducer requires Telos Bridge to be initialized")
        )
        bridge ensureInitialized("LLMTransducer")
        self
    )

    // Submit a transduction task through the bridge
    submitTransductionTask := method(taskType, inputData, bufferSize,
        ensureBridge

        // Build the JSON task payload
        taskPayload := Map clone do(
            operation := "llm_transduction"
            type := taskType
            data := inputData
            timestamp := Date now asNumber
        )

        // Convert to JSON string
        jsonPayload := taskPayload asJson
        response := bridge submitTask(jsonPayload, bufferSize)

        if(response at("success") == true,
            response,
            errorMsg := response at("error")
            Exception raise("LLM task submission failed: " .. if(errorMsg isNil, "unknown error", errorMsg))
        )
    )

    // Generic transduce method that routes based on request method
    transduce := method(request,
        if(request isNil or request at("method") isNil,
            Exception raise("transduce requires a request with method field")
        )

        method := request at("method")
        if(method == "text_to_schema",
            transduceTextToSchema(request at("text"), request at("schema"), request at("options")),
            if(method == "schema_to_text",
                transduceSchemaToText(request at("schema"), request at("template"), request at("options")),
                if(method == "text_to_tool_call",
                    transduceTextToToolCall(request at("text"), request at("tools"), request at("options")),
                    if(method == "generate",
                        // Simple generation - route to text_to_schema with empty schema
                        transduceTextToSchema(request at("prompt", ""), Map clone, request),
                        Exception raise("Unknown transduction method: " .. method)
                    )
                )
            )
        )
    )

    // Transduce text to structured schema
    transduceTextToSchema := method(text, schemaSpec, options,
        if(text isNil or text size == 0,
            Exception raise("transduceTextToSchema requires non-empty text input")
        )

        inputData := Map clone do(
            text := text
            schema := schemaSpec
            options := if(options isNil, Map clone, options)
        )

        response := submitTransductionTask("text_to_schema", inputData, 16384)

        if(response at("success") == true,
            response at("result"),
            errorMsg := response at("error")
            Exception raise("LLM transduction failed: " .. if(errorMsg isNil, "unknown error", errorMsg))
        )
    )

    // Transduce structured schema to natural text
    transduceSchemaToText := method(schemaData, templateSpec, options,
        if(schemaData isNil,
            Exception raise("transduceSchemaToText requires schema data")
        )

        inputData := Map clone do(
            schema := schemaData
            template := templateSpec
            options := if(options isNil, Map clone, options)
        )

        response := submitTransductionTask("schema_to_text", inputData, 16384)

        if(response at("success") == true,
            response at("result"),
            errorMsg := response at("error")
            Exception raise("LLM transduction failed: " .. if(errorMsg isNil, "unknown error", errorMsg))
        )
    )

    // Transduce text to tool call specification
    transduceTextToToolCall := method(text, toolSpec, options,
        if(text isNil or text size == 0,
            Exception raise("transduceTextToToolCall requires non-empty text input")
        )

        inputData := Map clone do(
            text := text
            tools := toolSpec
            options := if(options isNil, Map clone, options)
        )

        response := submitTransductionTask("text_to_tool_call", inputData, 16384)

        if(response at("success") == true,
            response at("result"),
            errorMsg := response at("error")
            Exception raise("LLM transduction failed: " .. if(errorMsg isNil, "unknown error", errorMsg))
        )
    )

    // Get transducer status and capabilities
    getStatus := method(
        ensureBridge

        statusPayload := Map clone do(
            operation := "llm_transduction"
            type := "status"
            timestamp := Date now asNumber
        )

        jsonPayload := statusPayload asJson
        response := bridge submitTask(jsonPayload, 4096)

        Map clone do(
            oid := oid
            createdAt := createdAt
            lastActivity := lastActivity
            bridgeStatus := response
        )
    )

    // Persistence covenant - mark object as changed
    markChanged := method(
        // This would integrate with ZODB persistence layer
        // For now, just update the timestamp
        lastActivity = Date now
        self
    )
)

// Export to global namespace
if(Lobby hasSlot("Telos") not, Lobby Telos := Object clone)
Telos LLMTransducer := LLMTransducer