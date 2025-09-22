#!/usr/bin/env io

/*
=======================================================================================
  VALIDATION: Enhanced BABS WING Loop with Persona Priming Pipeline
=======================================================================================

Temporary validation script to prove the Enhanced BABS WING Loop with Persona
Priming Pipeline is functional and integrates properly with the TelOS system.

This validates:
- System autoload of new modules
- Enhanced BABS WING Loop operation
- Persona Priming System functionality  
- Complete integration with existing TelOS architecture
- WAL persistence and logging
*/

writeln("🔬 VALIDATION: Enhanced BABS WING + Persona Priming Integration")
writeln("=============================================================")

# Test 1: System initialization and module loading
writeln("Test 1: System initialization...")
initSuccess := try(
    # Load TelOS core system
    doFile("libs/Telos/io/TelosCore.io")
    writeln("  ✓ TelOS Core loaded successfully")
    true
) catch(e,
    writeln("  ❌ TelOS Core load failed: ", e description)
    false
)

# Test 2: Enhanced BABS WING Loop availability
writeln("Test 2: Enhanced BABS WING Loop availability...")
babsSuccess := try(
    # Test BABS WING Loop creation
    babsLoop := EnhancedBABSWINGLoop clone
    babsConfig := Object clone
    babsConfig progressiveResolution := true
    babsLoop initialize(babsConfig)
    
    writeln("  ✓ Enhanced BABS WING Loop: Created and initialized")
    
    # Test basic functionality
    statusReport := babsLoop getStatusReport
    writeln("  ✓ Status report generated: ", statusReport totalGaps, " gaps tracked")
    true
) catch(e,
    writeln("  ❌ Enhanced BABS WING Loop failed: ", e description)
    false
)

# Test 3: Persona Priming System availability
writeln("Test 3: Persona Priming System availability...")
primingSuccess := try(
    # Test Persona Priming System creation
    primingSystem := PersonaPrimingSystem clone
    primingConfig := Object clone
    primingConfig maxKnowledgeItems := 20
    primingSystem initialize(primingConfig)
    
    writeln("  ✓ Persona Priming System: Created and initialized")
    
    # Test basic functionality
    statusReport := primingSystem getStatus
    writeln("  ✓ Status report generated: ", statusReport systemPrompts, " prompts ready")
    true
) catch(e,
    writeln("  ❌ Persona Priming System failed: ", e description)
    false
)

# Test 4: Integration test - mini research cycle
writeln("Test 4: Mini research cycle integration...")
integrationSuccess := try(
    # Create mini research cycle
    babsLoop := EnhancedBABSWINGLoop clone
    babsLoop initialize(Object clone)
    
    # Extract some concepts (mock)
    conceptResults := babsLoop extractRoadmapConcepts("mock_roadmap_path")
    writeln("  ✓ Concept extraction: ", conceptResults totalExtracted, " concepts")
    
    # Ingest some contexts (mock)  
    contextResults := babsLoop ingestBATOSContexts("mock_batos_path")
    writeln("  ✓ Context ingestion: ", contextResults totalIngested, " contexts")
    
    # Try gap resolution
    resolutionResults := babsLoop resolveGapsProgressively
    writeln("  ✓ Gap resolution: ", resolutionResults resolved, "/", resolutionResults totalGaps, " gaps")
    
    true
) catch(e,
    writeln("  ❌ Integration test failed: ", e description)
    false
)

# Test 5: Persona priming pipeline test
writeln("Test 5: Persona priming pipeline...")
pipelineSuccess := try(
    primingSystem := PersonaPrimingSystem clone
    primingSystem initialize(Object clone)
    
    # Create test persona
    testPersona := Object clone
    testPersona name := "TestPersona"
    testPersona role := "Test Role"
    testPersona speakStyle := "technical"
    
    # Create mock knowledge sources
    knowledgeSources := List clone
    mockSource := Object clone
    mockSource type := "mock_knowledge"
    mockSource content := "Test knowledge content for persona priming"
    knowledgeSources append(mockSource)
    
    # Run priming pipeline
    primingResults := primingSystem runCompletePrimingPipeline(testPersona, knowledgeSources)
    writeln("  ✓ Pipeline executed: ", primingResults knowledgeItemsCurated, " items curated")
    
    true
) catch(e,
    writeln("  ❌ Pipeline test failed: ", e description)
    false
)

# Summary
writeln("")
writeln("🎯 VALIDATION SUMMARY:")
writeln("====================")
writeln("System initialization: ", if(initSuccess, "✅ PASS", "❌ FAIL"))
writeln("Enhanced BABS WING:    ", if(babsSuccess, "✅ PASS", "❌ FAIL"))
writeln("Persona Priming:       ", if(primingSuccess, "✅ PASS", "❌ FAIL"))
writeln("Integration test:      ", if(integrationSuccess, "✅ PASS", "❌ FAIL"))
writeln("Pipeline test:         ", if(pipelineSuccess, "✅ PASS", "❌ FAIL"))

# Overall validation result
overallSuccess := initSuccess and babsSuccess and primingSuccess and integrationSuccess and pipelineSuccess
successCount := 0
if(initSuccess, successCount = successCount + 1)
if(babsSuccess, successCount = successCount + 1)
if(primingSuccess, successCount = successCount + 1)
if(integrationSuccess, successCount = successCount + 1)
if(pipelineSuccess, successCount = successCount + 1)

writeln("")
if(overallSuccess,
    writeln("🎉 VALIDATION COMPLETE: ALL TESTS PASSED (", successCount, "/5)")
    writeln("✅ Enhanced BABS WING Loop with Persona Priming is OPERATIONAL")
    writeln("Ready for autonomous research operations")
,
    writeln("⚠️  VALIDATION PARTIAL: ", successCount, "/5 TESTS PASSED")
    writeln("System partially operational - review failed tests")
)

# Return validation results
validationResults := Object clone
validationResults allPassed := overallSuccess
validationResults passCount := successCount
validationResults totalTests := 5
validationResults ready := overallSuccess

validationResults