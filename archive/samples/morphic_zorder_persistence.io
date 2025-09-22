// Z-order persistence demo: bring-to-front writes zIndex; auto-replay restores order
Telos init
// Use message passing instead of setSlot
Telos doString("autoReplay := false")
w := Telos createWorld

r1 := Lobby getSlot("RectangleMorph") clone do(doString("id := \"z1\""); x=20; y=20; width=80; height=40)
r2 := Lobby getSlot("RectangleMorph") clone do(doString("id := \"z2\""); x=40; y=30; width=80; height=40)
w addMorph(r1); w addMorph(r2)

Telos walBegin("frame")
r2 setZIndex(10)
Telos walEnd("frame")

Telos draw
"-- Z-Order Snapshot --" println
Telos captureScreenshot println

"Z-order persistence demo done" println
