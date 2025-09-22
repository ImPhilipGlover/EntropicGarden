doFile("libs/Telos/io/TelosCore.io")

writeln("Telos slotNames (subset):")
slots := Telos slotNames sort
slots foreach(name,
    if(name == "walAppend" or name == "createWorld" or name == "pyEval",
        writeln(" - ", name)
    )
)

writeln("Has slots:")
writeln("walAppend: " .. Telos hasSlot("walAppend"))
writeln("createWorld: " .. Telos hasSlot("createWorld"))
writeln("pyEval: " .. Telos hasSlot("pyEval"))

writeln("Test complete: slot inspection finished")
