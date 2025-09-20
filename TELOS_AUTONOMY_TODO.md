# TelOS Autonomous Runbook and Live Checklist

Single source of truth for autonomous work on this repository. Agents MUST update this file continuously while operating.

Paths:
- Windows: `C:\EntropicGarden\TELOS_AUTONOMY_TODO.md`
- WSL: `/mnt/c/EntropicGarden/TELOS_AUTONOMY_TODO.md`

## Prime Directive
Act as a co-evolving partner. Build vertical slices that breathe: UI (Canvas) + FFI (Synaptic Bridge) + Persistence (Living Image). Io is the mind; Python is the muscle; avoid Python monoliths. Prefer WSL for all builds and runs.

## How to Use This File (Agent Rules)
- Maintain this file as you work. It is the living checklist and run log.
- Exactly one checklist item is in-progress at any time. Update status before starting work.
- After each action batch (edits/commands/tests), update:
  - Checklist item status and notes
  - Work Log with a succinct delta
  - Decisions Log if you made a structural choice
- Keep changes minimal and focused. Prefer incremental, vertical slices.
- All execution MUST occur inside WSL (Ubuntu). Use the WSL-built `io`.

Orientation (mandatory before each slice):
- Read `docs/TelOS-Io_Development_Roadmap.md` and quickly skim related blueprints in `docs/` to identify the Roadmap phase/subphase being advanced.
- Record the targeted phase and acceptance criteria in the Decisions Log before coding.
- Extract any cross-phase seams (WAL tags, UI hooks, FFI slots) and plan to wire them as extension points.

## Quick Start (WSL)
If you’re starting fresh or resuming a session:

```
# Open WSL and go to the repo
wsl.exe ~
cd /mnt/c/EntropicGarden

# Build (if not already built)
./build.sh || true

# Smoke tests (adjust paths as needed if binaries differ)
./build/bin/io samples/telos/ollama_smoke.io || true
./build/bin/io samples/telos/germination_chat.io || true
./build/bin/io samples/telos/curation_flush.io || true
```

