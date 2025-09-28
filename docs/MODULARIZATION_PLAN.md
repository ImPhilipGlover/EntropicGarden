# Modularization Plan — Prioritized Splits (2025-09-27)

Purpose: capture a prioritized, low-risk plan to break apart files discovered by the Architectural Compliance Audit that exceed the 300-line guideline. Each proposal includes the split approach, estimated risk, tests to run, and an approximate effort estimate. Follow the AutoPrompt guardrails: make small, focused edits, run `ctest` after each change, and log all actions in `run_log.md`.

---

## Summary of audit (top offenders)
- `libs/Telos/python/workers.py` — 3173 lines (very large)
- `libs/Telos/python/_telos_bridge.c` — 1797 lines (C shim / generated)
- `libs/Telos/python/prototypal_bridge.py` — 1768 lines
- `libs/Telos/python/l2_cache_manager.py` — 1289 lines
- `libs/Telos/source/IoTelosBridge.c` — 1149 lines
- `libs/Telos/source/telos_proxy.c` — 942 lines
- `libs/Telos/python/l1_cache_manager.py` — 870 lines
- `libs/Telos/python/cache_coordinator.py` — 869 lines
- `libs/Telos/source/telos_proxy_forwarding.c` — 732 lines
- `libs/Telos/python/zodb_manager.py` — 718 lines
- `libs/Telos/io/TelosHRC.io` — 628 lines
- `libs/Telos/source/synaptic_bridge_io.c` — 526 lines
- `libs/Telos/python/opentelemetry_bridge.py` — 523 lines
- `libs/Telos/python/worker_types.py` — 515 lines
- (full sorted list captured in the build terminal log)

Notes: Many of the Python files are natural consolidation points (workers, caches, bridges). Io prototype files may be larger by nature, but splitting into coordinator/proxy/kernel helpers will improve readability and testability.

---

## Prioritized split proposals (first-pass)

1) `libs/Telos/python/workers.py` — Priority: P0 (first split)
- Rationale: central worker logic; largest single file; changes here can be done gradually with façade compatibility to minimize breakage.
- Proposed split:
  - `libs/Telos/python/workers/runner.py` — process pool / lifecycle and CLI/test entrypoints.
  - `libs/Telos/python/workers/handlers.py` — handler registry and JSON -> handler dispatch adapters.
  - `libs/Telos/python/workers/utils.py` — shared helper functions (serialization, shared-memory helpers, small utilities).
  - `libs/Telos/python/workers/types.py` — small dataclasses / type definitions used across the module.
  - Leave a thin compatibility module `libs/Telos/python/workers.py` that re-exports symbols from the new modules to preserve import paths during the refactor.
- Risk: Low-to-medium (if compatibility façade is kept, imports should remain stable).
- Quick-tests:
  - Run `python -m compileall libs/Telos/python/workers` locally (syntax sanity).
  - Run `ctest --test-dir build --output-on-failure --timeout 300` (full suite) after split.
- Est. effort: 2–4 small commits, each < 40 lines of net changes in a given file (move definitions, add re-exports). Keep change surface minimal.

2) `libs/Telos/python/prototypal_bridge.py` (and `_telos_bridge.c`) — Priority: P1
- Rationale: Bridge glue is large and mixes generated C shim logic and higher-level dispatching. Separate generated/auto-produced code from handwritten logic.
- Proposed split:
  - For `_telos_bridge.c` and other generated artifacts, keep generated sources in `libs/Telos/python/generated/` and add small `*_shim.c` files for handwritten glue.
  - `libs/Telos/python/prototypal_bridge.py` -> split into `prototypal_bridge/core.py` (dispatch logic) and `prototypal_bridge/compat.py` (backwards-compatible names) plus `prototypal_bridge/metrics.py` (observability helpers).
- Risk: Medium — C-level splits require careful CMake adjustments; do not change build targets or names. Best approach: refactor Python first, then extract C into separate compile units while preserving same linkable symbols.
- Quick-tests:
  - Rebuild with `cmake -S . -B build && cmake --build build`.
  - Run bridge-specific tests: `ctest -R "bridge_send_message_c|telos_bridge_io" --test-dir build --output-on-failure --timeout 300`.
