("Starting test") println
AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
("After appendSearchPath") println
paths := AddonLoader searchPaths
("Paths after append: " .. paths) println
("Length: " .. paths size) println
paths foreach(i, v, ("[" .. i .. "]: " .. v) println)