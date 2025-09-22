writeln("--- TelOS Conversation Demo ---")

Telos openWindow
Telos createWorld

brick := Telos personaCodex choose("BRICK")
robin := Telos personaCodex choose("ROBIN")
alfred := Telos personaCodex choose("ALFRED")

// Load persona kernels (offline codex)
brick loadPersonaContext
robin loadPersonaContext
alfred loadPersonaContext

// User asks a question
userMsg := "How should we implement WAL commit markers and show them in a small UI?"

// BRICK answers with architecture focus
brickReply := brick converse(userMsg)
writeln("BRICK: ", brickReply)

// ROBIN adds UI angle
robinReply := robin converse("Design a small control to visualize commits")
writeln("ROBIN: ", robinReply)

// ALFRED comments on both
comment1 := alfred commentOn(brick, brickReply)
comment2 := alfred commentOn(robin, robinReply)
writeln("ALFRED on BRICK: ", comment1)
writeln("ALFRED on ROBIN: ", comment2)

// Persist last exchange
brick commit(Telos, "lastConversationTopic", userMsg)

// Draw a simple text morph indicating conversation occurred
m := TextMorph clone
m setText("Chat: BRICK & ROBIN (+ALFRED)")
Telos addSubmorph(Telos world, m)
Telos draw

writeln("--- Conversation Demo complete ---")
