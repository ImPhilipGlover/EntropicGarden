writeln("Testing TelosMorphic load method...")
doFile("libs/Telos/io/TelosMorphic.io")

writeln("Calling TelosMorphic load method...")
result := TelosMorphic load
writeln("Load method returned: " .. result type)

if(result == TelosMorphic,
    writeln("✓ Load method returned self correctly")
,
    writeln("✗ Load method returned unexpected value")
)

writeln("Checking if Telos has createMorphWithLogging...")
if(Telos hasSlot("createMorphWithLogging"),
    writeln("✓ createMorphWithLogging method available on Telos")
,
    writeln("✗ createMorphWithLogging method not found on Telos")
)