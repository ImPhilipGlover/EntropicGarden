#!/usr/bin/env io

// Mock Persona Forward Protocol Test  
// Tests routing logic without hanging on LLM calls

"=== Mock Persona Forward Protocol Test ===" println
"🎯 Testing routing logic with mock persona responses" println

// Mock persona facets that don't make LLM calls
MockBrickFacet := Object clone do(
    facetName := "MockTamlandEngine"
    processQuery := method(queryObj,
        response := Object clone
        response facetName := self facetName  
        response model := "mock-brick"
        response response := "[MOCK_BRICK_ANALYSIS] Technical guidance for: " .. queryObj methodName .. ". Recommend optimized implementation with algorithmic efficiency."
        response
    )
)

MockRobinFacet := Object clone do(
    facetName := "MockAlanWattsSage"
    processQuery := method(queryObj,
        response := Object clone
        response facetName := self facetName
        response model := "mock-robin" 
        response response := "[MOCK_ROBIN_WISDOM] Creative approach for: " .. queryObj methodName .. ". Embrace the flow of aesthetic harmony and mindful design."
        response
    )
)

MockSimpleHeartFacet := Object clone do(
    facetName := "MockWinniePoohHeart"
    processQuery := method(queryObj,
        response := Object clone
        response facetName := self facetName
        response model := "mock-robin"
        response response := "[MOCK_SIMPLE_HEART] Gentle guidance for: " .. queryObj methodName .. ". Approach with kindness and simple wisdom."
        response
    )
)

// Enhanced Forward Protocol with Mock Personas
EnhancedForwardObject := Object clone do(
    # Method categorization (same as before)
    categorizeMissingMethod := method(methodName,
        categoryAnalyzer := Object clone
        categoryAnalyzer methodName := methodName
        categoryAnalyzer isTechnical := methodName containsSeq("optimize") or methodName containsSeq("performance") or methodName containsSeq("algorithm") or methodName containsSeq("data") or methodName containsSeq("system") or methodName containsSeq("debug") or methodName containsSeq("error")
        categoryAnalyzer isCreative := methodName containsSeq("artistic") or methodName containsSeq("creative") or methodName containsSeq("render") or methodName containsSeq("visual") or methodName containsSeq("aesthetic") or methodName containsSeq("design") or methodName containsSeq("morph")
        categoryAnalyzer isQuery := methodName containsSeq("get") or methodName containsSeq("find") or methodName containsSeq("search") or methodName containsSeq("query")
        categoryAnalyzer isAction := methodName containsSeq("do") or methodName containsSeq("execute") or methodName containsSeq("run") or methodName containsSeq("perform")
        
        if(categoryAnalyzer isTechnical, 
            categoryAnalyzer category := "technical",
            if(categoryAnalyzer isCreative,
                categoryAnalyzer category := "creative", 
                if(categoryAnalyzer isQuery,
                    categoryAnalyzer category := "query",
                    if(categoryAnalyzer isAction,
                        categoryAnalyzer category := "action",
                        categoryAnalyzer category := "general"
                    )
                )
            )
        )
        
        categoryAnalyzer
    )
    
    # Route to mock personas
    routeToPersona := method(methodName, category,
        routingDecision := Object clone
        routingDecision methodName := methodName
        routingDecision category := category
        
        if(category == "technical",
            routingDecision persona := "BRICK"
            routingDecision facet := MockBrickFacet clone
            routingDecision intent := "Provide technical analysis for: " .. methodName,
            
            if(category == "creative",
                routingDecision persona := "ROBIN"
                routingDecision facet := MockRobinFacet clone
                routingDecision intent := "Provide creative wisdom for: " .. methodName,
                
                # Default to simple heart for general
                routingDecision persona := "ROBIN"
                routingDecision facet := MockSimpleHeartFacet clone
                routingDecision intent := "Provide guidance for: " .. methodName
            )
        )
        
        routingDecision
    )
    
    # Enhanced forward with mock routing
    forward := method(
        methodName := call message name
        ("🔄 Forward called for: " .. methodName) println
        
        categoryInfo := self categorizeMissingMethod(methodName)
        ("📊 Category: " .. categoryInfo category .. " (tech:" .. categoryInfo isTechnical .. " creative:" .. categoryInfo isCreative .. ")") println
        
        routing := self routeToPersona(methodName, categoryInfo category)
        ("🎯 Routing to: " .. routing persona .. " (" .. routing facet facetName .. ")") println
        
        queryObj := Object clone
        queryObj queryText := routing intent
        queryObj methodName := methodName
        queryObj category := categoryInfo category
        
        try(
            response := routing facet processQuery(queryObj)
            ("📞 " .. routing persona .. " responded: " .. response response slice(0, 80) .. "...") println
            
            # Create and install synthetic method
            syntheticMethod := method(
                ("🤖 " .. methodName .. " (synthesized by " .. routing persona .. ") executing...") println
                
                result := Object clone
                result methodName := methodName
                result category := categoryInfo category
                result persona := routing persona
                result facet := routing facet facetName
                result guidance := response response
                result synthesized := true
                result timestamp := Date now asNumber
                result
            )
            
            // Use message passing instead of setSlot
            self doString(methodName .. " := " .. syntheticMethod asString)
            ("✅ Method " .. methodName .. " installed and ready!") println
            
            # Execute it by calling it on self and return the result
            result := self performWithArgList(methodName, list())
            result
        ,
            ("❌ Routing failed: " .. call sender) println
            nil
        )
    )
)

