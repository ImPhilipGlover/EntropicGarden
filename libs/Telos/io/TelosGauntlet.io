//
// TelosGauntlet.io
//
// Implementation of the Compositional Gauntlet generator as specified in
// docs/Compositional_Gauntlet_Design.md.
//
// This module provides the prototypes and logic required to procedurally
// generate synthetic knowledge graphs, test queries, and semantic distractors
// for system-wide validation.
//

if(Lobby hasSlot("Telos") not, Lobby Telos := Object clone)

Telos GauntletGenerator := Telos Concept clone do(
    // Trait for identification
    setTrait("GauntletGenerator")

    // Slots for the generated components
    graph := nil
    queries := list()
    distractors := list()

    // Generates a new gauntlet based on a configuration map.
    // config example: Map clone at("nodes", 50) at("branching", 3)
    generate := method(config,
        writeln("Generating Compositional Gauntlet...")

        // 1. Create the BenchmarkGraph
        self graph = Telos BenchmarkGraph clone
        self graph generate(config)
        Telos ConceptRepository save(self graph)

        // 2. Create Queries and Distractors
        self queries = list()
        self distractors = list()

        self graph nodes foreach(node,
            // For each node, create a simple retrieval query
            if (node relationships and node relationships size > 0,
                // Create a query about its first relationship
                rel := node relationships at(0)
                query := Telos GauntletQuery clone do(
                    setPrompt("What is the '" .. rel name .. "' of '" .. node name .. "'?")
                    setExpectedResult(rel target)
                    setQueryType("simple retrieval")
                )

                // Create a distractor for this query
                distractor := Telos Distractor clone do(
                    // A simple distractor: claim a different target for the same relationship
                    falseTarget := self graph nodes sample
                    setContent("'" .. node name .. "' " .. rel name .. " is '" .. falseTarget name .. "'.")
                    setDistractorType("semantic near-miss")
                    setTargetQuery(query)
                )

                query setAssociatedDistractors(list(distractor))
                self queries append(query)
                self distractors append(distractor)
            )
        )

        // 3. Persist all generated concepts
        self queries foreach(q, Telos ConceptRepository save(q))
        self distractors foreach(d, Telos ConceptRepository save(d))

        writeln("...Gauntlet generation complete.")
        writeln("  Graph: ", self graph name)
        writeln("  Queries: ", self queries size)
        writeln("  Distractors: ", self distractors size)
        self
    )
)

Telos BenchmarkGraph := Telos Concept clone do(
    setTrait("BenchmarkGraph")
    nodes := list()
    relationships := list()
    schema := Map clone

    generate := method(config,
        nodeCount := config at("nodes") ifNil(20)
        branchingFactor := config at("branching") ifNil(2)

        // Generate nodes
        self nodes = list()
        for(i, 1, nodeCount,
            node := Telos Concept clone do(
                setName("Concept" .. i)
            )
            self nodes append(node)
        )

        // Generate relationships
        self relationships = list()
        self nodes foreach(node,
            for(i, 1, branchingFactor,
                targetNode := self nodes sample
                if (targetNode != node,
                    rel := Telos Concept clone do(
                        setName("relatedTo" .. i)
                        setSource(node)
                        setTarget(targetNode)
                    )
                    node addRelationship(rel)
                    self relationships append(rel)
                )
            )
        )
        self
    )
)

Telos GauntletQuery := Telos Concept clone do(
    setTrait("GauntletQuery")
    prompt := ""
    expectedResult := nil
    queryType := "unset"
    associatedDistractors := list()
)

Telos Distractor := Telos Concept clone do(
    setTrait("Distractor")
    content := ""
    distractorType := "unset"
    targetQuery := nil
)

Telos GauntletRunResult := Telos Concept clone do(
    setTrait("GauntletRunResult")
    query := nil
    actualResult := nil
    isCorrect := false
    telemetry := Map clone
)

// Add to Telos namespace
Telos BenchmarkGraph := Telos BenchmarkGraph
Telos GauntletQuery := Telos GauntletQuery
Telos Distractor := Telos Distractor
Telos GauntletRunResult := Telos GauntletRunResult

writeln("TelosGauntlet module loaded.")
