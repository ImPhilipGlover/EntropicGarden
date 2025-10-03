doFile("libs/Telos/io/HRCOrchestrator.io")
doFile("libs/Telos/io/FractalCognitionEngine.io")

hrc := HRCOrchestrator clone
fce := FractalCognitionEngine clone

("fce has handleFractalCognitionRequest: " .. (fce hasSlot("handleFractalCognitionRequest"))) println
("fce slotNames: " .. fce slotNames asString) println

hrc integrateFractalCognitionEngine(fce)

("hrc fractalCognitionEngine: " .. hrc fractalCognitionEngine type) println

fractalRequest := Map clone do(
    atPut("type", "pattern_analysis")
    atPut("data", Map clone do(
        atPut("patterns", list("recursive", "self_similar", "scale_invariant"))
        atPut("complexity", 0.8)
    ))
    atPut("scale", "meso")
)

fractalResult := hrc executeFractalCognition(fractalRequest, Map clone)
("fractalResult type: " .. fractalResult type) println
("fractalResult keys: " .. fractalResult keys asString) println