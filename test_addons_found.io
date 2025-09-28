AddonLoader appendSearchPath("build/addons")
if(AddonLoader hasSlot("_searchPaths") not,
    AddonLoader _searchPaths := AddonLoader searchPaths
)
AddonLoader _searchPaths append("build/addons")
addons := AddonLoader addons
("Found addons: " .. addons map(name)) println