Notes:
- Ensure Ollama is running and telos/* models exist (see `docs/Ollama_Setup.md`).
- If build artifacts are elsewhere, search under `/mnt/c/EntropicGarden/build/bin` for the `io` binary.

## Roadmap Plan (Living Slice Cadence)
- Near-term slices (Morphic-first):
   1) Morphic UI v1 (textual canvas heartbeat + morph tree snapshot; minimal event loop)
   2) Curator v1 (dedupe/filter) → higher-signal `candidate_gold.jsonl`
   3) Persona Consistency Scorer → annotate entries with score+rationale
   4) Integrate scores into flush → thresholding + summaries
   5) rRAG skeleton (Io→C→Python vector ops) → memory bridge
   6) Optional streaming & SDL2 UI spike → richer UX without breaking existing demos
- Ongoing:
   - Expand personas and genOptions; wire ROBIN UI shaping
   - Strengthen logging; guardrails and reproducible run seeds

## Live Checklist
Conventions: [not-started] → [in-progress] → [completed]. Keep one [in-progress].

1. [completed] Morphic UI v1: Textual canvas + morph tree
    - Goal: Ensure every run shows a "Morphic Canvas" heartbeat and a snapshot of the morph tree; support creating a few basic morphs (Rect, Text) and a short loop.
    - Acceptance:
       - `Telos.createWorld`, `Telos.createMorph` produce visible textual draw logs
   - `Telos.mainLoop` prints heartbeat with morph count and draws morphs
       - `Telos.captureScreenshot` returns a readable morph tree

2. [completed] Curator v1: Deduplicate & filter curation queue
   - Goal: Produce higher-signal `candidate_gold.jsonl` via length thresholds, duration sanity checks, and deduplication (prompt+response hash).
   - Acceptance:
     - Implements `Telos.curator.flushToCandidates(max, opts)` filters: min tokens, max tokens, min duration, persona allowlist; dedupe by normalized keys
     - Writes stats summary (kept/dropped counts, reasons) to `logs/curation_summary.log`
     - Zero regressions: existing flush still works when filters disabled

3. [completed] WAL Replay v0: id-prefixed SET apply
    - Goal: Replay telos.wal lines of the form `SET <id>.<slot> TO <value>` to restore morph state by id.
    - Acceptance:
       - `Telos.replayWal(path)` indexes current world morphs by `id` and applies slots: `position`, `size`, `color`.
       - Added sample `samples/telos/morphic_wal_replay_smoke.io` demonstrating mutate→snapshot A→reset→replay→snapshot B.
       - Deprecation warnings resolved (`slice`→`exSlice`).

4. [completed] Persona Consistency Scorer
   - Goal: Score outputs for alignment with persona ethos/speakStyle; annotate entries.
   - Acceptance: Adds `consistencyScore` (0..1) + rationale; used by curator filters and summary stats

4. [completed] Integrate Scores into Flush
   - Goal: Use `consistencyScore` and basic quality heuristics in selection
   - Acceptance: Thresholds configurable via `opts`; summary includes score distribution

5. [completed] rRAG Skeleton (VSA-NN Synaptic Bridge)
   - Goal: Io→C→Python bridge stub for vector memory ops (no monoliths)
   - Acceptance: Minimal addon registered; `Telos.rag.index(docs)` and `Telos.rag.query(q)` round trip with stub vectors
   - Evidence: `samples/telos/rag_skeleton_demo.io` prints ranked results; persistence writes `lastRagIndexSize` and `lastRagQuery`; included in `samples/telos/regression_smokes.io`.

6. [not-started] Optional: Streaming LLM Responses
   - Goal: Add non-breaking streaming path for Ollama; update demos

7. [not-started] SDL2 Interactive UI Spike
   - Goal: Replace stub Morphic loop with clickable/keyboard input via SDL2; retain textual snapshot for logs

8. [completed] LLM bridge v1 (Ollama)
   - Goal: Io→C→Python HTTP call to Ollama using `telos/brick:latest`; log JSONL; heartbeat visible; WAL intact.
   - Acceptance:
     - `samples/telos/persona_chat_console_demo.io` prints BRICK replies sourced from Ollama
     - `logs/persona_llm.jsonl` has `provider:"ollama"` entries with `model:"telos/brick:latest"`
     - Window breathes (heartbeats before/after), no GC assertions, run exits 0
     - WAL file present (e.g., prior `SET` entries) and UI snapshot files written

9. [completed] WAL Integrity v1: Frame-Scoped Replay
    - Goal: Apply only complete BEGIN/END frames during WAL replay; ignore trailing partial frames; keep legacy behavior when no frames exist.
    - Acceptance:
       - `Telos.walCommit(tag, info, block)` writes framed transactions around sets
       - `Telos.replayWal(path)` applies only complete frames; trailing incomplete frame operations are ignored
       - Demo `samples/telos/wal_recovery_demo.io` shows that only the first, completed frame is applied after a simulated crash

## Next Up (Active Focus)
- Harden Morphic interaction samples and add simple UI regression checks for click/drag and replay across runs; then consider a minimal SDL2 spike without disturbing Io invariants.

## Work Log
- 2025-09-19: SDL2 window smoke — added optional SDL2 bridge in Telos addon (guarded by `TELOS_HAVE_SDL2`), linked SDL2 into executables, and created `samples/telos/ui_window_smoke.io`. Built and ran under WSL: a 640x480 window appeared via WSLg; Morphic heartbeat printed; window closed cleanly; run exited 0.
 - 2025-09-19: Regression stabilization pass — fixed Io event dispatch nil-call by guarding `Telos.dispatchEvent` to fall back to C `handleEvent` safely; removed brittle named-arg `map(...)` usage across IoTelos by switching to `Map clone` + `atPut` (affecting logs/curation/LLM stubs and RAG query logging); simplified `Telos.memory.search` scoring/select loop to avoid symbol collisions. Validated in WSL with `samples/telos/regression_smokes.io`: Morphic heartbeat/snapshots/WAL writes are green; rRAG demos pass; run exited 0.
- 2025-09-19: Telos Io layer extended: added `Telos.mark(tag, info)` WAL marker, `logs.tail(path,n)`, a minimal textual `commands.run(name, args)` router, and clipboard-based selection copy/paste with morph spec export/import (`toSpec`/`fromSpec`). Added samples: `samples/telos/command_router_demo.io`, `samples/telos/clipboard_demo.io`, and `samples/telos/logs_tail_demo.io`. Ran command router and clipboard demos in WSL: world created, WAL writes observed, heartbeat and snapshots printed; logs tail demo pending minor fix in tail on some environments.
Append a short entry after each meaningful action batch.

- 2025-09-19: Breadth-first Io layer expansions: added WAL timestamps (walBegin), simple in-memory `Telos.memory` index/search, `Telos.saveSnapshot`, selection helper `Telos.selectAt`, simple `Telos.ui` helpers, `Telos.loadConfig` for world seeding, and basic `RowLayout`/`ColumnLayout` prototypes. Added demos `samples/telos/lowres_whole_slice_demo.io` and `samples/telos/layout_demo.io`.
- 2025-09-19: Added breadth-first, roadmap-aligned guidance to Copilot instructions: render a low-res whole, progress via vertical slices across phases, consult `docs/*` and `TelOS/BAT OS Development/` for big-picture alignment while preserving prototypal Io purity.
- 2025-09-19: Updated Copilot instructions: added System-Wide Context Review Protocol; corrected history path to `TelOS-Python-Archive/BAT OS Development/` and emphasized continuous low-res whole rendering. Runbook remains the source of truth.
- 2025-09-19: Updated Copilot instructions to prioritize fractal, low-resolution system-level testing with minimal demos/smokes and a DOE mindset; emphasized end-to-end live runs and succinct runbook summaries.
- 2025-09-19: Initialized autonomous runbook and live checklist. Seeded next steps and WSL quick start.
- 2025-09-19: Updated `.github/copilot-instructions.md` to require maintaining this runbook.
- 2025-09-19: Implemented `Telos.curator.flushToCandidates(limit, opts)` filters (min tokens, min duration, persona allowlist) and dedupe with summary logging to `logs/curation_summary.log`. Added sample `samples/telos/curation_flush_filtered.io`.
- 2025-09-19: Refocused roadmap to Morphic-first; set Morphic UI v1 as the active in-progress slice; verified current Io-level Morphic stubs print draw calls and heartbeat.
- 2025-09-19: Added `samples/telos/morphic_canvas_smoke.io` and validated in WSL. Output shows: world draw log, morph tree snapshot (world → rect → text), and WAL persistence on text change. Initially avoided C `mainLoop` due to instability.
- 2025-09-19: Stabilized C `Telos.mainLoop` by removing GC-unsafe Io list access; re-enabled in sample. Validated 4 heartbeat iterations without segfault:
   - "Telos: Drawing world (800x600)" x4 and "Telos: World heartbeat (morphs: 0)" x4, then graceful loop exit.
- 2025-09-19: Implemented Io-side event dispatch (`Telos.dispatchEvent`/`Telos.click`) and RectangleMorph click-to-toggle color behavior; added `samples/telos/morphic_click_toggle.io` and validated in WSL. Io handled events first, then C stub logged receipt.
- 2025-09-19: Annotated captureScreenshot with color, and added `List atIfAbsent` helper to stabilize printing.
- 2025-09-19: Added drag interaction via `mouseDown/move/up`; `Morph` tracks dragging and moves with pointer outside bounds; added `samples/telos/morphic_drag_smoke.io` and validated.
- 2025-09-19: Wired WAL persistence hooks on morph changes: `moveTo`, `resizeTo`, `setColor`, and drag `mouseup` write `SET` records. Added `samples/telos/morphic_persistence_smoke.io` that clears WAL, performs click+drag, prints snapshot and WAL. Validated WAL contains color and position entries.
- 2025-09-19: Added hit-test utilities (`Telos.morphsAt`/`hitTest`) and WAL markers (`walBegin`/`walEnd`). Created `samples/telos/morphic_multi_rect.io` to exercise multi-rect interactions with framed WAL output. Validated snapshot and WAL markers.
- 2025-09-19: Implemented `Telos.replayWal(path)` minimal WAL playback (id-prefixed SET). Created `samples/telos/morphic_wal_replay_smoke.io` to validate snapshot restoration after replay. Fixed deprecated `slice` usage.
 - 2025-09-19: Repaired `libs/Telos/io/IoTelos.io` after corruption from earlier edits (removed stray blocks, restored `isReplaying` flag restoration). Added offline-only `Telos.llmCall` stub. Validated `samples/telos/morphic_canvas_smoke.io` and `samples/telos/morphic_wal_replay_smoke.io` both pass under WSL with no GC assertions. Fixed Io scoping bug in replay (`do(setSlot("id", mid))` → set after clone).
 - 2025-09-19: Z-order persistence v1: added `setZIndex` persistence and replay; validated with `samples/telos/morphic_zorder_persistence.io`. Kept replay free of list sorting to avoid GC assertions.
 - 2025-09-19: TextInput persistence demo: created `samples/telos/textinput_persistence_demo.io` to persist `.text` and replay successfully.
 - 2025-09-19: Auto-replay loader: enabled `autoReplay` path and added `samples/telos/auto_replay_loader.io` to reconstruct morphs by `.type` on world creation; validated snapshot shows reconstructed tree.
 - 2025-09-19: WAL rotation utility: added `Telos.rotateWal(path, maxBytes)` and `samples/telos/wal_rotation_demo.io` (single-slot rotation to `<path>.1`).
- 2025-09-19: [START] Persona Consistency Scorer v0 — set task in-progress; plan: add `Telos.consistencyScoreFor(persona, text)`, include `consistencyScore` in `llmCall` logs, and add `minScore` gate to `curator.flushToCandidates` with summary counts.
- 2025-09-19: Persona Consistency Scorer v0 implemented — added `Telos.consistencyScoreFor(persona, text)`, integrated `consistencyScore` into `llmCall` JSONL, and extended `curator.flushToCandidates(limit, opts)` with optional `minScore` threshold and `dropped_score` metric. Validated `samples/telos/morphic_canvas_smoke.io` runs green under WSL with no GC assertions; exercised curation filters via `samples/telos/curation_flush_filtered.io` (result: score gating active, flushed 0/3 with minScore=0.2).
 - 2025-09-19: Added regression runner `samples/telos/regression_smokes.io` to execute core Morphic and Curation samples using the WSL-built `io` binary; ran it successfully in WSL. Gates: Morphic heartbeat printed; snapshots rendered; WAL writes present; curation flush filtered printed `Flush result: flushed: 0/3`. No GC assertions; all runs exited 0.
 - 2025-09-19: rRAG skeleton vertical slice implemented — C addon exposes `Telos_rawRagIndex`/`Telos_rawRagQuery` using embedded Python; Io layer `Telos.rag.index/query` wraps and persists `lastRagIndexSize`/`lastRagQuery`. Demo `samples/telos/rag_skeleton_demo.io` added and included in regression runner. Validated in WSL: ranked results printed, WAL/persistence entries present, no GC assertions.
 - 2025-09-19: Added consolidated Morphic interaction regression `samples/telos/morphic_interaction_regression.io` (click toggle + drag + WAL print) and wired into `samples/telos/regression_smokes.io`. Validated in WSL: color toggle and drag persisted (`SET rect1.color`, `SET rect1.position`), heartbeat printed, no GC assertions.
 - 2025-09-19: Fixed IoTelos API alignment — Io now calls C methods without `_raw` suffix and added C method `addMorphToWorld` to mirror Io morphs into the C world's submorphs so C draw/loop shows them. Implemented Io-level `createMorph` to use `Morph` prototype, maintain `Telos.morphIndex`, and append to C world. Updated sample `samples/telos/lowres_whole_slice_demo.io` to exercise UI+FFI+WAL+snapshot JSON.
 - 2025-09-19: Added world JSON export/import scaffold (`Telos.saveWorldJson`, `Telos.loadWorldJson`) leveraging specs; introduced `ButtonMorph` with `action` and generic `onClick`; enriched command router (`newRect`, `newText`, `move`, `resize`, `color`, `front`, `toggleGrid`, `export.json`, `import.json`). Added `samples/telos/command_script_demo.io` to script scene creation and manipulation.

- 2025-09-20: Ollama bridge v1 online — fixed embedded Python execution to use a single shared `env` dict for both globals/locals so `import json` is visible across calls; prefer `/api/chat` first, then fallback to `/api/generate`, then retry without `:latest` tag. Set `keep_alive` to `"0s"` and enriched error strings. Built in WSL and ran `samples/telos/persona_chat_console_demo.io`: window opened, heartbeats printed before/after calls, BRICK returned multi-turn replies; no GC assertions; run exited 0. Verified `logs/persona_llm.jsonl` now contains `provider:"ollama"` entries with `model:"telos/brick:latest"`; `telos.wal` present with prior `SET` lines.

- 2025-09-20: WAL Integrity v1 — added `Telos walCommit(tag, info, block)` and made `Telos replayWal(path)` frame-aware: groups `BEGIN <tag> ... END <tag>` frames and applies only complete frames; falls back to legacy unframed `SET` scanning if no frames present. Added `samples/telos/wal_recovery_demo.io` and wired it into `samples/telos/regression_smokes.io`. Validated in WSL with `/mnt/c/EntropicGarden/build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/wal_recovery_demo.io`: Snapshot B reflected only the completed frame (e.g., `rect1` moved to `(25,35)` with green color; `rect2` resized to `60x40`, ignoring later incomplete-frame moves/colors). No GC assertions; run exited 0.

- 2025-09-20: FFI maturation (pyEval v0) — added `Telos_rawPyEval` C bridge and Io wrapper `Telos pyEval(code)` that logs to tools JSONL and WAL-marks an event. Added `samples/telos/python_eval_demo.io`. Current behavior: returns empty string in demo environment (per-run isolated Python env; expressions/exec succeed silently). Functional seam is established; result marshalling will be refined (Phase 4 Roadmap).

## Decisions Log
- 2025-09-19: Minimal, non-invasive GUI path — reintroduced windowing as an optional addon seam using SDL2, keeping existing textual Morphic invariants intact. All GUI work runs under WSLg; no Windows-native path is required.
- 2025-09-19: Standardized map construction — avoid named-argument `map(...)` forms due to parser/shim brittleness; use explicit `Map clone` + `atPut` everywhere for stability and clarity.
- 2025-09-19: Event dispatch safety — never send `call` to potentially-nil slots; route Io-first then guarded C fallback in `Telos.dispatchEvent` to prevent nil-call regressions.
- 2025-09-19: rRAG selection heuristic — prefer simple list of tuples or maps with plain numeric compare; avoid reusing short variable names (`t`, `m`) across nested blocks to reduce shadowing errors. Next step is to finalize top-k selection structure to remove `'score'` lookup fragility.
- 2025-09-19: Avoided registering command blocks at load-time to prevent early resolution errors; implemented runtime dispatch for `Telos.commands.run`. Simplified `ui.heartbeat` to a single print to sidestep Io loop scoping quirks during DOE smokes. Implemented `logs.tail` without early returns or semicolon sequencing to keep Io parser stable across versions.
Record structural choices and rationale; reference related commits/patches.

- 2025-09-19: Kept all new features purely Io/prototypal; deferred C changes to avoid GC instability. Chose naive memory index and simple layout for low-res breadth while preserving vertical slice invariants (UI heartbeat, WAL writes, snapshot).
- 2025-09-19: Committed to breadth-first vertical slicing with continuous low-res rendering and blueprint/roadmap consultation; all future slices must check `docs/TelOS-Io_Development_Roadmap.md` and relevant BAT OS Development history for alignment. Io remains strictly prototypal; Python only via FFI.
- 2025-09-19: Adopted DOE-style, whole-system-first testing philosophy. We will run minimal smokes only for invariants and otherwise test vertical slices live end-to-end, accepting crashes as learning signals. Prefer reusing existing regression runners over creating new demos.
- 2025-09-19: Establish `TELOS_AUTONOMY_TODO.md` as the single source of truth for session state and task flow.
- 2025-09-19: Chose lightweight, best-effort JSON field extraction to avoid adding a parser dependency, since logs are JSONL with predictable keys; sufficient for filtering and stats.
- 2025-09-19: Main loop stabilization: Avoid storing or iterating GC-managed Io objects in C; restrict loop to safe logging and bounded iterations. Re-enabled `Telos.mainLoop` in sample.
- 2025-09-19: Event handling path: Route events Io-first (`world handleEvent`), then fall through to C stub for logging; event maps accessed via `atIfAbsent` to avoid sending selectors to maps.
 - 2025-09-19: API contract — treat C-exposed Io methods as canonical (`createWorld`, `mainLoop`, `createMorph`, `addSubmorph`, `removeSubmorph`, `draw`, `handleEvent`). Avoid `_raw*` names in Io layer; add a C `addMorphToWorld` seam so Io-created morphs can be rendered by the C draw loop without duplicating world state.
 - 2025-09-19: JSON export/import minimalism — reuse existing spec emitters (`toSpec`) and keep import as scaffold without implementing a full JSON parser; prefer world seeding via `loadConfig` and internal tools to stay dependency-light at this phase.
- 2025-09-19: Persistence format v0: Append-only `SET <slot> TO <value>` lines for morph changes. Begin/End markers and replay will be added later; current goal is visibility and smoke-testable living image.
- 2025-09-19: WAL framing v0: `BEGIN <tag> {json?}` and `END <tag>` helpers to group interactions/frames for future replay tooling.
- 2025-09-19: WAL replay v0: parse `SET <id>.<slot> TO <value>` and apply to matching morphs by `id`. Read file content into memory and iterate lines for simplicity.
 - 2025-09-19: To avoid GC instability, replay must not mutate sibling order or sort lists; `zIndex` is persisted and can be interpreted by future renderers without Io-side list sorting.
 - 2025-09-19: WAL rotation kept deliberately simple (single backup slot) to minimize complexity; can extend to N-rotation later if needed.
- 2025-09-19: Scoring heuristic chosen for offline safety: token overlap against persona ethos/style/routing hints plus a small brevity bonus when persona favors precision; bounded to [0,1]. Avoids JSON parsing in flush by naive field extraction to keep dependencies minimal.
 - 2025-09-19: Explicit Io receiver usage for raw C slots — call `Telos Telos_rawRagIndex`/`Telos Telos_rawRagQuery` to avoid lookup on `Protos`. Avoid default parameters in Io method signatures; set defaults inside method body. Guard optional slots via `hasSlot` (e.g., `autoReplay`).

- 2025-09-20: Ollama bridge strategy — execute embedded Python with a shared env dict (globals==locals) to persist imports; try `/api/chat` first (with optional `system` as first message), then `/api/generate`, and finally strip `:latest` if needed. Keep `keep_alive` set to `"0s"` to avoid lingering models. Retain enriched error messages for DOE diagnostics. This keeps the Io→C→Python seam robust while preserving prototypal Io purity.

- 2025-09-20: WAL framing and recovery — Treat `BEGIN/END` as commit boundaries and ignore trailing incomplete frames during replay to improve durability after crashes. Preserve legacy behavior by scanning for `SET` lines when no frames are found to maintain backward compatibility with older WALs. Implemented purely in Io to avoid GC instability; no Io VM/C changes needed.

- 2025-09-20: pyEval seam minimalism — Implemented a minimal eval/exec bridge returning stringified results or empty string, prioritizing a stable Io→C→Python seam over rich result types. We will iterate on environment persistence and richer marshaling (JSON in/out) under Roadmap Phase 4.

## References
- Copilot Ops Guide: `.github/copilot-instructions.md`
- Logging & Curation: `docs/Logging_and_Curation.md`
- Ollama Setup: `docs/Ollama_Setup.md`
- Samples: `samples/telos/`

## Meta-Prompt for New Session (Copy/Paste into a fresh chat)
You are GitHub Copilot operating inside a private repository to build TelOS. Follow this exactly:

1) Read `/mnt/c/EntropicGarden/TELOS_AUTONOMY_TODO.md`. Treat it as the single source of truth for this session. Maintain it as you work.
2) Rules:
   - WSL-first: build/run/test only in WSL Ubuntu; use `/mnt/c/...` paths and the WSL-built `io` binary.
   - Living slice: each step integrates UI (Canvas), FFI (Io→C→Python), and Persistence (state/logging).
   - Prototypal Io: use clones/message passing; no classes.
   - Maintain the checklist: exactly one item in-progress; update after each tool batch with deltas in Work Log; record Decisions.
   - Orientation: Before coding, review `docs/TelOS-Io_Development_Roadmap.md` and any relevant `docs/*` blueprints. State which Roadmap phase your slice implements and its acceptance criteria; then proceed.
3) Start by validating the current in-progress checklist item and continue autonomously until it’s completed. Then proceed to the next.
4) Keep edits minimal and targeted; run small smoke tests after substantive changes.
5) If blocked by missing info, make the most reasonable assumption, proceed, and document it in the Decisions Log.

When ready, begin by updating the Live Checklist status for the current item to in-progress (if not already), then perform the next concrete action.

---

## Work Log (2025-09-20)
- Fixed Persona.converse default-argument pitfall by moving defaults into method body and explicitly calling `self composeSystemPrompt`.
- Added `contextKernel` initialization in `Persona.init` and lazy load in `composeSystemPrompt` to avoid missing-slot errors.
- Rebuilt in WSL and ran `samples/telos/persona_chat_console_demo.io`: window opened via WSLg, two chat turns printed `[OFFLINE_STUB_COMPLETION]`, window closed cleanly.
 - Canvas heartbeat made loopable: `Canvas.heartbeat(n)` now calls `Telos.mainLoop` n times to keep the window alive longer during demos.
 - Persona chat demo updated to wait: added extra `cv heartbeat` calls before and after each LLM request and before closing, so the window stays open long enough to observe output.
 - Repaired stray Io source corruption: removed accidental `"ollama serve"` fragment in `libs/Telos/io/IoTelos.io` that caused a `Block does not respond to 'ollama'` exception.
 - Verified telos models registered in WSL (`/api/tags` shows `telos/{alfred,babs,brick,robin}:latest`). Demo now opens and breathes; LLM calls still return `[OLLAMA_ERROR] request failed` (bridge payload/endpoint investigation next).

## Decisions Log (2025-09-20)
- Avoid Io default arguments in method signatures; set defaults inside the method body to prevent parser misinterpretation.
- Initialize persona context eagerly and guard with lazy-load in `composeSystemPrompt`.
 - Keep UI visible: prefer loopable heartbeats over sleeps to stay within Morphic invariants; use `Canvas.heartbeat(n)` around I/O.
 - Source hygiene: protect Io files from stray terminal text; added a check to grep for unexpected tokens when demo exceptions appear.
