// Minimal window smoke for WSLg: open, clear, present a few frames, then close
Telos := Protos Telos clone

// Open a window via SDL2 bridge if available (falls back to stub)
Telos openWindow

// Run a short morphic main loop (prints heartbeats; SDL2 will be displayed meanwhile)
Telos mainLoop

Telos closeWindow
"Window smoke done" print
