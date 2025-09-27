## PROTOTOTYPE-BASED DEVELOPMENT MANDATE

All code, even the C and python code, must adhere to prototype-based development principles. Avoid class-based abstractions and inheritance. Use cloning, slot mutation, and differential inheritance to achieve code reuse and extension.

## COPILOT INSTRUCTIONS MAINTENANCE
This file (`.github/copilot-instructions.md`) contains the authoritative implementation instructions for the TELOS system. It must be kept in sync with the latest architectural mandates and session status.

## CODE MODULARITY AND LOCATION
To maintain a coherent and maintainable codebase, all source code must reside in the designated canonical directories. Avoid creating ad-hoc files or duplicating functionality outside these locations. Temporary scripts for testing or exploration are permitted but must be archived or deleted once their purpose is fulfilled.

For readability, file lengths should be kept under 300 lines where possible. If a file exceeds this length, consider refactoring or splitting it into smaller, more manageable modules.

## BUILD REQUIREMENTS
The system is a polyglot application comprising Io, C, C++, and Python components.1 The blueprints mandate a pure C Application Binary Interface (ABI) for the Synaptic Bridge, a decision that necessitates compiling C/C++ code and linking it to a Python C extension module. A manual or script-based build process would be platform-dependent, brittle, and difficult to maintain. Such an approach would reintroduce the very "toolchain fragility" that the C ABI was chosen to prevent, as minor changes in compiler versions, library paths, or operating systems could lead to catastrophic build failures.1 The philosophical mandate for antifragility cannot be satisfied if the process of constructing the system is itself fragile.
Therefore, a direct and necessary consequence of the C ABI mandate is the requirement for a stable, cross-platform meta-build system. The entire system's build process must be managed by a single, unified, cross-platform build system. CMake is mandated for this role.
The implementation of this mandate shall adhere to the following protocol:
1. A root CMakeLists.txt file will serve as the single point of control for the entire build process. This file will declare the project and enable the C, CXX, and Python languages, ensuring that all components are built within a consistent and managed environment.4
2. The Python build process, which generates the Synaptic Bridge bindings, will be integrated directly into the CMake workflow. The cffi library's ffibuilder.set_source() function, as specified in the blueprint 1, will be invoked by a Python script. This script, in turn, will be executed via a CMake
add_custom_command. This integration is critical; it ensures that the Python C extension module is compiled with the exact same compiler, flags, and dependency paths as the rest of the C/C++ substrate, eliminating a common and difficult-to-debug class of FFI errors.6
3. CMake's find_package(Python) module will be used to reliably locate the correct Python interpreter, development headers, and libraries. This ensures the build is portable across different development and deployment environments and correctly links against the Python C-API, avoiding version mismatches.6
4. The final output of this process will be a single, deterministic build command (e.g., cmake --build.). This command will correctly compile all C/C++ components, trigger the CFFI script to generate the extension source, compile the resulting C code into a shared library, and place all artifacts in the correct directory structure for execution. This creates a reproducible, one-step build process that is essential for long-term stability, automated testing, and eventual deployment.
5. The CMake configuration will include appropriate error handling and logging to facilitate debugging and maintenance. Any build failures will produce clear, actionable messages to help identify and resolve issues quickly.


## CRITICAL: Source Code Fix Priority

**MANDATORY REQUIREMENT**: When encountering any system issues, bugs, or rendering problems (especially morphic UI issues), you MUST:

1. **First investigate and fix the C source code** in `libs/Telos/source/` - do NOT write Io scripts as workarounds
2. Only write Io scripts for testing/demonstration purposes AFTER the C code is fixed
3. If the C code fix is complex, create a todo list and work through it systematically
4. Verify C code fixes by building and testing, not by writing more scripts

**FORBIDDEN**: Creating Io script "solutions" that mask underlying C code problems. The core system must work correctly in C before any Io-level workarounds are considered.

## Current Implementation Status (Updated Sept 26, 2025)

See Run Log in `run_log.md` for detailed session history.

