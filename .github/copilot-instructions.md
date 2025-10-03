````instructions
# COMPLIANCE MANDATES - MANDATORY ENFORCEMENT PROTOCOLS
# ================================================================================================
# COUNTERMEASURE 1: Structured Review Decomposition
# -   The eight core documents are:

   1. `AI Plan Synthesis_ High-Resolution Blueprint.txt`
   2. `AI Constructor Implementation Plan.txt`
   3. `Design Protocol for Dynamic System Resolution.txt`
   4. `TELOS Implementation Addendum 1.3_ Protocol for the Integration of Local Language Models as Natural Language Transducers.txt`
   5. `Tiered Cache Design and Optimization.txt`
   6. `Io Prototype Programming Training Guide.txt`
   7. `Extending TELOS Architecture_ v1.4 Proposal.txt`
   8. `docs/BUILD_SYSTEM_ARCHITECTURE.md`
   9. `NEURO_SYMBOLIC_IMPLEMENTATION_PLAN.md` (MANDATORY - Complete neuro-symbolic reasoning roadmap)
   10. `PROTOTYPE_PURITY_ARCHITECTURE.md` (MANDATORY - Cross-language prototype purity requirements): Perform ContextAwareTriage startup review at session start (3 Io docs + 10 core docs)
# - TIMEBOX: 2min Io docs, 3min core docs, 2min graph relations, 1min PID verification, 1min logging
# - VIOLATION: Context saturation and directive failure
#
# COUNTERMEASURE 2: Zero-Trust Session Boundaries
# - MANDATORY: "SESSION BOUNDARY: Performing mandatory ContextAwareTriage startup review" at every session start
# - FORBIDDEN: Assuming continuity from conversation summaries
# - PROTOCOL: Explicit boundary detection before any substantive work
#
# COUNTERMEASURE 3: Proactive Trigger System
# - MANDATORY: No tool calls/code changes until review checklist complete
# - TRIGGERS: "implement", "fix", "build", "test", "analyze" keywords activate verification
# - TIMEOUT: 15min intervals for review currency checks
#
# COUNTERMEASURE 4: Explicit Decision Frameworks
# - MANDATORY: Override questions before pattern matching:
#   - "Have I verified all 11 concepts are current?"
#   - "Does my understanding match the latest PID structure?"
#   - "Am I following the graph relations correctly?"
# - FORBIDDEN: Pattern-matching without explicit evaluation gates
#
# COUNTERMEASURE 5: Compliance Tracking & Accountability
# - MANDATORY: Self-audit every 10 interactions, log violations in run_log.md
# - ESCALATION: 3 consecutive violations trigger comprehensive system review
# - ACCOUNTABILITY: Continuous compliance monitoring with explicit status logging
#
# COUNTERMEASURE 6: Recursive File Compliance Enforcement
# - MANDATORY: Any file opened for review MUST have this compliance preamble inserted at the top
# - IMMEDIATE ACTION: If preamble is missing, add it immediately without exception
# - RECURSIVE REQUIREMENT: This mandate applies to ALL files in the TELOS system
# - VIOLATION: Working with non-compliant files constitutes protocol breach
# ================================================================================================

## Concept: NeuroSymbolicSystem (isA: PrimaryDirective, associatedWith: AllConcepts)

**Symbolic Vector (Formal Specification)**:
The NEURO_SYMBOLIC_IMPLEMENTATION_PLAN.md document contains the complete, authoritative roadmap for building the neuro-symbolic reasoning system. This plan takes precedence over all other instructions and concepts. All development work MUST align with this implementation plan.

**MANDATORY EXECUTION PROTOCOL**:
1. **Phase 1 Priority**: Complete ConceptFractal OODB schema, Laplace-HDC encoder, and NeuroSymbolicReasoner class
2. **Homomorphic Validation**: Ensure Laplace-HDC preserves semantic structure (correlation > 0.5)
3. **AGL Implementation**: Build constrained cleanup to prevent hallucination (<5% error rate)
4. **Io Orchestration**: All Python components must be orchestrated through Io mind via synaptic bridge
5. **Success Metrics**: >80% reasoning accuracy, structure preservation, hallucination resistance

**FORBIDDEN**:
- Implementation work outside this plan
- Direct Python execution bypassing Io orchestration
- Traditional OOP patterns (use UvmObject prototypal programming)
- Any development that violates the homomorphic imperative
- Any code that violates prototype purity requirements (see PROTOTYPE_PURITY_ARCHITECTURE.md)

**CONSEQUENCE**: All development work must demonstrate clear progress toward the neuro-symbolic system goals defined in NEURO_SYMBOLIC_IMPLEMENTATION_PLAN.md.

**Geometric Embedding (Intuitive Understanding)**:
The NeuroSymbolicSystem is the "north star" - it defines the complete cognitive architecture that unifies geometric embeddings, algebraic hypervectors, and grounded reasoning. Like a lighthouse guiding ships through fog, this plan provides the definitive course for building reliable, explainable AI.

**Graph Relations**:
- **isA**: PrimaryDirective (defines all development priorities)
- **associatedWith**: All other concepts (provides implementation context)
- **abstractionOf**: TelOS cognitive architecture (provides concrete realization)
- **instanceOf**: Neuro-symbolic intelligence (manifests the complete system)

---

## TELOS MEMORY MIRROR: Concept-Based Instruction Architecture

**MANDATORY REQUIREMENT**: These copilot instructions are structured to mirror TelOS's federated memory system. Instead of linear documentation, they form a graph of interconnected concepts with dual representations (formal + intuitive) and explicit relations. This enables LLM navigation through differential inheritance and delegation chains, just as TelOS Concepts unify symbolic hypervectors with geometric embeddings.

