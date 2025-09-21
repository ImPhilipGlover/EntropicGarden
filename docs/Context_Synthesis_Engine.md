# Context Synthesis Engine

**Purpose**: Automatically synthesize information from multiple sources to provide agents with comprehensive context without manual document consultation.

## Core Synthesis Architecture

### Information Sources (Input Streams)
1. **`TELOS_AUTONOMY_TODO.md`** - Current work state, decisions, progress
2. **`docs/TelOS-Io_Development_Roadmap.md`** - Phase requirements, acceptance criteria
3. **`Io Prototype Programming Training Guide.txt`** - Prototypal programming principles
4. **`Morphic UI Framework Training Guide Extension.txt`** - UI philosophy, direct manipulation
5. **`Building TelOS with Io and Morphic.txt`** - Overall architectural vision
6. **`TelOS-Python-Archive/BAT OS Development/`** - Historical context, patterns
7. **Agent Memory Bank** - Cross-session learning, successful patterns

### Synthesis Process Flow

```
CONTEXT_SYNTHESIS_ENGINE := {
    
    // Phase 1: Information Ingestion
    current_state := extract_runbook_state(),
    roadmap_context := extract_current_phase_requirements(),
    prototypal_principles := extract_programming_guidelines(),
    morphic_philosophy := extract_ui_principles(),
    architectural_vision := extract_system_blueprint(),
    historical_patterns := extract_successful_implementations(),
    learned_patterns := load_agent_memory(),
    
    // Phase 2: Context Integration
    synthesized_context := integrate_information_streams(),
    priority_matrix := calculate_context_priorities(),
    action_recommendations := generate_next_actions(),
    
    // Phase 3: Decision Support
    architectural_constraints := derive_design_constraints(),
    implementation_templates := select_applicable_patterns(),
    validation_criteria := define_acceptance_requirements()
}
```

## Automated Context Extraction

### Runbook State Extractor
```python
def extract_runbook_state():
    return {
        "current_in_progress": get_current_todo_item(),
        "completed_items": list_completed_todos(),
        "recent_decisions": extract_latest_decisions(),
        "work_log_patterns": analyze_recent_work(),
        "blockers_identified": scan_for_impediments(),
        "next_priorities": predict_upcoming_work()
    }
```

### Roadmap Phase Analyzer
```python
def extract_current_phase_requirements():
    current_phase = identify_active_roadmap_phase()
    return {
        "phase_name": current_phase.name,
        "acceptance_criteria": current_phase.acceptance,
        "cross_phase_seams": current_phase.extension_points,
        "required_pillars": ["UI", "FFI", "Persistence"],
        "integration_requirements": current_phase.vertical_slice_specs,
        "next_phase_prep": current_phase.future_seams
    }
```

### Prototypal Principle Synthesizer
```python
def extract_programming_guidelines():
    return {
        "core_laws": [
            "parameters_are_objects",
            "variables_are_slots", 
            "message_passing_universal",
            "immediate_usability",
            "no_init_ceremonies",
            "avoid_do_scope_issues"
        ],
        "violation_patterns": load_anti_patterns(),
        "transformation_templates": load_prototypal_patterns(),
        "validation_checklist": generate_compliance_checks()
    }
```

### Architectural Vision Synthesizer
```python
def extract_system_blueprint():
    return {
        "core_metaphor": "living_organism_with_zygote_metabolism",
        "philosophy": "taoist_anarchist_tolstoyan",
        "architecture": "io_mind_python_muscle_synaptic_bridge",
        "ui_paradigm": "morphic_direct_manipulation",
        "persistence": "living_image_wal_snapshots",
        "cognition": "vsa_rag_neuro_symbolic_intelligence"
    }
```

## Intelligent Context Integration

### Priority Matrix Calculation
```python
def calculate_context_priorities():
    priority_weights = {
        "prototypal_compliance": 0.3,      # Highest - foundational
        "current_work_continuity": 0.25,   # High - momentum
        "architectural_alignment": 0.2,    # High - coherence
        "vertical_slice_completeness": 0.15, # Medium - integration
        "historical_pattern_reuse": 0.1    # Lower - efficiency
    }
    
    return apply_weights_to_context_elements(priority_weights)
```

