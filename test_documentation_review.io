#!/usr/bin/env io

// Test script for TelOS Compiler documentation review integration
// This script demonstrates the documentation review system that forces
// reading of Io .html guides and architectural documents during compiler failures

"🧪 Testing TelOS Compiler Documentation Review Integration" println

// Import the TelosCompiler
TelosCompiler := doFile("libs/Telos/io/TelosCompiler.io")

// Create compiler instance
compiler := TelosCompiler clone

// Initialize with mock bridge for testing
MockBridge := Object clone do(
    submitTask := method(task, bufferSize,
        // Simulate Python bridge response
        operation := task at("operation")
        if(operation == "review_documentation",
            // Return mock successful response
            Map clone atPut("success", true) atPut("doc_path", task at("doc_path")) atPut("guidance", "Mock guidance from " .. task at("doc_path")) atPut("relevant", true) atPut("content_length", 1234)
            ,
            Map clone atPut("success", false) atPut("error", "Unknown operation")
        )
    )
)

compiler setSlot("bridge", MockBridge clone)

"✅ Mock bridge initialized" println

// Test documentation review triggering
"🔍 Testing documentation review trigger..." println
compiler triggerDocumentationReview("io", "Io file contains class-based patterns")

"✅ Documentation review integration test completed" println