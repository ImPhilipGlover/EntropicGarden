AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
paths := AddonLoader searchPaths
("Search paths after append: " .. paths) println
("Has _searchPaths slot: " .. (AddonLoader hasSlot("_searchPaths"))) println
if(AddonLoader hasSlot("_searchPaths"), ("_searchPaths: " .. AddonLoader _searchPaths) println)