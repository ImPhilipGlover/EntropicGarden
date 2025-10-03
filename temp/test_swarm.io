// Test swarm intelligence
doFile("libs/Telos/io/FractalCognitionEngine.io")
f := FractalCognitionEngine clone
agents := list(
    Map clone atPut("id", "agent1") atPut("position", list(0, 0)),
    Map clone atPut("id", "agent2") atPut("position", list(1, 1))
)
result := f implementCollectiveForaging(agents, Map clone)
"Test passed - foraging result:" println
result println
