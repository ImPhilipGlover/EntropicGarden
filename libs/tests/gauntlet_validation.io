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
try(doFile("libs/Telos/io/TelosBridge.io"))
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
            // For now, we assume distractors are simple concepts.
            // A more robust implementation would handle different concept types.
            query associatedDistractors foreach(distractor,
                // writeln("Injecting distractor: ", distractor name) // Optional: for debugging
                self Telos FederatedMemory add(distractor)
            )

            // 4b. Submit prompt to HRC
            actualResult := self Telos HRC process(query prompt)

            // 5. Compare results
            isCorrect := (actualResult name == query expectedResult name)


            if (isCorrect, correctCount = correctCount + 1; writeln(" CORRECT"))
            if (isCorrect not, writeln(" INCORRECT"))

            // 6. Store result
            result := Telos GauntletRunResult clone do(
                setQuery(query)
                setActualResult(actualResult)
                setIsCorrect(isCorrect)
                // setTelemetry(...) // TODO: capture from HRC
            )
            runResults append(result)
        )

        // --- 7. Reporting ---
        writeln("\n--- Gauntlet Run Summary ---")
        accuracy := (correctCount / totalQueries) * 100
        writeln("  Total Queries:   ", totalQueries)
        writeln("  Correct Answers: ", correctCount)
        writeln("  Accuracy:        ", accuracy, "%")
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
