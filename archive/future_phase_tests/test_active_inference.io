// Active Inference Test Suite
// Comprehensive validation of Active Inference implementation in TelOS

// Load required components
doFile("libs/Telos/io/Concept.io")
doFile("libs/Telos/io/GenerativeWorldModel.io")
doFile("libs/Telos/io/VSARAGFusion.io")
doFile("libs/Telos/io/HRCOrchestrator.io")

// Test suite setup
TestSuite := Object clone do(
    tests := list()
    passed := 0
    failed := 0

    addTest := method(name, testBlock,
        tests append(Map clone atPut("name", name) atPut("block", testBlock))
    )

    run := method(
        "Running Active Inference Test Suite..." println
        "" println

        tests foreach(test,
            try(
                result := test at("block") call
                if(result,
                    passed = passed + 1
                    ("✓ PASS: " .. test at("name")) println
                ,
                    failed = failed + 1
                    ("✗ FAIL: " .. test at("name")) println
                )
            ) catch(Exception,
                failed = failed + 1
                ("✗ ERROR: " .. test at("name") .. " - Exception occurred") println
            )
        )

        "" println
        ("Results: " .. passed .. " passed, " .. failed .. " failed") println
        passed == tests size
    )
)

suite := TestSuite clone

// Test 1: World Model Initialization
suite addTest("World Model Initialization",
    block(
        worldModel := Telos GenerativeWorldModel
        worldModel isNil not and worldModel hasSlot("causalGraph")
    )
)

// Test 2: State Prediction
suite addTest("State Prediction",
    block(
        worldModel := Telos GenerativeWorldModel
        currentState := Map clone atPut("position", "start") atPut("resources", 10)
        action := "move_forward"

        prediction := worldModel predictNextState(currentState, action)
        prediction isNil not and prediction hasKey("position")
    )
)

// Test 3: EFE Calculation
suite addTest("EFE Calculation",
    block(
        worldModel := Telos GenerativeWorldModel
        goal := Map clone atPut("target", "goal_state")
        currentState := Map clone atPut("position", "start")
        policy := list("move_forward", "gather_resources")

        efe := worldModel calculateExpectedFreeEnergy(policy, currentState, goal)
        efe isKindOf(Number)
    )
)

// Test 4: Policy Planning
suite addTest("Policy Planning",
    block(
        worldModel := Telos GenerativeWorldModel
        goal := Map clone atPut("target", "goal_state")
        currentState := Map clone atPut("position", "start")

        plan := worldModel planWithActiveInference(goal, currentState, 3)
        plan isNil not and plan hasKey("policy") and plan at("policy") isKindOf(List)
    )
)

// Test 5: Experience Learning
suite addTest("Experience Learning",
    block(
        worldModel := Telos GenerativeWorldModel
        action := "move_forward"
        outcome := Map clone atPut("success", true) atPut("new_state", Map clone atPut("position", "middle"))
        context := Map clone atPut("goal", "reach_goal")

        result := worldModel learnFromExperience(action, outcome, context)
        result isNil not
    )
)

// Test 6: HRC Active Inference Integration
suite addTest("HRC Active Inference Integration",
    block(
        hrc := Telos HRCOrchestrator
        goal := Map clone atPut("description", "solve complex problem")
        currentState := Map clone atPut("complexity", 0.8)

        plan := hrc planWithActiveInference(goal at("description"), currentState, goal)
        plan isNil not and plan hasKey("strategy")
    )
)

// Test 7: Policy Execution
suite addTest("Policy Execution",
    block(
        hrc := Telos HRCOrchestrator
        policy := Map clone atPut("policy", list("gather_information", "apply_strategy"))
        context := Map clone atPut("query", "test query")

        result := hrc executeActiveInferencePolicy(policy, context)
        result isNil not and result hasKey("success")
    )
)

// Test 8: Complexity Assessment
suite addTest("Complexity Assessment",
    block(
        hrc := Telos HRCOrchestrator
        goal := "solve complex multi-step problem"
        context := Map clone atPut("time_pressure", true)

        complexity := hrc assessComplexity(goal, context)
        complexity isKindOf(Number) and complexity >= 0 and complexity <= 1
    )
)

// Test 9: Free Energy Calculation
suite addTest("Free Energy Calculation",
    block(
        hrc := Telos HRCOrchestrator
        currentState := Map clone atPut("error_rate", 0.2) atPut("uncertainty_level", 0.8)
        goal := Map clone atPut("target", "optimal_state")

        fe := hrc calculateCurrentFreeEnergy(currentState, goal)
        fe isKindOf(Number) and fe >= 0
    )
)

// Test 10: Active Inference Triggering
suite addTest("Active Inference Triggering",
    block(
        hrc := Telos HRCOrchestrator
        currentState := Map clone atPut("error_rate", 0.3) atPut("uncertainty_level", 0.9)
        goal := Map clone atPut("target", "complex_goal")

        shouldTrigger := hrc shouldTriggerActiveInference(currentState, goal)
        shouldTrigger == true or shouldTrigger == false
    )
)

