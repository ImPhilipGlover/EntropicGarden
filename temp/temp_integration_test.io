doFile("libs/Telos/io/HRCOrchestrator.io")
doFile("libs/Telos/io/FractalCognitionEngine.io")

hrc := HRCOrchestrator clone
fce := FractalCognitionEngine clone

hrc integrateFractalCognitionEngine(fce)

fractalRequest := Map clone do(
    atPut("type", "pattern_analysis")
    atPut("data", Map clone do(
        atPut("patterns", list("recursive", "self_similar", "scale_invariant"))
        atPut("complexity", 0.8)
    ))
    atPut("scale", "meso")
)

fractalResult := hrc executeFractalCognition(fractalRequest, Map clone)
("Result type: " .. fractalResult type) println
("Result: " .. fractalResult asString) println