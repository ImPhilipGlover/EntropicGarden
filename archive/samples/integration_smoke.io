writeln("TelOS Integration Smoke: starting")

// Ensure core is loaded (it auto-inits the system and loads modules)
doFile("libs/Telos/io/TelosCore.io")

writeln("TelOS Integration Smoke: system initialized")

// Check method availability on Telos prototype
hasWalAppend := Telos hasSlot("walAppend")
hasPyEval := Telos hasSlot("pyEval")
hasCreateWorld := Telos hasSlot("createWorld")

writeln("Method availability check:")
writeln(" - walAppend: " .. hasWalAppend)
writeln(" - pyEval: " .. hasPyEval)
writeln(" - createWorld: " .. hasCreateWorld)

// Report completion only (no misleading success claims)
writeln("Test complete: Integration smoke finished")
