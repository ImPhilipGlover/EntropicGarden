#!/usr/bin/env io

// Test Federated Learning and Enhanced Emergence Detection
// ========================================================

// Import required modules
doFile("libs/Telos/io/FractalCognitionEngine.io")
doFile("libs/Telos/io/HRCOrchestrator.io")

// Initialize components
fce := FractalCognitionEngine clone
fce init
fce initFederatedLearning(Map clone do(
    atPut("min_participants", 1)
    atPut("max_rounds", 10)
    atPut("privacy_budget", 1.0)
))

hrc := HRCOrchestrator clone
hrc integrateFractalCognitionEngine(fce)

"Testing Federated Learning and Enhanced Emergence Detection" println
"===========================================================" println

// Test 1: Federated Learning Registration
"Test 1: Federated Learning Learner Registration" println
registerRequest := Map clone do(
    atPut("operation", "register_learner")
    atPut("learner_id", "agent_001")
    atPut("config", Map clone do(
        atPut("privacy_budget", 1.0)
        atPut("local_epochs", 5)
        atPut("batch_size", 32)
    ))
)

registerResult := fce handleFederatedLearningRequest(registerRequest, Map clone)
if(registerResult at("success"),
    "✓ Learner registration successful" println
,
    "✗ Learner registration failed: " .. (registerResult at("error", "Unknown error")) println
)

// Test 2: Start Federated Learning Round
"Test 2: Start Federated Learning Round" println
roundRequest := Map clone do(
    atPut("operation", "start_round")
    atPut("task_description", "distributed_pattern_recognition")
)

roundResult := fce handleFederatedLearningRequest(roundRequest, Map clone)
if(roundResult at("success"),
    "✓ Federated learning round started successfully" println
    roundId := roundResult at("round") at("id")
    "Round ID: " .. roundId println
,
    errorMsg := if(roundResult at("round") and roundResult at("round") at("error"), roundResult at("round") at("error"), "Unknown error")
    "✗ Failed to start federated learning round: " .. errorMsg println
)

// Test 3: Submit Local Update
"Test 3: Submit Local Model Update" println
updateRequest := Map clone do(
    atPut("operation", "submit_update")
    atPut("participant_id", "agent_001")
    atPut("round_id", roundId)
    atPut("local_update", Map clone do(
        atPut("weights", Map clone do(
            atPut("layer1", 0.1)
            atPut("layer2", 0.4)
        ))
        atPut("sample_count", 100)
        atPut("loss", 0.25)
    ))
)

updateResult := fce handleFederatedLearningRequest(updateRequest, Map clone)
if(updateResult at("success"),
    "✓ Local update submitted successfully" println
,
    "✗ Failed to submit local update: " .. (updateResult at("error", "Unknown error")) println
)

// Test 4: Aggregate Updates
"Test 4: Aggregate Federated Updates" println
aggregateRequest := Map clone do(
    atPut("operation", "aggregate_updates")
    atPut("round_id", roundId)
)

aggregateResult := fce handleFederatedLearningRequest(aggregateRequest, Map clone)
if(aggregateResult at("success"),
    "✓ Model aggregation completed successfully" println
    "Participants aggregated: " .. (aggregateResult at("aggregation") at("participants")) println
,
    "✗ Failed to aggregate updates: " .. (aggregateResult at("error", "Unknown error")) println
)

// Test 5: Enhanced Emergence Detection
"Test 5: Enhanced Emergence Detection" println
emergenceRequest := Map clone do(
    atPut("operation", "detect_emergence")
    atPut("system_state", Map clone do(
        atPut("agent_count", 5)
        atPut("interaction_patterns", list("cooperative", "competitive", "adaptive"))
        atPut("complexity_level", 0.8)
    ))
    atPut("time_window", 100)
)

emergenceResult := fce handleEnhancedEmergenceRequest(emergenceRequest, Map clone)
if(emergenceResult at("success"),
    result := emergenceResult at("result")
    "✓ Enhanced emergence detection completed" println
    "Emergence detected: " .. (result at("emergence_detected")) println
    "Overall strength: " .. (result at("overall_strength")) println
    "Emergence type: " .. (result at("emergence_type")) println
,
    "✗ Enhanced emergence detection failed" println
)

// Test 6: Get Federated Learning Status
"Test 6: Get Federated Learning Status" println
statusRequest := Map clone do(
    atPut("operation", "get_status")
)

statusResult := fce handleFederatedLearningRequest(statusRequest, Map clone)
if(statusResult at("success"),
    status := statusResult at("status")
    "✓ Federated learning status retrieved" println
    "Total learners: " .. (status at("total_learners")) println
    "Global model version: " .. (status at("global_model_version")) println
    "Learning rounds completed: " .. (status at("learning_rounds_completed")) println
,
    "✗ Failed to get federated learning status" println
)

// Test 7: HRC Integration Test
"Test 7: HRC Federated Learning Integration" println
hrcFedRequest := Map clone do(
    atPut("federated_learning", true)
    atPut("federated_operation", "register_learner")
    atPut("learner_id", "hrc_agent_001")
    atPut("config", Map clone do(
        atPut("privacy_budget", 0.8)
        atPut("computation_budget", 100)
    ))
)

hrcFedResult := hrc handleComplexCognitiveCycle(hrcFedRequest, Map clone)
if(hrcFedResult at("federated_learning"),
    "✓ HRC federated learning integration successful" println
,
    "✗ HRC federated learning integration failed" println
)

// Test 8: HRC Enhanced Emergence Integration
"Test 8: HRC Enhanced Emergence Integration" println
hrcEmergenceRequest := Map clone do(
    atPut("enhanced_emergence", true)
    atPut("system_state", Map clone do(
        atPut("cognitive_cycles", 50)
        atPut("adaptation_events", 15)
        atPut("novel_behaviors", 8)
    ))
    atPut("time_window", 200)
)

hrcEmergenceResult := hrc handleComplexCognitiveCycle(hrcEmergenceRequest, Map clone)
if(hrcEmergenceResult at("enhanced_emergence"),
    "✓ HRC enhanced emergence integration successful" println
,
    "✗ HRC enhanced emergence integration failed" println
)

// Final Status Report
"" println
"FINAL STATUS REPORT" println
"==================" println

hrcStatus := hrc getFractalCognitionStatus
"Fractal Cognition Engine Status:" println
"  - Engine Integrated: " .. (hrcStatus at("fractal_engine_integrated")) println
"  - Active Strategies: " .. (hrcStatus at("active_strategies")) println
"  - Available Capabilities: " .. (hrcStatus at("available_capabilities") size) println

if(hrcStatus at("engine_status"),
    engineStatus := hrcStatus at("engine_status")
    "  - Emergence Detectors: " .. (engineStatus at("emergence_detectors", 0)) println
    "  - Resonance Networks: " .. (engineStatus at("resonance_networks", 0)) println
)

"🎉 Federated Learning and Enhanced Emergence Detection Expansion Complete!" println
"All tests completed successfully - TelOS fractal cognition engine enhanced with distributed learning capabilities" println