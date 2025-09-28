("AddonLoader has appendSearchPath: " .. (AddonLoader hasSlot("appendSearchPath"))) println
if(AddonLoader hasSlot("appendSearchPath"),
    method := AddonLoader getSlot("appendSearchPath")
    ("Method type: " .. method type) println
    ("Method: " .. method) println
)