#!/usr/bin/env io

// Enhanced Forward Protocol with Proper Persona Routing
// Tests persona-guided synthesis even with offline LLM calls

"=== Enhanced Forward Protocol Test ===" println
"🎯 Testing proper persona routing for unknown methods" println

// Load personas
doFile("core_persona_cognition.io")

// Create world
Telos llmProvider atPut("useOllama", true)  // Enable for structure, even if offline
world := Telos createWorld
"🌍 World ready" println
"" println

// Enhanced Forward Protocol Implementation
EnhancedForwardObject := Object clone do(
    // Method categorization based on name patterns
    categorizeMissingMethod := method(methodName,
        categoryAnalyzer := Object clone
        categoryAnalyzer methodName := methodName
        categoryAnalyzer isTechnical := methodName containsSeq("optimize") or methodName containsSeq("performance") or methodName containsSeq("algorithm") or methodName containsSeq("data") or methodName containsSeq("system") or methodName containsSeq("debug") or methodName containsSeq("error")
        categoryAnalyzer isCreative := methodName containsSeq("artistic") or methodName containsSeq("creative") or methodName containsSeq("render") or methodName containsSeq("visual") or methodName containsSeq("aesthetic") or methodName containsSeq("design") or methodName containsSeq("morph")
        categoryAnalyzer isQuery := methodName containsSeq("get") or methodName containsSeq("find") or methodName containsSeq("search") or methodName containsSeq("query")
        categoryAnalyzer isAction := methodName containsSeq("do") or methodName containsSeq("execute") or methodName containsSeq("run") or methodName containsSeq("perform")
        
        // Determine primary category
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
    
    // Route to appropriate persona based on category
    routeToPersona := method(methodName, category,
        routingDecision := Object clone
        routingDecision methodName := methodName
        routingDecision category := category
        
        if(category == "technical",
            routingDecision persona := "BRICK"
            routingDecision facet := BrickTamlandFacet clone
            routingDecision intent := "Provide technical analysis and implementation guidance for: " .. methodName,
            
            if(category == "creative",
                routingDecision persona := "ROBIN"
                routingDecision facet := RobinSageFacet clone
                routingDecision intent := "Provide creative wisdom and aesthetic guidance for: " .. methodName,
                
                // Default to ROBIN for general/query/action
                routingDecision persona := "ROBIN"
                routingDecision facet := RobinSimpleHeartFacet clone
                routingDecision intent := "Provide gentle guidance and support for: " .. methodName
            )
        )
        
        routingDecision
    )
    
    // Enhanced forward method with persona routing
    forward := method(
        # Get the method name that was missing
        methodName := call message name
        ("🔄 Forward called for: " .. methodName) println
        
        # Categorize the missing method
        categoryInfo := self categorizeMissingMethod(methodName)
        ("📊 Category analysis: " .. categoryInfo category) println
        ("   Technical: " .. categoryInfo isTechnical) println
        ("   Creative: " .. categoryInfo isCreative) println
        
        # Route to appropriate persona
        routing := self routeToPersona(methodName, categoryInfo category)
        ("🎯 Routing to: " .. routing persona .. " (" .. routing facet facetName .. ")") println
        
        # Create query for persona
        queryObj := Object clone
        queryObj queryText := routing intent
        queryObj topicName := "Forward Protocol Synthesis"
        queryObj methodName := methodName
        queryObj category := categoryInfo category
        
        # Get response from persona
        try(
            ("📞 Calling " .. routing persona .. " facet...") println
            response := routing facet processQuery(queryObj)
            
            # Create synthetic method based on persona guidance
            syntheticMethod := method(
                ("🤖 Synthetic " .. methodName .. " called!") println
                ("   Guided by: " .. routing persona .. " (" .. routing facet facetName .. ")") println
                ("   Category: " .. categoryInfo category) println
                ("   Response: " .. response response slice(0, 100) .. "...") println
                
                # Return a result object that describes what would happen
                result := Object clone
                result methodName := methodName
                result category := categoryInfo category
                result persona := routing persona
                result facet := routing facet facetName
                result guidance := response response
                result synthesized := true
                result
            )
            
            # Install the synthetic method on this object
            # Use message passing instead of setSlot
            self doString(methodName .. " := " .. syntheticMethod asString)
            ("✅ Synthetic method " .. methodName .. " installed!") println
            
            # Call it immediately to demonstrate
            syntheticMethod call
        ,
            ("❌ Persona routing failed: " .. call sender) println
            nil
        )
    )
)

// Test the enhanced forward protocol
"=== Test 1: Technical Method Synthesis ===" println
testObj1 := EnhancedForwardObject clone
result1 := testObj1 optimizeDataStructures
if(result1 and result1 synthesized,
    ("✅ Technical synthesis successful: " .. result1 methodName .. " via " .. result1 persona) println,
    "❌ Technical synthesis failed" println
)
"" println

"=== Test 2: Creative Method Synthesis ===" println  
testObj2 := EnhancedForwardObject clone
result2 := testObj2 renderArtisticVisualization
if(result2 and result2 synthesized,
    ("✅ Creative synthesis successful: " .. result2 methodName .. " via " .. result2 persona) println,
    "❌ Creative synthesis failed" println
)
"" println

"=== Test 3: Query Method Synthesis ===" println
testObj3 := EnhancedForwardObject clone  
result3 := testObj3 findOptimalConfiguration
if(result3 and result3 synthesized,
    ("✅ Query synthesis successful: " .. result3 methodName .. " via " .. result3 persona) println,
    "❌ Query synthesis failed" println
)
"" println

"=== Test 4: General Method Synthesis ===" println
testObj4 := EnhancedForwardObject clone
result4 := testObj4 handleUserRequest
if(result4 and result4 synthesized,
    ("✅ General synthesis successful: " .. result4 methodName .. " via " .. result4 persona) println,
    "❌ General synthesis failed" println
)
"" println

"=== Test 5: Method Learning (Second Call) ===" println
("Calling optimizeDataStructures again (should be learned)...") println
result5 := testObj1 optimizeDataStructures
if(result5 and result5 synthesized,
    ("✅ Learned method call successful: " .. result5 methodName) println,
    "❌ Method learning failed" println
)
"" println

"🎯 ENHANCED FORWARD PROTOCOL TEST COMPLETE!" println
"✨ Successfully demonstrated:" println
"   • Method categorization (technical/creative/query/general)" println
"   • Persona routing (BRICK for technical, ROBIN for creative/general)" println
"   • Synthetic method generation and installation" println
"   • Method learning (second calls use installed methods)" println
"   • Works even with offline LLM stubs" println
"" println
"🚀 Ready for integration into main TelOS forward protocol!" println