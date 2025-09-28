AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
paths1 := AddonLoader searchPaths
("After append: " .. paths1) println
paths2 := AddonLoader searchPaths
("Second call: " .. paths2) println
("Same object: " .. (paths1 == paths2)) println