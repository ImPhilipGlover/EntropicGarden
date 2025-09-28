# AutoPrompt Search Guidelines

This document explains how to perform and log external internet searches per the AutoPrompt `External Intelligence` policy.

When to search
- After exhausting local docs, repo history, and targeted code reads.
- For clarifying language/runtime/library behavior, finding upstream bug reports, or discovering canonical examples.

How to craft a query
- Include subsystem, error text or symptom, language/runtime and version, and the specific goal.
- Example: `synaptic_bridge error json_parse_string segfault parson C11 clang-13`.

Permitted sources
- Official docs (language references, library docs), RFCs, GitHub issues, Stack Overflow, vendor KBs.
- Avoid unvetted or proprietary sources unless corroborated.

Timebox
- Spend no more than 15 minutes per blocking research question. If unresolved, summarize findings and choose next action.

Logging template (use `scripts/log_search.py`)
- Use the helper script to append a structured entry to `run_log.md`.
Example command:

```bash
python scripts/log_search.py \
   --query "synaptic_bridge json_parse_string segfault" \
   --results-file /tmp/search_results.json \
   --action "Adjusted null-termination in synaptic_bridge_io.c" \
   --cite "github.com 2025-09-27" "stackoverflow.com 2024-11-03" \
   --os "Ubuntu 22.04" --python "3.10.6" --cmake "3.25.0" --tools "clang-13" "ollama-1.2"
```

You can also include or override git metadata. If `--commit` and `--user` are omitted, the script tries to auto-detect them from the repository (git rev-parse HEAD, git config user.name).

Example with explicit commit/user:

```bash
python scripts/log_search.py \
   --query "synaptic_bridge json_parse_string segfault" \
   --results-file /tmp/search_results.json \
   --action "Adjusted null-termination in synaptic_bridge_io.c" \
   --commit "abcdef1234567890" --user "phil" \
   --cite "github.com 2025-09-27" --os "Ubuntu 22.04" --python "3.10.6"
```

Example run_log entry (what the script appends)

---
AutoPrompt External Search
Timestamp: 2025-09-27T12:34:00Z
Query: synaptic_bridge json_parse_string segfault
Citations: github.com 2025-09-27, stackoverflow.com 2024-11-03

Top results:
1. Parson JSON parser - GitHub
   https://github.com/kgabis/parson
   Notes about null-termination in parse_string implementation

2. Stack Overflow - json parse string c segfault
   https://stackoverflow.com/questions/xxxxx
   Discussion about ensuring C strings are null-terminated before parsing

Derived action: Added explicit null-terminator when copying JSON into shared memory
---

Security and privacy
- Never paste secrets or private hostnames into queries. Redact before searching.
- Prefer public, canonical sources.

Citation conventions
- Short citation in AutoPrompt header: `[domain.com YYYY-MM-DD]`
- Full URLs go into `run_log.md` entries created by the helper script.

Questions or contributions
- If you'd like a different log format or extra metadata (e.g., OS, tool versions), say which fields to include and I can add them to `scripts/log_search.py`.

Autonomy reference
- The repository `AutoPrompt.txt` now contains an "AUTONOMOUS DECISION GUIDELINES" section describing when the agent may act without explicit user approval (low-risk edits, triage, timed diagnostics). See `AutoPrompt.txt` for the definitive policy. Example allowed autonomous action: fixing a missing null-terminator in `synaptic_bridge_io.c`, then running the affected native tests and logging the outcome.

User-granted full autonomy
- On 2025-09-27 the repository owner explicitly authorized the agent to make all operational decisions autonomously. This grant was recorded in `run_log.md` with the query "User autonomy grant: full autonomous decisions" and will be used as provenance for future autonomous actions. The agent will still follow the Safety, Timeboxing, and Logging rules from `AutoPrompt.txt`.