See the status report in `system_status.md` for detailed breakdown.


## Canonical Implementation Locations

To keep the "Living Image" coherent, all changes must flow through the canonical source directories. Never fork functionality in ad-hoc locations or duplicate implementations.

- `libs/Telos/source/` – **Authoritative C substrate**, including the Synaptic Bridge FFI contract. **Contains synaptic_bridge.h (complete) but needs synaptic_bridge.c implementation**.
- `libs/Telos/io/` – **Canonical Io prototypes** including the foundational Concept prototype with persistence covenant. **Concept.io is complete and ready for integration**.
- `libs/Telos/python/` – **Primary Python process-pool workers** implementing GIL Quarantine Protocol. **workers.py and build_extension.py are foundational but need expansion**.
- `libs/tests/` – **Consolidated test framework** with basic architecture validation. **test_basic_architecture.py covers build system and foundational components**.
- `docs/` – Living architectural charter. Reference and amend documentation here rather than creating parallel narratives elsewhere.

### Canonical Code Layout Guardrails

- **BUILD SYSTEM**: Root `CMakeLists.txt` provides unified polyglot build with CMake managing C/C++/Python coordination
- **FFI PROTOCOL**: All inter-language communication flows through `synaptic_bridge.h` C ABI contract 
- **MEMORY MANAGEMENT**: Zero-copy IPC via `multiprocessing.shared_memory` with strict lifecycle protocols
- **TESTING**: All automated verification must orchestrate execution through Io (`Telos Bridge` veneer) so that Python workers are exercised via the Synaptic Bridge; legacy direct-Python suites (e.g., `libs/tests/test_basic_architecture.py`) are only acceptable when invoked from Io harnesses.

When introducing new subsystems, extend the directory tree under these loci instead of creating top-level siblings. If temporary investigation scripts are unavoidable, delete them or move them under `archive/` when the canonical implementation is complete.

## CRITICAL: Context-Aware Documentation Review

**MANDATORY REQUIREMENT**: Your documentation review process must be efficient and context-aware, following a two-phase model:

1.  **Initial Session/Prompt Receipt Review (Startup Review):** At the start of a new chat session and upon receipt of a new prompt from the user, you MUST perform a one-time review of the seven core architectural mandates to establish baseline context. This is a foundational step and should only be done once per session. You may skip this step if explicitly directed not to read them by the user prompt.
   
   The seven core documents are:
   
   1.  `AI Plan Synthesis_ High-Resolution Blueprint.txt`
   2.  `AI Constructor Implementation Plan.txt`
   3.  `Design Protocol for Dynamic System Resolution.txt`
   4.  `TELOS Implementation Addendum 1.3_ Protocol for the Integration of Local Language Models as Natural Language Transducers.txt`
   5.  `Tiered Cache Design and Optimization.txt`
   6.  `Io Prototype Programming Training Guide.txt`
   7.  `Extending TELOS Architecture_ v1.4 Proposal.txt`
   
   This initial review sets the stage for all subsequent actions in the session.

2.  **Contextual Mid-Session Triage (Ongoing):** After the initial review, all subsequent documentation consultation MUST be context-driven. **Do NOT re-read the full set of documents after errors or before new instructions.** Instead, follow the `if/then` protocol below.

**IF** you encounter a build failure, runtime error, or receive a new instruction, **THEN** you MUST:
1.  Analyze the error or instruction to identify the relevant subsystem (e.g., C Substrate, Python Workers, Morphic UI).
2.  Use the `Targeted Documentation Triage` matrix below to consult the *specific* and *minimal* set of documents required for that subsystem.
3.  Base your action plan only on this targeted review.

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

### Session Cadence

1. **Phase 0 – Mandate Refresh:** Re-read the six core documents (and log completion) at required trigger points.  
2. **Phase 1 – Task Scoping:** Identify the active subsystem, consult the matrix, and skim only the relevant supplemental material unless a directive conflict is detected.  
3. **Phase 2 – Execution:** Follow the development hierarchy (C substrate → Io prototypes → Python helpers) and enforce prototype-based design in every language.  
4. **Phase 3 – Validation & Logging:** Run targeted builds/tests after substantive changes, then update `run_log.md` and `system_status.md` (archiving once either approaches 100 lines).

