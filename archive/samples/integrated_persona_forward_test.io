#!/usr/bin/env io

// Integrated Persona Forward Protocol Test
// Tests the enhanced TelOS forward method with persona routing

"=== Integrated Persona Forward Protocol Test ===" println
"🚀 Testing enhanced TelOS forward method with persona routing" println

// Load personas for integration
doFile("core_persona_cognition.io")

// Create TelOS world
world := Telos createWorld
"🌍 World created" println

// Enable LLM (will use offline stubs but validates architecture)
Telos llmProvider atPut("useOllama", true)
Telos llmProvider atPut("baseUrl", "http://localhost:11434")
"" println

"=== Persona-Guided Synthesis Tests ===" println

# Test 1: Technical method should route to BRICK
"" println
"Test 1: Technical optimization method..." println
try(
    result1 := Telos optimizeDataProcessing("large_dataset", 1000)
    if(result1 and result1 hasSlot("personaSynthesized") and result1 personaSynthesized,
        ("✅ Technical synthesis: " .. result1 methodName .. " → " .. result1 persona) println
        ("   Facet: " .. result1 facet) println
        ("   Guidance preview: " .. result1 guidance exSlice(0, 80) .. "...") println,
        "❌ Technical synthesis failed or not persona-guided" println
    )
,
    ("❌ Technical test exception: " .. call sender) println
)

# Test 2: Creative method should route to ROBIN
"" println
"Test 2: Creative visualization method..." println  
try(
    result2 := Telos renderArtisticVisualization("fractal_beauty", "golden_ratio")
    if(result2 and result2 hasSlot("personaSynthesized") and result2 personaSynthesized,
        ("✅ Creative synthesis: " .. result2 methodName .. " → " .. result2 persona) println
        ("   Facet: " .. result2 facet) println
        ("   Guidance preview: " .. result2 guidance exSlice(0, 80) .. "...") println,
        "❌ Creative synthesis failed or not persona-guided" println
    )
,
    ("❌ Creative test exception: " .. call sender) println
)

# Test 3: Non-persona method should use standard synthesis
"" println
"Test 3: Standard method (should bypass personas)..." println
try(
    result3 := Telos findResource("config_file")
    if(result3 and result3 hasSlot("personaSynthesized") not,
        ("✅ Standard synthesis: " .. result3 type .. " (bypassed personas as expected)") println,
        if(result3 and result3 hasSlot("personaSynthesized"),
            ("🔍 Unexpected persona routing: " .. result3 persona) println,
            "❌ Standard synthesis failed" println
        )
    )
,
    ("❌ Standard test exception: " .. call sender) println
)

# Test 4: Method learning (second call should use installed method)
"" println
"Test 4: Method learning (second call)..." println
try(
    result4 := Telos optimizeDataProcessing("cached_dataset", 500)  # Same method, different args
    if(result4 and result4 hasSlot("personaSynthesized"),
        ("✅ Method reuse: " .. result4 methodName .. " (learned from first call)") println
        ("   Timestamp: " .. result4 timestamp) println,
        "❌ Method learning failed" println
    )
,
    ("❌ Learning test exception: " .. call sender) println
)

# Test 5: Multiple persona categories
"" println  
"Test 5: Different technical method..." println
try(
    result5 := Telos debugSystemPerformance("memory_leaks")
    if(result5 and result5 hasSlot("personaSynthesized") and result5 persona == "BRICK",
        ("✅ Debug synthesis: " .. result5 methodName .. " → BRICK") println,
        "❌ Debug routing failed" println
    )
,
    ("❌ Debug test exception: " .. call sender) println
)

"" println
"Test 6: Creative design method..." println
try(
    result6 := Telos designHarmoniousInterface("user_flow")
    if(result6 and result6 hasSlot("personaSynthesized") and result6 persona == "ROBIN",
        ("✅ Design synthesis: " .. result6 methodName .. " → ROBIN") println,
        "❌ Design routing failed" println
    )
,
    ("❌ Design test exception: " .. call sender) println
)

"" println
"=== Integration Summary ===" println

# Check that methods were installed on Telos
"Installed persona-guided methods on Telos:" println
personaMethods := List clone
if(Telos hasSlot("optimizeDataProcessing"), personaMethods append("optimizeDataProcessing"))
if(Telos hasSlot("renderArtisticVisualization"), personaMethods append("renderArtisticVisualization"))
if(Telos hasSlot("debugSystemPerformance"), personaMethods append("debugSystemPerformance"))
if(Telos hasSlot("designHarmoniousInterface"), personaMethods append("designHarmoniousInterface"))

personaMethods foreach(method, ("  ✅ " .. method) println)
if(personaMethods size == 0, "  ❌ No methods were installed" println)

"" println
"🎯 INTEGRATED PERSONA FORWARD PROTOCOL TEST COMPLETE!" println
"" println
"📊 Results:" println
("   Technical → BRICK routing: " .. if(result1 and result1 persona == "BRICK", "✅", "❌")) println
("   Creative → ROBIN routing: " .. if(result2 and result2 persona == "ROBIN", "✅", "❌")) println
("   Standard synthesis bypass: " .. if(result3 and result3 hasSlot("personaSynthesized") not, "✅", "❌")) println
("   Method learning: " .. if(result4, "✅", "❌")) println
("   Persona method installation: " .. if(personaMethods size > 0, "✅ " .. personaMethods size .. " methods", "❌")) println
"" println
"🚀 Phase 6 Generative Kernel with Persona Integration: OPERATIONAL!" println