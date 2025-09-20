# TelOS-Io Development Roadmap (EntropicGarden)

This roadmap distills the project’s philosophical covenant and engineering plans into actionable phases for the Io-based TelOS system. It is designed to produce living, vertical slices that always integrate:
- UI (Canvas/Morphic)
- FFI (Io → C → Python Synaptic Bridge)
- Persistence (Living Image behavior, starting with WAL and evolving toward orthogonal persistence)

It also charts the longer path to a self-hosting organism on a formally verified substrate (Genode/seL4).

## Vision and Guiding Principles

- Prototypes-only mandate: All Io code is purely prototypal. Use `clone`, message-passing, dynamic slots; no classes.
- Living Slice is law: Deliver end-to-end slices that show liveness (UI), intelligence (FFI to Python “muscle”), and durable state change (persistence).
- Io mind, Python muscle: Io orchestrates cognition and state; Python is embedded as a subordinate compute engine via the CPython C-API.
- Watercourse Way: Flow around friction (e.g., build in WSL); keep changes minimal, composable, and reversible.
- Antifragility: Favor systems that learn from perturbations (metabolize failure) over brittle transactional rollbacks; add recovery and healing rather than “erase and reset.”
- Path to Genode/seL4: Target organizational closure (self-updating while live) and a formally verified kernel boundary.

## Current Status (baseline)

- Io VM builds and runs in WSL; main coroutine return handling fixed to avoid abort on normal script completion.
- TelOS addon (C) registers a `Telos` proto under `Protos` via IoState bindings-init callback.
- Synaptic Bridge initializes CPython; FFI stubs available from Io through raw C methods.
- Persistence: initial WAL-like writes in place; recovery not yet implemented.
- UI: console/heartbeat stubs; no real window yet.
- Smoke test (`samples/telos/smoke.io`) validates Python version call, simple transactional set, heartbeat loop.

## Contracts and Conventions

- C exports to Io: `Io[ObjectName]_[methodName](IoObject *self, IoObject *locals, IoMessage *m)`; symbols via `IoState_symbolWithCString_(state, "name")` in init contexts.
- Addon init: register via `IoState_setBindingsInitCallback` -> `IoAddonsInit` -> `IoTelosInit`.
- GIL discipline: wrap all Python calls with `PyGILState_Ensure/Release`; initialize interpreter once.
- Persistence discipline: append-only WAL with commit markers; replay only complete transactions; plan orthogonal persistence later.
- Io style: PascalCase for prototypes, camelCase for slots/methods; everything is a message.

## Phased Roadmap

Each phase ends with concrete deliverables and acceptance criteria. Phases are incremental; ship small, living slices.

### Phase 0 — Baseline Health and WSL Flow (Done/Verify)
- Deliverables:
  - Clean build under WSL.
  - Main coroutine completion returns cleanly.
- Acceptance:
  - `io -e "writeln(\"ok\")"` prints `ok`.
  - Run `samples/telos/smoke.io` without crash.

### Phase 1 — Autoload Io-Level TelOS Prototypes
- Goal: `Telos` Io API available at startup without manual `doFile`.
- Work:
  - In `IoTelosInit`, after registering the proto, load `libs/Telos/io/IoTelos.io` if present.
  - Guard missing file with a non-fatal warning; VM continues.
- Deliverables:
  - Auto-load code path with clear logs.
- Acceptance:
  - `io -e "writeln(Protos Telos type)"` prints `Object`.
  - `samples/telos/smoke.io` runs without any manual prototype load.

### Phase 2 — Real Window/Canvas (SDL2 minimum viable UI)
- Goal: Replace console stubs with a minimal window + draw loop.
- Work:
  - Add SDL2 to CMake on Linux (WSL). Create window in `Telos_rawOpenWindow`; pump events in `Telos_rawMainLoop`; draw a rectangle in `Telos_rawDraw`.
  - Maintain stable Io API; close cleanly on window close.
- Deliverables:
  - New sample `samples/telos/first_glance.io` creating a world, drawing a morph, exiting on close.
- Acceptance:
  - Window opens, a rectangle renders, heartbeat logs, exits on user close; no leaks on repeated cycles.

### Phase 3 — Persistence Integrity & Recovery (WAL+)
- Goal: Make WAL robust to interruption.
- Work:
  - Write a versioned header and per-transaction commit marker.
  - Implement replay: only apply complete commits; ignore trailing partial.
  - Add a small verification sample/test.
- Deliverables:
  - Minimal recovery module + test sample.
- Acceptance:
  - After simulated crash (truncate last bytes), recovery replays up to last complete commit; sample asserts key-values intact.

### Phase 4 — Synaptic Bridge Maturation (Python Runtime)
- Goal: Robust embedded Python runtime with safe concurrency.
- Work:
  - Centralize Python init/finalize; job queue for Python calls if needed; structured error propagation.
  - Define Io↔Python marshaling (start with JSON strings; consider MessagePack later).
- Deliverables:
  - `Telos pyEval:` Io message to evaluate a small Python function and return a value.
  - Error paths return Io Exceptions with Python traceback text.
