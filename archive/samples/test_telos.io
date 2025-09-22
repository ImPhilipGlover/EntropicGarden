#!/usr/bin/env io

// Test TelOS morphic UI launch
Telos := Lobby getSlot("Telos")
if(Telos == nil,
    Telos := IoTelos clone
    "TelOS addon loaded successfully" println
)

"Launching morphic UI..." println
Telos mainLoop