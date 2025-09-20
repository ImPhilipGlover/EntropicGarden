// Morphic Canvas smoke test: textual heartbeat + morph tree snapshot
Telos init
world := Telos createWorld

// Create a rectangle and a text morph
rect := Lobby getSlot("RectangleMorph") clone do(
    x = 20; y = 30; width = 80; height = 40
)
text := Lobby getSlot("TextMorph") clone do(
    x := 15; y := 15; fontSize := 14
)
text setText("Morphic Canvas")

// Build morph tree: rect contains text; world contains rect
rect addMorph(text)
world addMorph(rect)

// Draw once and print screenshot
Telos draw
writeln("\n--- Morph Tree Snapshot ---")
writeln(Telos captureScreenshot)

// Persist a WAL entry on morph change
Telos transactional_setSlot(text, "text", "Morphic Canvas: alive")

// Enter a short C-level main loop; it prints a heartbeat a few times
Telos mainLoop