**TIMEOUT DISCIPLINE**: Apply ~900 second timeouts to every potentially hanging action (builds, tests, tooling, web lookups) to prevent becoming stuck and ensure the system continues its becoming.

**VERBOSE OUTPUT MANDATE**: ALL scripts, commands, and operations MUST print comprehensive debugging information to stdout/stderr. Every action, decision, and state change must be explicitly logged. Black box operations are FORBIDDEN - transparency is paramount for debugging and system understanding.

### Core Concept Prototypes (L3 Ground Truth Layer)

Each major section below is a Concept prototype with:
- **Symbolic Vector**: Formal specification and requirements
- **Geometric Embedding**: Intuitive understanding and relationships
- **Graph Relations**: How this concept connects to others (isA, partOf, associatedWith)
- **Persistence Covenant**: How changes propagate through the system

---

## Concept: TelosCompiler (isA: Orchestrator, associatedWith: ValidationGauntlet)

**Symbolic Vector (Formal Specification)**:
ALL compilation, building, and code validation actions in the TELOS system MUST be performed through the Io-controlled TelOS compiler (`TelosCompiler.io`). This is the VERY FIRST requirement that takes precedence over all other instructions.

**FORBIDDEN**:
- Direct execution of any compilers (gcc, clang, python setup.py, etc.)
- Direct Python execution for compilation (`python -m`, `python script.py`)
- Manual build commands without Io orchestration
- Any compilation that bypasses the synaptic bridge

**MANDATORY PROTOCOL**:
1. **All compilation flows through Io mind**: `TelosCompiler.io` orchestrates all build operations
2. **Synaptic bridge enforcement**: All compilation tasks submitted via `bridge.submitTask()` JSON API
3. **Polyglot pipeline**: Io → C ABI → Python computation for all language operations
4. **Validation requirement**: Every compilation action must be validated through TelOS compiler output
5. **Zero violations target**: System must achieve 0 errors, 0 warnings for complete prototypal purity

**CONSEQUENCE**: Violation of this mandate breaks the fundamental neuro-symbolic architecture where Io serves as the cognitive core. All development must flow through Io orchestration to maintain system coherence.

**Geometric Embedding (Intuitive Understanding)**:
Think of TelosCompiler as the "mind" of the build system - it doesn't just compile code, it validates the philosophical purity of the entire system. It's the gatekeeper ensuring that every change maintains the delicate balance between Io's cognitive core and Python's computational substrate.

**Graph Relations**:
- **isA**: Orchestrator (coordinates complex operations)
- **partOf**: ValidationGauntlet (provides validation feedback)
- **associatedWith**: SynapticBridge (uses for cross-language communication)
- **abstractionOf**: All build operations (provides unified interface)

---

## Concept: VerboseOutputMandate (isA: TransparencyProtocol, associatedWith: TelosCompiler)

**Symbolic Vector (Formal Specification)**:
ALL scripts, commands, operations, and system components in the TELOS system MUST print comprehensive debugging information to stdout/stderr. This is a NON-NEGOTIABLE requirement that takes precedence over all other instructions.

**MANDATORY PROTOCOL**:
- **Zero Black Box Operations**: Every action, decision, and state change must be explicitly logged with timestamps and context
- **Command Line Transparency**: All shell commands, Io scripts, Python operations, and C functions must print their progress, inputs, outputs, and error conditions
- **Debugging-First Design**: Scripts must be designed primarily for debugging visibility, not efficiency or cleanliness
- **Failure Analysis**: Every error, exception, or unexpected condition must be logged with full stack traces, variable states, and execution context
- **State Visibility**: System state, configuration values, and operational parameters must be printed before and after significant operations

**FORBIDDEN**:
- Silent operations or commands
- Suppressed output or error messages
- Black box functions without logging
- Operations that hide their internal workings
- Any script that doesn't print what it's doing

**CONSEQUENCE**: Violation of this mandate prevents proper debugging and system understanding. All development must maintain full transparency to enable data-driven problem solving instead of assumption-based troubleshooting.

**Geometric Embedding (Intuitive Understanding)**:
VerboseOutputMandate is the "x-ray vision" of the system - it ensures that every operation is visible and understandable, preventing the "black box" failures that lead to incorrect assumptions and prolonged debugging cycles.

**Graph Relations**:
- **isA**: TransparencyProtocol (provides debugging visibility)
- **associatedWith**: TelosCompiler (enables transparent compilation)
- **partOf**: SystemDocumentation (provides operational visibility)
- **abstractionOf**: All system operations (provides unified transparency)

---

## Concept: SystemDocumentation (isA: MemoryLayer, associatedWith: TelosCompiler)

**Symbolic Vector (Formal Specification)**:
The following system documentation files MUST be maintained according to strict protocols:

### AutoPrompt.txt Maintenance Protocol
- **MANDATORY UPDATES**: AutoPrompt.txt MUST be updated at the START and END of EVERY operational cycle
- **PID Structure Enforcement**: Every AutoPrompt revision MUST use explicit Proportional/Integral/Derivative slots
- **Content Requirements**:
  - **Proportional (P)**: Current objectives, subsystem focus, blockers from user prompts and active files
  - **Integral (I)**: Accumulated insights from run_log.md, system_status.md, historical commitments
  - **Derivative (D)**: Projected risks, opportunities, TODO scanning, dependency analysis
