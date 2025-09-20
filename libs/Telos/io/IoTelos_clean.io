/*
   IoTelos.io - TelOS Synaptic Bridge: Prototypal Implementation
   Everything is a prototype with behaviors - no classes, no init methods
   */

// Provide a minimal global map(...) fallback (no-arg support) for this environment
map := method(
    m := Map clone
    // Note: Named-argument parsing not implemented; acts as empty Map literal.
    m
)

// Provide a helper on Map to safely read with default
Map atIfAbsent := method(key, default,
    v := self at(key)
    if(v == nil, default, v)
)

// Provide a helper on List to safely read with default
List atIfAbsent := method(index, default,
    if(index isNil, return default)
    if(index < 0, return default)
    if(self size <= index, return default)
    self at(index)
)

// Extend the C-level Telos prototype with living behaviors (immediately usable)
Telos := Lobby Protos Telos clone

// Immediate state - no initialization needed, directly usable
Telos verbose := false
Telos world := nil
Telos morphs := List clone
Telos morphIndex := Map clone
Telos isReplaying := false
Telos autoReplay := false

// Determine stable WAL path (prototypal - state is immediate)
Telos walPath := "telos.wal"
repoRoot := "/mnt/c/EntropicGarden"
if(Directory with(repoRoot) exists,
    Telos walPath = repoRoot .. "/telos.wal"
)

// Living behaviors emerge through message passing
Telos log := method(msg,
    if(verbose == true, writeln(msg))
)

// Pillar 1: Synaptic Bridge - Reach into Python muscle
Telos getPythonVersion := method(
    resend
)

// Pillar 2: Transactional persistence
Telos transactional_setSlot := method(obj, slotName, value,
    resend(obj, slotName, value)
    self log("TelOS: Transactional persistence - slot '" .. slotName .. "' set to '" .. value .. "'")
    "ok"
)

// WAL marker helpers
Telos walAppend := method(line,
    // Write to stable WAL path
    p := self walPath ifNil("telos.wal")
    f := File with(p)
    f openForAppending
    f write(line .. "\n")
    f close
    "ok"
)

Telos mark := method(tag, info,
    if(tag == nil, tag = "mark")
    if(info == nil, info = Map clone)
    info atPut("t", Date clone now asNumber)
    line := "MARK " .. tag .. " " .. info asString
    self walAppend(line)
)

// Pillar 3: Create living world
Telos createWorld := method(
    resend
    morphProto := Lobby getSlot("Morph")
    self world := morphProto clone
    self world x := 0
    self world y := 0 
    self world width := 800
    self world height := 600
    self world submorphs := List clone
    self log("Telos: Morphic World created (living canvas: " .. world width .. "x" .. world height .. ")")
    world
)

// Start the main event loop - the heart of the living interface
Telos mainLoop := method(
    if(world == nil, return "Telos: No world exists - call createWorld first")
    self log("Telos: Entering Morphic main loop (living interface active)")
    resend
    "Telos: Morphic main loop completed"
)

// Create a new morph - a living visual object
Telos createMorph := method(morphType,
    // Create an Io-level Morph and register
    if(morphType == nil, morphType = "RectangleMorph")
    morphProto := Lobby getSlot(morphType)
    if(morphProto == nil, morphProto = Lobby getSlot("Morph"))
    m := morphProto clone
    if(m hasSlot("submorphs") not, m submorphs := List clone)
    morphs append(m)
    // Index by id
    if(self hasSlot("morphIndex") not, self morphIndex := Map clone)
    self morphIndex atPut(m id asString, m)
    self log("Telos: Morph created and added to living hierarchy")
    m
)

// Event dispatch - direct manipulation
Telos dispatchEvent := method(event,
    if(world == nil, return false)
    // Try Io-level event handling first
    if(world hasSlot("handleEvent"),
        result := world handleEvent(event)
        if(result, return result)
    )
    // Fall back to C handling
    if(self hasSlot("handleEvent"), self handleEvent(event))
    true
)

// Hit testing
Telos hitTest := method(x, y,
    if(world == nil, return list())
    self morphsAt(x, y)
)

Telos morphsAt := method(x, y,
    found := List clone
    if(world != nil and world hasSlot("submorphs"),
        world submorphs foreach(morph,
            if(morph containsPoint(x, y), found append(morph))
        )
    )
    found
)

// Capture current state
Telos captureScreenshot := method(
    if(world == nil, return "No world to capture")
    
    writeln("--- Morph Tree Snapshot ---")
    self draw
    
    // Return snapshot info
    snapshot := "World: " .. world width .. "x" .. world height
    if(world hasSlot("submorphs"),
        snapshot = snapshot .. " (" .. world submorphs size .. " morphs)"
    )
    snapshot
)

// Draw world and morphs
Telos draw := method(
    if(world != nil,
        writeln("Telos: Drawing world (" .. world width .. "x" .. world height .. ")")
        if(world hasSlot("submorphs"),
            world submorphs foreach(morph, morph draw)
        )
    )
)

writeln("Telos: Zygote pillars loaded - mind touches muscle, heartbeat begins, first glance opens")

// Morph prototype - immediately usable, no initialization needed
Morph := Object clone
Morph id := System uniqueId
Morph x := 100
Morph y := 100
Morph width := 50
Morph height := 50
Morph color := list(1, 0, 0, 1)  // Red by default
Morph submorphs := List clone
Morph owner := nil
Morph dragging := false
Morph dragDX := 0
Morph dragDY := 0
Morph zIndex := 0
Morph persistedIdentity := false

