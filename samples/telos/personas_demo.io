writeln("--- TelOS Personas Demo ---")

// Ensure Telos loaded and world created
Telos openWindow
Telos createWorld

// Choose BRICK and ALFRED
brick := Telos personaCodex choose("BRICK")
alfred := Telos personaCodex choose("ALFRED")
writeln("Persona: ", brick name, " (", brick role, ")")

// BRICK thinks about a small design prompt
resp := brick think("Sketch a persistence test plan for WAL commit markers")
writeln("BRICK Think: ", resp)

// ALFRED meta-commentary on BRICK's output
comment := alfred commentOn(brick, resp)
writeln("ALFRED Comment: ", comment)

// ALFRED performs a contract check on the plan
check := alfred checkContracts(resp)
writeln("Contract Check: ", check)

// Recall related memory (offline stub returns empty list)
hits := p recall("commit markers recovery")
writeln("Recall hits: ", hits)

// Evaluate a dummy solution with BRICK's weights
score := brick evaluate(map())
writeln("BRICK Score: ", score)

// Commit a small state change via transactional_setSlot
brick commit(Telos, "lastPlan", "WAL markers: write BEGIN/END; replay on startup")

// Draw a small text morph mentioning the persona
m := TextMorph clone
m setText("Hello from " .. brick name)
Telos addSubmorph(Telos world, m)
Telos draw

writeln("--- Demo complete ---")