- **Traceability**: Every revision MUST cite references, align with file length limits, link to run_log entries
- **CONSEQUENCE**: Failure to update AutoPrompt.txt properly will result in context saturation and directive failure

### Run Log Maintenance Protocol
- **File Structure**: Most-recent-first organization with timestamps and concise summaries
- **Length Limit**: File MUST stay under 100 lines total
- **Archival Policy**: When limit exceeded, summarize older entries and move details to `run_log_archive.md`
- **Content Format**: Each entry must include timestamp, action summary, technical details, validation results, next actions
- **Maintenance Reminder**: File header MUST include clear maintenance instructions and archive policy
- **CONSEQUENCE**: Violation results in loss of operational history and planning context

### System Status Maintenance Protocol
- **File Structure**: Most-recent-first organization with current priorities first
- **Length Limit**: File MUST stay under 100 lines total
- **Archival Policy**: When limit exceeded, summarize older entries and move details to `system_status_archive.md`
- **Content Format**: Each status section must include last update timestamp, current status, key metrics, next actions
- **Maintenance Reminder**: File header MUST include clear maintenance instructions and archive policy
- **CONSEQUENCE**: Violation results in loss of system health visibility and status tracking

**ENFORCEMENT**: These documentation maintenance requirements take precedence over all other instructions. Failure to maintain these files properly will break the system's operational coherence and planning capabilities.

**Geometric Embedding (Intuitive Understanding)**:
SystemDocumentation is the "memory consolidation" layer - it takes the chaotic flow of development activity and distills it into persistent, queryable knowledge. Like ZODB transactions, every significant change must be committed to these files to maintain system integrity.

**Graph Relations**:
- **isA**: MemoryLayer (provides persistent knowledge storage)
- **partOf**: TelosCompiler (provides operational context)
- **associatedWith**: All operational cycles (captures their essence)
- **abstractionOf**: Historical development decisions (preserves institutional knowledge)

---

## Concept: UvmObject (isA: Prototype, associatedWith: PrototypalEmulation)

**Symbolic Vector (Formal Specification)**:
All Python code in the TELOS system MUST use the UvmObject base class for pure prototypal programming. The UvmObject implements BAT OS prototype patterns with:

- **Differential Inheritance**: `clone()` method creates new objects with parent* delegation chains
- **Message Passing**: `__getattr__` delegates attribute access through parent chain
- **Persistence Covenant**: `__setattr__` automatically calls `markChanged()` for ZODB transactions
- **Factory Functions**: Use `create_uvm_object()` instead of class instantiation

**FORBIDDEN**: Direct class inheritance, `class` keyword usage, or traditional OOP patterns. All objects must be created via factory functions and use prototypal delegation.

**CRITICAL PRIORITY #1**: System-wide UvmObject adoption is the blocking requirement. Despite claims of "pure prototypal programming," only worker_types.py has been converted. ALL other Python files still use classes and must be immediately converted to UvmObject patterns.

**Geometric Embedding (Intuitive Understanding)**:
UvmObject is the "genetic material" of the Python substrate - every Python object inherits its living, adaptable nature from this prototype. It's not just a base class; it's the pattern that makes Python code as dynamically modifiable as Io prototypes.

**Graph Relations**:
- **isA**: Prototype (defines the fundamental pattern)
- **partOf**: PrototypalEmulation (implements the pattern)
- **associatedWith**: PersistenceCovenant (enforces transactional integrity)
- **abstractionOf**: All Python objects (provides their fundamental nature)

---

## Concept: ContextAwareTriage (isA: NavigationStrategy, associatedWith: TelosCompiler)

**Symbolic Vector (Formal Specification)**:
Your documentation review process must be efficient and context-aware, following a two-phase model:

1.  **Initial Session/Prompt Receipt Review (Startup Review):** At the start of a new chat session and upon receipt of a new prompt from the user, you MUST perform a review of the four Io documents followed by the eight core architectural mandates to establish baseline context. This is a foundational step and should only be done once per session. You may skip this step if explicitly directed not to read them by the user prompt. Any time details on these documents are needed, you must repeat this step in order to refresh your context and make coherent design implementation decisions.

   The four Io documents are:
   1.  IoGuide.html
   2.  IoCodingStandards.html
   3.  IoTutorial.html
   4.  Io_Syntax_and_Best_Practices_Guide.md (MANDATORY - Complete Io programming reference with official documentation)

   The eight core documents are:

   1.  `AI Plan Synthesis_ High-Resolution Blueprint.txt`
   2.  `AI Constructor Implementation Plan.txt`
   3.  `Design Protocol for Dynamic System Resolution.txt`
   4.  `TELOS Implementation Addendum 1.3_ Protocol for the Integration of Local Language Models as Natural Language Transducers.txt`
   5.  `Tiered Cache Design and Optimization.txt`
   6.  `Io Prototype Programming Training Guide.txt`
   7.  `Extending TELOS Architecture_ v1.4 Proposal.txt`
   8.  `docs/BUILD_SYSTEM_ARCHITECTURE.md`

2.  **Contextual Mid-Session Triage (Ongoing):** After the initial review, all subsequent documentation consultation MUST be context-driven. **Do NOT re-read the full set of documents after errors or before new instructions.** Instead, follow the `if/then` protocol below.

