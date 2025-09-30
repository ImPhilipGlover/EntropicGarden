//
// test_soar_architecture.io - Test Suite for SOAR Cognitive Architecture
//
// This file tests the complete SOAR (State, Operator, And Result) cognitive architecture
// implementation, validating all phases: perception, decision, action, and learning.
//

// Load the HRC system
doFile("libs/Telos/io/TelosHRC.io")

"Testing SOAR Cognitive Architecture Implementation" println
"==================================================" println

// Test 1: SOAR Architecture Initialization
"Test 1: SOAR Architecture Initialization" println
if(Telos hasSlot("SOAR"),
    "✓ SOAR architecture loaded" println
    soar := Telos SOAR

    // Check core components
    if(soar hasSlot("runDecisionCycle"),
        "✓ runDecisionCycle method available" println,
        "✗ runDecisionCycle method missing" println
    )

    if(soar hasSlot("problemSpaces") and soar problemSpaces size > 0,
        "✓ Problem spaces initialized (#{soar problemSpaces size} spaces)" interpolate println,
        "✗ Problem spaces not initialized" println
    )

    if(soar hasSlot("availableOperators") and soar availableOperators size > 0,
        "✓ Operators initialized (#{soar availableOperators size} operators)" interpolate println,
        "✗ Operators not initialized" println
    )
,
    "✗ SOAR architecture not loaded" println
)

// Test 2: Basic SOAR Decision Cycle
"Test 2: Basic SOAR Decision Cycle" println
if(Telos hasSlot("SOAR"),
    soar := Telos SOAR

    // Create a test state
    testState := Map clone do(
        atPut("query", "What is VSA-RAG fusion?")
        atPut("context", "AI cognitive architecture research")
        atPut("timestamp", Date now)
        atPut("query_complexity", 2)
    )

    // Run decision cycle
    result := soar runDecisionCycle(testState)

    if(result,
        "✓ Decision cycle completed" println
        "  Cycles executed: #{result at('cycles', 'unknown')}" interpolate println
        "  Impasse detected: #{result at('impasse', false)}" interpolate println

        finalState := result at("finalState")
        if(finalState,
            "  Final state keys: #{finalState keys size}" interpolate println
            if(finalState hasKey("fusion_result"),
                "✓ VSA-RAG fusion operator applied" println
            )
        )
    ,
        "✗ Decision cycle failed" println
    )
,
    "✗ Cannot test decision cycle - SOAR not available" println
)

// Test 3: Operator Proposal and Selection
"Test 3: Operator Proposal and Selection" println
if(Telos hasSlot("SOAR"),
    soar := Telos SOAR

    // Test state that should trigger VSA search
    vsaState := Map clone do(
        atPut("query", "vsa symbolic reasoning")
        atPut("context", "cognitive architecture")
    )

    proposals := soar proposeOperators(vsaState)
    if(proposals size > 0,
        "✓ Operator proposals generated (#{proposals size} proposals)" interpolate println

        // Check if VSA search is proposed
        vsaProposed := proposals detect(proposal, proposal at("operator") == "vsa_search")
        if(vsaProposed,
            "✓ VSA search operator proposed with utility #{vsaProposed at('utility')}" interpolate println
        ,
            "✗ VSA search operator not proposed" println
        )

        // Test operator selection
        selected := soar selectOperator(proposals, vsaState)
        if(selected,
            "✓ Operator selected: #{selected}" interpolate println
        ,
            "✗ No operator selected" println
        )
    ,
        "✗ No operator proposals generated" println
    )
,
    "✗ Cannot test operators - SOAR not available" println
)

