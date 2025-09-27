# Compositional Gauntlet Design Specification

## 1. Overview

The Compositional Gauntlet is a system-wide validation framework designed to test the TELOS system's reasoning capabilities, as mandated by the "Extending TELOS Architecture v1.4 Proposal." Its primary purpose is to generate synthetic knowledge graphs, associated queries, and semantic distractors to create a challenging benchmark. This allows us to quantitatively measure the system's performance in terms of accuracy, transparency, and resilience against misleading information.

The Gauntlet serves as the foundation for the "Algebraic Crucible + Compositional Gauntlet" master validation script, providing the structured test cases needed to evaluate the Hierarchical Reasoning Core (HRC) and the entire cognitive architecture.

## 2. Core Prototypes

The Gauntlet will be implemented as a society of Io prototypes, adhering to the system's prototype-based development mandate. All prototypes will be subtypes of the canonical `Concept` prototype to ensure they can be persisted in the ZODB (L3) via the `TelosConceptRepository`.

### 2.1. `GauntletGenerator`

The central actor responsible for orchestrating the creation of the entire gauntlet.

-   **`generate(config)`**: The primary method. Takes a configuration map specifying the desired complexity of the graph (e.g., number of nodes, relationships, distractor density). It will generate the `BenchmarkGraph`, `GauntletQuery` set, and `Distractor` set, and persist them.
-   **`newGraph`**: Slot for the `BenchmarkGraph` being constructed.
-   **`queries`**: A list of `GauntletQuery` objects.
-   **`distractors`**: A list of `Distractor` objects.

### 2.2. `BenchmarkGraph`

A `Concept` representing the synthetic knowledge graph, which serves as the ground truth for the validation run.

-   **`nodes`**: A list of `Concept` objects representing the entities in the graph.
-   **`relationships`**: A list of `Concept` objects describing the links between nodes (e.g., "ConceptA `isA` ConceptB").
-   **`schema`**: A description of the types of nodes and relationships used in the graph.

### 2.3. `GauntletQuery`

A `Concept` representing a single test case. Each query asks a question about the `BenchmarkGraph` that the HRC must answer.

-   **`prompt`**: The natural language question to be presented to the HRC.
-   **`expectedResult`**: The ground truth answer, derived from the `BenchmarkGraph`. This could be a specific `Concept`, a list of `Concept`s, or a boolean value.
-   **`queryType`**: The category of the query (e.g., "simple retrieval," "multi-hop inference," "negation").
-   **`associatedDistractors`**: A list of `Distractor` objects specifically designed to interfere with this query.

### 2.4. `Distractor`

A `Concept` representing a piece of information that is plausible but incorrect or misleading. Distractors are designed to test the system's ability to ignore irrelevant data.

-   **`content`**: The fallacious information, either as a natural language statement or a structured `Concept`.
-   **`distractorType`**: The category of distraction (e.g., "semantic near-miss," "false premise," "out-of-context fact").
-   **`targetQuery`**: The `GauntletQuery` this distractor is intended to disrupt.

### 2.5. `GauntletRunResult`

A `Concept` to store the outcome of a single `GauntletQuery` execution.

-   **`query`**: The `GauntletQuery` that was executed.
-   **`actualResult`**: The result produced by the HRC.
-   **`isCorrect`**: A boolean indicating if `actualResult` matches `expectedResult`.
-   **`telemetry`**: A map containing performance metrics from the run (e.g., latency, number of cognitive cycles, `theta` values).

## 3. Data Schemas and Persistence

All Gauntlet prototypes will inherit from `Concept`. Their slots will be standard Io objects (Lists, Maps, Sequences). The `TelosConceptRepository` will handle their serialization and persistence into the ZODB automatically.

**Example `Concept` structure for a `GauntletQuery`:**

```io
MyQuery := Concept clone do(
    // Inherited slots from Concept
    // ...

    // GauntletQuery slots
    setTrait("GauntletQuery")
    setPrompt("What is the primary component of SystemX?")
    setExpectedResult(Concept get("ComponentY"))
    setQueryType("simple retrieval")
    setAssociatedDistractors(list(Distractor get("DistractorZ")))
)
```

## 4. Generation Process

The `GauntletGenerator` will use a procedural approach based on an input configuration map.

1.  **Schema Definition**: Define a simple ontology (e.g., `Person`, `Location`, `Event`; `worksAt`, `locatedIn`).
2.  **Graph Generation**:
    -   Create a set of `Concept` instances for the nodes (e.g., "Alice", "Bob", "MegaCorp", "London").
    -   Create relationships between them according to the schema (e.g., "Alice `worksAt` MegaCorp").
    -   Store these in a `BenchmarkGraph` object.
3.  **Query and Distractor Generation**:
    -   For each relationship, generate a simple retrieval query (e.g., "Where does Alice work?").
    -   Generate multi-hop queries by traversing the graph.
    -   For each query, generate a plausible but incorrect `Distractor` (e.g., "Alice `worksAt` OmniCorp").
4.  **Persistence**:
    -   Use `TelosConceptRepository` to `save` all generated `Concept`s (`BenchmarkGraph`, `GauntletQuery`, `Distractor`) to the ZODB.

## 5. Integration with HRC and Validation Harness

The master validation harness (`validation.io`) will be responsible for executing the Gauntlet.

1.  **Load**: The harness will load the `GauntletGenerator` and instruct it to `generate` a new benchmark (or load a pre-existing one).
2.  **Execute**: It will iterate through each `GauntletQuery`. For each query, it will:
    -   Inject the associated `Distractor`s into the HRC's working memory via `TelosFederatedMemory`.
    -   Submit the query `prompt` to the `TelosHRC`'s `startCognitiveCycle` method.
    -   Await the result from the HRC.
3.  **Evaluate**:
    -   Compare the HRC's result with the `expectedResult` in the `GauntletQuery`.
    -   Create a `GauntletRunResult` object with the outcome and telemetry.
4.  **Report**: After all queries are run, the harness will aggregate the `GauntletRunResult`s and compute overall metrics (e.g., accuracy percentage, average latency). The results will be printed in a structured report.
