writeln("Testing TelosMorphic.io syntax...")
try(
    doFile("libs/Telos/io/TelosMorphic.io")
    writeln("File loaded successfully!")
) ifError(e,
    writeln("SYNTAX ERROR: " .. e description)
    writeln("Error type: " .. e type)
    if(e hasSlot("error"), writeln("Error detail: " .. e error))
)