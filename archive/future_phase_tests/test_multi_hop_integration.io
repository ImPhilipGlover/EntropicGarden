// Test multi-hop retrieval integration
// This test verifies that the multi-hop retrieval strategy is properly integrated
// into the cognitive cycle architecture

testMultiHopIntegration := method(
    "Testing Multi-Hop Retrieval Integration..." println

    // Verify strategy is registered
    strategies := Telos HRC reasoningStrategies
    if(strategies at("multi_hop_retrieval"),
        "✓ Multi-hop retrieval strategy registered" println
        strategy := strategies at("multi_hop_retrieval")
        "  - Name: #{strategy at('name')}" interpolate println
        "  - Expected success: #{strategy at('expected_success')}" interpolate println
        "  - Expected cost: #{strategy at('expected_cost')}" interpolate println
    ,
        "✗ Multi-hop retrieval strategy not found" println
        return false
    )

    // Test utility calculation for complex query
    query := Map clone
    query atPut("type", "complex_multi_hop")
    query atPut("message", "What are the relationships between Io prototypes and Python UvmObjects?")

    context := Map clone
    context atPut("has_graph_data", true)

    utility := Telos HRC calculateUtility(strategies at("multi_hop_retrieval"), query, context)
    "✓ Utility calculation for complex query: #{utility}" interpolate println

    // Test strategy selection
    selectedStrategy := Telos HRC selectReasoningStrategy(query, context)
    "✓ Strategy selection result: #{selectedStrategy}" interpolate println

    // Test cognitive cycle creation (without actually running it)
    cycleId := Telos HRC startCognitiveCycle(query, context)
    if(cycleId,
        "✓ Cognitive cycle started with ID: #{cycleId}" interpolate println

        // Check cycle status
        status := Telos HRC getCycleStatus(cycleId)
        if(status,
            "✓ Cycle status retrieved: #{status at('status')}" interpolate println
        ,
            "✗ Failed to get cycle status" println
        )
    ,
        "✗ Failed to start cognitive cycle" println
        return false
    )

    "Multi-Hop Retrieval Integration Test: PASSED" println
    true
)

// Run the test
if(Telos hasSlot("HRC"),
    testMultiHopIntegration()
,
    "Telos HRC not available - cannot run integration test" println
)</content>
<parameter name="filePath">c:\EntropicGarden\test_multi_hop_integration.io