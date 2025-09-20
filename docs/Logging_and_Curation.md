# TelOS Logging and Curation (JSONL)

This slice instruments persona LLM calls and tool use, and adds a curation queue for future VSA+NN rRAG processing into golden datasets.

## Files
- `logs/persona_llm.jsonl` — One JSON object per persona LLM call:
  - `t` (timestamp), `persona`, `provider`, `model`, `prompt`, `system`, `options`, `duration_ms`, `output`
- `logs/tool_use.jsonl` — Tool invocations and their results
  - `t`, `tool`, `result`
- `logs/curation_queue.jsonl` — Queue for deferred curation
  - `kind` ("llm" | "tool"), `key`, `path` (log source), `record`
- `logs/candidate_gold.jsonl` — Produced by a flush; ready for offline curation

## API
- Io: `Telos llmCall(spec)`
  - Merges persona defaults (`genOptions`) and per-call overrides, calls provider (Ollama or offline), and writes a JSONL entry.
- Io: `Telos toolUse(toolSpec)`
  - Logs a JSONL entry for tool activity.
- Io: `Telos curator enqueue(map)`
  - Adds an entry to curation queue; later consumed by rRAG.
- Io: `Telos curator flushToCandidates(limit := 1000)`
  - Moves up to `limit` entries from the queue into `candidate_gold.jsonl` and clears the queue.
- C: `Telos_rawLogAppend(path, line)`
  - Appends a line to a file, creating `logs/` on demand.

## Usage (WSL)
1. Run any TelOS script that makes LLM calls or tool uses.
2. Inspect logs in `logs/`.
3. Produce candidates:
   ```
   io -e 'Telos curator flushToCandidates(1000) println'
   ```

## Next Steps
- Implement a curator that:
  - Computes embeddings and clusters (VSA)
  - Scores quality signals (length, perplexity proxies, latency, persona consistency)
  - Emits deduplicated, ranked candidate gold records
- Add a Python muscle that exports these candidates into a fine-tuning dataset format
