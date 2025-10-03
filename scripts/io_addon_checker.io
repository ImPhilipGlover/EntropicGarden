#!/usr/bin/env io

// Io Addon Checker - Critical tool for bridge success
// Verifies Io addon loading and bridge initialization

AddonChecker := Object clone do(

    checkAddonLoading := method(
        "🔍 Checking Io addon loading..." println
        TelosBridge := doFile("libs/Telos/io/TelosBridge.io")
        if(TelosBridge == nil,
            "❌ FAILED: TelosBridge.io failed to load" println
            return false
        )
        "✅ SUCCESS: TelosBridge.io loaded successfully" println
        return true
    )

    checkBridgeInitialization := method(
        "🔍 Checking bridge initialization..." println
        bridge := TelosBridge clone
        if(bridge == nil,
            return false
        )
        result := bridge initialize(Map clone atPut("max_workers", 2) atPut("initialized", 1))
        if(result == nil,
            return false
        )
        "✅ SUCCESS: Bridge initialized successfully" println
        return true
    )

    runFullCheck := method(
        "🚀 Io Addon Checker - Starting full verification..." println
        addonOk := checkAddonLoading
        if(addonOk,
            bridgeOk := checkBridgeInitialization
            if(bridgeOk,
                "🎉 ALL CHECKS PASSED - Bridge ready for Io-C-Python communication!" println
                return true
            )
        )
        return false
    )
)

if(isLaunchScript,
    checker := AddonChecker clone
    checker runFullCheck
)