// Test 11: Causal Relationship Management
suite addTest("Causal Relationship Management",
    block(
        worldModel := Telos GenerativeWorldModel
        relationship := Map clone
        relationship atPut("cause", "action_A")
        relationship atPut("effect", "state_B")
        relationship atPut("strength", 0.8)

        worldModel addCausalRelationship(relationship)
        relationships := worldModel getCausalRelationships()
        relationships isKindOf(List) and relationships size >= 1
    )
)

// Test 12: Pragmatic Value Calculation
suite addTest("Pragmatic Value Calculation",
    block(
        worldModel := Telos GenerativeWorldModel
        action := "optimal_action"
        goal := Map clone atPut("target", "desired_state")
        predictedState := Map clone atPut("position", "goal")

        value := worldModel calculatePragmaticValue(action, predictedState, goal)
        value isKindOf(Number)
    )
)

// Test 13: Epistemic Value Calculation
suite addTest("Epistemic Value Calculation",
    block(
        worldModel := Telos GenerativeWorldModel
        action := "explore_action"
        currentState := Map clone atPut("uncertainty", 0.8)
        predictedState := Map clone atPut("uncertainty", 0.3)

        value := worldModel calculateEpistemicValue(action, currentState, predictedState)
        value isKindOf(Number)
    )
)

// Test 14: Policy Evaluation
suite addTest("Policy Evaluation",
    block(
        worldModel := Telos GenerativeWorldModel
        policies := list(
            list("action1", "action2"),
            list("action3", "action4")
        )
        goal := Map clone atPut("target", "goal")
        currentState := Map clone atPut("position", "start")

        bestPolicy := worldModel evaluatePolicies(policies, currentState, goal)
        bestPolicy isKindOf(List)
    )
)

// Test 15: Sensory State Update
suite addTest("Sensory State Update",
    block(
        worldModel := Telos GenerativeWorldModel
        currentState := Map clone atPut("position", "start") atPut("resources", 10)
        sensoryInput := Map clone atPut("vision", "obstacle_ahead") atPut("resources", 8)

        updatedState := worldModel updateSensoryState(currentState, sensoryInput)
        updatedState isNil not and updatedState hasKey("vision")
    )
)

// Test 16: Multi-step Planning
suite addTest("Multi-step Planning",
    block(
        worldModel := Telos GenerativeWorldModel
        goal := Map clone atPut("target", "distant_goal")
        currentState := Map clone atPut("position", "start")
        horizon := 5

        plan := worldModel planWithActiveInference(goal, currentState, horizon)
        policy := plan at("policy")
        policy isKindOf(List) and policy size <= horizon
    )
)

// Test 17: Integration Test - Full Active Inference Cycle
suite addTest("Integration Test - Full Active Inference Cycle",
    block(
        hrc := Telos HRCOrchestrator
        worldModel := Telos GenerativeWorldModel

        // Setup scenario
        goal := Map clone atPut("description", "navigate to goal and gather resources")
        currentState := Map clone atPut("position", "start") atPut("resources", 5) atPut("complexity", 0.7)

        // Plan with Active Inference
        plan := hrc planWithActiveInference(goal at("description"), currentState, goal)

        if(plan and plan hasKey("policy"),
            // Execute the plan
            executionResult := hrc executeActiveInferencePolicy(plan, currentState)

            // Verify execution
            executionResult hasKey("success") and executionResult hasKey("executed_actions")
        ,
            false
        )
    )
)

// Test 18: Error Handling - Invalid Policy
suite addTest("Error Handling - Invalid Policy",
    block(
        hrc := Telos HRCOrchestrator
        invalidPolicy := Map clone atPut("invalid", "policy")

        result := hrc executeActiveInferencePolicy(invalidPolicy, Map clone)
        result hasKey("error")
    )
)

// Test 19: Error Handling - Nil Inputs
suite addTest("Error Handling - Nil Inputs",
    block(
        hrc := Telos HRCOrchestrator
        result := hrc planWithActiveInference(nil, nil, nil)
        result isNil or result hasKey("error")
    )
)

// Test 20: Performance Metrics
suite addTest("Performance Metrics",
    block(
        worldModel := Telos GenerativeWorldModel
        metrics := worldModel getModelStatus()
        metrics isKindOf(Map) and metrics hasKey("relationships_count")
    )
)

// Test 21: Active Inference Configuration
suite addTest("Active Inference Configuration",
    block(
        hrc := Telos HRCOrchestrator

        // Test enabling/disabling
        hrc enableActiveInference(true)
        hrc activeInferenceEnabled == true

        // Test threshold setting
        hrc setFreeEnergyThreshold(0.5)
        hrc freeEnergyThreshold == 0.5

        // Test planning horizon
        hrc setPlanningHorizon(10)
        hrc planningHorizon == 10
    )
)

// Run the test suite
success := suite run()

if(success,
    "🎉 All Active Inference tests passed!" println
    exit(0)
,
    "❌ Some Active Inference tests failed. Check output above." println
    exit(1)
)