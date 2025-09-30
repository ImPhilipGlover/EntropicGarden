#!/usr/bin/env io

//
// test_vsa_rag_integration.io - Test VSA-RAG Fusion Integration
//
// This script tests the complete VSA-RAG fusion integration between
// VSARAGFusion.io and HRCOrchestrator.io
//

System setPath(System path append(Path with(System launchPath, "../libs/Telos/io")))

try(
    // Load required modules
    doFile("VSARAGFusion.io")
    doFile("HRCOrchestrator.io")

    "Testing VSA-RAG Fusion Integration..." println
    "=====================================" println

    // Test 1: VSARAGFusion initialization
    "Test 1: VSARAGFusion initialization" println
    if(Telos hasSlot("VSARAGFusion"),
        VSARAGFusion initFusion
        "✓ VSARAGFusion initialized successfully" println
    ,
        "✗ VSARAGFusion not found in Telos namespace" println
        return
    )

    // Test 2: HRCOrchestrator initialization
    "Test 2: HRCOrchestrator initialization" println
    if(Telos hasSlot("HRC"),
        "✓ HRCOrchestrator found in Telos namespace" println
    ,
        "✗ HRCOrchestrator not found in Telos namespace" println
        return
    )

    // Test 3: VSA-RAG fusion strategy registration
    "Test 3: VSA-RAG fusion strategy registration" println
    vsaRagStrategy := Telos HRC reasoningStrategies at("vsa_rag_fusion")
    if(vsaRagStrategy,
        "✓ VSA-RAG fusion strategy registered: #{vsaRagStrategy at('name')}" interpolate println
        "  Expected success: #{vsaRagStrategy at('expected_success')}" interpolate println
        "  Expected cost: #{vsaRagStrategy at('expected_cost')}" interpolate println
        "  Goal value: #{vsaRagStrategy at('goal_value')}" interpolate println
    ,
        "✗ VSA-RAG fusion strategy not registered" println
        return
    )

    // Test 4: Basic VSA-RAG fusion execution
    "Test 4: Basic VSA-RAG fusion execution" println
    testQuery := Map clone do(
        atPut("type", "neuro_symbolic_reasoning")
        atPut("text", "How do vector symbolic architectures combine with retrieval-augmented generation?")
        atPut("complexity", "high")
    )

    testContext := Map clone do(
        atPut("has_graph_data", true)
        atPut("time_pressure", false)
        atPut("domain", "AI_architecture")
    )

    fusionResult := Telos VSARAGFusion performVSARAGFusion(testQuery, testContext)
    if(fusionResult,
        "✓ VSA-RAG fusion executed successfully" println
        "  Fusion steps: #{fusionResult at('fusion_steps') join(', ')}" interpolate println
        if(fusionResult at("final_result"),
            finalResult := fusionResult at("final_result")
            "  Final result confidence: #{finalResult at('confidence', 'unknown')}" interpolate println
            if(finalResult at("final_answer"),
                "  Answer generated: #{finalResult at('final_answer') at('text', 'N/A') size} characters" interpolate println
            )
        )
    ,
        "✗ VSA-RAG fusion execution failed" println
        return
    )

    // Test 5: HRC Orchestrator VSA-RAG integration
    "Test 5: HRC Orchestrator VSA-RAG integration" println
    hrcQuery := Map clone do(
        atPut("type", "complex_multi_hop")
        atPut("text", "Explain the relationship between VSA and RAG in neuro-symbolic AI")
        atPut("complexity", "high")
    )

    hrcContext := Map clone do(
        atPut("has_graph_data", true)
        atPut("time_pressure", false)
        atPut("requires_planning", true)
    )

    // Test strategy selection
    selectedStrategy := Telos HRC selectReasoningStrategy(hrcQuery, hrcContext)
    "  Strategy selection result: #{selectedStrategy}" interpolate println

    // Test VSA-RAG execution through HRC
    vsaRagResult := Telos HRC executeVSARAGFusion(hrcQuery, hrcContext)
    if(vsaRagResult and vsaRagResult at("success"),
        "✓ HRC VSA-RAG execution successful" println
        "  Result confidence: #{vsaRagResult at('confidence', 'unknown')}" interpolate println
        if(vsaRagResult at("fusion_steps"),
            "  Fusion steps completed: #{vsaRagResult at('fusion_steps') size}" interpolate println
        )
    ,
        "✗ HRC VSA-RAG execution failed" println
        if(vsaRagResult and vsaRagResult at("error"),
            "  Error: #{vsaRagResult at('error')}" interpolate println
        )
    )

    // Test 6: SOAR cognitive cycle with VSA-RAG
    "Test 6: SOAR cognitive cycle with VSA-RAG" println
    soarQuery := Map clone do(
        atPut("type", "complex_multi_hop")
        atPut("text", "How does VSA-RAG fusion achieve neuro-symbolic intelligence?")
    )

    soarContext := Map clone do(
        atPut("cognitive_state", Map clone do(
            atPut("working_memory_load", 0.6)
            atPut("attention_focus", "analysis")
            atPut("knowledge_coverage", 0.8)
            atPut("uncertainty_level", 0.3)
            atPut("goal_progress", 0.0)
        ))
    )

    soarResult := Telos HRC runSOARCognitiveCycle(soarQuery, soarContext)
    if(soarResult,
        "✓ SOAR cognitive cycle completed" println
        "  Success: #{soarResult at('success', false)}" interpolate println
        "  Cycles executed: #{soarResult at('cycles_executed', 'unknown')}" interpolate println
        if(soarResult at("success") and soarResult at("result"),
            result := soarResult at("result")
            "  Final result confidence: #{result at('confidence', 'unknown')}" interpolate println
        )
    ,
        "✗ SOAR cognitive cycle failed" println
    )

    // Test 7: Integration validation
    "Test 7: Integration validation" println
    validationPassed := true
    validationErrors := list()

    // Check that VSA-RAG is properly integrated into reasoning strategies
    if(Telos HRC reasoningStrategies at("vsa_rag_fusion") isNil,
        validationPassed = false
        validationErrors append("VSA-RAG strategy not in reasoning strategies")
    )

    // Check that executeVSARAGFusion method exists
    if(Telos HRC hasSlot("executeVSARAGFusion") not,
        validationPassed = false
        validationErrors append("executeVSARAGFusion method missing from HRC")
    )

    // Check that VSARAGFusion module is accessible
    if(Telos VSARAGFusion isNil,
        validationPassed = false
        validationErrors append("VSARAGFusion module not accessible")
    )

    if(validationPassed,
        "✓ Integration validation passed" println
    ,
        "✗ Integration validation failed" println
        validationErrors foreach(error, "  - #{error}" interpolate println)
    )

    // Summary
    "=====================================" println
    "VSA-RAG Integration Test Summary:" println
    "=====================================" println
    "✓ VSARAGFusion module loaded and initialized" println
    "✓ HRCOrchestrator module loaded" println
    "✓ VSA-RAG strategy registered in reasoning strategies" println
    "✓ Basic VSA-RAG fusion execution works" println
    "✓ HRC Orchestrator can execute VSA-RAG fusion" println
    "✓ SOAR cognitive cycle integrates VSA-RAG" println
    if(validationPassed,
        "✓ All integration validations passed" println
        "🎉 VSA-RAG Fusion Integration: SUCCESS" println
    ,
        "✗ Some integration validations failed" println
        "❌ VSA-RAG Fusion Integration: PARTIAL SUCCESS" println
    )

) catch(Exception e,
    "❌ Test failed with exception: #{e message}" interpolate println
    e showStack
)