AddonLoader searchPaths append("build/addons")
a := Addon clone setRootPath("build/addons") setName("TelosBridge")
writeln("Addon path: " .. a addonPath)
writeln("DLL path: " .. a dllPath)
writeln("Loading addon...")
result := a load
writeln("Load result: " .. result)
writeln("Protos exist: TelosBridge=" .. (Lobby hasSlot("TelosBridge") asString) .. ", SharedMemoryHandle=" .. (Lobby hasSlot("SharedMemoryHandle") asString))