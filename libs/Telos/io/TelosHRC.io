//
// TELOS Phase 3: Hierarchical Reflective Cognition (HRC) System
//
// This file loads and integrates all the HRC actor prototypes for the
// cognitive core. The individual actors are implemented in separate files
// to maintain the 300-line file size limit.
//
// Key Components:
// - HRCOrchestrator: Central coordinator for cognitive cycles
// - CognitiveCycle: Individual reasoning cycle implementation
// - PendingResolution: Placeholder for unresolved computations
// - GenerativeKernel: LLM-powered code and response generation
// - LLMTransducer: Natural language transduction interface
// - PromptTemplate: Versioned prompt template management
//

// Load individual actor files
Lobby doFile("HRCOrchestrator.io")
Lobby doFile("CognitiveCycle.io")
Lobby doFile("PendingResolution.io")
Lobby doFile("GenerativeKernel.io")
Lobby doFile("LLMTransducer.io")
Lobby doFile("PromptTemplate.io")

// =============================================================================
// Integration with IoVM doesNotUnderstand mechanism
// =============================================================================

// Override the default doesNotUnderstand behavior
Object oldDoesNotUnderstand := Object doesNotUnderstand
Object doesNotUnderstand := method(
    // First try the original behavior
    result := oldDoesNotUnderstand(@call message, @call sender, @call evalArgs)

    // If that failed, escalate to HRC
    if(result isNil or result type == "Exception",
        hrcResult := Telos HRC handleDoesNotUnderstand(@call message, self, @call evalArgs)
        if(hrcResult,
            return hrcResult
        )
    )

    result
    markChanged
)

// =============================================================================
// System Integration
// =============================================================================

// Ensure all actors are properly initialized
if(Telos hasSlot("HRC") not or Telos HRC isNil,
    Telos HRC := HRCOrchestrator clone init()
)

// Auto-load message
"TELOS Phase 3 HRC System loaded successfully" println