// TELOS HRC System smoke validation
// Ensures the HRC system can be initialized and basic operations work

TelosHRCSmoke := Object clone do(
    assert := method(condition, message,
        if(condition,
            true,
            Exception raise("TelosHRCSmoke assertion failed: " .. message)
        )
    )

    loadHRCSystem := method(
        // Load dependencies first
        doRelativeFile("../Telos/io/TelosBridge.io")
        doRelativeFile("../Telos/io/TelosFederatedMemory.io")
        doRelativeFile("../Telos/io/TelosHRC.io")

        assert(Lobby hasSlot("Telos"), "Telos namespace not available")
        assert(Telos hasSlot("HRC"), "HRC system not loaded")
        assert(Telos hasSlot("GenerativeKernel"), "GenerativeKernel not loaded")
        assert(Telos hasSlot("LLMTransducer"), "LLMTransducer not loaded")
        assert(Telos hasSlot("PromptTemplate"), "PromptTemplate not loaded")

        Telos HRC
    )

    testHRCInitialization := method(
        hrc := Telos HRC

        // Test basic properties
        assert(hrc thetaSuccess == 0.8, "thetaSuccess not set correctly")
        assert(hrc thetaDisc == 0.3, "thetaDisc not set correctly")
        assert(hrc maxIterations == 10, "maxIterations not set correctly")

        // Test initial state
        stats := hrc getStatistics
        assert(stats at("activeCycles") == 0, "Should start with no active cycles")
        assert(stats at("autopoiesisEnabled") == true, "Autopoiesis should be enabled")

        hrc
    )

    testCognitiveCycleCreation := method(hrc,
        // Test starting a cognitive cycle
        query := Map clone
        query atPut("type", "test")
        query atPut("message", "test query")

        context := Map clone
        context atPut("test", true)

        cycleId := hrc startCognitiveCycle(query, context)
        assert(cycleId != nil, "Cycle ID should not be nil")
        assert(cycleId size > 0, "Cycle ID should not be empty")

        // Check that cycle is active
        status := hrc getCycleStatus(cycleId)
        assert(status at("cycleId") == cycleId, "Cycle ID mismatch")
        assert(status at("status") == "running" or status at("status") == "completed", "Cycle should be running or completed")

        cycleId
    )

    testPromptTemplateSystem := method(
        pt := Telos PromptTemplate

        // Test getting a template
        template := pt getTemplate("doesNotUnderstand", Map clone atPut("message", "test"), Map clone)
        assert(template != nil, "Template should not be nil")
        assert(template containsSeq("test"), "Template should contain the test message")

        // Test template statistics
        stats := pt getStatistics
        assert(stats at("totalTemplates") > 0, "Should have templates loaded")

        pt
    )

    testLLMTransducer := method(
        transducer := Telos LLMTransducer

        // Test basic transduction
        request := Map clone
        request atPut("method", "generate")
        request atPut("prompt", "Hello world")
        request atPut("model", "test")

        result := transducer transduce(request)
        assert(result at("success") == true, "Transduction should succeed")
        assert(result at("result") != nil, "Should have a result")

        transducer
    )

    run := method(
        hrc := loadHRCSystem
        testHRCInitialization(hrc)
        cycleId := testCognitiveCycleCreation(hrc)
        testPromptTemplateSystem
        testLLMTransducer

        // Clean up
        Telos stop

        "ok"
    )
)

result := try(TelosHRCSmoke run)
if(result type == "Exception",
    System log("TelosHRCSmoke failure: " .. result message)
    result pass
)

System log("TelosHRCSmoke success")</content>
<parameter name="filePath">c:/EntropicGarden/libs/tests/telos_hrc_smoke.io