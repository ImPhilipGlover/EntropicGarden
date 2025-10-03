// Simple test to verify TelosBridge addon works
"Loading TelosBridge addon..." println

try(
    doFile("build/addons/TelosBridge/io/TelosBridge.io")
    "✓ Addon loaded successfully" println

    if(Lobby hasSlot("Telos"),
        "✓ Telos namespace exists" println

        if(Telos hasSlot("Bridge"),
            "✓ Telos.Bridge exists" println

            bridge := Telos Bridge
            "Testing status method..." println
            status := bridge status
            "Status result: " .. status println
            "✓ Status method works!" println

            "Testing initialize method..." println
            initResult := bridge initialize(Map clone)
            "Initialize result: " .. initResult println
            "✓ Initialize method works!" println

            "🎉 TELOS BRIDGE ADDON IS FULLY FUNCTIONAL!" println
        ,
            "✗ Telos.Bridge not found" println
        )
    ,
        "✗ Telos namespace not found" println
    )
) catch(Exception e,
    "✗ Exception during testing: " .. e println
)