- Est. effort: medium; require incremental commits and CI verification.

3) Cache managers and coordinator (`l2_cache_manager.py`, `l1_cache_manager.py`, `cache_coordinator.py`) — Priority: P1–P2
- Rationale: Split policy, index-building, storage/deps, and RPC surfaces.
- Proposed split for each manager:
  - `<manager>/api.py` — external-facing API surface.
  - `<manager>/policy.py` — eviction/promotion heuristics.
  - `<manager>/indexing.py` — index build/load/save helpers.
  - `<manager>/tests/` — unit tests for heuristics/index fallback.
- Risk: Low-to-medium. Focus on isolating pure functions (policy) first.
- Quick-tests: targeted unit tests for policy functions and ctest after assembly.

4) `libs/Telos/source/*` C files (IoTelosBridge.c, telos_proxy.c, telos_proxy_forwarding.c)
- Rationale: C sources mix lifecycle, forwarding, and helper I/O. Split by responsibility.
- Proposed split:
  - `synaptic_bridge_core.c` (lifecycle/GIL/quarantine)
  - `synaptic_bridge_shared_memory.c` (already separate — keep)
  - `telos_proxy_dispatch.c` (dispatch + forwarding)
  - `telos_proxy_utils.c` (helpers)
- Risk: Medium-to-high if public ABI names change. Maintain exported symbol names and update `CMakeLists.txt` carefully to compile the new translation units into the same shared library. Prefer only moving static/internal functions and leaving public functions untouched.
- Quick-tests: ASan builds for safety; `ctest` with bridge tests.

5) Io prototypes over 300 lines (e.g., `TelosHRC.io`, `TelosBridge.io`, `TelosTelemetryDashboard.io`)
- Rationale: Io prototypes are natural coarse-grained units; split complex prototypes (Coordinator, Kernel, Prompter) into smaller prototypes that compose.
- Approach: create helper prototypes in `libs/Telos/io/` and import/clone them into the main prototypes; keep behavior the same, but break long files into composable parts.
- Risk: Low (Io is prototypal; splitting into small protos is idiomatic).
- Quick-tests: Io harness tests via `ctest` (Io runners) and small Io smoke scripts.

---

## Small-change strategy & checklist
For every split, follow this pattern (keeps edits <40 lines per file where possible):
1. Create new module/file with selected functions/classes copied (small chunk).
2. Add a compatibility façade in the original file that imports and re-exports the moved names (so other imports see no API change).
3. Run `python -m compileall` on the affected package to catch syntax errors.
4. Run `cmake -S . -B build && cmake --build build` if C files changed; otherwise just run `ctest` from `build`.
5. Append `run_log.md` entry documenting the split intent, affected files, tests run, and results.
6. If tests fail, revert the commit (local git reset) and analyze; log revert and next candidate.

---

## Edge cases & risks
- Public API and symbol exposure: maintain compatibility by adding façades/re-exports and preserving exported C symbol names.
- Build integration: C splits may require updating `CMakeLists.txt` to include new source files. Do this only to add translation units (do not rename public objects).
- Test flakiness: tightly scope quick-tests and keep timeboxes (300s). If a test is flaky, isolate and write a focused test for the module before large refactors.
- Io prototype semantics: ensure cloned prototypes preserve slot names and side effects.

---

## Proposed immediate next step (low-risk)
- Implement the first small split on `libs/Telos/python/workers.py`:
  - Move a small set of helper utilities into `libs/Telos/python/workers/utils.py` (e.g., serialization helpers, small stateless helpers).
  - Add `workers/utils.py` unit-level sanity and keep `workers.py` re-exporting names.
  - Run `ctest` and append results to `run_log.md`.

Rationale: helps reduce size slightly, is low-risk, and proves the façade pattern works before larger refactors.

---

## Acceptance criteria for the modularization plan
- Plan file exists in `docs/` and is referenced from `AutoPrompt.txt` and `run_log.md`.
- Each split is accompanied by a short test plan and a small-change checklist.
- First small split implemented and validated by `ctest` with no regressions.


Signed-off: Copilot agent — modularization plan (draft)
