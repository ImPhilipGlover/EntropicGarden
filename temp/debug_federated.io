doFile("libs/Telos/io/FractalCognitionEngine.io")

fce := FractalCognitionEngine clone
fce initFederatedLearning(Map clone do(
    atPut("min_participants", 2)
    atPut("max_rounds", 10)
    atPut("privacy_budget", 1.0)
))

"Testing federated learning registration..." println

request := Map clone do(
    atPut("operation", "register_learner")
    atPut("learner_id", "test_agent")
    atPut("config", Map clone do(
        atPut("privacy_budget", 0.8)
        atPut("local_epochs", 5)
    ))
)

"learner_id value: " print
(request at("learner_id")) println
"config value: " print
(request at("config")) println

"Calling handleFederatedLearningRequest..." println
result := fce handleFederatedLearningRequest(request, Map clone)
result println