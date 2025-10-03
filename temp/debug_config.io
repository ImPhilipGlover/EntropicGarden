doFile("libs/Telos/io/FractalCognitionEngine.io")

fce := FractalCognitionEngine clone
config := Map clone do(
    atPut("min_participants", 2)
    atPut("max_rounds", 10)
    atPut("privacy_budget", 1.0)
)
fce initFederatedLearning(config)

"Config after init:" println
fce federatedConfig println
"max_rounds value:" println
fce federatedConfig at("max_rounds") println
"Type of max_rounds:" println
(fce federatedConfig at("max_rounds") type) println