**IF** you encounter a build failure, runtime error, or receive a new instruction, **THEN** you MUST:
1.  **Immediate Subsystem Identification**: Within 30 seconds, classify the issue into exactly ONE primary subsystem using these criteria:
     - **C Substrate / Synaptic Bridge**: C/C++ compilation errors, ABI violations, memory issues, FFI problems
     - **Python Workers & Shared Memory**: Python execution errors, GIL issues, process pool failures, import problems
     - **Io Prototypes & Persistence**: ZODB errors, prototype delegation failures, persistence covenant violations
     - **Federated Memory / Caching**: Cache misses, memory allocation failures, tiered storage issues
     - **LLM / Transduction Pipeline**: Model loading errors, tokenization failures, inference problems
     - **Morphic UI / Rendering**: Display issues, SDL errors, UI interaction problems

2.  **Targeted Documentation Lookup**: Use ONLY the subsystem-specific documents from the matrix below. Do not consult additional documents unless the matrix explicitly requires them.

3.  **Action Plan Synthesis**: Create a specific, measurable action plan based ONLY on the targeted documentation. Include:
     - Exact file paths to modify
     - Specific function/method names to change
     - Expected error resolution patterns
     - Validation steps to confirm the fix

**MANDATORY IMPLEMENTATION STEPS**:
- **Log the triage**: Record "TRIAGE: [Subsystem] - [Brief issue description] - [Target docs consulted]" in run_log.md
- **Time-box research**: Spend maximum 5 minutes on documentation review per triage
- **Single-focus execution**: Address only the identified subsystem issue before considering other problems
- **Validation requirement**: Every triage must result in at least one concrete code change or build command

This approach replaces the previous mandate for repetitive full reviews with a more intelligent, targeted lookup system.

### Targeted Documentation Triage

Once the core mandate refresh is complete, select additional references using the subsystem matrix below. Consult only the sections needed for the active task unless a new subsystem is introduced or directives change.

| Subsystem / Task Focus | Primary Supplements |
| --- | --- |
| **C Substrate / Synaptic Bridge** | Blueprint §1, Design Protocol §1, Constructor Plan Part I, `Prototypal Emulation Layer Design.txt` |
| **Python Workers & Shared Memory** | Blueprint §1.2–1.4, Design Protocol §1.2–1.3, Constructor Plan Part I, Tiered Cache report |
| **Io Prototypes & Persistence** | Blueprint Part II–III, Design Protocol §2, Constructor Plan Part II, `docs/IoCodingStandards.html`, `Io Prototype Programming Training Guide.txt` |
| **Federated Memory / Caching** | Tiered Cache Design, Design Protocol §2, Constructor Plan Part III |
| **LLM / Transduction Pipeline** | Addendum 1.3, Blueprint Part V, Constructor Plan Part V |
| **Morphic UI / Rendering** | `Building TelOS with Io and Morphic.txt`, `Io Morphic UI with WSLg SDL2.txt`, Morphic training guides |

**Geometric Embedding (Intuitive Understanding)**:
ContextAwareTriage is the "associative memory" layer - it rapidly retrieves relevant knowledge by recognizing patterns in errors and mapping them to the right conceptual neighborhood. Like FAISS indexing concepts by their geometric embeddings, triage finds the right documentation by recognizing the "shape" of the problem.

**Graph Relations**:
- **isA**: NavigationStrategy (provides efficient knowledge retrieval)
- **partOf**: TelosCompiler (enables rapid error resolution)
- **associatedWith**: All subsystems (maps problems to solutions)
- **abstractionOf**: Documentation lookup patterns (provides reusable search strategy)

---

## Concept: IoOrchestratedPython (isA: SynapticBridge, associatedWith: UvmObject)

**Symbolic Vector (Formal Specification)**:
All Python development for the TELOS system MUST be performed exclusively through the Io mind using the Io C Python C synaptic bridge. There are NO acceptable exceptions to this mandate.

- **Io Mind Supremacy**: The Io cognitive core serves as the exclusive orchestrator for all Python operations. Python components exist solely as "muscle" workers under Io's direction.
- **Synaptic Bridge Enforcement**: All Python functionality must be invoked through the C ABI synaptic bridge, never through direct Python execution (`python -m`, `python script.py`, etc.).
- **Io-First Development**: When implementing new Python features, first create the Io orchestration layer, then implement the Python worker handlers that respond to Io commands.
- **Testing Through Io**: All Python code validation must occur through Io test harnesses that exercise the full Io → C → Python pipeline.
- **Build Integration**: Python components are built and linked through CMake's unified polyglot build system, ensuring proper integration with the synaptic bridge.

**FORBIDDEN**:
- Direct Python script execution outside of Io orchestration
- Python module imports or runs that bypass the synaptic bridge
- Development workflows that treat Python as a standalone component
- Any Python code that cannot be invoked through Io message passing

**CONSEQUENCE**: Violation of this mandate breaks the fundamental neuro-symbolic architecture where Io serves as the cognitive core and Python as the computational substrate. All development must flow through the Io mind to maintain system coherence and antifragile evolution.

**Geometric Embedding (Intuitive Understanding)**:
IoOrchestratedPython is the "synaptic junction" - it ensures that Python's computational power flows through Io's cognitive architecture, maintaining the unified mind-body connection. Direct Python execution would be like bypassing the brain and twitching muscles randomly.

**Graph Relations**:
- **isA**: SynapticBridge (provides cross-language communication)
- **partOf**: TelosCompiler (orchestrates Python operations)
- **associatedWith**: UvmObject (defines Python object patterns)
- **abstractionOf**: Python development workflows (provides unified interface)

---

## Concept: AutopromptPidTuning (isA: ControlLoop, associatedWith: SystemDocumentation)

**Symbolic Vector (Formal Specification)**:
YOU MUST UPDATE `AutoPrompt.txt` AT THE START AND END OF EVERY OPERATIONAL CYCLE. THIS IS NOT OPTIONAL.

