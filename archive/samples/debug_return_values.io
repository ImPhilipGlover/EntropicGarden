#!/usr/bin/env io

// Debug Return Values
// Check what the forward method is actually returning

"=== Debug Return Values ===" println

MockBrickFacet := Object clone do(
    facetName := "MockTamlandEngine"
    processQuery := method(queryObj,
        response := Object clone
        response facetName := self facetName  
        response response := "[MOCK_RESPONSE]"
        response
    )
)

TestObj := Object clone do(
    forward := method(
        methodName := call message name
        ("🔄 Forward for: " .. methodName) println
        
        facet := MockBrickFacet clone
        queryObj := Object clone
        queryObj methodName := methodName
        response := facet processQuery(queryObj)
        
        syntheticMethod := method(
            ("🤖 Synthetic called") println
            result := Object clone
            result methodName := methodName
            result persona := "BRICK"
            result synthesized := true
            result
        )
        
        // Use message passing instead of setSlot
        self doString(methodName .. " := " .. syntheticMethod asString)
        result := self performWithArgList(methodName, list())
        
        ("📊 Returning from forward: " .. result type) println
        if(result hasSlot("synthesized"),
            ("📊 Result synthesized: " .. result synthesized) println,
            "📊 Result missing synthesized slot!" println
        )
        
        result
    )
)

"" println
"Test call..." println
obj := TestObj clone
result := obj testMethod

"" println
("Final result type: " .. result type) println
if(result hasSlot("synthesized"),
    ("Final result synthesized: " .. result synthesized) println,
    "Final result missing synthesized!" println
)

if(result != nil and result synthesized == true,
    "✅ Test condition would pass" println,
    "❌ Test condition fails" println
)

"" println
"🔍 Debug complete!" println