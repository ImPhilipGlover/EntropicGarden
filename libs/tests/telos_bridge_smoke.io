// TELOS Io-driven Synaptic Bridge smoke validation
// Ensures the Synaptic Bridge can be initialized, allocate shared memory,
// and shut down when orchestrated entirely from Io.

TelosBridgeSmoke := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosBridgeSmoke assertion failed: " .. message)
        )
    )

    ensureBridgeLoaded := method(
        addonPath := System getEnvironmentVariable("TELOS_ADDON_PATH")
        if(addonPath and addonPath size > 0,
            AddonLoader appendSearchPath(addonPath)
        )

        doRelativeFile("../Telos/io/TelosBridge.io")
        if(Lobby hasSlot("Telos") not,
            Exception raise("Telos namespace unavailable after loading TelosBridge.io")
        )
        Telos Bridge
    )

    validateHandle := method(handle, expectedSize,
        assert(handle hasProto(Telos SharedMemoryHandle), "SharedMemoryHandle prototype missing")
        assert(handle size == expectedSize, "Shared memory size mismatch")
        nameSeq := handle name
        assert(nameSeq size > 0, "Shared memory name is empty")
        handle
    )

    clearBridgeState := method(
        Telos Bridge clearError
    )

    run := method(
        bridge := ensureBridgeLoaded
        clearBridgeState

        startupResult := Telos start(1)
        assert(startupResult, "Telos start did not succeed")

        status := bridge status
        assert(status at("initialized"), "Bridge status did not report initialized")

        sharedHandle := nil

        operation := try(
            segmentSize := 256
            sharedHandle = bridge createSharedMemory(segmentSize)
            validateHandle(sharedHandle, segmentSize)

            destroyResult := bridge destroySharedMemory(sharedHandle)
            assert(destroyResult, "destroySharedMemory returned false")

            bridge clearError
            "ok"
        )

        Telos stop
        clearBridgeState

        if(operation type == "Exception",
            operation pass,
            operation
        )
    )
)

result := try(TelosBridgeSmoke run)
if(result type == "Exception",
    System log("TelosBridgeSmoke failure: " .. result message)
    result pass
)

System log("TelosBridgeSmoke success")