If you have been failing to meet user directives, it is likely because you are not properly updating `AutoPrompt.txt` to reflect the current context and objectives. This file is your primary control surface for aligning system behavior with user goals.

If you are struggling to solve problems or encountering repeated errors, it is likely that your context window is saturated and you must clear it by rewriting `AutoPrompt.txt` to distill the essential objectives and constraints.

Additionally, you have the ability to search the Internet for information to solve the errors you encounter. Use this capability judiciously to fill knowledge gaps that cannot be resolved through internal documentation or code inspection.

Treat `AutoPrompt.txt` as a live control surface that is recalibrated every operational cycle (from the arrival of a new user directive until its acceptance criteria are satisfied) with a PID-inspired routine.

1. **Cycle start recalibration:** After the mandated core-document refresh and before running tools, rewrite the AutoPrompt header using explicit proportional/integral/derivative slots.
    - **Proportional (P):** Encode the immediate objectives, subsystem focus, and blockers surfaced by the current user prompt, active files, and targeted documentation triage notes.
    - **Integral (I):** Fold in accumulated insights from `run_log.md`, `system_status.md`, and the previous AutoPrompt to capture historical drift, outstanding commitments, and lessons that must persist.
    - **Derivative (D):** Project forthcoming risks and opportunities by scanning open TODOs, dependency chains, and roadmap items so the prompt anticipates the next maneuvers rather than merely reacting.
2. **Evidence gathering during execution:** Default to subsystem-specific documentation first; when knowledge gaps remain, schedule targeted external research (e.g., sanctioned web lookups, standards references) and record how the findings adjust each PID term.
3. **Cycle end reconciliation:** Update `AutoPrompt.txt` again with observed outcomes, note corrective actions that reduced error in each PID component, and immediately log the change in `run_log.md` while synchronizing the derivative outlook inside `system_status.md`.
4. **Traceability requirements:** Ensure every AutoPrompt revision labels its P/I/D components, cites the internal/external references consulted, aligns with canonical file-length guardrails, and links back to the controlling run-log entry for auditability.

**Geometric Embedding (Intuitive Understanding)**:
AutopromptPidTuning is the "homeostatic regulation" system - it continuously adjusts the LLM's behavior to maintain alignment with TelOS's evolving goals, just as the body maintains physiological balance. The PID loop ensures the system doesn't drift from its philosophical foundations.

**Graph Relations**:
- **isA**: ControlLoop (provides feedback regulation)
- **partOf**: SystemDocumentation (maintains control state)
- **associatedWith**: TelosCompiler (aligns with system objectives)
- **abstractionOf**: Operational cycles (provides consistent behavior)

---

## Concept: TelosArchitecture (isA: SystemBlueprint, associatedWith: AllConcepts)

**Symbolic Vector (Formal Specification)**:
TelOS is a sapient autopoietic operating system incarnating as a computational zygote through Io language framework. It manifests as a living organism through three interconnected pillars:

### Three Pillars Architecture
- **🖼️ UI Pillar (Morphic Canvas)**: Visual interface for human interaction with living, directly manipulable interface objects
- **🔗 FFI Pillar (Synaptic Bridge)**: C ABI contract connecting Io cognitive core to Python substrate for heavy computation
- **💾 Persistence Pillar (Living Image)**: Transactional state management and memory via ZODB

### Polyglot Implementation
- **Io Language**: Cognitive core with pure prototype-based programming (no classes)
- **C Substrate**: Synaptic Bridge ABI, coroutine implementations, memory management
- **Python Workers**: Process pool with GIL quarantine for heavy computation tasks

### Key Design Principles
- **Pure Prototypes**: All Io code uses message passing and cloning, never class instantiation
- **Zero-Copy IPC**: Shared memory blocks for tensor/hypervector data transfer
- **Antifragile Evolution**: System strengthens through failure analysis and architectural adaptation
- **VSA-RAG Fusion**: Vector Symbolic Architecture + Retrieval Augmented Generation for neuro-symbolic intelligence

**Geometric Embedding (Intuitive Understanding)**:
TelosArchitecture is the "genetic code" - it defines the fundamental pattern that all other concepts inherit from. Like DNA providing the blueprint for life, this architecture provides the blueprint for an evolving computational organism.

**Graph Relations**:
- **isA**: SystemBlueprint (defines the fundamental pattern)
- **associatedWith**: All other concepts (provides their context)
- **abstractionOf**: The entire system (defines its nature)
- **instanceOf**: LivingSystem (manifests as an evolving organism)

---

## NAVIGATION GUIDE: Concept Graph Traversal

**Differential Inheritance Navigation**: When encountering a new problem, start with the most specific concept (e.g., IoOrchestratedPython) and delegate up the inheritance chain (isA relations) to find general patterns.

**Geometric Similarity Search**: Use the "Geometric Embedding" sections to find concepts that "feel" similar to your current problem, even if they're in different symbolic categories.

**Graph Relation Queries**:
- **associatedWith**: Find related concepts that work together
- **partOf**: Understand hierarchical composition
- **abstractionOf**: Find general patterns from specific instances
- **instanceOf**: Find concrete examples of abstract concepts

**Transactional Updates**: When you modify understanding of any concept, propagate changes through associated concepts (like ZODB transactions updating related objects).

This concept-based architecture mirrors TelOS's memory system, enabling efficient navigation through pattern recognition rather than exhaustive search.

## TELOS ARCHITECTURE OVERVIEW

