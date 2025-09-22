#!/usr/bin/env io

// TelOS Autopoietic Living Slice - Minimal, Io-native forward demo
// Requirements: pure prototypal style, no misleading success claims, Morphic UI via Telos
// Run (WSL): TELOS_NONINTERACTIVE=1 /mnt/c/EntropicGarden/tools/run_io.sh 15 /mnt/c/EntropicGarden/samples/telos/autopoietic_simple_demo.io

writeln("\n=== TelOS Autopoietic Living Slice (Minimal forward demo) ===")
writeln("Bootstrap: starting autopoietic object and UI hooks")

// Phase 1: Core Autopoietic System (pure Io forward)
TelosAutopoietic := Object clone
TelosAutopoietic synthesizedCapabilities := Map clone
TelosAutopoietic synthesisEvents := List clone
TelosAutopoietic forward := method(messageName,
    writeln("autopoietic: unknown message → " .. messageName)

    // event record as object slots
    event := Object clone
    event capability := messageName
    event id := (messageName .. "_" .. System uniqueId)
    event timestamp := Date now asString
    event status := "synthesizing"
    self synthesisEvents append(event)
    writeln("memory: recorded synthesis event " .. event id)

    // synthesize a callable method that prints args and returns self
    synthesized := method(
        argsStr := call message arguments asString
        writeln("synthesized: executing '" .. call message name .. "' with args: " .. argsStr)
        self
    )

    // install method under the requested message name
    self setSlot(messageName, synthesized)
    self synthesizedCapabilities atPut(messageName, synthesized)
    event status := "completed"
    writeln("autopoietic: installed capability '" .. messageName .. "'")

    // dispatch original call now that slot exists
    resend
)

TelosAutopoietic showFractalMemoryState := method(
    writeln("state: capabilities=" .. self synthesizedCapabilities size .. ", events=" .. self synthesisEvents size)
    self synthesizedCapabilities keys sort foreach(k, writeln("  capability: " .. k))
    self synthesisEvents foreach(i, e,
        writeln("  event: " .. (i+1) .. " " .. e capability .. " [" .. e id .. "] " .. e status)
    )
    self
)

// Phase 2: WAL (prefer Telos Persistence if present; fallback local)
Wal := Object clone
Wal entries := List clone
Wal write := method(tag, payload,
    // write local record first (always available)
    f := Object clone; f ts := Date now asString; f tag := tag; f payload := payload; f id := System uniqueId
    self entries append(f)
    writeln("wal: " .. tag .. " " .. payload)

    // optional Telos persistence hook if available
    if(Lobby hasSlot("Telos") and Telos hasSlot("persistence") and Telos persistence hasSlot("append"),
        Telos persistence append(tag, payload) ifNonNil(nil)
    )
    f
)
Wal show := method(
    writeln("wal: entries=" .. self entries size)
    self entries foreach(i, f,
        writeln("  " .. (i+1) .. ". [" .. f ts .. "] " .. f tag .. ": " .. f payload)
    )
    self
)

// Phase 3: Morphic UI via Telos (heartbeat + snapshot if available)
Ui := Object clone
Ui start := method(
    if(Lobby hasSlot("Telos") and Telos hasSlot("createWorld"),
        Telos createWorld; writeln("ui: world created"),
        writeln("ui: Telos.createWorld unavailable (running headless fallback)")
    )
    self
)
Ui heartbeat := method(
    if(Lobby hasSlot("Telos") and Telos hasSlot("ui") and Telos ui hasSlot("heartbeat"),
        Telos ui heartbeat; writeln("ui: heartbeat signaled"),
        writeln("ui: heartbeat unavailable")
    )
    self
)
Ui snapshot := method(
    if(Lobby hasSlot("Telos") and Telos hasSlot("saveSnapshot"),
        Telos saveSnapshot; writeln("ui: snapshot requested"),
        writeln("ui: snapshot unavailable")
    )
    self
)

// Phase 4: Demo flow (no success theater; just completion statements)
writeln("demo: begin")
Wal write("DEMO_START", "autopoietic_forward")

// trigger three unknown messages to exercise forward
TelosAutopoietic dreamOfElectricSheep("consciousness", "emergence")
TelosAutopoietic contemplateInfinity("fractals", "recursion")
TelosAutopoietic evolveConsciousness("autopoiesis", "metamorphosis")

writeln("demo: state dump")
TelosAutopoietic showFractalMemoryState

writeln("demo: ui setup")
Ui start; Ui heartbeat; Ui snapshot

writeln("demo: wal dump")
Wal write("DEMO_COMPLETE", "autopoietic_forward_finished")
Wal show

writeln("demo: autopoietic re-invoke (validation)")
TelosAutopoietic dreamOfElectricSheep("validation")
TelosAutopoietic contemplateInfinity("operational_check")
TelosAutopoietic evolveConsciousness("system_validation")

writeln("Test complete: autopoietic_simple_demo finished")