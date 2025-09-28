AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
paths := AddonLoader searchPaths
("Paths after append: " .. paths) println
("Length: " .. paths size) println
paths foreach(i, v, ("[" .. i .. "]: " .. v) println)