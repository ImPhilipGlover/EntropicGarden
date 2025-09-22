#!/usr/bin/env io
/*
 * Comprehensive Morphic UI Regression Test
 * Tests: creation, click, drag, z-order, persistence, and replay
 * Part of TelOS autonomous development cycle
 */

// Create world and initial morphs for testing
world := Telos createWorld

// Test 1: Basic Morph Creation
writeln("=== Test 1: Basic Morph Creation ===")
rect1 := Telos createMorph("RectangleMorph") do(
    id := "rect1"
    x := 50
    y := 50
    width := 80
    height := 60
    color := list(1, 0, 0, 1)  // red
)
world addMorph(rect1)

rect2 := Telos createMorph("RectangleMorph") do(
    id := "rect2"
    x := 150
    y := 100
    width := 60
    height := 80
    color := list(0, 1, 0, 1)  // green
)
world addMorph(rect2)

text1 := Telos createMorph("TextMorph") do(
    id := "text1"
    x := 200
    y := 50
    width := 100
    height := 30
    text := "Hello Morphic"
    color := list(0, 0, 1, 1)  // blue
)
world addMorph(text1)

writeln("Created 3 morphs: rect1, rect2, text1")
Telos captureScreenshot

// Test 2: Click Interactions (color toggle)
writeln("\n=== Test 2: Click Interactions ===")
writeln("Simulating click on rect1 at (90, 80)")
clickEvent := Map clone do(
    atPut("type", "click")
    atPut("x", 90)
    atPut("y", 80)
)
Telos dispatchEvent(clickEvent)

writeln("Simulating click on text1 at (250, 65)")
clickEvent2 := Map clone do(
    atPut("type", "click")
    atPut("x", 250)
    atPut("y", 65)
)
Telos dispatchEvent(clickEvent2)

Telos captureScreenshot

// Test 3: Drag Interactions
writeln("\n=== Test 3: Drag Interactions ===")
writeln("Simulating drag of rect2 from (180, 140) to (250, 200)")

// Mouse down
mouseDownEvent := Map clone do(
    atPut("type", "mouseDown")
    atPut("x", 180)
    atPut("y", 140)
)
Telos dispatchEvent(mouseDownEvent)

// Mouse move (drag)
mouseMoveEvent := Map clone do(
    atPut("type", "mouseMove")
    atPut("x", 250)
    atPut("y", 200)
)
Telos dispatchEvent(mouseMoveEvent)

// Mouse up
mouseUpEvent := Map clone do(
    atPut("type", "mouseUp")
    atPut("x", 250)
    atPut("y", 200)
)
Telos dispatchEvent(mouseUpEvent)

Telos captureScreenshot

// Test 4: Z-Order Manipulations
writeln("\n=== Test 4: Z-Order Manipulations ===")
writeln("Moving rect1 to front")
rect1 setZIndex(10)

writeln("Moving text1 to back")
text1 setZIndex(-5)

writeln("rect2 stays at default z-order (0)")
Telos captureScreenshot

// Test 5: WAL Persistence Check
writeln("\n=== Test 5: WAL Persistence Check ===")
writeln("Current WAL contents:")
if(File with("telos.wal") exists,
    walLines := File with("telos.wal") readLines
    walLines foreach(i, line,
        lineStr := line asString
        if(lineStr containsSeq("rect") or lineStr containsSeq("text"),
            writeln("  " .. lineStr)
        )
    )
,
    writeln("  WAL file not found")
)

// Test 6: Snapshot and State Verification
writeln("\n=== Test 6: Final State Verification ===")
writeln("Final morph positions and properties:")
world submorphs foreach(morph,
    if(morph hasSlot("id"),
        writeln("  " .. morph id .. " @(" .. morph x .. "," .. morph y .. ") " .. 
                morph width .. "x" .. morph height .. " z=" .. morph zIndex .. 
                " color=" .. morph color asString)
    )
)

// Test 7: Replay Capability Test
writeln("\n=== Test 7: Replay Capability Test (if supported) ===")
if(Telos hasSlot("replayWal"),
    writeln("Testing WAL replay...")
    
    // Save current state
    Telos captureScreenshot
    preReplaySnapshot := world submorphs map(morph, 
        if(morph hasSlot("id"), 
            morph id .. "@(" .. morph x .. "," .. morph y .. ")",
            "anonymous@(" .. morph x .. "," .. morph y .. ")"
        )
    )
    
    writeln("Pre-replay state: " .. preReplaySnapshot join(", "))
    
    // Clear morphs and replay
    world submorphs empty
    
    // Attempt replay if WAL exists
    if(File with("telos.wal") exists,
        try(
            Telos replayWal("telos.wal")
            writeln("WAL replay completed")
            
            postReplaySnapshot := world submorphs map(morph,
                if(morph hasSlot("id"),
                    morph id .. "@(" .. morph x .. "," .. morph y .. ")",
                    "anonymous@(" .. morph x .. "," .. morph y .. ")"
                )
            )
            writeln("Post-replay state: " .. postReplaySnapshot join(", "))
            
            Telos captureScreenshot
        ) catch(Exception,
            writeln("WAL replay failed: " .. Exception description)
        )
    )
,
    writeln("WAL replay not supported in current implementation")
)

// Test 8: Hit Testing
writeln("\n=== Test 8: Hit Testing ===")
if(Telos hasSlot("hitTest"),
    testPoints := list(
        list(90, 80, "rect1"),
        list(250, 200, "rect2 (after drag)"),
        list(250, 65, "text1"),
        list(10, 10, "empty space")
    )
    
    testPoints foreach(test,
        x := test at(0)
        y := test at(1)
        desc := test at(2)
        hits := Telos hitTest(x, y)
        if(hits size > 0,
            hitIds := hits map(morph, 
                if(morph hasSlot("id"), morph id, "anonymous")
            )
            writeln("  (" .. x .. "," .. y .. ") [" .. desc .. "]: " .. hitIds join(", "))
        ,
            writeln("  (" .. x .. "," .. y .. ") [" .. desc .. "]: no hits")
        )
    )
,
    writeln("Hit testing not supported in current implementation")
)

// Final heartbeat and cleanup
writeln("\n=== Morphic Comprehensive Regression Complete ===")
Telos mainLoop  // Brief heartbeat to show liveness

writeln("All tests completed. Check output above for any failures.")
writeln("Expected: 3 morphs created, colors toggled, rect2 moved, z-order changed")
writeln("WAL should contain SET operations for position, color, and z-index changes")