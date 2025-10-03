writeln("Testing addon loading with LD_LIBRARY_PATH...")
writeln("LD_LIBRARY_PATH: ", System getEnvironmentVariable("LD_LIBRARY_PATH"))
result := AddonLoader loadAddonNamed("TelosBridge")
if(result,
    writeln("Addon loaded successfully, type: ", result type)
    writeln("Addon slots: ", result slotNames)
,
    writeln("Addon loading failed")
)