- Acceptance:
  - Round-trips of primitives and small lists/maps validated; intentional Python error surfaces correctly without crashing VM.

### Phase 5 — Morphic Substrate (Io Prototypes)
- Goal: Io-level `World`, `Morph`, and direct manipulation skeleton.
- Work:
  - Implement `World`, `Morph` prototypes in `libs/Telos/io/`; maintain `drawOn`, `step`, `handleEvent` messages mapping to C backend.
  - Basic selection/dragging; z-order list.
- Deliverables:
  - Sample with two morphs, drag-and-drop, and redraw.
- Acceptance:
  - Morphs can be created, moved, and redrawn at ~60 FPS on WSL; CPU usage reasonable.

### Phase 6 — Generative Kernel via `forward`
- Goal: Make missing messages fuel growth (doesNotUnderstand analog).
- Work:
  - Add `forward` on key prototypes to intercept unknown messages.
  - Phase A: Log + guide user; Phase B: synthesize trivial behaviors; Phase C: route to Python “Prometheus” tool-maker path.
- Deliverables:
  - Forwarding hook with toggles, logging, and a safe sandbox for experiments.
- Acceptance:
  - Unknown messages don’t crash; controlled synthesis path can inject a new slot and persist it.

### Phase 7 — VSA-RAG Foundations (Io API over Python libs)
- Goal: Neuro-symbolic memory substrate accessible from Io.
- Work:
  - Wrap embeddings + vector index (e.g., FAISS or DiskANN via Python) behind stable Io messages; define persistence hooks.
  - Start simple: in-memory FAISS + on-disk snapshot; add 2-phase commit with WAL later.
- Deliverables:
  - `Memory addContext:`, `search:`, `addConcept:` Io APIs.
- Acceptance:
  - Insert 100+ items; queries return relevant neighbors; round-trip persists across runs.

### Phase 7.5 — Non-local LLM Bridge (Io → Python → API)
- Goal: Allow the Io “mind” to borrow non-local reasoning capacity via external LLM APIs when local GPU/VRAM is insufficient.
- Work:
  - Define Io message family on `Telos` such as `llmCall:` and `toolUse:` that forwards to Python glue.
  - Implement Python-side adapters for popular API providers behind a single normalized schema (prompt, tools, system, temperature, maxTokens, budget), driven by Io state.
  - Add budget and privacy guards: rate limits, redact sensitive slots, log calls transactionally in WAL for reproducibility.
- Deliverables:
  - Minimal prompt→completion call from Io with a deterministic test stub provider.
  - Toggle to disable network in “offline mode,” with graceful fallback to local models.
- Acceptance:
  - A script demonstrates: try local model; on failure/insufficient capability, route to non-local API; persist request/response; resume Io flow.

### Phase 8 — Personas and Planner (Society of Minds)
- Goal: BRICK/ROBIN/BABS/ALFRED as Io prototypes orchestrating Python models.
- Work:
  - Implement persona prototypes and a simple ReAct loop orchestrator.
  - Ensure serial GPU/VRAM usage (sequential model loading) where applicable.
- Deliverables:
  - Sample task flowing BABS→BRICK→ROBIN→ALFRED; return synthesis.
- Acceptance:
  - Deterministic small tasks complete; logs show persona sequencing; failures are contained and recoverable.

### Phase 8.5 — Cognitive Entropy Maximization (Personas × Memory)
- Goal: Operationalize “maximize cognitive entropy while seeking minimum Gibbs-like free energy” via personas orchestrated over navigable memory.
- Work:
  - Equip personas with access to `Memory` APIs (Phase 7) and non-local `llmCall:` (Phase 7.5).
  - Add planning heuristic that rewards structured diversity of hypotheses (entropy) while penalizing energy cost (tokens/time/API budget) and incoherence.
  - Provide levers in Io: `entropyWeight`, `coherenceWeight`, `costWeight`, `noveltyWeight` with defaults.
- Deliverables:
  - A persona round-table sample that explores multiple solution candidates, prunes low-coherence branches, and converges on a final plan.
- Acceptance:
  - Logs show exploration breadth, citations to memory entries, and a final converged solution with favorable metric.

### Phase 9 — Composite Entropy Metric (Toward Gibbs Free Energy)
### Phase 9.5 — Persona Priming & BABS WING Loop
- Persona priming pipeline: Curate → Summarize → Pack (system prompt) → Converse
- BABS: identify gaps → draft WING prompts → human Deep Research → ingest reports as ContextFractals → refine ConceptFractals with provenance

- Goal: Define and instrument a composite metric that approximates an entropically favorable path akin to Gibbs free energy minimization.
- Work:
  - Draft metric G_hat = alpha·S_structured − beta·C_cost − gamma·I_incoherence − delta·R_risk, where:
    - S_structured: information entropy over solution candidates conditioned on structural cohesion (e.g., topic/graph consistency from VSA clusters).
    - C_cost: compute/latency/token cost (local + non-local), normalized per outcome value.
    - I_incoherence: contradiction or lack of consistency across persona outputs and memory (e.g., entailment scores or self-consistency checks).
    - R_risk: risk of brittleness or data loss; penalize long chains with low persistence checkpoints.
  - Implement metric calculation in Python, surfaced as Io message `scoreSolution:`; persist intermediate scores and chosen plan.
  - Add ablations for metric study and toggles for alpha/beta/gamma/delta.
