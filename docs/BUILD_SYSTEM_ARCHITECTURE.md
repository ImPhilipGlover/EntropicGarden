# TELOS Build System Architecture

This document outlines the recursive and interdependent build process of the TELOS system. Understanding this architecture is critical for developers to diagnose build issues and contribute to the project, as the system is designed to be "self-compiling" through its own neuro-symbolic architecture.

The build process follows a strict dependency order, reflecting the "Io Mind, C Synapse, Python Muscle" design principle.

## Build Stages

The build is orchestrated by CMake but follows a logical progression of stages. Each stage must complete successfully before the next can begin.

### Stage 1: Build the Io Virtual Machine (IoVM)

-   **Target**: `iovm` and its dependencies (`basekit`, `garbagecollector`, `coroutine`).
-   **Output**: The `io` executable and the `libiovmall` shared library.
-   **Purpose**: The `io` executable is the cognitive core. It is a fundamental prerequisite for running any Io scripts, including the prototypal linter and the final build orchestrator. This is an external dependency bundled with the project, not part of TelOS itself.

### Stage 2: Build the Synaptic Bridge (`telos_core` and `IoTelosBridge`)

This stage creates the critical communication layer between the Io mind and the C/Python substrate.

1.  **Prototypal Purity Linting (`prototypal_lint_check`)**:
    -   **Input**: The `io` executable from Stage 1.
    -   **Action**: Runs the `PrototypalLinter.io` script over the Io codebase.
    -   **Purpose**: Enforces architectural purity *before* compiling the core logic. A failure here indicates a violation of the prototype-based programming principles. This is a dependency for `telos_core`.

2.  **Core C Library (`telos_core`)**:
    -   **Input**: C source files for the synaptic bridge.
    -   **Output**: `libtelos_core.so` (or equivalent).
    -   **Purpose**: Provides the fundamental C functions for inter-process communication, shared memory, and VSA operations.

3.  **Io Addon (`IoTelosBridge`)**:
    -   **Input**: `telos_core` library and IoVM headers.
    -   **Output**: `IoTelosBridge.so` (or equivalent C addon for Io).
    -   **Purpose**: This is the type-safe "synapse" that connects the Io language to the `telos_core` C library, allowing Io scripts to call bridge functions securely.

### Stage 3: Build the Python Substrate (`telos_python_extension`)

-   **Input**: `telos_core` library and Python CFFI build scripts.
-   **Output**: A Python extension module (`_telos_bridge.c` and resulting `.so` file).
-   **Purpose**: Enables the "Python muscle" by allowing Python worker processes to call back into the `telos_core` C library, completing the communication loop.

### Stage 4: System Self-Compilation (Orchestration)

-   **Action**: Running an Io script like `clean_and_build.io`.
-   **Dependencies**: The `io` executable (Stage 1), the `IoTelosBridge` addon (Stage 2), and the `telos_python_extension` (Stage 3).
-   **Purpose**: This is the final step where the system becomes "self-compiling." The Io cognitive core, using the very bridge it just helped build, orchestrates the final build and validation steps, sending tasks to Python workers through the C synapse.

This recursive process ensures that the system is built using its own architectural principles, reinforcing the integrity of the design.
