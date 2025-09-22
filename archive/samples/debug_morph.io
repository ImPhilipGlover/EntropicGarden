// Debug morph creation step by step

Telos createWorld
writeln("Step 1: World created")

// Test basic morph creation without type
m1 := Telos createMorph(nil)
writeln("Step 2: Created morph with nil type")
writeln("Step 2a: morph hasSlot id: ", m1 hasSlot("id"))
if(m1 hasSlot("id"), writeln("Step 2b: morph id: ", m1 id), writeln("Step 2b: morph has no id slot"))

// Test Object clone directly
obj := Object clone
obj id := "test123"
writeln("Step 3: Basic object with id: ", obj id)

// Test the typeResolver logic independently
typeResolver := Object clone
typeResolver typeName := "Morph"
typeResolver proto := Lobby getSlot(typeResolver typeName) ifNil(Morph)
writeln("Step 4: Type resolved to: ", typeResolver proto type)

// Test proto clone directly  
proto := typeResolver proto
directMorph := proto clone
identityProvider := Object clone
identityProvider newId := System uniqueId
directMorph setSlot("id", identityProvider newId)
writeln("Step 5: Direct morph has id: ", directMorph hasSlot("id"))
if(directMorph hasSlot("id"), writeln("Step 5a: Direct morph id: ", directMorph id))

writeln("Debugging complete")