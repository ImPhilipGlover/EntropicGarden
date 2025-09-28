//
// HRCOrchestrator.io - Central Coordinator for Hierarchical Reflective Cognition
//
// This file implements the HRCOrchestrator actor that manages cognitive cycles,
// handles doesNotUnderstand messages, and coordinates the Io actor society.
// It provides the central intelligence for Phase 3 Cognitive Core.
//

HRCOrchestrator := Object clone do(
    // Configuration slots
    thetaSuccess := 0.8    // Success threshold for cognitive cycles
    thetaDisc := 0.3       // Discrimination threshold for triggering generation
    maxIterations := 10    // Maximum iterations per cognitive cycle
    cycleTimeout := 30.0   // Timeout in seconds for cognitive cycles

    // SOAR Impasse Types
    IMPASSE_TYPES := Map clone do(
        atPut("state_no_change", "State No-Change Impasse")
        atPut("operator_tie", "Operator Tie Impasse")
        atPut("operator_no_change", "Operator No-Change Impasse")
        atPut("operator_failure", "Operator Failure Impasse")
    )

    // Reasoning Strategies with Utility Parameters
    reasoningStrategies := Map clone do(
        atPut("vsa_native", Map clone do(
            atPut("name", "VSA-Native Search")
            atPut("expected_success", 0.7)
            atPut("expected_cost", 0.2)
            atPut("goal_value", 1.0)
        ))
        atPut("graph_disambiguation", Map clone do(
            atPut("name", "Graph Disambiguation")
            atPut("expected_success", 0.8)
            atPut("expected_cost", 0.5)
            atPut("goal_value", 1.0)
        ))
        atPut("llm_decomposition", Map clone do(
            atPut("name", "LLM Query Decomposition")
            atPut("expected_success", 0.9)
            atPut("expected_cost", 0.8)
            atPut("goal_value", 1.0)
        ))
        atPut("global_search", Map clone do(
            atPut("name", "Global Summary Search")
            atPut("expected_success", 0.6)
            atPut("expected_cost", 0.9)
            atPut("goal_value", 1.0)
        ))
    )

    // Runtime state
    activeCycles := Map clone
    cycleHistory := list()
    autopoiesisEnabled := true

    // Initialize the HRC system
    init := method(
        activeCycles = Map clone
        cycleHistory = list()
        autopoiesisEnabled = true
        markChanged
        self
    )

    // Start a new cognitive cycle
    startCognitiveCycle := method(query, context,
        cycleId := uniqueId
        cycle := CognitiveCycle clone setCycleId(cycleId) setQuery(query) setContext(context)
        activeCycles atPut(cycleId, cycle)

        // Start the cycle asynchronously
        cycle start
        markChanged

        cycleId
    )

    // Handle doesNotUnderstand messages (forwarded from IoVM)
    handleDoesNotUnderstand := method(message, receiver, args,
        // Create a cognitive cycle to handle the unknown message
        query := Map clone
        query atPut("type", "doesNotUnderstand")
        query atPut("message", message name)
        query atPut("receiver", receiver)
        query atPut("args", args)

        context := Map clone
        context atPut("trigger", "doesNotUnderstand")
        context atPut("receiverType", receiver type)
        context atPut("messageName", message name)

        cycleId := startCognitiveCycle(query, context)

        // Return a placeholder that will be resolved when cycle completes
        PendingResolution clone setCycleId(cycleId)
    )

    // Get cycle status
    getCycleStatus := method(cycleId,
        cycle := activeCycles at(cycleId)
        if(cycle,
            cycle getStatus,
            Map clone atPut("error", "Cycle not found") atPut("cycleId", cycleId)
        )
    )

    // Complete a cognitive cycle
    completeCycle := method(cycleId, result,
        cycle := activeCycles at(cycleId)
        if(cycle,
            cycle complete(result)
            activeCycles removeAt(cycleId)
            cycleHistory append(cycle)

            // Trigger autopoiesis if enabled and cycle was successful
            if(autopoiesisEnabled and result at("success"),
                triggerAutopoiesis(cycle)
            )
        )
        markChanged
    )

    // Trigger autopoiesis based on cycle results
    triggerAutopoiesis := method(cycle,
        // Analyze cycle for patterns and trigger prompt evolution
        analysis := analyzeCycleForAutopoiesis(cycle)

        if(analysis at("shouldEvolve"),
            PromptTemplate evolveTemplate(analysis)
        )
    )

    // Analyze a completed cycle for autopoiesis opportunities
    analyzeCycleForAutopoiesis := method(cycle,
        analysis := Map clone
        analysis atPut("cycleId", cycle cycleId)
        analysis atPut("queryType", cycle query at("type"))
        analysis atPut("iterations", cycle iterations)
        analysis atPut("success", cycle result at("success"))

        // Determine if this pattern warrants template evolution
        shouldEvolve := false

        if(cycle query at("type") == "doesNotUnderstand",
            // Check if this is a recurring unknown message
            similarCycles := cycleHistory select(c,
                c query at("type") == "doesNotUnderstand" and
                c query at("message") == cycle query at("message")
            )

            if(similarCycles size > 2,
                shouldEvolve = true
                analysis atPut("evolutionReason", "recurring_unknown_message")
            )
        )

        if(cycle iterations > maxIterations / 2,
            // Complex cycles might benefit from better prompts
            shouldEvolve = true
            analysis atPut("evolutionReason", "high_iteration_complexity")
        )

        analysis atPut("shouldEvolve", shouldEvolve)
        analysis
    )

    // Utility-based policy selection (ACT-R inspired)
    selectReasoningStrategy := method(query, context,
        bestStrategy := nil
        bestUtility := -1

        reasoningStrategies foreach(strategyName, strategy,
            utility := calculateUtility(strategy, query, context)
            if(utility > bestUtility,
                bestUtility = utility
                bestStrategy = strategyName
            )
        )

        bestStrategy
    )

    // Calculate utility using ACT-R formula: U = P * G - C
    calculateUtility := method(strategy, query, context,
        p := strategy at("expected_success", 0.5)  // Probability of success
        g := strategy at("goal_value", 1.0)        // Goal importance
        c := strategy at("expected_cost", 0.5)     // Expected cost

        // Adjust based on query characteristics
        if(query at("type") == "complex_multi_hop",
            // Boost LLM decomposition for complex queries
            if(strategy at("name") == "LLM Query Decomposition",
                p = p + 0.2
            )
        )

        if(query at("type") == "doesNotUnderstand",
            // Prefer VSA search for unknown messages initially
            if(strategy at("name") == "VSA-Native Search",
                p = p + 0.1
            )
        )

        utility := (p * g) - c
        utility
    )

    // Detect impasse type from failure condition
    detectImpasse := method(failureCondition, cycle,
        impasseType := nil
        subGoal := nil

        if(failureCondition == "no_vsa_result",
            impasseType = "state_no_change"
            subGoal = "Formulate new query via graph expansion, LLM-driven query rewriting"
        )

        if(failureCondition == "multiple_similar_results",
            impasseType = "operator_tie"
            subGoal = "Retrieve full symbolic Concept objects and perform weighted pathfinding"
        )

        if(failureCondition == "no_applicable_operators",
            impasseType = "operator_no_change"
            subGoal = "Search knowledge base for applicable operators or invoke GenerativeKernel"
        )

        if(failureCondition == "generation_failed",
            impasseType = "operator_failure"
            subGoal = "Retry generation with different prompt or escalate to human intervention"
        )

        Map clone atPut("type", impasseType) atPut("subGoal", subGoal)
    )
)

// Export to global namespace
if(Lobby hasSlot("Telos") not, Lobby Telos := Object clone)
if(Telos hasSlot("HRC") not, Telos HRC := HRCOrchestrator clone init)