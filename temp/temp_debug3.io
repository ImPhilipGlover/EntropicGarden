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
("fractalResult type: " .. fractalResult type) println

// Try the exact failing line
if(fractalResult at("success"),
    "✓ Fractal cognition analysis executed successfully" println
    "  - Detected patterns: #{fractalResult at(\"patterns\", Map clone) at(\"detected_patterns\", list()) size}" interpolate println
,
    "✗ Fractal cognition analysis failed: #{fractalResult at(\"error\", \"unknown error\")}" interpolate println
)