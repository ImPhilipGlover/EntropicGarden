//
// TELOS Synaptic Bridge Io Veneer
//
// This veneer provides a high-level Io interface to the TelosBridge addon.
// The addon handles the C FFI, ensuring type safety and proper communication
// with the underlying C substrate.
//

// The TelosBridge object is provided by the C addon, which is loaded automatically
// by the Io VM when placed in the addons directory.
// We can clone and extend it with higher-level logic.
Telos := Object clone do(
    Bridge := TelosBridge clone
)

// --- High-Level API ---

Telos Bridge do(
    // Override initialize to provide a default config if none is given.
    // The addon's `initialize` expects a number of workers.
    initialize := method(configMap,
        workers := 4 // Default
        if(configMap and configMap hasSlot("max_workers"),
            workers = configMap at("max_workers")
        )
        
        // Call the addon's initialize method, which is now a C function
        // bound to the 'initialize' slot on the prototype.
        self proto initialize(workers)
    ),

    // The addon provides submitTask, but it expects a raw JSON string.
    // This wrapper converts an Io Map to JSON before calling the addon's method.
    submitTask := method(taskMap,
        self ensureInitialized("submitTask")
        if(taskMap isNil or taskMap type != "Map",
            Exception raise("submitTask requires an Io Map object")
        )

        jsonRequest := taskMap asJson
        
        // The addon's submitTask returns a JSON string response.
        // The addon's C code handles the buffer allocation and C string conversion.
        jsonResponse := self proto submitTask(jsonRequest, 8192) // 8k buffer

        if(jsonResponse isNil or jsonResponse size == 0,
            Exception raise("Bridge submitTask returned an empty response.")
        )

        // Attempt to parse the JSON response back into an Io object.
        parsedResponse := try(Lobby doString("return " .. jsonResponse))
        if (parsedResponse isError,
            writeln("WARNING: Could not parse JSON response: ", jsonResponse)
            return jsonResponse // Return raw string if parsing fails
        )
        
        parsedResponse
    ),

    ensureInitialized := method(operationName,
        // The addon's status method returns a map.
        status := self status
        if(status isNil or status at("initialized") != true,
            Exception raise("TelosBridge " .. operationName .. " requires initialize() to be called first")
        )
        self
    )
)

// --- Global Namespace ---

// Expose the extended bridge to the global Lobby.
Lobby Telos := Telos

if(System hasSlot("writeln"),
    System writeln("TELOS Bridge Addon Integration Loaded")
)