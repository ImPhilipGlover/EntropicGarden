// Simple SDL2 window test
"Creating world..." println
Telos createWorld

"Opening window..." println  
Telos openWindow

"Drawing world..." println
Telos drawWorld

"Window should be visible. Press any key..." println
System system("read -t 5 -n 1") // 5 second pause

"Closing window..." println
Telos closeWindow

"Done" println
