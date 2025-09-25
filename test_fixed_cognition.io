#!/usr/bin/env io

"🧠 Testing Fixed Cognitive System..." println

// Initialize TelOS cognitive system
Telos initializeCognition

// Test GCE retrieval
"Testing GCE (System 1)..." println
gceResult := Telos cognition gce retrieve("quantum consciousness", nil)
"GCE candidates:" println
gceResult foreach(candidate, candidate println)

// Test HRC reasoning  
"Testing HRC (System 2)..." println
hrcResult := Telos cognition hrc reason("artificial intelligence", nil, gceResult)
"HRC result:" println
hrcResult println

// Test complete cognitive query
"Testing complete cognitive query..." println
cogResult := Telos cognitiveQuery("What is consciousness?", "neuroscience")
"Cognitive result:" println
cogResult println

"✅ Fixed Cognitive System Test Complete" println