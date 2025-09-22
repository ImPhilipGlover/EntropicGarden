// Vertical Slice: Persona-guided UI plan that applies to the Morphic world
Telos init
Telos createWorld

// Ask ROBIN to propose a plan and apply it
res := Telos commands run("ui.plan.apply", list("ROBIN", "Compose a small banner: a red rectangle as a bar and a text label at top-left"))
writeln("apply result: ", res)

// If nothing applied, fall back to a minimal deterministic plan DSL
if(res == nil or res asString containsSeq("applied:0"),
    plan := """
let bar = newRect 10 10 220 28 0.9 0.2 0.2 1
let label = newText 16 16 TelOS
front label
"""
    _ := Telos ui parseAndApply(plan, Map clone atPut("source", "ui_plan_slice_fallback"))
)

// Save snapshots for provenance
_ := Telos saveSnapshot(nil)
_ := Telos saveSnapshotJson(nil)

// Short heartbeat
Telos ui heartbeat(1)