// When cloning, new identity emerges automatically
Morph clone := method(
    newMorph := resend
    newMorph id := System uniqueId
    newMorph submorphs := List clone
    newMorph
)

// Move the morph (direct manipulation)
Morph moveTo := method(newX, newY,
    self x = newX
    self y = newY
    if(Telos isReplaying == false,
        if(persistedIdentity == false,
            Telos transactional_setSlot(self, id .. ".type", self type)
            persistedIdentity = true
        )
        Telos transactional_setSlot(self, id .. ".position", "(" .. x .. "," .. y .. ")")
    )
    "Telos: Morph moved to living position"
)

// Resize the morph
Morph resizeTo := method(newWidth, newHeight,
    self width = newWidth
    self height = newHeight
    if(Telos isReplaying == false,
        if(persistedIdentity == false,
            Telos transactional_setSlot(self, id .. ".type", self type)
            persistedIdentity = true
        )
        Telos transactional_setSlot(self, id .. ".size", "(" .. width .. "x" .. height .. ")")
    )
    "Telos: Morph resized in living space"
)

// Change color
Morph setColor := method(r, g, b, a,
    if(g == nil,
        // Single argument - assume it's a list
        self color = r
    ,
        // Four arguments
        if(a == nil, a = 1)
        self color = list(r, g, b, a)
    )
    if(Telos isReplaying == false,
        if(persistedIdentity == false,
            Telos transactional_setSlot(self, id .. ".type", self type)
            persistedIdentity = true
        )
        Telos transactional_setSlot(self, id .. ".color", color asString)
    )
    "Telos: Morph color changed"
)

// Set z-index for layering
Morph setZIndex := method(newZ,
    self zIndex = newZ
    if(Telos isReplaying == false,
        if(persistedIdentity == false,
            Telos transactional_setSlot(self, id .. ".type", self type)
            persistedIdentity = true
        )
        Telos transactional_setSlot(self, id .. ".zIndex", zIndex asString)
    )
    "Telos: Morph z-index updated"
)

// Set a specific ID for the morph
Morph setId := method(newId,
    self id = newId
    "Telos: Morph ID set"
)

// Basic drawing behavior
Morph draw := method(
    writeln("Morph#" .. id .. " @(" .. x .. "," .. y .. ") " .. width .. "x" .. height .. " z=" .. zIndex .. " color=" .. color asString)
    if(hasSlot("submorphs"),
        submorphs foreach(child,
            writeln("  " .. child asString)
        )
    )
)

// Contains point test
Morph containsPoint := method(px, py,
    (px >= x) and (px <= (x + width)) and (py >= y) and (py <= (y + height))
)

// Event handling
Morph handleEvent := method(event,
    // Children first
    if(hasSlot("submorphs"),
        submorphs foreach(m, if(m handleEvent(event), return true))
    )
    // Handle drag events
    t := event atIfAbsent("type", "")
    ex := event atIfAbsent("x", 0)
    ey := event atIfAbsent("y", 0)
    
    if(t == "mouseDown" and containsPoint(ex, ey),
        dragging = true
        dragDX = ex - x
        dragDY = ey - y
        writeln("Telos: Event received (direct manipulation ready)")
        return true
    )
    if(t == "mouseMove" and dragging,
        moveTo(ex - dragDX, ey - dragDY)
        writeln("Telos: Event received (direct manipulation ready)")
        return true
    )
    if(t == "mouseUp" and dragging,
        dragging = false
        writeln("Telos: Event received (direct manipulation ready)")
        return true
    )
    false
)

// Add submorph
Morph addSubmorph := method(child,
    if(hasSlot("submorphs") not, submorphs := List clone)
    submorphs append(child)
    child owner := self
    "Morph: Child added to living hierarchy"
)

// Rectangle morph - specialized behavior
RectangleMorph := Morph clone

RectangleMorph draw := method(
    writeln("  RectangleMorph#" .. id .. " @(" .. x .. "," .. y .. ") " .. width .. "x" .. height .. " z=" .. zIndex .. " color=" .. color asString)
)

// Toggle color on click (red <-> green)
RectangleMorph handleEvent := method(event,
    // Children first
    if(hasSlot("submorphs"),
        submorphs foreach(m, if(m handleEvent(event), return true))
    )
    t := event atIfAbsent("type", "")
    if(t == "click",
        // Check bounds
        if(self containsPoint(event atIfAbsent("x", 0), event atIfAbsent("y", 0)),
            current := color
            // Decide based on red channel
            red := current at(0) ifNil(1)
            if(red > 0.5,
                setColor(0, 1, 0, 1),
                setColor(1, 0, 0, 1)
            )
            writeln("Telos: RectangleMorph toggled color at (" .. x .. "," .. y .. ")")
            return true
        )
    )
    // Fallback to generic behavior (e.g., dragging)
    resend
)

// Text morph - for displaying text (prototypal)
TextMorph := Morph clone
TextMorph text := "Hello TelOS" 
TextMorph fontSize := 12

TextMorph draw := method(
    writeln("    TextMorph#" .. id .. " @(" .. x .. "," .. y .. ") " .. width .. "x" .. height .. " z=" .. zIndex .. " color=" .. color asString .. " text='" .. text .. "'")
)

TextMorph setText := method(newText,
    self text = newText
    if(Telos isReplaying == false,
        if(persistedIdentity == false,
            Telos transactional_setSlot(self, id .. ".type", self type)
            persistedIdentity = true
        )
        Telos transactional_setSlot(self, id .. ".text", newText)
    )
    "Telos: Text morph updated with living message"
)