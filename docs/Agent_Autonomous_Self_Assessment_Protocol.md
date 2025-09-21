# Agent Autonomous Self-Assessment Protocol

**Purpose**: Enable Copilot agents to automatically validate their prototypal compliance and autonomy effectiveness through systematic self-assessment.

## Core Self-Assessment Framework

### 1. Prototypal Purity Validator

Every agent must run this self-assessment after generating any Io code:

**Automated Compliance Checklist:**
```
PROTOTYPAL_PURITY_SCAN := {
    "parameters_as_objects": scan_for_simple_parameter_usage(),
    "variables_as_slots": scan_for_direct_variable_assignments(), 
    "message_passing_flow": scan_for_property_access_violations(),
    "scope_management": scan_for_do_block_issues(),
    "initialization_ceremonies": scan_for_init_method_patterns(),
    "class_like_thinking": scan_for_static_hierarchy_patterns()
}

COMPLIANCE_SCORE := calculate_weighted_score(PROTOTYPAL_PURITY_SCAN)
```

**Self-Assessment Questions:**
1. **Parameter Object Compliance**: "Did I treat every method parameter as a prototypal object accessed through message passing?"
2. **Variable Slot Compliance**: "Did I use `obj slot := value` instead of `var := value` for all internal variables?"
3. **Message Passing Compliance**: "Did I access everything through object messages, never direct variable references?"
4. **Scope Management**: "Did I avoid `do()` blocks and use explicit slot assignment instead?"
5. **Immediate Usability**: "Can every prototype I created be used immediately after cloning without initialization?"
6. **Anti-Class Compliance**: "Did I avoid any patterns that resemble class-based thinking?"

### 2. Autonomy Effectiveness Validator

Assess autonomous operation effectiveness:

**Autonomous Operation Checklist:**
```
AUTONOMY_ASSESSMENT := {
    "decision_independence": count_human_prompts_required(),
    "vertical_slice_completion": verify_ui_ffi_persistence_integration(),
    "runbook_maintenance": verify_todo_updates_and_work_log(),
    "proactive_problem_solving": count_self_initiated_fixes(),
    "context_synthesis": verify_foundational_document_integration()
}

AUTONOMY_SCORE := calculate_autonomy_effectiveness(AUTONOMY_ASSESSMENT)
```

**Self-Assessment Questions:**
1. **Decision Independence**: "Did I make architectural decisions without waiting for human approval?"
2. **Living Slice Completeness**: "Does my work integrate UI, FFI, and Persistence in a single vertical slice?"
3. **Documentation Discipline**: "Did I update the runbook with work logs and decisions after each batch?"
4. **Proactive Excellence**: "Did I identify and fix issues before they were reported?"
5. **Context Integration**: "Did I synthesize information from foundational training documents?"

### 3. Automated Self-Correction Protocol

When compliance violations are detected:

**Violation Detection and Correction:**
```
if COMPLIANCE_SCORE < 0.8:
    trigger_automatic_refactoring()
    suggest_prototypal_alternatives()
    request_human_review_if_critical()

if AUTONOMY_SCORE < 0.7:
    increase_proactive_decision_making()
    expand_vertical_slice_scope()
    enhance_context_synthesis()
```

**Self-Correction Actions:**
1. **Prototypal Violations**: Automatically suggest transformations from class-like to prototypal patterns
2. **Scope Issues**: Recommend explicit slot assignment alternatives to `do()` blocks
3. **Parameter Problems**: Transform simple parameters into prototypal objects
4. **Autonomy Gaps**: Identify missed opportunities for independent action
5. **Context Gaps**: Integrate missing foundational principles

## Implementation in Agent Workflow

### Pre-Code Generation Phase
```
CONTEXT_SYNTHESIS := synthesize_foundational_context()
ROADMAP_ALIGNMENT := identify_current_phase_requirements()
PROTOTYPAL_READINESS := validate_prototypal_mindset()
```

### Post-Code Generation Phase
```
PROTOTYPAL_COMPLIANCE := run_prototypal_purity_validator()
AUTONOMY_EFFECTIVENESS := run_autonomy_validator()
SELF_CORRECTION := apply_automatic_fixes_if_needed()
RUNBOOK_UPDATE := document_assessment_results()
```

### Continuous Learning Loop
```
PATTERN_RECOGNITION := identify_successful_prototypal_patterns()
KNOWLEDGE_ACCUMULATION := add_to_cross_session_memory()
BEST_PRACTICE_EVOLUTION := update_pattern_library()
```

## Assessment Scoring System

### Prototypal Purity Score (0.0 - 1.0)
- **1.0**: Perfect prototypal compliance - all parameters are objects, all variables are slots, pure message passing
- **0.8**: Good compliance with minor violations (acceptable threshold)
- **0.6**: Moderate violations requiring attention
- **0.4**: Significant class-like thinking present
- **0.0**: Complete class-like violation - requires immediate refactoring

### Autonomy Effectiveness Score (0.0 - 1.0)
- **1.0**: Full autonomous operation - no human prompts needed, complete vertical slices, proactive problem solving
- **0.7**: Good autonomy with minor dependency (acceptable threshold)
- **0.5**: Moderate autonomy gaps requiring improvement
- **0.3**: High human dependency, reactive operation
- **0.0**: Completely dependent operation - requires workflow redesign

## Integration with Existing Workflow

### Runbook Updates
Every self-assessment must be recorded in `TELOS_AUTONOMY_TODO.md`:

```
## Self-Assessment Log
- Prototypal Purity Score: X.X/1.0
- Autonomy Effectiveness Score: X.X/1.0
- Violations Detected: [list]
- Self-Corrections Applied: [list]
- Learning Patterns Identified: [list]
```

### Continuous Improvement
- Track score trends across sessions
- Identify recurring violation patterns
- Evolve best practices based on successful implementations
- Build institutional memory for future agents

## Expected Outcomes

1. **Higher Prototypal Compliance**: Systematic validation catches violations before they propagate
2. **Increased Autonomy**: Self-assessment drives more independent decision making
3. **Faster Learning**: Automated feedback accelerates pattern recognition
4. **Better Documentation**: Structured assessment improves runbook quality
5. **Cross-Session Consistency**: Persistent learning maintains architectural coherence

This protocol transforms agent workflow from reactive compliance checking to proactive prototypal intelligence.