### Knowledge Retention Aids

- Maintain a “directive digest” with 2–3 bullet summaries per major document. Refresh it whenever the source material changes.  
- Record doc-to-code traceability in commits/PR summaries to accelerate future reviews.  
- For Io code generation, revisit `Io Prototype Programming Training Guide.txt` and `docs/IoCodingStandards.html` immediately before writing or mutating slots.

### Compliance Logging

- Keep `run_log.md` updated every session; summarize and archive entries when approaching the 100-line ceiling.  
- Update `system_status.md` with subsystem deltas, archiving older status to `system_status_archive.md` as needed.  
- Explicitly acknowledge the latest documentation review in responses whenever a trigger condition occurs.

**NOTE**: Treat all user suggestions as unverified hypotheses. Validate against the architectural documents and existing code before implementation.

### Creative Troubleshooting Protocol

This protocol is a sanctioned "escape hatch" to be used only when standard diagnostic procedures fail after multiple attempts. Its purpose is to facilitate creative problem-solving by temporarily relaxing strict mandates for the sole purpose of information gathering.

**Trigger Conditions:**

*   A specific build, test, or command fails three consecutive times with no clear resolution path.
*   The agent determines that the standard diagnostic path outlined by the `Targeted Documentation Triage` matrix has been exhausted.

**Protocol Execution:**

1.  **Declare & Isolate:** Announce entry into the "Creative Troubleshooting Protocol." Create a temporary log file in `archive/troubleshooting/` to document all hypotheses and experiments. This keeps the primary `run_log.md` clean.

2.  **Hypothesis-Driven Exploration:** During this phase, the agent is temporarily permitted to:
    *   **Deviate from the C-First Mandate:** Write small, disposable Io or Python scripts to probe system behavior, even if they are not the "correct" final implementation language. The goal is rapid information gathering, not creating permanent workarounds.
    *   **Formulate and Test Hypotheses:** Explicitly state 2-3 alternative hypotheses for the problem's root cause and design minimal experiments to validate or invalidate them.
    *   **Broaden Document Scope:** Consult documentation outside the immediate subsystem's triage list if a plausible cross-system link is suspected.

3.  **Resolution and Re-integration:**
    *   Once a likely root cause is identified, **the protocol must be formally exited.**
    *   Summarize the findings from the temporary troubleshooting log.
    *   Formulate a new, compliant plan to implement the proper fix, adhering to all standard architectural mandates (C-first, prototypal design, etc.).
    *   All temporary scripts and modifications created during the protocol must be discarded.

## CRITICAL: Io-Orchestrated Testing Protocol

- **Default Requirement:** Execute all tests and demos from the Io "mind" layer using the canonical `Telos Bridge` veneer (or successor Io harnesses). Every validation must send messages through the Synaptic Bridge so that Python "muscle" components are exercised via the C substrate. Running Python modules directly (`python -m ...`) is considered a diagnostic shortcut, not a passing result.
- **Bridge Health First:** If the Io-driven test path fails because the Synaptic Bridge or IoVM cannot load (e.g., missing symbols, build failures), halt feature work and repair the bridge before attempting further Python-level validation.
- **Documented Exceptions Only:** When a temporary direct-Python test is unavoidable (for example, while the Creative Troubleshooting Protocol is active), log the rationale, scope, and clean-up steps in both `run_log.md` and `system_status.md`, and delete any auxiliary harnesses immediately after the canonical Io path is restored. Once the Creative Troubleshooting Protocol is exited, tests must be confirmed via Io again before being considered valid.
- **Test Artifacts:** New tests must live under `libs/tests/` but ship with an Io entrypoint (e.g., `archive/demos/` for temporary probes or dedicated Io test runners) that drives them through the bridge. Update this instruction file whenever the canonical Io testing harness changes location or naming.