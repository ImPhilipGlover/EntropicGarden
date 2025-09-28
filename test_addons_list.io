AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
addons := AddonLoader addons
("Found addons: " .. addons map(name)) println
("Search paths: " .. AddonLoader searchPaths) println