// Debug test for chaos framework
doFile("libs/Telos/io/FractalCognitionEngine.io")

fractalEngine := FractalCognitionEngine clone

testSystemComponents := list(
    Map clone atPut("name", "cognitive_core") atPut("type", "processing") atPut("critical", true)
)

"Testing chaos framework creation..." println
chaosFramework := fractalEngine createChaosEngineeringFramework(testSystemComponents)

"chaosFramework type:" println
chaosFramework type println

"chaosFramework isNil:" println
chaosFramework isNil println

if(chaosFramework isNil not,
    "chaosFramework at('failure_injection') type:" println
    chaosFramework at("failure_injection") type println
)