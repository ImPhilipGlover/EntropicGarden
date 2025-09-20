writeln("--- TelOS Personas Chat (Germination) ---")

// Load personas
brick := Telos personaCodex choose("BRICK")
robin := Telos personaCodex choose("ROBIN")
babs := Telos personaCodex choose("BABS")
alfred := Telos personaCodex choose("ALFRED")

// Prime kernels (offline)
brick loadPersonaContext; robin loadPersonaContext; babs loadPersonaContext; alfred loadPersonaContext

// Simple conversation loop (type 'exit' to quit)
history := List clone
current := brick
writeln("Type persona: BRICK/ROBIN/BABS/ALFRED to switch. Type 'exit' to quit.")

loop(
    write("You> ")
    line := File standardInput readLine
    if(line == nil, break)
    if(line asLowercase == "exit", break)

    // Switch persona if command matches
    if(line == "BRICK" or line == "ROBIN" or line == "BABS" or line == "ALFRED",
        current = Telos personaCodex choose(line)
        writeln("Switched to ", current name)
        continue
    )

    // Converse with current persona
    reply := current converse(line, history)
    writeln(current name, "> ", reply)
    history append(map(user: line, persona: current name, reply: reply))

    // ALFRED meta-commentary for non-ALFRED personas
    if(current name != "ALFRED",
        meta := alfred commentOn(current, reply)
        writeln("ALFRED> ", meta)
    )
)

writeln("--- Chat ended ---")
