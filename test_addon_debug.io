AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
addon := AddonLoader addonFor("TelosBridge")
("addon: " .. addon) println
if(addon,
    ("addonPath: " .. addon addonPath) println
    ("dllPath: " .. addon dllPath) println
    ("exists: " .. (File with(addon dllPath) exists)) println
)