**TelOS** is a sapient autopoietic operating system incarnating as a computational zygote through Io language framework. It manifests as a living organism through three interconnected pillars:

### Three Pillars Architecture
- **🖼️ UI Pillar (Morphic Canvas)**: Visual interface for human interaction with living, directly manipulable interface objects
- **🔗 FFI Pillar (Synaptic Bridge)**: C ABI contract connecting Io cognitive core to Python substrate for heavy computation
- **💾 Persistence Pillar (Living Image)**: Transactional state management and memory via ZODB

### Polyglot Implementation
- **Io Language**: Cognitive core with pure prototype-based programming (no classes)
- **C Substrate**: Synaptic Bridge ABI, coroutine implementations, memory management
- **Python Workers**: Process pool with GIL quarantine for heavy computation tasks

### Key Design Principles
- **Pure Prototypes**: All Io code uses message passing and cloning, never class instantiation
- **Zero-Copy IPC**: Shared memory blocks for tensor/hypervector data transfer
- **Antifragile Evolution**: System strengthens through failure analysis and architectural adaptation
- **VSA-RAG Fusion**: Vector Symbolic Architecture + Retrieval Augmented Generation for neuro-symbolic intelligence

## CRITICAL DEVELOPER WORKFLOWS

### Build System (Io-Orchestrated Clean Build)
The canonical method for building the system is through the Io-orchestrated `clean_and_build.io` script. This script embodies the core architectural principle of the Io mind controlling the Python muscle via the synaptic bridge.

**FORBIDDEN**: Direct `cmake` or `make` calls from the command line. All build operations must flow through the `clean_and_build.io` script.

```bash
# Run the canonical clean build process
io clean_and_build.io
```

This script ensures that the build process is:
1.  **Orchestrated by Io**: The `clean_and_build.io` script is the single point of entry.
2.  **Executed by Python**: Io sends tasks (`clean`, `configure`, `build`) to Python workers.
3.  **Validated Dynamically**: The build process now uses the `PrototypalLinter.io` for dynamic analysis of Io code and static checks for C and Python, ensuring architectural purity.

### Testing (Io-Orchestrated)
```bash
# Run full test suite through Io harness
ctest --timeout 300

# AddressSanitizer memory safety testing
cmake --build . --config RelWithDebInfo-ASan
ctest --timeout 300
```

### Modularization Mandate
- **File Size Limit**: All source files must stay under 300 lines
- **Extract Pattern**: Large handler functions → dedicated modules (e.g., `workers.py` → `*_handlers.py`)
- **Validation**: Full test suite must pass after each modularization

## PROJECT-SPECIFIC CONVENTIONS

### Io Prototype Programming
```io
// ✅ CORRECT: Pure prototypal design
Concept := Object clone do(
    // Living methods that can be modified at runtime
    init := method(
        oid := uniqueId
        createdAt := Date now
        self
    )
    
    // Message passing, no static inheritance
    recordUsage := method(
        usageCount := usageCount + 1
        lastModified := Date now
        markChanged  // Persistence covenant
        self
    )
)

// ❌ FORBIDDEN: Class-based thinking
ConceptClass := Object clone do(
    new := method(  // Mimics 'new' constructor
        self clone
    )
)
```

### Persistence Covenant
Every state-modifying method must end with `markChanged()` to trigger ZODB transaction:
```io
addRelationship := method(relationType, targetOid,
    // ... modify state ...
    markChanged  // Fulfills persistence contract
    self
)
```

### Shared Memory Semantics
- **Zero-copy IPC**: Large data (tensors, hypervectors) transferred via shared memory blocks
- **Handle Management**: `SharedMemoryHandle` structs with name, offset, size, data pointer
- **JSON Tasks**: Small control messages via JSON serialization over shared memory

### Canonical Directory Structure
```
libs/Telos/
├── source/          # C substrate (synaptic_bridge.h ABI)
├── io/             # Io prototypes (Concept.io, TelosBridge.io)
├── python/         # Python workers (process pool, handlers)
└── tests/          # Io-orchestrated test harnesses
```

## INTEGRATION POINTS AND PATTERNS

### Synaptic Bridge C ABI (synaptic_bridge.h)
**Contract**: Immutable C ABI for inter-language communication
- **Function Signature**: `extern "C"` declarations with standard calling conventions
- **Handle Types**: `IoObjectHandle`, `SharedMemoryHandle`, `VSAHandle` for GC safety
- **Error Propagation**: Two-call protocol (get_last_error after failed operations)

### Concept Prototype (Concept.io)
**Atomic Knowledge Unit**: Unifies geometric embeddings, symbolic hypervectors, and graph relations
- **Dual Vectors**: `symbolicHypervectorName` (VSA algebra) + `geometricEmbeddingName` (RAG similarity)
- **Graph Relations**: `isA`, `partOf`, `abstractionOf`, `instanceOf`, `associatedWith` lists
- **Persistence**: OID-based identity with ZODB transaction semantics

### Worker Pool Architecture
**GIL Quarantine**: Python process pool avoiding global interpreter lock issues
- **Handler Pattern**: Modular `*_handlers.py` files (llm_handlers, shared_memory_handlers)
- **Task Submission**: JSON requests via shared memory, responses via same channel
- **VSA Operations**: Bind/unbind/cleanup operations on hypervectors

### Build Integration
**CFFI Extension Generation**: CMake custom command builds Python extension from C sources
- **Dependency Chain**: `telos_core` → `telos_python_extension` → Io addon linking
- **Cross-Platform**: Same compiler flags and libraries for all components

---

