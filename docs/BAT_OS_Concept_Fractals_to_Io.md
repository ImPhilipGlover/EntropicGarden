# BAT OS Concept Fractals → TelOS-Io Design Map

This document harvests durable “concept fractals” from the BAT OS Development corpus and maps them into concrete Io prototypes, messages, and slices. Treat this as living DNA → organism wiring; it evolves as the organism grows.

Guiding rules
- Prototypes-only in Io; everything is a clone with dynamic slots and message passing.
- Every concept maps to a living slice: UI + FFI + Persistence.
- Io is the mind and memory; Python/externals are muscles/tools.

Core concept fractals and Io mappings

1) Synaptic Bridge (Io → C → Python)
- Intent: Io mind can contract Python muscle safely and deterministically.
- Io mapping:
  - Prototype: `Telos` (C-level proto registered under `Lobby Protos Telos`).
  - Messages: `getPythonVersion`, `pyEval:` (Phase 4), transactional WAL hooks.
  - Persistence: WAL logs for every bridge call; later snapshots of “muscle artifacts.”

2) Morphic Canvas (Living Interface)
- Intent: Direct manipulation UI; world of morphs with draw/handle.
- Io mapping:
  - Prototypes: `World`, `Morph` (Phase 5); C stubs now, SDL2 later (Phase 2).
  - Messages: `createWorld`, `drawOn`, `mainLoop`, `handleEvent`.
  - Persistence: UI state deltas logged; replay recovers last living view.

3) Persistence as Metabolism (WAL → Orthogonal → Healing)
- Intent: Don’t roll back life; metabolize change: append, replay, snapshot, heal.
- Io mapping:
  - Messages: `transactional_setSlot`, planned `snapshot`, `replay`, `heal`.
  - C-level WAL: append-only with commit markers (Phase 3); replay on boot.
  - Healing: shadow clones + atomic swap (Phase 9).

4) Generative Kernel (`forward`)
- Intent: Missing messages fuel growth; system synthesizes/evolves behaviors.
- Io mapping:
  - Add `forward` to key prototypes (Phase 6); route to tool-maker path.
  - Persistence: synthesized slots logged, versioned, reviewable.

5) VSA-RAG Memory (Neuro-symbolic)
- Intent: Io holds navigable memory; Python provides efficient vectors/ANN.
- Io mapping:
  - Prototypes: `Telos memory` API with `addContext:`, `search:`, `addConcept:` (Phase 7).
  - Python: FAISS/DiskANN adapters (later), surfaced as Io messages.
  - Persistence: index metadata + corpus snapshots with WAL-guarded commits.

6) Non-local LLM Bridge (When local VRAM isn’t enough)
- Intent: Borrow remote cognition; Io controls goals, budget, and privacy.
- Io mapping:
  - Messages: `llmCall:`, `toolUse:` (stubs now; Phase 7.5 for real providers).
  - Guards: offline/dry-run mode, redaction, budget limits, deterministic tests.
  - Persistence: full call DAG logged for reproducibility.

7) Personas (Society of Minds)
- Intent: Specialized roles (e.g., BRICK/ROBIN/BABS/ALFRED) collaborate to plan, build, and verify.
- Io mapping:
  - Prototypes: `Telos personas` with role-specific `run:` and `orchestrate:`.
  - Tools: consult `memory`, call local/remote LLM via `llmCall:`; record steps.
  - Persistence: persona dialogues and decisions WAL’d; retrievable for audit.

8) Composite Entropy Metric (Toward Gibbs Free Energy)
- Intent: Maximize structured cognitive entropy while minimizing cost/incoherence/risk; converge to elegant forms.
- Io mapping:
  - Messages: `scoreSolution:` (Phase 9) computing G_hat = α·S_structured − β·C_cost − γ·I_incoherence − δ·R_risk.
  - Python assist: optional finer metrics (entailment/graph consistency) via FFI.
  - Persistence: metric components and choices logged; supports ablations.

9) Antifragility & Healing
- Intent: Prefer recovery and learning over brittle rollbacks.
- Io mapping:
  - Prototypes: `Healer` with `probe`, `revertToClone`, `autoHeal` (Phase 9).
  - Data: diff logs for slots; “safe points” with atomic swaps.

10) Capability/Component Model (Genode/seL4)
- Intent: Decompose organism into capability-constrained components.
- Io mapping:
  - Split VM, Python compute, UI, and persistence into components with RPC.
  - Preserve Io mind as the orchestrating locus.

Vertical slice references
- Phase 2: SDL2 window (first glance).
- Phase 3: WAL + replay (first heartbeat with integrity).
- Phase 7: VSA-RAG (memory as creative substrate).
- Phase 7.5: Non-local LLM (borrow cognition responsibly).
- Phase 8: Personas choreography (society of minds).
- Phase 9: Composite Entropy Metric (Gibbs-like convergence) + healing.

Next
- Stubs in Io (offline) for `llmCall:`, `toolUse:`, `scoreSolution:`; minimal `Telos memory` and `Telos personas` to exercise flows now, swap to real muscles later.
- Keep slices small and shippable; update this mapping with each evolution.
