// TELOS Synaptic Bridge Io Veneer
// Provides high-level Io interface to the TelosBridge addon

Telos := Object clone do(
    Bridge := TelosBridge clone
)

Telos Bridge do(
    initialize := method(configMap,
        config := configMap
        if(config isNil, config = Map clone)
        self proto initialize(config)
    ),

    status := method(
        statusCode := self proto status()
        statusMap := Map clone
        if(statusCode == 0,
            statusMap atPut("initialized", true)
            statusMap atPut("maxWorkers", 4)
            statusMap atPut("activeWorkers", 0)
        ,
            if(statusCode == 1,
                statusMap atPut("initialized", false)
                statusMap atPut("maxWorkers", 4)
                statusMap atPut("activeWorkers", 0)
            ,
                statusMap atPut("initialized", false)
                statusMap atPut("error", "status check failed")
                statusMap atPut("statusCode", statusCode)
            )
        )
        statusMap
    ),

    submitTask := method(taskMap,
        self ensureInitialized("submitTask")
        if(taskMap isNil or taskMap type != "Map",
            Exception raise("submitTask requires an Io Map object")
        )
        jsonRequest := taskMap asJson
        jsonResponse := self proto submitTask(jsonRequest, 8192)
        if(jsonResponse isNil or jsonResponse size == 0,
            Exception raise("Bridge submitTask returned an empty response.")
        )
        parsedResponse := try(Lobby doString("return " .. jsonResponse))
        if (parsedResponse isError,
            writeln("WARNING: Could not parse JSON response: ", jsonResponse)
            return jsonResponse
        )
        parsedResponse
    ),

    ensureInitialized := method(operationName,
        status := self status
        if(status isNil or status at("initialized") != true,
            Exception raise("TelosBridge " .. operationName .. " requires initialize() to be called first")
        )
        self
    )
)

Lobby Telos := Telos

if(System hasSlot("writeln"),
    System writeln("TELOS Bridge Addon Integration Loaded")
)