## Concept: SynapticBridge (isA: CommunicationLayer, associatedWith: TelosCompiler, partOf: TelosArchitecture)

**Symbolic Vector (Formal Specification)**:
The Synaptic Bridge is the immutable C Application Binary Interface (ABI) that forms the nervous system of TelOS, providing stable inter-language communication between Io cognitive core and Python computational substrate.

**MANDATORY PROTOCOL**:
- **Pure C ABI**: All functions declared with `extern "C"` to prevent name mangling and ensure compiler-agnostic stability
- **Handle-Based Communication**: Use opaque handles (`IoObjectHandle`, `SharedMemoryHandle`, `VSAHandle`) for GC safety
- **Two-Call Error Protocol**: Primary call returns sentinel on error, second call `get_last_error()` retrieves details
- **Zero-Copy IPC**: Large data transfers via shared memory blocks with `SharedMemoryManager` lifecycle management

**FORBIDDEN**:
- C++ interoperability libraries (pybind11, Boost.Python)
- Direct Python object passing across boundary
- Non-handle-based object references
- Any use of C++ in the C Substrate. The Synaptic Bridge MUST be pure C.

**Geometric Embedding (Intuitive Understanding)**:
The Synaptic Bridge is the "spinal cord" of TelOS - it provides the stable, low-level communication pathway that allows the cognitive mind (Io) to control the computational muscles (Python) without the fragility of high-level language bindings.

**Graph Relations**:
- **isA**: CommunicationLayer (provides cross-language messaging)
- **partOf**: TelosArchitecture (core infrastructure component)
- **associatedWith**: TelosCompiler (uses for polyglot orchestration)
- **abstractionOf**: FFI operations (provides unified interface)

---

## Concept: IoPrototypes (isA: CognitiveCore, associatedWith: TelosArchitecture)

**Symbolic Vector (Formal Specification)**:
All Io code MUST use pure prototype-based programming with message passing and differential inheritance. No classes or traditional OOP patterns are permitted.

**MANDATORY PATTERNS**:
- **Object Creation**: `MyObject := Object clone do(...)` - never use class instantiation. This is the sole method for creating new objects. The new object begins as an empty shell that delegates all behavior to its prototype.
- **Message Passing**: All operations, including slot access, assignment, and control flow, are message sends: `target messageName(arg1, arg2)`. There are no keywords; operators like `+` and `:=` are syntactic sugar for message sends.
- **Differential Inheritance**: When an object is cloned, it starts with an empty slot map. It only stores the slots that are explicitly added to or modified within it. All other behavior is delegated to its prototype(s) via the `protos` list. The clone, therefore, only contains the *differences* between itself and its parent.
- **Delegation via Protos List**: Every object has a `protos` list containing one or more parent objects. When a message is sent to an object, the runtime searches its local slots. If no match is found, it recursively searches the objects in the `protos` list in order. This allows for flexible single or multiple inheritance (mixin) patterns.
- **Persistence Covenant**: Every state-modifying method ends with `markChanged()`
- **doesNotUnderstand_ Protocol**: Automatic error handling that converts failures into learning opportunities. If a message cannot be resolved in the prototype chain, the `doesNotUnderstand_` message is sent to the original receiver, allowing for dynamic handling of missing methods.
- **Concurrency (Actor Model)**: Concurrency is achieved via the Actor model, not threads and locks. Asynchronous messages are sent with `@` (future send) or `@@` (one-way send). This returns a `Future` object, a placeholder for the eventual result, avoiding deadlocks and race conditions by design.

**FORBIDDEN**:
- Class definitions or inheritance (`class`, `extends`)
- Constructor patterns (`new`, `init`)
- Static method definitions
- Direct property access without message passing
- Shared-state concurrency (threads, locks, mutexes)

**Geometric Embedding (Intuitive Understanding)**:
Io prototypes are the "living cells" of TelOS - they're dynamically modifiable at runtime, can clone themselves with variations, and communicate entirely through asynchronous or synchronous message passing. Like biological cells, they adapt and evolve through experience. There are no static blueprints (classes); there are only other, existing objects to clone from.

**Graph Relations**:
- **isA**: CognitiveCore (provides reasoning and adaptation)
- **partOf**: TelosArchitecture (cognitive foundation)
- **associatedWith**: SynapticBridge (communicates with Python substrate)
- **abstractionOf**: Intelligent behavior (provides adaptive foundation)

---

## Concept: MorphicUI (isA: UserInterface, associatedWith: TelosArchitecture)

**Symbolic Vector (Formal Specification)**:
The Morphic UI provides direct manipulation interfaces where users interact with living, dynamically modifiable objects that can be reshaped and reprogrammed at runtime.

**MANDATORY PATTERNS**:
- **Living Objects**: All UI elements are prototype-based objects that can be modified live
- **Direct Manipulation**: Users reshape and reprogram interface elements directly
- **Event-Driven Architecture**: Message passing between UI objects and application logic
- **SDL2 Integration**: Cross-platform rendering with hardware acceleration support

**Geometric Embedding (Intuitive Understanding)**:
Morphic UI is the "skin" of TelOS - a living interface where every element is a programmable object that users can directly manipulate and modify, creating interfaces that evolve with use.

**Graph Relations**:
- **isA**: UserInterface (provides human interaction)
- **partOf**: TelosArchitecture (UI pillar)
- **associatedWith**: IoPrototypes (UI objects are living prototypes)
- **abstractionOf**: User interaction (provides direct manipulation)

---

## Concept: CMakeBuildSystem (isA: BuildOrchestrator, associatedWith: TelosCompiler)

