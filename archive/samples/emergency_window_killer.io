/*
   Emergency SDL2 Window Killer - Force close any stuck TelOS windows
*/

// Load TelOS Core
doFile("libs/Telos/io/TelosCore.io")

"=== EMERGENCY SDL2 WINDOW KILLER ===" println
"Attempting to force close any stuck SDL2 windows..." println

// Try to close window through Telos
if(Telos hasSlot("closeWindow"),
    "Calling Telos closeWindow..." println
    Telos closeWindow
,
    "No closeWindow method available" println
)

// Try direct C-level close if available
if(Telos hasSlot("Telos_rawCloseWindow"),
    "Calling raw close window..." println  
    Telos Telos_rawCloseWindow
)

// Force SDL quit
"Forcing SDL quit..." println
System exit(0)