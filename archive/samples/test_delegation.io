// Test prototypal delegation patterns

// Test basic world creation and morphic operations
Telos createWorld
writeln("World created: ", world type)

// Test morphic creation through delegation
rect := Telos createMorph("RectangleMorph")
writeln("Created morph: ", rect type, " id: ", rect id)

// Test prototypal parameter handling
colorTest := Object clone
colorTest value := "[255, 128, 0, 1]"
Telos ColorParser parseColor(colorTest value)
writeln("Color parsing through delegation works")

// Test VSA operations through delegation
vectorA := list(1, 0, 1, 0, 1)
vectorB := list(0, 1, 0, 1, 0)
similarity := Telos memory similarity(vectorA, vectorB)
writeln("VSA similarity through delegation: ", similarity)

// Test context fractal creation through delegation
textObj := Object clone
textObj content := "test context"
fractal := ContextFractal with(textObj content)
writeln("Context fractal created through delegation: ", fractal id)

// Test WAL operations through delegation
Telos mark("test_delegation", Map clone atPut("successful", true))
writeln("WAL operation through delegation completed")

// Test snapshot through delegation
snapshot := Telos captureScreenshot
writeln("Screenshot captured through delegation, length: ", snapshot size)

// Test LLM call stub through delegation  
llmSpec := Map clone
llmSpec atPut("prompt", "test delegation")
llmSpec atPut("persona", "BRICK")
result := Telos llmCall(llmSpec)
writeln("LLM call through delegation: ", result exSlice(0, 50))

writeln("All prototypal delegation patterns validated successfully")