/*
   TelosFFI.io - Prototypal Io→C→Python Bridge (Io layer)

   Purpose:
   - Extend the Telos prototype with a minimal, safe `pyEval` seam that
	 calls into the C bridge when available and degrades gracefully when not.
   - Follow strict prototypal purity: parameters and variables are objects,
	 no init methods, immediate usability after cloning.

   Roadmap Alignment: Phase 4 (Synaptic Bridge maturation)
*/

// Use the existing Telos prototype installed by TelosCore (do not override)

// Guarded bridge call to the raw C function if available
Telos pyEval := method(codeParam,
	// Parameters are objects accessed via message passing
	param := Object clone
	param code := codeParam

	// Result container as object
	resultObj := Object clone
	resultObj value := ""

	// Check for C-level raw bridge
	hasRaw := self hasSlot("Telos_rawPyEval")

	if(hasRaw,
		// Delegate to C bridge (expected to return a Sequence or Number)
		// Use explicit receiver to avoid accidental Lobby dispatch
		resultObj value := self Telos_rawPyEval(param code asString)
	,
		// Degrade gracefully: return empty string
		resultObj value := ""
	)

	// Coerce to string via prototypal path
	return resultObj value asString
)

// Optional async stub (no-op placeholder seeded for later phases)
// Returns immediate placeholder string; real async handled in C/Python later
Telos pyEvalAsync := method(codeParam,
	asyncParam := Object clone
	asyncParam code := codeParam
	placeholder := Object clone
	placeholder message := "[pyEvalAsync placeholder]"
	placeholder message
)

// Small helper: evaluate a list of snippets and return List of strings
Telos pyEvalMany := method(codeListParam,
	listParam := Object clone
	listParam codes := codeListParam

	out := List clone

	// Defensive checks using message passing
	typeAnalyzer := Object clone
	typeAnalyzer isList := listParam codes type == "List"
	if(typeAnalyzer isList not, return out)

	i := 0
	while(i < listParam codes size,
		snippet := listParam codes at(i)
		out append(self pyEval(snippet))
		i := i + 1
	)
	out
)

// Minimal health indicator for the bridge
Telos ffiHealth := method(
	health := Map clone
	health atPut("hasRawPyEval", self hasSlot("Telos_rawPyEval"))
	health atPut("pyEvalAvailable", self hasSlot("pyEval"))
	health
)

// Module loaded banner (kept terse for DOE smokes)
"TelosFFI.io: Io layer FFI slots installed (pyEval, pyEvalAsync, pyEvalMany, ffiHealth)" println

// Provide a load method placeholder (optional)
TelosFFI := Object clone
TelosFFI load := method(self)

