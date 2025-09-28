//
// gauntlet_validation.io
//
// Master Validation Harness for the Compositional Gauntlet
//
// This script orchestrates the execution of a full validation run using the
// Compositional Gauntlet. It performs the following steps:
//
// 1. Initializes the TELOS system.
// 2. Instructs the GauntletGenerator to create a new benchmark dataset
//    (knowledge graph, queries, and distractors).
// 3. Iterates through each generated GauntletQuery.
// 4. For each query:
//    a. Injects associated distractors into the HRC's working memory.
//    b. Submits the query prompt to the TelosHRC.
//    c. Captures the result and relevant telemetry.
// 5. Compares the actual result against the expected result.
// 6. Stores the outcome in a GauntletRunResult object.
// 7. Aggregates all results and computes system-wide accuracy and performance metrics.
// 8. Prints a final structured report to the console.
// 9. Shuts down the TELOS system.
//

// Ensure we can find the core system files
try(doFile("init.io"))
try(doFile("../iovm/init.io"))
doFile("libs/Telos/io/TelosBridge.io")
try(doFile("../Telos/io/TelosBridge.io"))
try(doFile("libs/Telos/io/TelosGauntlet.io"))

GauntletValidationHarness := Object clone do(
    Telos := Lobby getSlot("Telos")

    run := method(
        writeln("========================================")
        writeln("= Starting Compositional Gauntlet Test =")
        writeln("========================================")

        // --- 1. Initialization ---
        if(self Telos start(4) not,
            writeln("FATAL: Could not initialize TELOS Bridge. Aborting.")
            return
        )
        // Ensure ZODB is running for persistence
        // In a real scenario, we'd ensure the ZEO server is up.
        // For now, we assume it's available.

        // --- 2. Generation ---
        writeln("\n--- Generating Benchmark Data ---")
        gauntletConfig := Map clone at("nodes", 10) at("branching", 2)
        generator := self Telos Gauntlet clone
        generator generate(gauntletConfig)

        if (generator queries size == 0,
            writeln("FATAL: Gauntlet generation produced no queries. Aborting.")
            self Telos stop
            return
        )

        // --- 3. Execution & Evaluation ---
        writeln("\n--- Executing Queries ---")
        runResults := list()
        totalQueries := generator queries size
        correctCount := 0

        generator queries foreach(i, query,
            write("  (" .. (i+1) .. "/" .. totalQueries .. ") Executing query: ", query prompt, "...")

            // This is where we would interact with the HRC.
            // For now, we'll simulate the process.
            // TODO: Replace this with actual calls to TelosHRC and FederatedMemory

            // 4a. Inject distractors
            // Distractors are already persisted via ConceptRepository in the generator
            // They should be available in the federated memory system
            query associatedDistractors foreach(distractor,
                // Ensure distractor is persisted and indexed
                if(distractor oid isNil,
                    Telos ConceptRepository save(distractor)
                )
            )

            // 4b. Submit prompt to HRC
            // Create proper query structure for HRC
            hrcQuery := Map clone
            hrcQuery atPut("type", "gauntlet_query")
            hrcQuery atPut("message", query prompt)
            hrcQuery atPut("queryType", query queryType)

            hrcContext := Map clone
            hrcContext atPut("source", "gauntlet_validation")
            hrcContext atPut("expectedResult", query expectedResult)
            hrcContext atPut("distractorsInjected", query associatedDistractors size)

            cycleId := self Telos HRC startCognitiveCycle(hrcQuery, hrcContext)

            // Wait for cycle completion (simplified - in practice would be async)
            cycleStatus := self Telos HRC getCycleStatus(cycleId)
            waitCount := 0
            while(cycleStatus at("status") != "completed" and waitCount < 50,
                System sleep(0.1)
                cycleStatus = self Telos HRC getCycleStatus(cycleId)
                waitCount = waitCount + 1
            )

            if(cycleStatus at("status") == "completed",
                actualResult := cycleStatus at("result")
                if(actualResult and actualResult at("success"),
                    // Extract the best result from HRC response
                    bestMatch := actualResult at("bestMatch")
                    if(bestMatch,
                        actualResult = bestMatch,
                        actualResult = Map clone atPut("name", "no_result") atPut("confidence", 0)
                    ),
                    actualResult = Map clone atPut("name", "hrc_failed") atPut("confidence", 0)
                ),
                actualResult = Map clone atPut("name", "cycle_timeout") atPut("confidence", 0)
            )

            // 5. Compare results
            // Compare the name field of actualResult with expectedResult name
            actualName := actualResult at("name", "unknown")
            expectedName := query expectedResult name
            isCorrect := (actualName == expectedName)


            if (isCorrect, correctCount = correctCount + 1; writeln(" CORRECT"))
            if (isCorrect not, writeln(" INCORRECT"))

            // 6. Store result
            result := Telos GauntletRunResult clone do(
                setQuery(query)
                setActualResult(actualResult)
                setIsCorrect(isCorrect)
                // Capture telemetry from HRC cycle
                telemetry := Map clone
                telemetry atPut("cycleId", cycleId)
                telemetry atPut("cycleStatus", cycleStatus)
                if(actualResult hasSlot("confidence"),
                    telemetry atPut("confidence", actualResult at("confidence"))
                )
                if(actualResult hasSlot("searchHits"),
                    telemetry atPut("searchHits", actualResult at("searchHits"))
                )
                setTelemetry(telemetry)
            )
            runResults append(result)

            // Persist result to ZODB
            Telos ConceptRepository save(result)
        )

        // --- 7. Generate detailed report ---
        writeln("\n--- Gauntlet Run Summary ---")
        accuracy := (correctCount / totalQueries) * 100
        writeln("  Total Queries:   ", totalQueries)
        writeln("  Correct Answers: ", correctCount)
        writeln("  Accuracy:        ", accuracy, "%")

        // Calculate additional metrics
        totalConfidence := 0
        totalSearchHits := 0
        validResults := 0
        runResults foreach(result,
            telemetry := result telemetry
            if(telemetry,
                confidence := telemetry at("confidence")
                if(confidence, totalConfidence = totalConfidence + confidence; validResults = validResults + 1)
                searchHits := telemetry at("searchHits")
                if(searchHits, totalSearchHits = totalSearchHits + searchHits)
            )
        )

        if(validResults > 0,
            avgConfidence := totalConfidence / validResults
            writeln("  Average Confidence: ", avgConfidence round(2))
        )
        if(runResults size > 0,
            avgSearchHits := totalSearchHits / runResults size
            writeln("  Average Search Hits: ", avgSearchHits round(2))
        )

        // Analyze anomalies
        anomalies := runResults select(result, result isCorrect not)
        if(anomalies size > 0,
            writeln("  Anomalies Detected: ", anomalies size)
            anomalies foreach(i, anomaly,
                queryText := anomaly query prompt
                actualName := anomaly actualResult at("name", "unknown")
                expectedName := anomaly query expectedResult name
                writeln("    Query ", (i+1), ": Expected '", expectedName, "', got '", actualName, "'")
            )
        )

        writeln("----------------------------")


        // --- 9. Shutdown ---
        writeln("\n--- Shutting down TELOS system ---")
        self Telos stop
        writeln("========================================")
        writeln("=      Gauntlet Test Complete      =")
        writeln("========================================")
    )
)

// Execute the harness
GauntletValidationHarness run