- Deliverables:
  - Io sample demonstrating multiple candidate solutions scored and a choice traced with metric components shown.
- Acceptance:
  - Re-running yields similar selections under fixed seeds; adjusting weights predictably shifts choices; all calls persisted in WAL.

### Phase 9 — Antifragile Healing
- Goal: Self-repair mechanisms over transactional rollback.
- Work:
  - Diff log of slot changes; shadow clone + atomic swap; automatic reversion after instability; health probe.
- Deliverables:
  - Healing routines callable from Io; health dashboard log.
- Acceptance:
  - Inject a faulty behavior; system detects instability, reverts to prior clone without losing unrelated state.

### Phase 10 — Tests, CI, and Quality Gates
- Goal: Keep the organism healthy.
- Work:
  - Add Io unit samples; wire a test runner script; basic lints/build checks.
- Deliverables:
  - `tools/tests/run_all.io` that validates happy paths and a few edge cases.
- Acceptance:
  - Tests pass in WSL CI-like run; failures print actionable diagnostics.

### Phase 11 — Packaging & Autoload
- Goal: Smooth dev UX and repeatability.
- Work:
  - Auto-load Io scripts from `libs/Telos/io/` on startup; improve logs; versioned features.
- Deliverables:
  - Clear boot banner showing loaded prototypes and addons.
- Acceptance:
  - Fresh `io` invocation exposes `Telos` APIs and core prototypes by default.

### Phase 12 — Path to Genode/seL4 (Strategic)
- Goal: Road to self-hosting organism.
- Work:
  - Componentize Io VM for Genode; replace POSIX calls; split Python into dedicated components; define capability-based RPC APIs; integrate persistence server (SQLite/LMDB-backed) with a custom VFS.
- Milestones:
  - M1: Io “hello world” Genode component.
  - M2: TelOS addon runs (no Python).
  - M3: Python compute component communicates with Io mind via RPC.
  - M4: Minimal Morphic window via framebuffer component.

## Risks and Mitigations

- SDL2 dependency in WSL: Prefer Linux/WSL packages; gate platform-specific code with CMake options.
- CPython embedding: Strict GIL handling; centralized init/finalize; avoid long-held locks in UI loop.
- Persistence corruption: Commit markers + recovery; add periodic snapshots.
- Performance drift: Maintain profiling hooks; keep UI draws minimal; marshal data efficiently.
- Complexity creep: Keep each slice small and shippable; resist premature generalization.
- External APIs: Provide offline mode and deterministic stubs; redact sensitive data; budget guardrails and caching to constrain costs.

## Build & Run (WSL flow)

From Windows PowerShell:

```powershell
# Enter WSL Ubuntu
wsl -d Ubuntu

# Inside WSL shell
cd /mnt/c/EntropicGarden
cmake -S . -B build
make -C build -j4

# Run Io
./build/_build/binaries/io -e 'writeln("Hello from TelOS-Io")'

# Run smoke test
./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/smoke.io

# First Launch: Germination (Windows + WSL)

Goal: start a live, conversational co-creation session with personas and ALFRED commentary.

If you already have an `io` binary from the WSL build above, try:

```powershell
# Interactive personas chat (switch with BRICK/ROBIN/BABS/ALFRED)
wsl -d Ubuntu ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/personas_chat.io

# Conversation demo
wsl -d Ubuntu ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/conversation_demo.io

# BABS research loop
wsl -d Ubuntu ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/research_loop_demo.io
```

Outcome:
- Live REPL with persona voices (ethos-conditioned), ALFRED meta-commentary, and BABS research prompts/ingestion.
- WAL entries written deterministically; canvas stubs render draw logs.
```

## Immediate Next Steps

1) Phase 1: Autoload `IoTelos.io` during addon registration
- Implement guarded load in `IoTelosInit`. Verify with a one-liner.

2) Phase 2: SDL2 window slice
- Add dependency; implement `openWindow`, `mainLoop`, `draw`; ship `samples/telos/first_glance.io`.

3) Phase 3: WAL integrity & recovery
- Add commit markers + replay; include a tiny replay sample.

4) Prepare Phase 7.5/8.5/9 stubs
- Sketch Io messages (`llmCall:`, `toolUse:`, `scoreSolution:`) and Python glue interfaces; add no-op/offline stubs now with logs so higher phases can be integrated incrementally.

## Acceptance Checklist per Slice

- Build passes under WSL.
- Minimal unit sample(s) included and runnable.
- Io API stable and documented in-line.
- Logs clear; errors return as Io exceptions (no aborts).
- Persistence either no-ops safely or commits atomically with recovery.

---
This document is a living artifact. Update it with each completed slice, recording actual acceptance evidence (commands/outputs), deltas, and any deviations from plan.
