AddonLoader appendSearchPath("/mnt/c/EntropicGarden/build/addons")
result := AddonLoader loadAddonNamed("TelosBridge")
("Addon loaded: " .. result) println
("TelosBridge in Lobby: " .. (Lobby hasSlot("TelosBridge"))) println
if(Lobby hasSlot("TelosBridge"), Lobby TelosBridge println, "TelosBridge not found" println)