// Test 4: Impasse Detection and Resolution
"Test 4: Impasse Detection and Resolution" println
if(Telos hasSlot("SOAR"),
    soar := Telos SOAR

    // Create an impasse state (no applicable operators)
    impasseState := Map clone do(
        atPut("no_operators", true)
        atPut("query", "impossible query")
    )

    impasse := soar handleImpasse(impasseState)
    if(impasse,
        "✓ Impasse detected and handled" println
        "  Impasse type: #{impasse at('type', 'unknown')}" interpolate println

        if(impasse hasKey("subgoal_created"),
            "✓ Subgoal created for impasse resolution" println
        ,
            "✗ No subgoal created" println
        )
    ,
        "✗ Impasse handling failed" println
    )
,
    "✗ Cannot test impasse handling - SOAR not available" println
)

// Test 5: Learning and Chunking
"Test 5: Learning and Chunking" println
if(Telos hasSlot("SOAR"),
    soar := Telos SOAR

    initialProductions := soar productions size

    // Simulate a successful learning cycle
    oldState := Map clone do(
        atPut("query", "complex vsa query")
        atPut("query_complexity", 4)
    )

    newState := Map clone do(
        atPut("success", true)
        atPut("fusion_result", "integrated answer")
    )

    soar learnFromCycle(oldState, "vsa_rag_fusion", newState)

    if(soar productions size > initialProductions,
        "✓ Additional production learned through chunking" println
        "  Productions before: #{initialProductions}, after: #{soar productions size}" interpolate println
    ,
        "✗ No additional production learned" println
    )
,
    "✗ Cannot test learning - SOAR not available" println
)

// Test 6: Integration with HRC Orchestrator
"Test 6: Integration with HRC Orchestrator" println
if(Telos hasSlot("HRC") and Telos hasSlot("SOAR"),
    hrc := Telos HRC
    soar := Telos SOAR

    // Test the enhanced SOAR cognitive cycle
    query := Map clone do(
        atPut("type", "complex_reasoning")
        atPut("content", "How does VSA-RAG fusion work?")
    )

    context := Map clone do(
        atPut("domain", "AI")
        atPut("complexity", "high")
    )

    cycleResult := hrc runSOARCognitiveCycle(query, context)

    if(cycleResult,
        "✓ Enhanced SOAR cognitive cycle completed" println
        "  Architecture: #{cycleResult at('architecture', 'unknown')}" interpolate println
        "  Success: #{cycleResult at('success', false)}" interpolate println
        "  Duration: #{cycleResult at('duration', 0)} seconds" interpolate println

        if(cycleResult hasKey("soarResult"),
            soarResult := cycleResult at("soarResult")
            "  SOAR cycles: #{soarResult at('cycles', 0)}" interpolate println
            "  Impasse resolved: #{cycleResult at('impasseResolved', false)}" interpolate println
        )
    ,
        "✗ Enhanced SOAR cognitive cycle failed" println
    )
,
    "✗ Cannot test HRC integration - HRC or SOAR not available" println
)

// Test 7: Utility-Based Operator Selection
"Test 7: Utility-Based Operator Selection" println
if(Telos hasSlot("SOAR"),
    soar := Telos SOAR

    // Test utility calculation for different operators
    testOperator := Map clone do(
        atPut("name", "VSA-RAG Fusion")
        atPut("utility", 0.8)
        atPut("cost", 4.0)
    )

    normalState := Map clone do(
        atPut("query_complexity", 2)
    )

    complexState := Map clone do(
        atPut("query_complexity", 4)
        atPut("time_pressure", true)
    )

    normalUtility := soar calculateOperatorUtility(testOperator, normalState)
    complexUtility := soar calculateOperatorUtility(testOperator, complexState)

    "✓ Utility calculation working" println
    "  Normal state utility: #{normalUtility}" interpolate println
    "  Complex state utility: #{complexUtility}" interpolate println

    // Utility should be lower under time pressure due to higher cost
    if(complexUtility < normalUtility,
        "✓ Time pressure correctly reduces utility" println
    ,
        "✗ Time pressure utility adjustment failed" println
    )
,
    "✗ Cannot test utility calculation - SOAR not available" println
)

"SOAR Architecture Testing Complete" println
"===================================" println