### Action Recommendation Generator
```python
def generate_next_actions():
    synthesis = integrate_all_context_streams()
    
    recommendations = {
        "immediate_action": determine_next_concrete_step(synthesis),
        "implementation_approach": select_prototypal_pattern(synthesis),
        "validation_strategy": define_testing_approach(synthesis),
        "integration_points": identify_cross_phase_seams(synthesis),
        "documentation_updates": specify_runbook_changes(synthesis)
    }
    
    return prioritize_recommendations(recommendations)
```

## Decision Support Framework

### Architectural Constraint Derivation
```python
def derive_design_constraints():
    return {
        "prototypal_constraints": [
            "all_parameters_must_be_objects",
            "all_variables_must_be_slots",
            "immediate_usability_required",
            "message_passing_only"
        ],
        "vertical_slice_constraints": [
            "must_include_morphic_ui",
            "must_include_ffi_bridge", 
            "must_include_persistence",
            "must_be_demonstrable"
        ],
        "integration_constraints": [
            "wsl_execution_only",
            "wal_persistence_required",
            "regression_coverage_needed"
        ]
    }
```

### Implementation Template Selector
```python
def select_applicable_patterns():
    current_context = get_synthesized_context()
    
    applicable_patterns = {
        "prototypal_patterns": match_prototypal_templates(current_context),
        "morphic_patterns": match_ui_templates(current_context),
        "persistence_patterns": match_wal_templates(current_context),
        "ffi_patterns": match_bridge_templates(current_context)
    }
    
    return rank_patterns_by_relevance(applicable_patterns)
```

## Usage Integration

### Pre-Action Context Synthesis
```python
def synthesize_context_for_action():
    """Called before any significant agent action"""
    
    # Automated context gathering
    context = CONTEXT_SYNTHESIS_ENGINE.synthesize()
    
    # Priority-based focus
    focused_context = context.apply_priority_filter()
    
    # Action-specific recommendations
    recommendations = context.generate_recommendations()
    
    return {
        "synthesized_context": focused_context,
        "recommended_actions": recommendations,
        "validation_criteria": context.acceptance_requirements,
        "prototypal_constraints": context.design_constraints
    }
```

### Continuous Context Updates
```python
def update_context_continuously():
    """Called after each agent action batch"""
    
    # Update learned patterns
    update_agent_memory(recent_actions, outcomes)
    
    # Refine synthesis algorithms
    improve_context_integration(feedback_data)
    
    # Evolve recommendation quality
    enhance_action_suggestions(success_patterns)
```

## Context-Aware Agent Workflow

### Enhanced Pre-Code Generation
```python
ENHANCED_WORKFLOW = {
    # OLD: Manual document consultation
    # NEW: Automated context synthesis
    "context": synthesize_context_for_action(),
    
    # OLD: Ad-hoc decision making  
    # NEW: Template-based recommendations
    "approach": select_recommended_implementation(),
    
    # OLD: Manual prototypal checking
    # NEW: Automated constraint application
    "constraints": apply_design_constraints(),
    
    # OLD: Reactive validation
    # NEW: Proactive compliance checking
    "validation": prepare_acceptance_criteria()
}
```

### Enhanced Post-Code Generation
```python
POST_GENERATION_SYNTHESIS = {
    # Automated compliance validation
    "prototypal_score": validate_prototypal_compliance(),
    
    # Context-aware integration testing
    "integration_validation": test_vertical_slice_completeness(),
    
    # Continuous learning update
    "pattern_learning": update_successful_patterns(),
    
    # Synthesis improvement
    "context_refinement": improve_synthesis_quality()
}
```

## Expected Outcomes

### Autonomy Improvements
1. **Reduced Manual Consultation**: From 5-10 document reads per action to 0
2. **Faster Context Integration**: From 2-3 minutes to 10-15 seconds
3. **Better Decision Quality**: Template-based recommendations vs ad-hoc choices
4. **Proactive Problem Prevention**: Constraint checking vs reactive fixing

### Prototypal Compliance Improvements  
1. **Systematic Constraint Application**: Automated vs manual checking
2. **Pattern-Based Implementation**: Templates vs from-scratch coding
3. **Continuous Learning**: Cross-session improvement vs session isolation
4. **Predictive Validation**: Pre-code compliance vs post-code fixing

### Implementation Efficiency
1. **Context Synthesis**: 10-15 seconds automated vs 2-3 minutes manual
2. **Decision Making**: Template selection vs architectural research
3. **Validation**: Automated compliance checking vs manual review
4. **Learning**: Persistent pattern improvement vs repeated mistakes

This Context Synthesis Engine transforms agent workflow from manual, reactive consultation to automated, proactive intelligence synthesis.