// Canvas prototype smoke: open a window, run a short heartbeat, close
Telos := Protos Telos clone
Canvas := Lobby getSlot("Canvas") ifNil(Exception raise("Canvas not found"))
cv := Canvas clone init
cv open
cv heartbeat(1)
cv close
"Canvas proto smoke done" println
