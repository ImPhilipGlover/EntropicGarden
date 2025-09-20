# Persona Priming Method: Curate → Summarize → Pack → Converse

Goal: Give each persona (BRICK, ROBIN, BABS, ALFRED) a living “voice” by feeding its LLM with carefully curated context from BAT OS Development codex materials. Conversation with these personas becomes the primary UX.

## Stages

1) Curate (per persona)
- Source: BAT OS Development docs (e.g., Persona Codex Entropy Maximization, AURA’s Living Codex Protocol, Morphic UI plans).
- Filter by persona’s `memoryTags` and routing hints.
- Output: a set of short passages (quotes/paraphrases) that capture vows, metaphors, and canonical moves.

2) Summarize (compress to stable kernels)
- Create a compact kernel for each theme: ethos, invariants, do/don’t, voice patterns, tool affordances.
- Keep < 1–2k tokens per persona kernel to fit within prompt budgets.

3) Pack (system prompt assembly)
- Compose a structured system prompt:
  - Persona card: name, role, ethos (bulleted vows), speakStyle hints
  - Behavioral constraints: do/don’t, failure modes to avoid
  - Memory tags (for retrieval hints) and tool affordances
  - Alignment hooks (for ALFRED: contract policy and meta-commentary function)

4) Converse (runtime)
- For an incoming `userMsg` and (optional) `history`, call:
  - `Persona.composeSystemPrompt()`
  - `Telos.llmCall(map(system: systemPrompt, prompt: userMsg, history: history, provider: cfg))`
- ALFRED meta-loop (optional):
  - `ALFRED.commentOn(persona, reply)`
  - If issues detected, return annotated feedback or propose a revision.

## Io Integration
- `Telos codex.getPassages(persona)` returns curated text chunks (stub offline; later from VSA store).
- `Persona.loadPersonaContext()` pulls passages via codex and caches a small `contextKernel`.
- `Persona.composeSystemPrompt()` wraps kernel into the system prompt with vows and style.
- `Persona.converse(userMsg, history)` sends system + user + history to `Telos.llmCall:`.

### BABS: Research (WING) Loop
- Identify low-confidence ConceptFractals: `Persona.identifyConceptGaps(concepts)`
- Draft WING prompts for a human Deep Research tool: `Persona.suggestWingPrompts(gapConcepts)`
- Ingest returned research as ContextFractals: `Persona.ingestResearchReport(concept, reportText)`
- Refine ConceptFractals by binding the new contexts and re-summarizing; persist provenance.

## Contracts and Safety
- Persona vows act as creative constraints; ALFRED ensures contracts are met.
- Budget and risk: adjustable per persona; offline-safe fallback with deterministic stubs.

## Future
- Replace codex stub with VSA-RAG retrieval by `memoryTags`.
- Extend ALFRED’s check to policy graphs and test assertions.
