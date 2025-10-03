doFile("libs/Telos/io/FractalCognitionEngine.io")

fce := FractalCognitionEngine clone
fce initFederatedLearning(Map clone do(
    atPut("min_participants", 2)
    atPut("max_rounds", 10)
    atPut("privacy_budget", 1.0)
))

"Testing direct method call..." println
result := fce registerFederatedLearner("test_id", Map clone do(atPut("test", "config")))
result println