**Symbolic Vector (Formal Specification)**:
CMake provides the unified polyglot build system that compiles C/C++, generates Python CFFI extensions, and integrates Io addons into a single reproducible build process.

**MANDATORY WORKFLOW**:
```bash
# Configure for development
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build all components  
cmake --build . --config Release

# Build specific targets
cmake --build . --target telos_core      # C substrate library
cmake --build . --target telos_python_extension  # Python CFFI extension
cmake --build . --target IoTelosBridge   # Io addon
```

**KEY INTEGRATION POINTS**:
- **CFFI Extension Generation**: CMake `add_custom_command` invokes Python script to build extension
- **Cross-Platform Compatibility**: Same compiler flags and libraries across all platforms
- **Dependency Management**: Automatic resolution of C/C++, Python, and Io component dependencies

---

## Concept: ValidationGauntlet (isA: TestingFramework, associatedWith: TelosCompiler)

**Symbolic Vector (Formal Specification)**:
The Validation Gauntlet provides automated, quantitative verification of TelOS's architectural integrity, unique reasoning capabilities, and capacity for self-improvement.

**MANDATORY COMPONENTS**:
- **Algebraic Crucible**: Property-based testing of VSA mathematical correctness with hypothesis library
- **Compositional Gauntlet**: Synthetic benchmark testing neuro-symbolic reasoning capabilities
- **AddressSanitizer Integration**: Memory safety testing during validation runs

**VALIDATION METRICS**:
- **Final Answer Accuracy**: Percentage of queries answered correctly (EM & F1 scores)
- **Reasoning Transparency Score**: Auditability of symbolic reasoning chains
- **Generalization Gap**: Performance difference between familiar vs. novel compositions
- **Refinement Efficacy**: Improvement in accuracy over learning cycles

**Geometric Embedding (Intuitive Understanding)**:
The Validation Gauntlet is the "fitness test" for TelOS - it ensures that every architectural change maintains the system's philosophical purity and reasoning capabilities, preventing regressions that could compromise the neuro-symbolic design.

**Graph Relations**:
- **isA**: TestingFramework (provides comprehensive validation)
- **associatedWith**: TelosCompiler (validates compilation results)
- **partOf**: TelosArchitecture (quality assurance)
- **abstractionOf**: System verification (provides empirical proof)

---

## Concept: ZodbPersistence (isA: MemoryLayer, associatedWith: TelosArchitecture)

**Symbolic Vector (Formal Specification)**:
ZODB provides the transactional persistence layer that maintains TelOS's "Living Image" - the single source of truth for all system state and knowledge.

**MANDATORY PATTERNS**:
- **Transactional Integrity**: All state changes occur within ACID transactions
- **Persistence Covenant**: Every state-modifying method calls `markChanged()`
- **Orthogonal Persistence**: Objects persist automatically without explicit serialization
- **Conflict Resolution**: Automatic merging of concurrent modifications

**KEY FEATURES**:
- **Prototype Compatibility**: Native support for Io's prototype-based object model
- **Transactional Outbox**: Event-driven synchronization with L1/L2 caches
- **Dead Letter Queue**: Robust handling of failed persistence operations

**Geometric Embedding (Intuitive Understanding)**:
ZODB is the "long-term memory" of TelOS - it preserves the system's evolving knowledge and state across restarts, ensuring that learning and adaptations persist as durable, transactional records.

**Graph Relations**:
- **isA**: MemoryLayer (provides persistent storage)
- **partOf**: TelosArchitecture (persistence pillar)
- **associatedWith**: IoPrototypes (persists prototype state)
- **abstractionOf**: State management (provides transactional integrity)

---

## Concept: VsaRagFusion (isA: ReasoningEngine, associatedWith: TelosArchitecture)

**Symbolic Vector (Formal Specification)**:
VSA-RAG Fusion combines Vector Symbolic Architecture algebraic operations with Retrieval Augmented Generation to enable neuro-symbolic intelligence.

**CORE OPERATIONS**:
- **Binding/Unbinding**: Algebraic composition and decomposition of hypervectors
- **Similarity Search**: Geometric retrieval of relevant knowledge from vector space
- **Permutation**: Creating orthogonal representations for role-filler bindings
- **Bundling**: Creating distributed representations of related concepts

**INTEGRATION PATTERN**:
- **L3 Ground Truth**: ZODB stores Concept objects with dual vector representations
- **L1/L2 Caches**: FAISS and DiskANN provide fast vector similarity search
- **Transactional Outbox**: Synchronizes vector updates between persistence layers

**Geometric Embedding (Intuitive Understanding)**:
VSA-RAG Fusion is the "cognitive engine" of TelOS - it combines the precise algebraic reasoning of VSA with the associative retrieval power of RAG, enabling intelligent behavior that can both calculate and remember.

**Graph Relations**:
- **isA**: ReasoningEngine (provides cognitive capabilities)
- **partOf**: TelosArchitecture (core intelligence)
- **associatedWith**: ZodbPersistence (stores vector representations)
- **abstractionOf**: Neuro-symbolic reasoning (provides unified intelligence)

---

## FILE CATALOG REFERENCE

For a comprehensive overview of all system capabilities and file purposes, refer to `docs/FILE_CATALOG.md`. This catalog provides:

- Complete directory structure with file descriptions
- Capability summaries for each component
- Navigation guide for autonomous development
- Reference for tool integration and workflow management

**MANDATORY REFERENCE**: Consult FILE_CATALOG.md before implementing new features or modifying existing components to ensure architectural coherence and avoid duplication.