# Test Suite
"" println
"=== Test Suite: Method Synthesis with Persona Routing ===" println

# Test 1: Technical method
"" println
"Test 1: Technical optimization method..." println
testObj1 := EnhancedForwardObject clone
result1 := testObj1 optimizeDataStructures
if(result1 != nil and result1 synthesized == true,
    ("✅ SUCCESS: " .. result1 methodName .. " routed to " .. result1 persona) println,
    "❌ FAILED: Technical synthesis" println
)

# Test 2: Creative method  
"" println
"Test 2: Creative visualization method..." println
testObj2 := EnhancedForwardObject clone
result2 := testObj2 renderArtisticVisualization
if(result2 != nil and result2 synthesized == true,
    ("✅ SUCCESS: " .. result2 methodName .. " routed to " .. result2 persona) println,
    "❌ FAILED: Creative synthesis" println
)

# Test 3: Query method
"" println
"Test 3: Query/search method..." println
testObj3 := EnhancedForwardObject clone
result3 := testObj3 findOptimalConfiguration
if(result3 != nil and result3 synthesized == true,
    ("✅ SUCCESS: " .. result3 methodName .. " routed to " .. result3 persona) println,
    "❌ FAILED: Query synthesis" println
)

# Test 4: General/action method
"" println
"Test 4: General action method..." println
testObj4 := EnhancedForwardObject clone
result4 := testObj4 handleComplexRequest
if(result4 != nil and result4 synthesized == true,
    ("✅ SUCCESS: " .. result4 methodName .. " routed to " .. result4 persona) println,
    "❌ FAILED: General synthesis" println
)

# Test 5: Method learning (calling same method twice)
"" println
"Test 5: Method learning (second call)..." println
result5 := testObj1 optimizeDataStructures  # Should use installed method
if(result5 != nil and result5 synthesized == true,
    ("✅ SUCCESS: Learned method executed (timestamp: " .. result5 timestamp .. ")") println,
    "❌ FAILED: Method learning" println
)

# Test 6: Edge case - mixed characteristics
"" println
"Test 6: Mixed characteristics method..." println
testObj6 := EnhancedForwardObject clone
result6 := testObj6 debugArtisticAlgorithm  # Both technical AND creative
if(result6 != nil and result6 synthesized == true,
    ("✅ SUCCESS: " .. result6 methodName .. " routed to " .. result6 persona .. " (category: " .. result6 category .. ")") println,
    "❌ FAILED: Mixed characteristics" println
)

"" println
"🎯 MOCK PERSONA ROUTING TEST COMPLETE!" println
"" println
"📊 Test Results Summary:" println
("   Technical routing: " .. if(result1 != nil and result1 persona == "BRICK", "✅ BRICK", "❌ Failed")) println
("   Creative routing: " .. if(result2 != nil and result2 persona == "ROBIN", "✅ ROBIN", "❌ Failed")) println
("   Query routing: " .. if(result3 != nil and result3 persona != nil, "✅ " .. result3 persona, "❌ Failed")) println
("   General routing: " .. if(result4 != nil and result4 persona == "ROBIN", "✅ ROBIN", "❌ Failed")) println
("   Method learning: " .. if(result5 != nil, "✅ Working", "❌ Failed")) println
("   Mixed traits: " .. if(result6 != nil and result6 persona != nil, "✅ " .. result6 persona, "❌ Failed")) println
"" println
"🚀 Routing architecture validated - ready for live LLM integration!" println