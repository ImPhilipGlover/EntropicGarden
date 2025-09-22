// samples/telos/prototypal_purity_demo.io
//
// This script demonstrates and validates the prototypal purity refactoring
// of IoTelos.io. It tests:
// 1. Morph creation and manipulation with object-based parameters.
// 2. WAL persistence of these prototypal operations.
// 3. World state replay from the WAL.
// 4. Snapshot functionality before and after replay.
// 5. The command router's ability to use the refactored methods.

"--- Prototypal Purity Demo ---" println
"This demo will create morphs, save their state, replay it, and verify consistency." println

// Clean up previous run artifacts
File with("telos.wal") remove
File with("logs/snapshot_before.txt") remove
File with("logs/snapshot_after.txt") remove

// --- Phase 1: Create and Manipulate World ---

"1. Initializing World and Creating Morphs" println
Telos createWorld
Telos openWindow // Open a window to see the changes

// Create a red rectangle using object parameters
rect1 := Telos createMorph("Rectangle")
pos1 := Object clone do(x := 50; y := 50)
dim1 := Object clone do(width := 100; height := 75)
color1 := Object clone do(r := 1; g := 0; b := 0; a := 1)
rect1 moveTo(pos1)
rect1 resizeTo(dim1)
rect1 setColor(color1)
Telos addSubmorph(Telos world, rect1)

// Create a blue rectangle using the command router
"2. Creating a second morph via command router" println
blueArgs := list(200, 150, 80, 80, 0, 0, 1, 1)
blueRectId := Telos commands run("newRect", blueArgs)
"  - Created blue rectangle with ID: " .. blueRectId println

// Create a text morph
"3. Creating a text morph" println
textArgs := list(100, 250, "Prototypal!")
textMorphId := Telos commands run("newText", textArgs)
"  - Created text morph with ID: " .. textMorphId println

// Manipulate the blue rectangle using the command router
"4. Manipulating morphs via command router" println
moveArgs := list(blueRectId, 220, 160)
Telos commands run("move", moveArgs)
resizeArgs := list(blueRectId, 90, 90)
Telos commands run("resize", resizeArgs)

"5. Capturing pre-replay snapshot" println
Telos saveSnapshot("logs/snapshot_before.txt")
"  - Snapshot saved to logs/snapshot_before.txt" println

"--- Phase 2: Replay and Verification ---"

"6. Destroying and recreating the world for replay" println
// We create a new world to ensure we are starting from a clean slate
Telos createWorld

"  - World is now empty. Replaying from WAL..." println
Telos replayWal("telos.wal")
"  - WAL replay complete." println

"7. Capturing post-replay snapshot for verification" println
Telos saveSnapshot("logs/snapshot_after.txt")
"  - Snapshot saved to logs/snapshot_after.txt" println

"8. Verifying consistency" println
beforeSnap := File with("logs/snapshot_before.txt") contents
afterSnap := File with("logs/snapshot_after.txt") contents

if(beforeSnap == afterSnap,
    "SUCCESS: Snapshots match. Prototypal persistence is working correctly." println,
    "FAILURE: Snapshots do not match. There is an issue with persistence or replay." println
    "--- BEFORE ---" println
    beforeSnap println
    "--- AFTER ---" println
    afterSnap println
)

"9. Running main loop for visual confirmation (3 seconds)" println
Telos ui heartbeat(3) // Run for 3 seconds to see the result

"--- Demo Complete ---" println
"Check the console output and the snapshots in the 'logs' directory." println
"The window should show a red rectangle, a blue square, and the text 'Prototypal!'." println
