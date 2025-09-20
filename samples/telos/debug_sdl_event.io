// Test if dispatchSDLEvent method exists
Telos do(
    init
)

writeln("Testing if dispatchSDLEvent method exists...")

if(Telos hasSlot("dispatchSDLEvent"),
    writeln("dispatchSDLEvent method exists - testing it...")
    Telos dispatchSDLEvent("test", 100, 200)
    writeln("dispatchSDLEvent call successful")
,
    writeln("ERROR: dispatchSDLEvent method does not exist")
)

writeln("Test complete")