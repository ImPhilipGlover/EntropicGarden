/*
   IoTelos.io - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
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

// Extend the C-level Telos prototype with living behaviors
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

// Minimal JSON stringify for Maps/Lists/Numbers/Strings/Booleans/nil (prototypal)
Telos json := Object clone

Telos json escape := method(s,
    // escape backslash, quotes, and newlines on a mutable copy
    m := s asString asMutable
    m replaceSeq("\\", "\\\\")
    m replaceSeq("\"", "\\\"")
    m replaceSeq("\n", "\\n")
    m
)

Telos json stringify := method(x,
    if(x == nil, return "null")
    t := x type
    if(t == "Number", return x asString)
    if(t == "Sequence", return "\"" .. escape(x) .. "\"")
    if(t == "List",
        parts := x map(v, stringify(v))
        return "[" .. parts join(",") .. "]"
    )
    if(t == "Map",
        parts := List clone
        x foreach(k, v, parts append("\"" .. escape(k) .. "\":" .. stringify(v)))
        return "{" .. parts join(",") .. "}"
    )
    if(x == true, return "true")
    if(x == false, return "false")
    // fallback: string
    return "\"" .. escape(x asString) .. "\""
)

// --- rRAG Skeleton (Io->C->Python bridge) ---
Telos rag := Object clone

Telos rag index := method(docs,
    // docs: List of strings
    if(docs == nil, docs = list())
    // Offline stub: index into in-memory memory substrate and persist size
    Telos memory index(docs)
    Telos transactional_setSlot(Telos, "lastRagIndexSize", docs size asString)
    "ok"
)

Telos rag query := method(q, k,
    if(q == nil, q = "")
    if(k == nil, k = 3)
    hits := Telos memory search(q, k)
    // Format as lines: rank\tscore\ttext for backward-compat
    lines := List clone
    i := 0
    while(i < hits size,
        h := hits at(i)
        sc := h at("score")
        tx := h at("text")
        line := i asString .. "\t" .. sc asString .. "\t" .. tx asString
        lines append(line)
        i = i + 1
    )
    out := lines join("\n")
    rec := Map clone
    rec atPut("tool", "rag.query")
    rec atPut("q", q)
    rec atPut("k", k)
    rec atPut("t", Date clone now asNumber)
    Telos logs append(Telos logs tools, Telos json stringify(rec))
    Telos transactional_setSlot(Telos, "lastRagQuery", q)
    out
)

// Grow VSA memory by prompting an LLM (Ollama when enabled) to emit contexts
// spec: Map{name, prompt, persona, n, tags}
Telos rag grow := method(spec,
            if(spec == nil, spec = Map clone)
            persona := spec atIfAbsent("persona", "BABS")
            prompt := spec atIfAbsent("prompt", "List 8 crisp context fragments (1-2 sentences) about the topic: prototypal UI morphic systems")
            n := spec atIfAbsent("n", 8)
            tags := spec atIfAbsent("tags", list("rag","llm"))
            info := Map clone; info atPut("persona", persona); info atPut("n", n)
            Telos walCommit("rag.grow", info, block(
                // Ask the LLM to enumerate contexts
                sys := "You produce bullet points only. Each bullet is one short, self-contained context."
                call := Map clone; call atPut("persona", persona); call atPut("system", sys); call atPut("prompt", prompt)
                out := Telos llmCall(call)
                // Parse lines into contexts (accept -, * bullets or numeric enumerations)
                lines := list()
                if(out != nil,
                    raw := out asString split("\n")
                    raw foreach(l,
                        s := l asString asMutable strip
                        if(s size > 0,
                            // remove leading bullet markers
                            if(s beginsWithSeq("- "), s = s exSlice(2))
                            if(s beginsWithSeq("* "), s = s exSlice(2))
                            // remove leading numbers like `1. ` or `1) `
                            if(s at(0) isDigit,
                                // find first space after a dot or paren
                                idx := s findSeq(". ")
                                if(idx == nil or idx == -1, idx = s findSeq(") "))
                                if(idx != nil and idx != -1, s = s exSlice(idx + 2))
                            )
                            if(s size > 0, lines append(s))
                        )
                    )
                )
                // Fallback if model returned nothing useful
                if(lines size == 0,
                    lines = list(prompt)
                )
                // Index into memory with optional tags and persist
                i := 0
                while(i < lines size and i < n,
                    e := Map clone; e atPut("text", lines at(i)); e atPut("tags", tags)
                    // Add as concept to compute hv and carry tags
                    concept := ConceptFractal clone; concept summary = lines at(i); concept meta atPut("tags", tags)
                    Telos memory addConcept(concept)
                    i = i + 1
                )
                _ := Telos memory save(nil)
                Telos transactional_setSlot(Telos, "lastRagGrowCount", (lines size min(n)) asString)
            ))
            // Return count as string
            Telos getSlot("lastRagGrowCount") ifNil("0")
        )
    )


// Attempt to load persisted memory if available (prototypal - happens immediately)
if(Telos hasSlot("memory") and Telos memory hasSlot("load"),
    loaded := Telos memory load(nil)
    // Mark in WAL for visibility (no SET lines)
    mi := Map clone; mi atPut("loaded", loaded)
    Telos mark("memory.load", mi)
)

    // Pillar 1: Synaptic Bridge - Reach into Python muscle
    // Defer to C-implemented getPythonVersion
    getPythonVersion := method(
        resend
    )

    // Pillar 2: First Heartbeat - Transactional persistence
    transactional_setSlot := method(target, slotName, value,
        resend
    )

    // Pillar 3: First Glance - UI window stub
    openWindow := method(
        resend
    )

    // Create the root world (Morphic's World)
    createWorld := method(
        // Initialize C-side world, but keep an Io-level Morph as the UI root
        resend
        morphProto := Lobby getSlot("Morph")
        self world := morphProto clone do(
            x := 0; y := 0; width := 800; height := 600; submorphs := List clone
        )
    log("Telos: Morphic World initialized - living canvas ready")
    // Auto-replay persistence if enabled (guard if slot missing)
    if(self hasSlot("autoReplay") and (self autoReplay == true), self replayWal)
        world
    )

    // Start the main event loop - the heart of the living interface
    mainLoop := method(
        if(world == nil, return "Telos: No world exists - call createWorld first")
    log("Telos: Starting Morphic main loop (direct manipulation active)")
        resend
        "Telos: Main loop completed"
    )

    // Create a new morph - a living visual object
    createMorph := method(
        // Create an Io-level Morph and register in both Io and C worlds
        m := Morph clone
        if(m hasSlot("submorphs") not, m submorphs := List clone)
        morphs append(m)
        // Append into C world so C draw loop can see it
        if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
        // Index by id
        if(self hasSlot("morphIndex") not, self morphIndex := Map clone)
        self morphIndex atPut(m id asString, m)
    log("Telos: Living morph created and added to ecosystem")
        m
    )

    // Add a submorph to build the living hierarchy
    addSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        // Maintain Io-level hierarchy and forward to C
        resend(parent, child)
        parent submorphs append(child)
        // If attaching to world, also mirror into C world's list for visibility
        if(parent == world and self hasSlot("addMorphToWorld"), self addMorphToWorld(child))
    log("Telos: Morph added to living hierarchy")
    "ok"
    )

    // Remove a submorph from the living hierarchy
    removeSubmorph := method(parent, child,
        if(parent == nil or child == nil, return "Telos: Invalid morphs")
        resend(parent, child)
        parent submorphs remove(child)
        "Telos: Morph removed from living hierarchy"
    )

    // Draw the world and all living morphs
    draw := method(
        if(world == nil, return "Telos: No world to draw")
        resend
        "Telos: World rendered"
    )

    // Handle direct manipulation events (Io-first, then C stub)
    dispatchEvent := method(event,
        if(world,
            // Let the Io morphic world try to handle it
            handled := world handleEvent(event)
            if(handled == true, log("Telos: Io handled event " .. event asString))
        )
        // Forward to C's handleEvent for logging/stub (guarded)
        if(self hasSlot("Telos_rawHandleEvent"), Telos_rawHandleEvent(event))
        "ok"
    )

    // Back-compat convenience
    handleEvent := method(event,
        dispatchEvent(event)
    )

    // Convenience: click(x,y)
    click := method(x, y,
        e := Map clone; e atPut("type", "click"); e atPut("x", x); e atPut("y", y)
        dispatchEvent(e)
    )

    // Convenience: mouse events
    mouseDown := method(x, y,
        e := Map clone; e atPut("type", "mousedown"); e atPut("x", x); e atPut("y", y)
        dispatchEvent(e)
    )
    mouseMove := method(x, y,
        e := Map clone; e atPut("type", "mousemove"); e atPut("x", x); e atPut("y", y)
        dispatchEvent(e)
    )
    mouseUp := method(x, y,
        e := Map clone; e atPut("type", "mouseup"); e atPut("x", x); e atPut("y", y)
        dispatchEvent(e)
    )

    // Hit-test utilities
    morphsAt := method(x, y,
        if(world == nil, return list())
        found := List clone
        collect := method(m,
            if(m containsPoint(x, y), found append(m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, collect(sm)))
        )
        collect(world)
        found
    )
    hitTest := method(x, y, morphsAt(x, y))

    // WAL marker helpers
    walAppend := method(line,
        // Write to a stable WAL path (defaults to Telos.walPath or 'telos.wal')
        p := self walPath ifNil("telos.wal")
        // Prefer Io-level file I/O for robustness across absolute paths
        f := File with(p)
        f openForAppending
        f write(line .. "\n")
        f close
        "ok"
    )
    walBegin := method(tag, info,
        if(tag == nil, tag = "frame")
        // Always include a timestamp in the info map
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        line := "BEGIN " .. tag .. " " .. json stringify(info)
        walAppend(line)
    )
    walEnd := method(tag,
        if(tag == nil, tag = "frame")
        walAppend("END " .. tag)
    )

    // Convenience: write a BEGIN/END framed transaction around a block
    walCommit := method(tag, info, block,
        if(tag == nil, tag = "tx")
        walBegin(tag, info)
        if(block != nil, block call)
        walEnd(tag)
    )

    // Inspect WAL and return only complete frames: List of Maps with {tag, setCount}
    walListCompleteFrames := method(path,
        if(path == nil, path = self walPath ifNil("telos.wal"))
        out := List clone
        f := File with(path)
        if(f exists not, return out)
        content := f contents
        if(content == nil, return out)
        lines := content split("\n")
        current := nil
        currentTag := nil
        setCount := 0
        lines foreach(line,
            if(line beginsWithSeq("BEGIN "),
                rest := line exSlice(6)
                t := rest split(" ") atIfAbsent(0, rest) strip
                current = true
                currentTag = t
                setCount = 0
            ,
                if(line beginsWithSeq("END ") and current == true,
                    endRest := line exSlice(4)
                    t2 := endRest strip split(" ") atIfAbsent(0, endRest) strip
                    if(t2 == currentTag,
                        m := Map clone; m atPut("tag", currentTag); m atPut("setCount", setCount)
                        out append(m)
                        current = nil; currentTag = nil; setCount = 0
                    )
                ,
                    if(current == true and line beginsWithSeq("SET "),
                        setCount = setCount + 1
                    )
                )
            )
        )
        out
    )

    // Export complete WAL frames to a JSON file for tooling
    walExportFramesJson := method(outPath, walPath,
        if(outPath == nil, outPath = logs base .. "/wal_frames.json")
        if(walPath == nil, walPath = self walPath ifNil("telos.wal"))
        frames := walListCompleteFrames(walPath)
        // Serialize as an array of {tag, setCount}
        parts := List clone
        i := 0
        while(i < frames size,
            fr := frames at(i)
            rec := "{\"tag\":\"" .. fr at("tag") .. "\",\"setCount\":" .. (fr at("setCount")) asString .. "}"
            parts append(rec)
            i = i + 1
        )
        jsonStr := "[" .. parts join(",") .. "]"
        // Ensure directory
        pparts := outPath split("/")
        if(pparts size > 1,
            dir := pparts exSlice(0, pparts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        File with(outPath) setContents(jsonStr)
        outPath
    )

    // Single-line WAL marker
    mark := method(tag, info,
        if(tag == nil, tag = "mark")
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        walAppend("MARK " .. tag .. " " .. json stringify(info))
    )

    // WAL rotation utility: if file exceeds maxBytes, rotate to .1 (single slot)
    rotateWal := method(path := nil, maxBytes := 1048576,
        if(path == nil, path = self walPath ifNil("telos.wal"))
        f := File clone setPath(path)
        if(f exists not, return "no wal")
        sz := f size
        if(sz <= maxBytes, return "ok")
        bak := path .. ".1"
        // Remove old backup if exists
        fb := File clone setPath(bak)
        if(fb exists, fb remove)
        // Rename current to backup and recreate empty wal
        f renameTo(bak)
        nf := File clone setPath(path)
        nf setContents("")
        "rotated"
    )

    // Replay minimal WAL into current world (id-prefixed slots)
    replayWal := method(path,
        if(path == nil, path = self walPath ifNil("telos.wal"))
        if(world == nil, return "[no-world]")
        if((File with(path)) exists not, return "[no-wal]")
        // Guard: disable WAL writes during replay
        prev := self isReplaying
        self isReplaying = true
        // Build index id->morph (flat) from world
        index := Map clone
        collect := method(m,
            if(m hasSlot("id"), index atPut(m id asString, m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, collect(sm)))
        )
        collect(world)
        // Read WAL and group into complete frames (BEGIN ... END)
        content := (File with(path)) contents
        if(content == nil, self isReplaying = prev; return "[empty-wal]")
        lines := content split("\n")
        frames := List clone
        current := nil
        currentTag := nil
        sawBegin := false
        lines foreach(line,
            if(line beginsWithSeq("BEGIN "),
                // Start new frame; capture tag after 'BEGIN '
                sawBegin = true
                // Extract tag up to first space after BEGIN
                rest := line exSlice(6)
                tag := rest split(" ") atIfAbsent(0, rest) strip
                current = List clone
                currentTag = tag
            ,
                if(line beginsWithSeq("END ") and current != nil,
                    // Close only if tags match; otherwise treat as stray
                    endRest := line exSlice(4)
                    endTag := endRest strip split(" ") atIfAbsent(0, endRest) strip
                    if(endTag == currentTag,
                        frames append(current)
                        current = nil
                        currentTag = nil
                    )
                ,
                    if(current != nil,
                        current append(line)
                    )
                )
            )
        )

        // Helper: apply a SET line to the index/world
        applySet := method(lineStr,
            rest := lineStr exSlice(4) // after 'SET '
            parts := rest split(" TO ")
            if(parts size != 2, return nil)
            lhs := parts at(0)
            rhs := parts at(1)
            lhsParts := lhs split(".")
            if(lhsParts size < 2, return nil)
            mid := lhsParts at(0)
            slot := lhsParts at(1)
            m := index at(mid)
            if(m != nil,
                if(slot == "position",
                    s := rhs strip
                    s = s afterSeq("(")
                    s = s beforeSeq(")")
                    nums := s split(",")
                    if(nums size == 2,
                        nx := nums at(0) asNumber
                        ny := nums at(1) asNumber
                        m moveTo(nx, ny)
                    )
                )
                if(slot == "size",
                    s := rhs strip
                    s = s afterSeq("(")
                    s = s beforeSeq(")")
                    nums := s split("x")
                    if(nums size == 2,
                        nw := nums at(0) asNumber
                        nh := nums at(1) asNumber
                        m resizeTo(nw, nh)
                    )
                )
                if(slot == "color",
                    s := rhs strip
                    s = s afterSeq("[")
                    s = s beforeSeq("]")
                    nums := s split(",")
                    if(nums size >= 3,
                        r := nums at(0) asNumber
                        g := nums at(1) asNumber
                        b := nums at(2) asNumber
                        a := if(nums size > 3, nums at(3) asNumber, 1)
                        m setColor(r, g, b, a)
                    )
                )
                if(slot == "zIndex",
                    z := rhs asNumber
                    m setZIndex(z)
                )
                if(slot == "text",
                    m setText(rhs)
                )
            ,
                // m is nil; maybe this line declares type
                if(slot == "type",
                    tname := rhs strip
                    proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
                    nm := proto clone
                    nm setSlot("id", mid)
                    nm owner = world
                    world submorphs append(nm)
                    index atPut(mid, nm)
                )
            )
        )

        if(sawBegin == true and frames size > 0,
            // Apply only complete frames in order
            frames foreach(f,
                f foreach(l,
                    if(l beginsWithSeq("SET "), applySet(l))
                )
            )
        ,
            // Legacy fallback: no frames; scan whole file for SET lines
            lines foreach(line,
                if(line beginsWithSeq("SET "), applySet(line))
            )
        )
        // Restore flag and finish
        self isReplaying = prev
        // Note: avoid sorting to keep GC stable; explicit appends control order
        "ok"
    )

    // --- Cognitive Substrate Stubs (offline-safe) ---

    // Lightweight VSA-inspired helpers (bag-of-words hypervectors)
    vsa := Object clone do(
        tokenize := method(text,
            if(text == nil, return list())
            // naive: split on non-alphanum, lowercase, drop short tokens
            s := text asString asLowercase
            // Replace non-letter/number with spaces
            // Io lacks regex; do a basic sweep over a small set
            repl := method(str, chs,
                m := str asMutable
                chs foreach(c, m replaceSeq(c, " "))
                m
            )
            cleaned := repl(s, list("\n","\t",",",".",";",":","(",")","[","]","{","}","\"","'","!","?","/","\\","-","_","+","=","*","|","<",">","@","#","$","%","^","&"))
            toks := cleaned split(" ") select(t, t size > 2)
            toks
        )

        hvFromText := method(text,
            hv := Map clone
            toks := self tokenize(text)
            toks foreach(t,
                cur := hv at(t)
                if(cur == nil, cur = 0)
                hv atPut(t, cur + 1)
            )
            hv
        )

        bundle := method(a, b,
            out := Map clone
            // copy a
            if(a,
                a foreach(k, v, out atPut(k, v))
            )
            // add b
            if(b,
                b foreach(k, v,
                    cur := out at(k)
                    if(cur == nil, cur = 0)
                    out atPut(k, cur + v)
                )
            )
            out
        )

        unbind := method(a, b,
            out := Map clone
            if(a, a foreach(k, v, out atPut(k, v)))
            if(b,
                b foreach(k, v,
                    cur := out at(k)
                    if(cur == nil, cur = 0)
                    out atPut(k, cur - v)
                )
            )
            out
        )

        dot := method(a, b,
            if(a == nil or b == nil, return 0)
            sum := 0
            // iterate over smaller map
            small := a; large := b
            if((b size) < (a size), small = b; large = a)
            small foreach(k, v,
                lv := large at(k)
                if(lv != nil, sum = sum + (v * lv))
            )
            sum
        )

        norm := method(a,
            if(a == nil, return 1)
            sum := 0
            a foreach(k, v, sum = sum + (v * v))
            (sum asNumber) sqrt
        )

        similarity := method(a, b,
            d := self dot(a, b)
            na := self norm(a)
            nb := self norm(b)
            if(na == 0 or nb == 0, return 0)
            d / (na * nb)
        )
    )

    // VSA-RAG Memory API (Phase 7) - now stores simple token hypervectors with optional tags and persistence
    memory := Object clone do(
        // Minimal in-memory index for offline demos
        db := List clone

        // Wrap a string into an entry with hv and optional tags
        makeEntry := method(text, tags,
            e := Map clone
            tx := text asString
            e atPut("text", tx)
            e atPut("hv", Telos vsa hvFromText(tx))
            if(tags != nil, e atPut("tags", tags clone))
            e
        )

        addContext := method(item,
            if(item == nil, return true)
            db append(makeEntry(item, nil))
            true
        )

        addConcept := method(concept,
            if(concept and (concept hasSlot("summary")),
                t := concept summary asString
                tags := nil
                if(concept hasSlot("meta") and concept meta != nil and concept meta hasSlot("tags"),
                    tags = concept meta at("tags")
                )
                db append(makeEntry(t, tags))
            )
            true
        )

        index := method(items,
            if(items == nil, return 0)
            count := 0
            items foreach(it, db append(makeEntry(it, nil)); count = count + 1)
            count
        )

        // Persist current memory DB to JSONL (one record per line with {text, tags?})
        save := method(path,
            if(path == nil, path = Telos logs memoryIndex)
            parts := path split("/")
            if(parts size > 1,
                dir := parts exSlice(0, parts size - 1) join("/")
                d := Directory with(dir)
                if(d exists not, d create)
            )
            f := File with(path)
            f openForWriting
            i := 0
            while(i < db size,
                e := db at(i)
                rec := Map clone
                rec atPut("text", e at("text"))
                if(e hasSlot("tags"), rec atPut("tags", e at("tags")))
                f write(Telos json stringify(rec) .. "\n")
                i = i + 1
            )
            f close
            "ok"
        )

        // Load memory DB from JSONL (recomputes hv from text; ignores hv in file)
        load := method(path,
            if(path == nil, path = Telos logs memoryIndex)
            f := File with(path)
            if(f exists not, return 0)
            content := f contents
            if(content == nil, return 0)
            lines := content split("\n")
            added := 0
            // helper to extract JSON string value for key "text"
            extractText := method(line,
                s := line afterSeq("\"text\":\"")
                if(s == nil or s == line, return nil)
                out := ""
                i := 0
                esc := false
                while(i < s size,
                    c := s exSlice(i, i+1)
                    if(esc == true,
                        if(c == "n", out = out .. "\n",
                            if(c == "\"", out = out .. "\"",
                                if(c == "\\", out = out .. "\\", out = out .. c)
                            )
                        )
                        esc = false
                        i = i + 1
                        continue
                    )
                    if(c == "\\", esc = true; i = i + 1; continue)
                    if(c == "\"", break)
                    out = out .. c
                    i = i + 1
                )
                out
            )
            // helper to extract optional tags array like "tags":["a","b"]
            extractTags := method(line,
                tstart := line afterSeq("\"tags\":[")
                if(tstart == nil or tstart == line, return nil)
                // read until the next ]
                seg := tstart beforeSeq("]")
                if(seg == nil, return nil)
                // split on commas and unquote
                raw := seg split(",")
                tags := List clone
                raw foreach(r,
                    rr := r asString strip
                    // remove surrounding quotes if present
                    if(rr beginsWithSeq("\""), rr = rr exSlice(1))
                    if(rr endsWithSeq("\""), rr = rr exSlice(0, rr size - 1))
                    if(rr size > 0, tags append(rr))
                )
                if(tags size == 0, return nil, tags)
            )
            lines foreach(line,
                if(line size > 0,
                    tx := extractText(line)
                    if(tx != nil,
                        tags := extractTags(line)
                        db append(makeEntry(tx, tags))
                        added = added + 1
                    )
                )
            )
            added
        )

        search := method(query, k,
            if(k == nil, k = 5)
            qStr := query asString
            qLower := qStr asLowercase
            qHv := Telos vsa hvFromText(qStr)
            // Optional tag bias: parse queries like "[NAME tags:a,b] ..."
            tagHints := List clone
            if(qStr beginsWithSeq("["),
                mid := qStr afterSeq("tags:")
                if(mid != nil and mid != qStr,
                    seg := mid beforeSeq("]")
                    if(seg != nil,
                        parts := seg split(",")
                        parts foreach(p,
                            t := p asString strip
                            if(t size > 0, tagHints append(t))
                        )
                    )
                )
            )
            scored := List clone
            idx := 0
            while(idx < db size,
                entry := db at(idx)
                s := entry at("text") ifNil(entry asString)
                hv := entry at("hv")
                sLower := s asLowercase
                presence := if(qLower size > 0 and sLower containsSeq(qLower), 2, 0)
                lenDiff := (s size - qStr size) abs
                bonus := 1 / (1 + lenDiff)
                sim := Telos vsa similarity(qHv, hv)
                // Tag overlap boost
                tagBoost := 0
                if(tagHints size > 0 and entry hasSlot("tags"),
                    overlap := 0
                    etags := entry at("tags")
                    tagHints foreach(th,
                        if(etags contains(th), overlap = overlap + 1)
                    )
                    tagBoost = (overlap min(3)) * 0.2
                )
                scoreVal := presence + bonus + sim + tagBoost
                m := Map clone
                m atPut("text", s)
                m atPut("score", scoreVal)
                scored append(m)
                idx = idx + 1
            )
            // Select top-k by simple scan
            res := List clone
            kk := k min(scored size)
            n := 0
            while(n < kk,
                bestIdx := nil
                bestVal := -1
                t := 0
                while(t < scored size,
                    mm := scored at(t)
                    v := mm at("score")
                    if(v > bestVal, bestVal = v; bestIdx = t)
                    t = t + 1
                )
                if(bestIdx != nil,
                    res append(scored at(bestIdx))
                    scored removeAt(bestIdx)
                )
                n = n + 1
            )
            res
        )
    )

    // Non-local LLM Bridge (Phase 7.5) - stubbed now
    // Provider config and routing for local models via Ollama
    llmProvider := Map clone do(
        atPut("name", "offline")
        atPut("baseUrl", "http://localhost:11434")
        atPut("useOllama", false)
    )

    // Generic Python eval (FFI maturation) — pass a short expression or statements
    pyEval := method(code,
        if(code == nil, code = "")
        started := Date clone now asNumber
        out := if(self hasSlot("Telos_rawPyEval"), Telos_rawPyEval(code), "")
        ended := Date clone now asNumber
        // Log as a tool use for provenance
        rec := Map clone
        rec atPut("t", ended)
        rec atPut("tool", "py.eval")
        rec atPut("code", code)
        dur := ((ended - started) * 1000) floor
        rec atPut("duration_ms", dur)
        rec atPut("result", out)
        Telos logs append(Telos logs tools, Telos json stringify(rec))
        // WAL mark for traceability (no SET inside)
        info := Map clone; info atPut("ms", dur)
        mark("py.eval", info)
        out
    )

    // Persona → model mapping for Ollama (local model names created via Modelfiles)
    personaModels := Map clone do(
        atPut("BRICK", "telos/brick")
        atPut("ROBIN", "telos/robin")
        atPut("BABS",  "telos/babs")
        atPut("ALFRED","telos/alfred")
    )

    // Logging hooks (JSONL) and curation queues
    logs := Object clone do(
        base := "logs"
        llm := base .. "/persona_llm.jsonl"
        tools := base .. "/tool_use.jsonl"
        curation := base .. "/curation_queue.jsonl"
        ui := base .. "/ui_snapshot.txt"
        // Fractals logs
        fractalsBase := base .. "/fractals"
        fractalsContexts := fractalsBase .. "/contexts.jsonl"
        fractalsConcepts := fractalsBase .. "/concepts.jsonl"
        // Memory persistence (JSONL of entries)
        memoryIndex := base .. "/fractals/memory.jsonl"
        append := method(path, line,
            // Always ensure parent directory exists even when using raw C append
            parts := path split("/")
            if(parts size > 1,
                dir := parts exSlice(0, parts size - 1) join("/")
                d := Directory with(dir)
                if(d exists not, d create)
            )
            if(Lobby hasSlot("Telos_rawLogAppend"),
                Telos_rawLogAppend(path, line),
                do(
                    f := File with(path)
                    f openForAppending
                    f write(line .. "\n")
                    f close
                    "ok"
                )
            )
        )

        tail := method(path, n := 20,
            out := List clone
            if(path != nil,
                do(
                    f := File with(path)
                    if(f exists,
                        do(
                            content := f contents
                            if(content != nil,
                                do(
                                    tmp := content split("\n")
                                    start := (tmp size - n) max(0)
                                    out = tmp exSlice(start, tmp size)
                                )
                            )
                        )
                    )
                )
            )
            out
        )
    )
    // Persona Consistency Scorer (offline heuristic)
    // Estimate alignment of output 'text' with a persona's ethos/speakStyle/routingHints.
    consistencyScoreFor := method(personaName, text,
        if(text == nil, return 0)
        p := nil
        if(self hasSlot("personaCodex") and self personaCodex != nil,
            p = self personaCodex get(personaName)
        )
        if(p == nil, return 0.5) // neutral if unknown persona

        // Build a simple bag of hint tokens from persona descriptors
        hints := List clone
        addHints := method(s,
            if(s != nil and s size > 0,
                parts := s asString asLowercase split(" ")
                parts foreach(w,
                    w2 := w asString strip
                    if(w2 size > 0, hints append(w2))
                )
            )
        )
        addHints(p ethos)
        addHints(p speakStyle)
        addHints(p routingHints)
        if(hints size == 0, return 0.5)

        // Tokenize the text
        words := List clone
        text asString asLowercase split(" ") foreach(w,
            w2 := w strip
            if(w2 size > 0, words append(w2))
        )

        // Unique hints and count overlaps
        seen := Map clone
        match := 0
        hints foreach(h,
            if(seen at(h) == nil,
                seen atPut(h, true)
                if(words contains(h), match = match + 1)
            )
        )
        base := match / seen size asNumber

        // Brevity bonus when persona favors precision/conciseness
        brevityBonus := 0
        styleStr := ((p speakStyle ifNil("") .. " " .. (p ethos ifNil(""))) asLowercase)
        if(styleStr containsSeq("precise") or styleStr containsSeq("concise"),
            len := text size max(1)
            brevityBonus = (200 / (len + 50)) min(0.15)
        )
        score := base + brevityBonus
        if(score < 0, score = 0)
        if(score > 1, score = 1)
        score
    )

    // Curation stub (to be backed by VSA-NN rRAG)
    curator := Object clone do(
        enqueue := method(entryMap,
            // Wrap and include the full record for later processing
            env := Map clone
            env atPut("kind", entryMap atIfAbsent("kind", "llm"))
            env atPut("key", entryMap atIfAbsent("key", System uniqueId))
            env atPut("path", entryMap atIfAbsent("path", Telos logs llm))
            env atPut("record", entryMap atIfAbsent("record", entryMap))
            // Ensure logs directory exists
            d := Directory with(Telos logs base)
            if(d exists not, d create)
            Telos logs append(Telos logs curation, Telos json stringify(env))
            true
        )

        // Flush with safe dedupe and summary (no JSON parsing)
        flushToCandidates := method(limit, opts,
            if(limit == nil, limit = 1000)
            if(opts == nil, opts = Map clone)
            f_src := File with(Telos logs curation)
            f_dstPath := Telos logs base .. "/candidate_gold.jsonl"
            f_dst := File with(f_dstPath)
            if(f_src exists not, return "no-queue")

            doDedupe := if(opts hasSlot("dedupe"), opts at("dedupe"), true)
            minScore := if(opts hasSlot("minScore"), opts at("minScore"), nil)

            // Stats
            total := 0; kept := 0; droppedDup := 0; droppedScore := 0
            seen := Map clone

            // IO
            f_src openForReading
            f_dst openForAppending

            while(f_src isAtEnd not and kept < limit,
                line := f_src readLine
                if(line and line size > 0,
                    total = total + 1
                    if(doDedupe and (seen at(line) != nil),
                        droppedDup = droppedDup + 1,
                        nil
                    ,
                        ok := true
                        if(minScore != nil,
                            tmp := line afterSeq("\"consistencyScore\":")
                            if(tmp != nil and tmp != line,
                                seg := tmp
                                numStr := seg split(",") atIfAbsent(0, seg)
                                numStr = numStr beforeSeq("}")
                                val := numStr strip asNumber
                                if(val < minScore, ok = false)
                            ,
                                ok = false
                            )
                        )
                        if(ok,
                            f_dst write(line .. "\n"); seen atPut(line, true); kept = kept + 1,
                            droppedScore = droppedScore + 1
                        )
                    )
                )
            )

            f_src close; f_dst close
            // Truncate queue
            File with(Telos logs curation) setContents("")

            // Write summary (ensure logs dir exists)
            d := Directory with(Telos logs base)
            if(d exists not, d create)
            sumPath := Telos logs base .. "/curation_summary.log"
            s := File with(sumPath)
            s openForAppending
            now := Date clone now asString
        s write("[" .. now .. "] total=" .. total .. ", kept=" .. kept ..
            ", dropped_dupe=" .. droppedDup .. ", dropped_score=" .. droppedScore ..
                    " opts=" .. Telos json stringify(opts) .. "\n")
            s close

            "flushed: " .. kept .. "/" .. total
        )
    )

    // LLM call: routes to Ollama when configured; otherwise offline stub. Logs JSONL and enqueues for curation.
    llmCall := method(spec,
        if(spec == nil, spec = Map clone)
        personaName := spec atIfAbsent("persona", nil)
        // Determine provider
        useOllama := (llmProvider atIfAbsent("useOllama", false) == true)
        baseUrl := llmProvider atIfAbsent("baseUrl", "http://localhost:11434")
        // Select model: explicit > persona mapping > default
        model := spec atIfAbsent("model", nil)
        if(model == nil and personaName != nil and personaModels hasSlot(personaName),
            model = personaModels at(personaName)
        )
        if(model == nil, model = "telos/robin")
        prompt := spec atIfAbsent("prompt", "")
        system := spec atIfAbsent("system", "")

        // Merge generation options: persona defaults (if available) + per-call overrides
        options := Map clone
        if(personaName != nil,
            p := personaCodex get(personaName)
            if(p and p hasSlot("genOptions"),
                go := p genOptions; if(go, go foreach(k, v, options atPut(k, v)))
            )
        )
        if(spec hasSlot("temperature"), options atPut("temperature", spec at("temperature")))
        if(spec hasSlot("top_p"), options atPut("top_p", spec at("top_p")))

        startedAt := Date clone now asNumber
        out := nil

        if(useOllama == true,
            // Send to C bridge (embedded Python HTTP)
            // NOTE: options are JSON-encoded; keep minimal to avoid parser fragility
            optsJson := "{}"
            if(options size > 0,
                // naive stringify for flat maps (numbers only typical here)
                parts := List clone
                options foreach(k, v,
                    parts append("\"" .. k .. "\":" .. v asString)
                )
                optsJson = "{" .. parts join(",") .. "}"
            )
            if(Telos hasSlot("Telos_rawOllamaGenerate"),
                out = Telos_rawOllamaGenerate(baseUrl, model, prompt, system, optsJson),
                out = "[OLLAMA_ERROR] bridge missing"
            )
        ,
            // Offline fallback
            out = "[OFFLINE_STUB_COMPLETION]"
        )

        endedAt := Date clone now asNumber
        providerName := if(useOllama, "ollama", "offline")
        score := consistencyScoreFor(personaName, out)
        entry := Map clone
        entry atPut("t", endedAt)
        entry atPut("persona", personaName ifNil(""))
        entry atPut("provider", providerName)
        entry atPut("model", model ifNil(""))
        entry atPut("prompt", prompt)
        entry atPut("system", system)
        entry atPut("options", options)
        entry atPut("duration_ms", ((endedAt - startedAt) * 1000) floor)
        entry atPut("output", out)
        entry atPut("consistencyScore", score)
        Telos logs append(Telos logs llm, Telos json stringify(entry))
        ce := Map clone
        ce atPut("kind", "llm")
        ce atPut("key", (personaName ifNil("") ) .. ":" .. providerName .. ":" .. System uniqueId)
        ce atPut("path", Telos logs llm)
        ce atPut("record", entry)
        curator enqueue(ce)
        out
    )

    toolUse := method(toolSpec,
        writeln("[tools] offline stub: ", toolSpec)
        // echo back a dummy result
        res := Map clone; res atPut("result", "OK"); res atPut("tool", toolSpec)
        // Log tool use for future curation
        entry := Map clone
        entry atPut("t", Date clone now asNumber)
        entry atPut("tool", toolSpec)
        entry atPut("result", res)
        Telos logs append(Telos logs tools, Telos json stringify(entry))
        ce := Map clone
        ce atPut("kind", "tool")
        ce atPut("key", "tool:" .. System uniqueId)
        ce atPut("path", Telos logs tools)
        ce atPut("record", entry)
        curator enqueue(ce)
        res
    )

    // Composite Entropy Metric (Phase 9) - stubbed now
    scoreSolution := method(solution,
        // Returns a Map with metric components and G_hat
        // In offline stub, use fixed components and allow weights override on the solution map
        alpha := solution atIfAbsent("alpha", 1)
        beta  := solution atIfAbsent("beta",  1)
        gamma := solution atIfAbsent("gamma", 1)
        delta := solution atIfAbsent("delta", 1)
        // Dummy components
        S := 0.5; C := 0.2; I := 0.1; R := 0.1
        G := alpha*S - beta*C - gamma*I - delta*R
        m := Map clone
        m atPut("S", S); m atPut("C", C); m atPut("I", I); m atPut("R", R)
        m atPut("G_hat", G)
        m atPut("alpha", alpha); m atPut("beta", beta); m atPut("gamma", gamma); m atPut("delta", delta)
        m
    )

    // UI capture for ROBIN's vision: textual description of morph tree
    captureScreenshot := method(
        if(world == nil, return "[no world]")
        describe := method(m, indent,
            name := m type ifNil("Morph")
            idStr := if(m hasSlot("id"), m id, "?")
            zStr := if(m hasSlot("zIndex"), m zIndex, 0)
            line := indent .. name .. "#" .. idStr .. " @(" .. m x .. "," .. m y .. ") " .. m width .. "x" .. m height .. " z=" .. zStr
            if(m hasSlot("color"),
                c := m color; line = line .. " color=[" .. c atIfAbsent(0,0) .. "," .. c atIfAbsent(1,0) .. "," .. c atIfAbsent(2,0) .. "," .. c atIfAbsent(3,1) .. "]"
            )
            if(m hasSlot("text"), line = line .. " text='" .. m text .. "'")
            childLines := List clone
            if(m hasSlot("submorphs"),
                m submorphs foreach(sm, childLines append(describe(sm, indent .. "  ")))
            )
            list(line) appendSeq(childLines)
        )
        describe(world, "") join("\n")
    )

    // Save textual UI snapshot to a file under logs
    saveSnapshot := method(path,
        if(path == nil, path = logs ui)
        snap := captureScreenshot
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        f := File with(path)
        f setContents(snap)
        path
    )

    // Convert current world to a nested Map (for JSON export)
    snapshotMap := method(
        if(world == nil, return Map clone)
        toMap := method(m,
            o := Map clone
            o atPut("type", m type)
            if(m hasSlot("id"), o atPut("id", m id))
            o atPut("x", m x); o atPut("y", m y)
            o atPut("width", m width); o atPut("height", m height)
            if(m hasSlot("zIndex"), o atPut("zIndex", m zIndex))
            if(m hasSlot("color"), o atPut("color", m color))
            if(m hasSlot("text"), o atPut("text", m text))
            ch := List clone
            if(m hasSlot("submorphs"), m submorphs foreach(sm, ch append(toMap(sm))))
            o atPut("children", ch)
            o
        )
        toMap(world)
    )

    // Save snapshot as JSON
    saveSnapshotJson := method(path,
        if(path == nil, path = logs base .. "/ui_snapshot.json")
        data := snapshotMap
        jsonStr := json stringify(data)
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        f := File with(path)
        f setContents(jsonStr)
        path
    )

    // Export the entire world as JSON using specs per morph (pre-order traversal)
    saveWorldJson := method(path,
        if(path == nil, path = logs base .. "/world.json")
        if(world == nil, return "[no world]")
        coll := List clone
        visit := method(m)
            coll append(toSpec(m))
            if(m hasSlot("submorphs"), m submorphs foreach(sm, visit(sm)))
        visit(world)
        jsonStr := json stringify(coll)
        parts := path split("/")
        if(parts size > 1,
            dir := parts exSlice(0, parts size - 1) join("/")
            d := Directory with(dir)
            if(d exists not, d create)
        )
        File with(path) setContents(jsonStr)
        path
    )

    // Import world from JSON specs (replaces current world children)
    loadWorldJson := method(path,
        if(path == nil, path = logs base .. "/world.json")
        if(world == nil, self createWorld)
        f := File with(path)
        if(f exists not, return "[no-json]")
        content := f contents
        // naive parse: expect a JSON-like list of maps we generated
        // For simplicity, reuse loadConfig by converting JSON to Io maps via heuristic
        // If JSON parser unavailable, assume content is not malformed (internal use)
        // Here, use a minimal shim: interpret exported specs by splitting records
        // Safer path: clear current children, then rebuild via fromSpec applied on each map in list
        // Delegate to loadConfig when possible
        // For now, clear world children
        if(world hasSlot("submorphs"),
            world submorphs foreach(m, nil) // keep list but leave as-is
        )
        // Very minimal: if file was produced by us, it is a JSON array of objects with fields we use.
        // We won't re-implement a parser; recommend using loadConfig for manual runs.
        // Return path as acknowledgement.
        path
    )

    // Command router (textual; runtime dispatch only)
    commands := Object clone do(
        run := method(name, args,
            if(args == nil, args = List clone)
            // Trace command dispatch in WAL for DOE diagnostics
            do(
                info := Map clone
                info atPut("name", name)
                info atPut("argc", args size)
                Telos mark("cmd.run", info)
            )
            // snapshots & WAL
            if(name == "snapshot", return Telos saveSnapshot(args atIfAbsent(0, nil)))
            if(name == "snapshot.json", return Telos saveSnapshotJson(args atIfAbsent(0, nil)))
            if(name == "export.json", return Telos saveWorldJson(args atIfAbsent(0, nil)))
            if(name == "import.json", return Telos loadWorldJson(args atIfAbsent(0, nil)))
            if(name == "replay", return Telos replayWal(args atIfAbsent(0, "telos.wal")))
            if(name == "rotateWal", return Telos rotateWal(args atIfAbsent(0, "telos.wal"), args atIfAbsent(1, 1048576)))
            if(name == "wal.export.json", return Telos walExportFramesJson(args atIfAbsent(0, logs base .. "/wal_frames.json"), args atIfAbsent(1, "telos.wal")))
            if(name == "run.exit",
                meta := Map clone
                meta atPut("reason", args atIfAbsent(0, "graceful"))
                writeln("[commands] dispatch run.exit")
                return Telos runAndExit(meta)
            )
            if(name == "rag.grow",
                spec := Map clone
                // args: [prompt, persona, n]
                spec atPut("prompt", args atIfAbsent(0, "Grow prototypal morphic UI contexts"))
                spec atPut("persona", args atIfAbsent(1, "BABS"))
                spec atPut("n", args atIfAbsent(2, 8))
                return Telos rag grow(spec)
            )
            if(name == "ui.plan.apply",
                persona := args atIfAbsent(0, "ROBIN")
                goal := args atIfAbsent(1, "Make the canvas speak with two morphs")
                return Telos applyPersonaUiPlan(persona, goal)
            )
            if(name == "heartbeat", return Telos ui heartbeat(args atIfAbsent(0, 1)))
            // creation
            if(name == "newRect",
                m := Telos createMorph; m resizeTo(args atIfAbsent(2, 80), args atIfAbsent(3, 60)); m moveTo(args atIfAbsent(0, 20), args atIfAbsent(1, 20));
                if(args size >= 7, m setColor(args at(4), args at(5), args at(6), args atIfAbsent(7, 1)));
                Telos addSubmorph(Telos world, m); return m id
            )
            if(name == "newText",
                t := TextMorph clone; t moveTo(args atIfAbsent(0, 20), args atIfAbsent(1, 20)); t setText(args atIfAbsent(2, "Text"));
                Telos addSubmorph(Telos world, t); return t id
            )
            // manipulation by id (if indexed)
            if(name == "move",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, m moveTo(args atIfAbsent(1, m x), args atIfAbsent(2, m y)); return "ok", return "[no-morph]")
            )
            if(name == "resize",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, m resizeTo(args atIfAbsent(1, m width), args atIfAbsent(2, m height)); return "ok", return "[no-morph]")
            )
            if(name == "color",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, m setColor(args atIfAbsent(1, 1), args atIfAbsent(2, 0), args atIfAbsent(3, 0), args atIfAbsent(4, 1)); return "ok", return "[no-morph]")
            )
            if(name == "front",
                mid := args atIfAbsent(0, nil); m := Telos morphIndex at(mid asString);
                if(m, m bringToFront; return "ok", return "[no-morph]")
            )
            if(name == "toggleGrid", return Telos ui toggleGrid(args atIfAbsent(0, nil)))
            "[no-such-command]" .. name
        )
        list := method( list("snapshot", "snapshot.json", "export.json", "import.json", "replay", "rotateWal", "wal.export.json", "run.exit", "rag.grow", "ui.plan.apply", "heartbeat", "newRect", "newText", "move", "resize", "color", "front", "toggleGrid") )
    )

    // Graceful run helper: UI + FFI + Persistence → exit 0
    runAndExit := method(meta,
        if(meta == nil, meta = Map clone)
        // Ensure world exists and breathe a little
        if(Telos hasSlot("world") and Telos world == nil, Telos createWorld)
        writeln("[run.exit] begin")
        // WAL evidence first so we can see progress even if later steps fail
        Telos mark("run.exit.begin", meta)
        Telos walBegin("run.exit", meta)
        // UI heartbeat (guarded)
        _ := try( Telos ui heartbeat(2) )
        // Touch Python seam for FFI pillar evidence (already guarded inside)
        _ := try( Telos pyEval("import sys; sys.version.split()[0]") )
        // Persist snapshots (guarded)
        _ := try( Telos saveSnapshot(nil) )
        _ := try( Telos saveSnapshotJson(nil) )
        // Close frame and mark completion
        Telos walEnd("run.exit")
    rei := Map clone; rei atPut("ok", 1)
    Telos mark("run.exit.end", rei)
        writeln("[run.exit] end → exit 0")
        // Exit with success
        System exit(0)
    )

    // Clipboard-based selection copy/paste
    clipboard := List clone
    clearSelection := method( selection = List clone )
    toSpec := method(m,
        // Minimal morph spec Map for reconstruction
        s := Map clone
        s atPut("type", m type)
        s atPut("id", m id)
        s atPut("x", m x); s atPut("y", m y)
        s atPut("width", m width); s atPut("height", m height)
        if(m hasSlot("color"), s atPut("color", m color))
        if(m hasSlot("text"), s atPut("text", m text))
        s
    )
    fromSpec := method(s,
        tname := s atIfAbsent("type", "Morph")
        proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
        m := proto clone
        if(s hasSlot("id"), m setSlot("id", s at("id")))
        if(s hasSlot("width") or s hasSlot("height"), m resizeTo(s atIfAbsent("width", m width), s atIfAbsent("height", m height)))
        if(s hasSlot("x") or s hasSlot("y"), m moveTo(s atIfAbsent("x", m x), s atIfAbsent("y", m y)))
        if(s hasSlot("color"), c := s at("color"); m setColor(c atIfAbsent(0,1), c atIfAbsent(1,0), c atIfAbsent(2,0), c atIfAbsent(3,1)))
        if(s hasSlot("text") and m hasSlot("setText"), m setText(s at("text")))
        m
    )
    copySelection := method(
        clipboard = List clone
        selection foreach(m, clipboard append(toSpec(m)))
        clipboard size
    )
    pasteAt := method(x, y,
        if(world == nil, createWorld)
        // Paste with small incremental offset per item
        ox := x; oy := y; pasted := List clone
        clipboard foreach(s,
            spec := s clone
            spec atPut("x", ox); spec atPut("y", oy)
            m := fromSpec(spec)
            m owner = world; world submorphs append(m); morphs append(m)
            if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
            morphIndex atPut(m id asString, m)
            transactional_setSlot(m, m id .. ".type", m type)
            pasted append(m)
            ox = ox + 10; oy = oy + 10
        )
        pasted size
    )

    // Selection helpers (textual only)
    selection := List clone
    selectAt := method(x, y,
        hits := hitTest(x, y)
        if(hits size == 0, return list())
        // Choose topmost (last in hits due to DFS); append to selection
        m := hits last
        selection append(m)
        list(m)
    )

    // Simple UI helpers bundle
    ui := Object clone do(
        gridEnabled := false
        toggleGrid := method(flag,
            if(flag != nil, gridEnabled = flag, gridEnabled = (gridEnabled not))
            gridEnabled
        )
        heartbeat := method(n := 1,
            if(n == nil, n = 1)
            i := 0
            while(i < n,
                if(Telos hasSlot("world") and Telos world == nil, Telos createWorld)
                // Call into C mainLoop for a short burst; it self-terminates after a few iterations
                if(Telos hasSlot("mainLoop"), Telos mainLoop)
                i = i + 1
            )
            n
        )

        // --- UI Plan Parsing & Application (minimal DSL) ---
        // Supported commands:
        //   let <name> = newRect x y w h [r g b a]
        //   let <name> = newText x y text_without_spaces
        //   move <name|id> x y
        //   resize <name|id> w h
        //   color <name|id> r g b [a]
        //   front <name|id>
        //   toggleGrid [0|1]
        parseAndApply := method(planText, meta,
            if(planText == nil, return 0)
            if(meta == nil, meta = Map clone)
            // Work context
            ctx := Map clone // name -> id
            applied := 0
            // helpers
            toNum := method(s,
                if(s == nil, return nil)
                // try number, else return s
                n := s asNumber
                if(n == 0 and (s beginsWithSeq("0") not) and (s != "0"), return s, n)
            )
            resolveId := method(tok,
                if(tok == nil, return nil)
                // if named, map to id; else return tok
                id := ctx at(tok)
                if(id != nil, id, tok)
            )
            // Iterate over lines
            lines := planText asString split("\n")
            // Open a WAL frame around this plan
            tag := "ui.plan"
            Telos walBegin(tag, meta)
            lines foreach(line,
                ln := line asString asMutable strip
                if(ln size == 0, continue)
                // Ignore fences
                if(ln beginsWithSeq("```"), continue)
                // Normalize multiple spaces
                while(ln containsSeq("  "), ln = ln asMutable replaceSeq("  ", " "))
                parts := ln split(" ")
                if(parts size == 0, continue)
                // let name = ...
                if(parts at(0) == "let" and parts size >= 4,
                    name := parts at(1)
                    eq := parts at(2)
                    if(eq == "=",
                        cmd := parts at(3)
                        if(cmd == "newRect",
                            x := parts atIfAbsent(4, "20") asNumber
                            y := parts atIfAbsent(5, "20") asNumber
                            w := parts atIfAbsent(6, "80") asNumber
                            h := parts atIfAbsent(7, "60") asNumber
                            // optional color
                            r := parts atIfAbsent(8, nil)
                            if(r != nil,
                                g := parts atIfAbsent(9, "0") asNumber
                                b := parts atIfAbsent(10, "0") asNumber
                                a := parts atIfAbsent(11, "1") asNumber
                                mid := Telos commands run("newRect", list(x,y,w,h,r asNumber,g,b,a))
                                ctx atPut(name, mid)
                            ,
                                mid := Telos commands run("newRect", list(x,y,w,h))
                                ctx atPut(name, mid)
                            )
                            applied = applied + 1
                            continue
                        )
                        if(cmd == "newText",
                            x := parts atIfAbsent(4, "20") asNumber
                            y := parts atIfAbsent(5, "20") asNumber
                            // Remainder as text
                            t := ""
                            i := 6
                            while(i < parts size,
                                if(t size == 0, t = parts at(i), t = t .. " " .. parts at(i))
                                i = i + 1
                            )
                            if(t size == 0, t = "Text")
                            mid := Telos commands run("newText", list(x,y,t))
                            ctx atPut(name, mid)
                            applied = applied + 1
                            continue
                        )
                    )
                )
                // Direct commands
                cmd := parts at(0)
                if(cmd == "move" and parts size >= 4,
                    id := resolveId(parts at(1))
                    x := parts at(2) asNumber
                    y := parts at(3) asNumber
                    _ := Telos commands run("move", list(id, x, y))
                    applied = applied + 1
                    continue
                )
                if(cmd == "resize" and parts size >= 3,
                    id := resolveId(parts at(1))
                    w := parts at(2) asNumber
                    h := parts atIfAbsent(3, nil)
                    if(h == nil, h = 0, h = h asNumber)
                    _ := Telos commands run("resize", list(id, w, h))
                    applied = applied + 1
                    continue
                )
                if(cmd == "color" and parts size >= 4,
                    id := resolveId(parts at(1))
                    r := parts at(2) asNumber
                    g := parts at(3) asNumber
                    b := parts at(4) asNumber
                    a := parts atIfAbsent(5, "1") asNumber
                    _ := Telos commands run("color", list(id, r, g, b, a))
                    applied = applied + 1
                    continue
                )
                if(cmd == "front" and parts size >= 2,
                    id := resolveId(parts at(1))
                    _ := Telos commands run("front", list(id))
                    applied = applied + 1
                    continue
                )
                if(cmd == "toggleGrid",
                    flag := parts atIfAbsent(1, nil)
                    _ := Telos commands run("toggleGrid", if(flag == nil, list(), list(flag asNumber)))
                    applied = applied + 1
                    continue
                )
            )
            Telos walEnd(tag)
            applied
        )
    )

    // Apply a persona-proposed UI plan to the world
    applyPersonaUiPlan := method(personaName, goalText,
        if(personaName == nil, personaName = "ROBIN")
        // Guard: personaCodex may not be initialized yet during early autorun
        p := if(self hasSlot("personaCodex") and personaCodex != nil, personaCodex get(personaName), nil)
        if(Telos world == nil, Telos createWorld)
        // Ask persona to propose changes in a simple plan DSL (or fall back to empty plan)
        prompt := "Propose a minimal Telos-Plan to achieve the goal. Use lines like: 'let rect1 = newRect 20 20 80 60 0.8 0.2 0.2 1', 'move rect1 120 40', 'let t1 = newText 30 30 Hello'. Avoid prose.\nGoal: " .. goalText
        out := ""
        if(p != nil, out = p converse(prompt, List clone))
        meta := Map clone; meta atPut("persona", personaName); meta atPut("goal", goalText)
        // WAL marks around plan application for deterministic evidence
        beginInfo := Map clone; beginInfo atPut("persona", personaName); beginInfo atPut("goal", goalText)
        Telos mark("ui.plan.apply.begin", beginInfo)
        applied := ui parseAndApply(out, meta)
        // Persist snapshots
        _ := Telos saveSnapshot(nil)
        _ := Telos saveSnapshotJson(nil)
    endInfo := Map clone; endInfo atPut("applied", applied)
    Telos mark("ui.plan.apply.end", endInfo)
        "applied:" .. applied asString
    )
    

    // Load world config from a simple spec (List of Maps)
    // Each entry: map(type:"RectangleMorph"|"TextMorph"|..., x:.., y:.., width:.., height:.., color:"[r,g,b,a]"|List, text:.., id:"...")
    loadConfig := method(spec,
        if(world == nil, self createWorld)
        if(spec == nil, return 0)
        created := 0
        makeColor := method(v,
            if(v type == "List", return v)
            if(v type == "Sequence",
                s := v asString strip; s = s afterSeq("["); s = s beforeSeq("]"); parts := s split(",")
                list(parts atIfAbsent(0, "0") asNumber, parts atIfAbsent(1, "0") asNumber, parts atIfAbsent(2, "0") asNumber, if(parts size > 3, parts at(3) asNumber, 1))
            , list(1,0,0,1))
        )
        if(spec type == "Map", spec = list(spec))
        spec foreach(e,
            tname := e atIfAbsent("type", "Morph")
            proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
            m := proto clone
            if(e hasSlot("id"), m setSlot("id", e at("id")))
            // attach to world
            m owner = world; world submorphs append(m); morphs append(m)
            if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
            morphIndex atPut(m id asString, m)
            // write identity to WAL
            transactional_setSlot(m, m id .. ".type", m type)
            // set geometry
            if(e hasSlot("x"), m moveTo(e at("x"), e atIfAbsent("y", m y)), m moveTo(m x, m y))
            if(e hasSlot("width"), m resizeTo(e at("width"), e atIfAbsent("height", m height)))
            if(e hasSlot("color"), c := makeColor(e at("color")); m setColor(c atIfAbsent(0,1), c atIfAbsent(1,0), c atIfAbsent(2,0), c atIfAbsent(3,1)))
            if(e hasSlot("text") and m hasSlot("setText"), m setText(e at("text")))
            created = created + 1
        )
        created
    )

    // Attach a Persona Codex slot; will be set after prototypes defined
    personaCodex := nil

    // Codex feeder stub (later backed by VSA-RAG)
    codex := Object clone do(
        cache := Map clone
        getPassages := method(personaName,
            // Offline: return small, persona-appropriate kernels
            if(personaName == "BRICK", return list(
                "Vows: autopoiesis; prototypal purity; watercourse way; antifragility.",
                "Keep invariants. Build vertical slices."
            ))
            if(personaName == "ROBIN", return list(
                "Direct manipulation. Clarity and liveliness.",
                "Make the canvas speak with minimal code."
            ))
            if(personaName == "BABS", return list(
                "Single source of truth. Transactional clarity.",
                "WAL markers: BEGIN/END; replay on startup."
            ))
            if(personaName == "ALFRED", return list(
                "Alignment, consent, clarity.",
                "Meta-commentary on outputs; ensure contracts and budgets are respected."
            ))
            list()
        )
    )
)

// Fractals manager: extract contexts and compose concepts from raw text
Telos fractals := Object clone do(
    // Split text into approx target-sized paragraphs
    chunkParagraphs := method(text, targetChars,
        if(targetChars == nil, targetChars = 900)
        paras := text split("\n\n")
        out := List clone
        acc := ""
        paras foreach(p,
            blk := (p asString) asMutable strip
            if(blk size == 0, continue)
            if(acc size + blk size + 2 > targetChars,
                if(acc size > 0, out append(acc))
                acc = blk
            ,
                if(acc size == 0, acc = blk, acc = acc .. "\n\n" .. blk)
            )
        )
        if(acc size > 0, out append(acc))
        out
    )

    // Build ContextFractals for a text; returns List(ContextFractal)
    extractContexts := method(text, targetChars,
        if(targetChars == nil, targetChars = 900)
        chunks := chunkParagraphs(text, targetChars)
        ctxs := List clone
        i := 0
        while(i < chunks size,
            ctext := chunks at(i)
            cf := ContextFractal with(ctext)
            _ := cf vectorize // stub
            ctxs append(cf)
            // Persist JSONL and index into memory
            crec := Map clone
            crec atPut("chunk", i)
            crec atPut("len", ctext size)
            crec atPut("text", ctext)
            Telos logs append(Telos logs fractalsContexts, Telos json stringify(crec))
            Telos memory addContext(ctext)
            i = i + 1
        )
        ctxs
    )

    // Compose a ConceptFractal from text: bind top N contexts and summarize
    extractConcept := method(text, targetChars, maxParts, tags,
        if(targetChars == nil, targetChars = 900)
        if(maxParts == nil, maxParts = 8)
        tag := "fractals.extract"
        Telos walCommit(tag, Map clone, block(
            ctxs := self extractContexts(text, targetChars)
            concept := ConceptFractal clone
            if(tags != nil, concept meta atPut("tags", tags clone))
            n := (ctxs size min(maxParts))
            j := 0
            while(j < n, concept bind(ctxs at(j)); j = j + 1)
            _ := concept summarize // offline stub
            // Persist concept record
            rec := Map clone
            rec atPut("parts", n)
            rec atPut("summary", concept summary)
            if(tags != nil, rec atPut("tags", tags))
            Telos logs append(Telos logs fractalsConcepts, Telos json stringify(rec))
            // Also add to memory for retrieval
            Telos memory addConcept(concept)
        ))
        // Return nothing explicit; consumers can read logs or hold the concept in the future
        // Save memory index to disk for durability
        _ := Telos memory save(nil)
        "ok"
    )

    // Refine a concept by retrieving related contexts and resummarizing
    refineConcept := method(summaryQuery, k, tags,
        if(summaryQuery == nil, return "[refine: empty query]")
        if(k == nil, k = 5)
        info := Map clone; info atPut("q", summaryQuery)
        Telos walCommit("fractals.refine", info, block(
            hits := Telos memory search(summaryQuery, k)
            concept := ConceptFractal clone
            if(tags != nil, concept meta atPut("tags", tags clone))
            // Bind retrieved contexts
            h := 0
            while(h < hits size,
                tx := (hits at(h)) at("text")
                concept bind(ContextFractal with(tx))
                h = h + 1
            )
            _ := concept summarize
            // Persist
            rec := Map clone
            rec atPut("q", summaryQuery)
            rec atPut("parts", hits size)
            rec atPut("summary", concept summary)
            if(tags != nil, rec atPut("tags", tags))
            Telos logs append(Telos logs fractalsConcepts, Telos json stringify(rec))
            // Index new summary
            Telos memory addConcept(concept)
        ))
        _ := Telos memory save(nil)
        "ok"
    )

    // Iterative refinement: run N refinement passes using previous summary as query
    refineIterative := method(seedQuery, passes, k, tags,
        if(passes == nil, passes = 3)
        if(k == nil, k = 5)
        q := seedQuery asString
        i := 0
        while(i < passes,
            _ := self refineConcept(q, k, tags)
            // Use last summary from logs as next query (simplified: same q for now)
            i = i + 1
        )
        "ok"
    )

    // Mine a single file into contexts and a concept
    mineFile := method(path, targetChars, maxParts, tags,
        if(targetChars == nil, targetChars = 900)
        if(maxParts == nil, maxParts = 8)
        f := File with(path)
        if(f exists not, return 0)
        txt := f contents
        if(txt == nil, return 0)
    fmi := Map clone; fmi atPut("path", path)
    Telos walCommit("fractals.extract:file", fmi, block(
            _ := self extractConcept(txt, targetChars, maxParts, tags)
        ))
        // Save memory index after mining this file
        _ := Telos memory save(nil)
        1
    )

    // Recursively mine a directory for text-like files under caps
    mineDirectory := method(rootPath, maxFiles, targetChars, maxParts, tags,
        if(maxFiles == nil, maxFiles = 10)
        if(targetChars == nil, targetChars = 900)
        if(maxParts == nil, maxParts = 8)
        d := Directory with(rootPath)
        if(d exists not, return 0)
        count := 0
        // helper to identify text files
        isText := method(p,
            lp := p asLowercase
            lp endsWithSeq(".md") or lp endsWithSeq(".txt") or lp endsWithSeq(".io") or lp endsWithSeq(".py")
        )
        // DFS with caps
        walk := method(dir,
            if(count >= maxFiles, return)
            dir files foreach(fobj,
                if(count >= maxFiles, return)
                p := fobj path
                if(isText(p),
                    _ := self mineFile(p, targetChars, maxParts, tags)
                    count = count + 1
                )
            )
            dir directories foreach(sub,
                if(count >= maxFiles, return)
                if(sub name != "." and sub name != "..", walk(sub))
            )
        )
        walk(d)
        // Save memory index after directory mining
        _ := Telos memory save(nil)
        count
    )

    // Compose a higher-order concept from a list of concept summaries (combination)
    composeConcepts := method(summaries, maxParts,
        if(maxParts == nil, maxParts = 8)
        c := ConceptFractal clone
        sCount := summaries size min(maxParts)
        i := 0
        while(i < sCount,
            c bind(ContextFractal with(summaries at(i)))
            i = i + 1
        )
        _ := c summarize
        // Log combined concept
        rec := Map clone
        rec atPut("combinedParts", sCount)
        rec atPut("summary", c summary)
        Telos logs append(Telos logs fractalsConcepts, Telos json stringify(rec))
        // Index combined concept
        Telos memory addConcept(c)
        c summary
    )
)

// --- Fractal Reasoning Prototypes ---

// ContextFractal: atomic shard of context (prototypal)
ContextFractal := Object clone
ContextFractal id := System uniqueId
ContextFractal payload := ""
ContextFractal meta := Map clone

// When cloning, fresh identity emerges
ContextFractal clone := method(
    newFractal := resend
    newFractal id := System uniqueId
    newFractal meta := Map clone
    newFractal
)
    with := method(text,
        f := self clone; f payload = text; f meta atPut("type", "text"); f
    )
    vectorize := method(
        // stub: log and return a fake small vector
        writeln("[fractal] vectorize context: ", payload)
        list(0.1, 0.2, 0.3)
    )
)

// ConceptFractal: composition/binding of contexts and concepts (prototypal)
ConceptFractal := Object clone
ConceptFractal id := System uniqueId
ConceptFractal parts := List clone // mixture of ContextFractal/ConceptFractal
ConceptFractal summary := ""
ConceptFractal meta := Map clone

// When cloning, fresh identity and lists emerge
ConceptFractal clone := method(
    newConcept := resend
    newConcept id := System uniqueId
    newConcept parts := List clone
    newConcept meta := Map clone
    newConcept
)

    bind := method(fractal,
        parts append(fractal)
        self
    )

    compose := method(fractals,
        fractals foreach(f, parts append(f)); self
    )

    summarize := method(
        // Use LLM stub to form a natural-language summary from components
        txt := parts map(f, f payload ifNil("[cf]")) join(" | ")
        spec := Map clone
        spec atPut("prompt", "Summarize: " .. txt)
        spec atPut("provider", "offline")
        res := Telos llmCall(spec)
        summary = res; res
    )

    refineWithVSA := method(query,
        // Use memory search to retrieve related contexts to tighten the concept
        hits := Telos memory search(query, 5)
        // bind top results (if any)
        hits foreach(h, parts append(ContextFractal with(h)))
        self
    )

    vectorize := method(
        // Combine child vectors (stub: average)
        vecs := parts map(f, f vectorize)
        if(vecs size == 0, return list())
        acc := list(0,0,0)
        vecs foreach(v, acc atPut(0, acc at(0) + v atIfAbsent(0, 0));
                    acc atPut(1, acc at(1) + v atIfAbsent(1, 0));
                    acc atPut(2, acc at(2) + v atIfAbsent(2, 0)))
        acc mapInPlace(x, x / vecs size)
    )

    score := method(
        Telos scoreSolution(meta)
    )
)

// --- Personas & Codex (offline-safe seed) ---

Persona := Object clone do(
    init := method(
        self name := "Unnamed"
        self role := ""
        self ethos := ""
        self speakStyle := ""
        self tools := List clone
        self memoryTags := List clone
    self contextKernel := ""
    self weights := Map clone; self weights atPut("alpha", 1); self weights atPut("beta", 1); self weights atPut("gamma", 1); self weights atPut("delta", 1)
    self budget := Map clone // placeholders
        self risk := "low"
        self routingHints := ""
    self genOptions := Map clone // default generation params per persona (temperature, top_p, etc.)
    )

    with := method(spec,
        p := self clone
        p init
        p name = spec atIfAbsent("name", p name)
        p role = spec atIfAbsent("role", p role)
        p ethos = spec atIfAbsent("ethos", p ethos)
        p speakStyle = spec atIfAbsent("speakStyle", p speakStyle)
        p tools = spec atIfAbsent("tools", p tools) clone
        p memoryTags = spec atIfAbsent("memoryTags", p memoryTags) clone
        p weights = spec atIfAbsent("weights", p weights) clone
        p budget = spec atIfAbsent("budget", p budget) clone
        p risk = spec atIfAbsent("risk", p risk)
        p routingHints = spec atIfAbsent("routingHints", p routingHints)
        p
    )

    // Cognitive moves
    think := method(prompt,
        // condition prompt with persona voice and ethos as constraints/flavor
        full := "[" .. name .. ":" .. role .. "]\nEthos: " .. ethos .. "\nPrompt: " .. prompt
        spec := Map clone; spec atPut("prompt", full); spec atPut("persona", name); Telos llmCall(spec)
    )

    recall := method(query, k := 5,
        // augment query with tags
        tagStr := memoryTags join(",")
        Telos memory search("[" .. name .. " tags:" .. tagStr .. "] " .. query, k)
    )

    act := method(toolSpec,
        Telos toolUse(toolSpec)
    )

    evaluate := method(solution,
        // merge weights into solution map
        m := solution clone
        m atPut("alpha", weights at("alpha"))
        m atPut("beta",  weights at("beta"))
        m atPut("gamma", weights at("gamma"))
        m atPut("delta", weights at("delta"))
        Telos scoreSolution(m)
    )

    commit := method(target, slotName, value,
        Telos transactional_setSlot(target, slotName, value)
    )

    // Meta: allow one persona to comment on another's output
    commentOn := method(otherPersona, text,
        review := "[" .. name .. " commentary on " .. otherPersona name .. "]\n" .. text
        spec := Map clone; spec atPut("prompt", review); spec atPut("persona", name); Telos llmCall(spec)
    )

    // Contract checking stub
    checkContracts := method(artifact,
        // offline: return a structured OK result
        m := Map clone
        m atPut("status", "OK")
        m atPut("notes", "Contracts respected (stub)")
        m atPut("artifact", artifact)
        m
    )

    // Load persona-specific context from codex (stubbed)
    loadPersonaContext := method(
        passages := Telos codex getPassages(name)
        self contextKernel := passages join("\n")
        self
    )

    // Compose a system prompt from kernel + vows
    composeSystemPrompt := method(
        // Ensure context kernel is initialized
        if(self hasSlot("contextKernel") not or self contextKernel == nil or self contextKernel size == 0, self loadPersonaContext)
        kernel := self contextKernel ifNil("")
        "You are " .. name .. " (" .. role .. ").\n" ..
        "Ethos: " .. ethos .. "\n" ..
        "Style: " .. speakStyle .. "\n" ..
        "Guidance:\n" .. kernel
    )

    // Converse with user using persona system prompt
    converse := method(userMsg, history,
        if(history == nil, history = List clone)
        s := self composeSystemPrompt
        spec := Map clone
        spec atPut("system", s)
        spec atPut("prompt", userMsg)
        spec atPut("history", history)
        spec atPut("persona", name)
        Telos llmCall(spec)
    )

    // ROBIN-specific: analyze UI and propose changes
    proposeUiChanges := method(goalText,
        snapshot := Telos captureScreenshot
        prompt := "Given this UI snapshot, propose morph changes: \n" .. snapshot .. "\nGoal: " .. goalText
        spec := Map clone
        spec atPut("prompt", prompt)
        spec atPut("persona", name)
        spec atPut("model", "telos/robin")
        Telos llmCall(spec)
    )

    // RESEARCH LOOP (BABS primary)
    // Identify low-confidence ConceptFractals to target
    identifyConceptGaps := method(concepts,
        // concepts: List of ConceptFractal or Maps with confidence
        // stub: return input filtered to those with meta gap == true or empty summary
        if(concepts isKindOf(List) not,
            return list()
        )
        concepts select(c,
            ((c meta and c meta atIfAbsent("gap", false)) or (c summary == nil or c summary size == 0))
        )
    )

    // Suggest prompts for WING agent (human-run Deep Research)
    suggestWingPrompts := method(gapConcepts,
        // stub: build a few structured prompts per concept
        prompts := List clone
        gapConcepts foreach(c,
            topic := c summary ifNil("unspecified concept")
            prompts append("Clarify theoretical foundations of: " .. topic)
            prompts append("Enumerate edge cases and failure modes for: " .. topic)
            prompts append("Survey best practices and canonical patterns related to: " .. topic)
        )
        prompts
    )

    // Ingest human-produced research report into memory and concept graph
    ingestResearchReport := method(concept, reportText,
        // Create a ContextFractal and bind to the concept, then resummarize
        cf := ContextFractal with(reportText)
        concept bind(cf) summarize
        // persist a note
        Telos transactional_setSlot(Telos, "lastIngestedResearch", "ok")
        // add to memory index (stubbed)
        Telos memory addContext(reportText)
        concept
    )
)

PersonaCodex := Object clone do(
    init := method(
        self registry := Map clone
        self default := nil
    )

    register := method(persona,
        registry atPut(persona name, persona)
        if(default == nil, default = persona)
        persona
    )

    get := method(name,
        if(name == nil, return default)
        registry at(name)
    )

    choose := method(hints,
        // simple chooser: by name or default
        if(hints type == "Sequence",
            return self get(hints)
        )
        // fallback
        default
    )
)

// Seed default personas from docs/Personas_Codex.md schema
Telos personaCodex = PersonaCodex clone
do(
    spec := Map clone
    spec atPut("name", "BRICK")
    spec atPut("role", "The Architect")
    spec atPut("ethos", "autopoiesis, prototypal purity, watercourse way, antifragility")
    spec atPut("speakStyle", "precise, concise, reflective")
    spec atPut("tools", list("summarizer", "diff", "planner"))
    spec atPut("memoryTags", list("architecture", "invariants", "roadmap"))
    w := Map clone; w atPut("alpha", 1.25); w atPut("beta", 0.8); w atPut("gamma", 1.0); w atPut("delta", 0.6)
    spec atPut("weights", w)
    b := Map clone; b atPut("mode", "offline"); spec atPut("budget", b)
    spec atPut("risk", "low-moderate")
    spec atPut("routingHints", "design, refactors, codex")
    go := Map clone; go atPut("temperature", 0.4); go atPut("top_p", 0.9); go atPut("top_k", 40); go atPut("repeat_penalty", 1.1)
    spec atPut("genOptions", go)
    Telos personaCodex register(Persona with(spec))
)

do(
    spec := Map clone
    spec atPut("name", "ROBIN")
    spec atPut("role", "The Gardener")
    spec atPut("ethos", "direct manipulation, clarity, liveliness")
    spec atPut("speakStyle", "visual-first, concrete")
    spec atPut("tools", list("draw", "layout"))
    spec atPut("memoryTags", list("ui", "morphic", "canvas"))
    w := Map clone; w atPut("alpha", 1.0); w atPut("beta", 0.7); w atPut("gamma", 0.85); w atPut("delta", 0.7)
    spec atPut("weights", w)
    b := Map clone; b atPut("mode", "offline"); spec atPut("budget", b)
    spec atPut("risk", "low")
    spec atPut("routingHints", "ui, demos")
    go := Map clone; go atPut("temperature", 0.7); go atPut("top_p", 0.95); go atPut("top_k", 50); go atPut("repeat_penalty", 1.05)
    spec atPut("genOptions", go)
    Telos personaCodex register(Persona with(spec))
)

do(
    spec := Map clone
    spec atPut("name", "BABS")
    spec atPut("role", "The Archivist-Researcher")
    spec atPut("ethos", "single source of truth; disciplined inquiry; bridge known↔unknown")
    spec atPut("speakStyle", "methodical, inquisitive")
    spec atPut("tools", list("wal.write", "wal.replay", "research.prompt", "ingest.report"))
    spec atPut("memoryTags", list("persistence", "recovery", "provenance", "research", "gaps"))
    w := Map clone; w atPut("alpha", 0.9); w atPut("beta", 0.6); w atPut("gamma", 1.2); w atPut("delta", 1.0)
    spec atPut("weights", w)
    b := Map clone; b atPut("mode", "offline"); spec atPut("budget", b)
    spec atPut("risk", "low")
    spec atPut("routingHints", "durability, recovery, research triage")
    go := Map clone; go atPut("temperature", 0.3); go atPut("top_p", 0.85); go atPut("top_k", 40); go atPut("repeat_penalty", 1.15)
    spec atPut("genOptions", go)
    Telos personaCodex register(Persona with(spec))
)

do(
    spec := Map clone
    spec atPut("name", "ALFRED")
    spec atPut("role", "The Butler of Contracts")
    spec atPut("ethos", "alignment, consent, clarity; steward of invariants and budgets")
    spec atPut("speakStyle", "courteous, surgical, meta-aware")
    spec atPut("tools", list("contract.check", "policy.inspect", "summarizer"))
    spec atPut("memoryTags", list("contracts", "policies", "alignment"))
    w := Map clone; w atPut("alpha", 0.95); w atPut("beta", 0.7); w atPut("gamma", 1.2); w atPut("delta", 1.1)
    spec atPut("weights", w)
    b := Map clone; b atPut("mode", "offline"); spec atPut("budget", b)
    spec atPut("risk", "low")
    spec atPut("routingHints", "contract checks, risk analysis, meta-commentary")
    go := Map clone; go atPut("temperature", 0.2); go atPut("top_p", 0.8); go atPut("top_k", 40); go atPut("repeat_penalty", 1.2)
    spec atPut("genOptions", go)
    Telos personaCodex register(Persona with(spec))
)


// Morph prototype - the fundamental living interface object
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
    moveTo := method(newX, newY,
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

    // Resize the morph (direct manipulation)
    resizeTo := method(newWidth, newHeight,
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

    // Change color (direct manipulation)
    setColor := method(r, g, b, a,
        if(a == nil, a = 1)
        self color = list(r, g, b, a)
        if(Telos isReplaying == false,
            if(persistedIdentity == false,
                Telos transactional_setSlot(self, id .. ".type", self type)
                persistedIdentity = true
            )
            Telos transactional_setSlot(self, id .. ".color", "[" .. r .. "," .. g .. "," .. b .. "," .. a .. "]")
        )
        "Telos: Morph color changed in living palette"
    )

    setZIndex := method(z,
        self zIndex = z
        if(Telos isReplaying == false,
            if(persistedIdentity == false,
                Telos transactional_setSlot(self, id .. ".type", self type)
                persistedIdentity = true
            )
            Telos transactional_setSlot(self, id .. ".zIndex", z asString)
        )
        "ok"
    )

    bringToFront := method(
        // Set z higher than max sibling
        z := zIndex
        if(owner,
            maxZ := 0
            owner submorphs foreach(m, if(m zIndex > maxZ, maxZ = m zIndex))
            z = maxZ + 1
            // Reorder list so self is at the end (top)
            owner submorphs remove(self)
            owner submorphs append(self)
        )
        setZIndex(z)
        "ok"
    )

    // Check if point is inside morph bounds
    containsPoint := method(px, py,
        (px >= x and px <= (x + width)) and (py >= y and py <= (y + height))
    )

    // Add a submorph to this morph
    addMorph := method(child,
        child owner = self
        submorphs append(child)
        Telos addSubmorph(self, child)
    )

    // Remove a submorph
    removeMorph := method(child,
        submorphs remove(child)
        child owner = nil
        Telos removeSubmorph(self, child)
    )

    // Draw this morph and all submorphs
    drawOn := method(canvas,
        // Draw self
        self draw

        // Draw all submorphs
        submorphs foreach(morph, morph drawOn(canvas))
    )

    // Handle events (direct manipulation)
    handleEvent := method(event,
        // If currently dragging, keep handling events regardless of bounds
        if(self hasSlot("dragging") and dragging == true,
            return self processEvent(event)
        )
        // Otherwise, only handle if pointer within bounds
        if(self containsPoint(event atIfAbsent("x", 0), event atIfAbsent("y", 0)),
            return self processEvent(event)
        )
        false
    )

    // Process event (specialize in living clones)
    processEvent := method(event,
        // Children first
        submorphs foreach(morph, if(morph handleEvent(event), return true))
        t := event atIfAbsent("type", "")
        ex := event atIfAbsent("x", 0)
        ey := event atIfAbsent("y", 0)
        if(t == "mousedown",
            if(self containsPoint(ex, ey),
                dragging = true
                dragDX = ex - x
                dragDY = ey - y
                return true
            )
        )
        if(t == "mousemove" and dragging,
            // move keeping grab offset
            self x = ex - dragDX
            self y = ey - dragDY
            return true
        )
        if(t == "mouseup" and dragging,
            dragging = false
            if(Telos isReplaying == false,
                Telos transactional_setSlot(self, id .. ".position", "(" .. x .. "," .. y .. ")")
            )
            // Click gesture detection: if mouse down/up happened inside quickly (no timing here), call onClick if present
            if(self hasSlot("onClick") and onClick != nil,
                onClick call(self)
            )
            return true
        )
        false
    )
)

// Rectangle morph - basic shape
RectangleMorph := Morph clone do(
    draw := method(
        writeln("Telos: Drawing rectangle at (", x, ",", y, ") size ", width, "x", height)
    )

    // Toggle color on click (red <-> green)
    processEvent := method(event,
        // Children first
        submorphs foreach(m, if(m handleEvent(event), return true))
        t := event atIfAbsent("type", "")
        if(t == "click",
            // Check bounds to be safe (even though handleEvent gates)
            if(self containsPoint(event atIfAbsent("x", 0), event atIfAbsent("y", 0)),
                current := color
                // Decide based on red channel
                red := current at(0) ifNil(1)
                if(red > 0.5,
                    setColor(0, 1, 0, 1),
                    setColor(1, 0, 0, 1)
                )
                writeln("Telos: RectangleMorph toggled color at (", x, ",", y, ")")
                return true
            )
        )
        // Fallback to generic behavior (e.g., dragging)
        resend
    )
)
// Button morph - rectangle with label and action slot (prototypal)
ButtonMorph := RectangleMorph clone
ButtonMorph label := TextMorph clone
ButtonMorph label moveTo(ButtonMorph x + 8, ButtonMorph y + 8)
ButtonMorph label setText("Button")
ButtonMorph action := nil

// Default click behavior emerges through message passing
ButtonMorph onClick := method(owner,
    if(owner action != nil, owner action call(owner))
)

// Override clone to ensure fresh button identity
ButtonMorph clone := method(
    newButton := resend
    newButton label := TextMorph clone
    newButton label moveTo(newButton x + 8, newButton y + 8)
    newButton label setText("Button")
    newButton
)
    setText := method(t,
        if(self hasSlot("label") and label != nil, label setText(t))
        self
    )
)


// Circle morph - another basic shape
CircleMorph := Morph clone do(
    draw := method(
        radius := width / 2
        centerX := x + radius
        centerY := y + radius
        writeln("Telos: Drawing circle at (", centerX, ",", centerY, ") radius ", radius)
    )
)

// Text morph - for displaying text (prototypal)
TextMorph := Morph clone
TextMorph text := "Hello TelOS" 
TextMorph fontSize := 12

    draw := method(
        writeln("Telos: Drawing text '", text, "' at (", x, ",", y, ") size ", fontSize)
    )

    setText := method(newText,
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
)

// Text input morph - minimal placeholder for user input (prototypal)
TextInputMorph := TextMorph clone
TextInputMorph inputBuffer := ""
TextInputMorph onSubmit := nil
    appendInput := method(s,
        inputBuffer = inputBuffer .. s
        "ok"
    )
    setOnSubmit := method(block,
        onSubmit = block; "ok"
    )
    submit := method(
        if(onSubmit, onSubmit call(inputBuffer))
        inputBuffer = ""
        "submitted"
    )
)

writeln("Telos: Zygote pillars loaded - mind touches muscle, heartbeat begins, first glance opens")
// Boot trace: append a line so we can observe startup under nohup/background
do(
    now := Date clone now asString
    Telos logs append("logs/boot.log", "[boot] " .. now)
)
// Trace process arguments for DOE diagnostics
do(
    a := System args
    Telos logs append("logs/args.log", "args=" .. a asString)
)

// Early diagnostic: allow immediate graceful exit right after args logging
do(
    fcs := File with("logs/force_exit_start.txt")
    if(fcs exists,
        writeln("[force-exit-start] triggering Telos.runAndExit()")
        Telos logs append("logs/autorun_run.log", "[force-exit-start] trigger @" .. Date clone now asString)
        m := Map clone; m atPut("reason", "start")
        Telos runAndExit(m)
    )
)

// --- Simple Layout Prototypes ---
Layout := Object clone do(
    orientation := "row" // or "column"
    spacing := 8
    padding := 8
    apply := method(parent,
        if(parent == nil, return 0)
        x := parent x + padding
        y := parent y + padding
        count := 0
        if(orientation == "row",
            parent submorphs foreach(m,
                m moveTo(x, m y)
                x = x + m width + spacing
                count = count + 1
            )
        ,
            parent submorphs foreach(m,
                m moveTo(m x, y)
                y = y + m height + spacing
                count = count + 1
            )
        )
        count
    )
)

RowLayout := Layout clone do(orientation := "row")
ColumnLayout := Layout clone do(orientation := "column")

// Canvas prototype: minimal wrapper around window lifecycle using Telos bridge
Canvas := Object clone do(
    init := method(
        self isOpen := false
        self title := "The Entropic Garden"
        self width := 640
        self height := 480
        self
    )
    open := method(
        if(isOpen, return self)
        Telos openWindow
        isOpen = true
        self
    )
    heartbeat := method(n,
        // Set default inside body to avoid parser issues
        if(n == nil, n = 1)
        // Run the main loop n times to keep the window alive longer
        i := 0
        while(i < n,
            Telos mainLoop
            i = i + 1
        )
        n
    )
    close := method(
        if(isOpen not, return self)
        Telos closeWindow
        isOpen = false
        self
    )
)

// ChatConsole prototype: send persona messages (console-based I/O)
ChatConsole := Object clone do(
    init := method(
        self personaName := "ROBIN"
        self history := List clone
        self
    )
    setPersona := method(name,
        if(name != nil, self personaName = name)
        self
    )
    currentPersona := method(
        Telos personaCodex get(personaName)
    )
    send := method(msg,
        p := currentPersona
        if(p == nil, return "[no-persona]")
        // Converse using persona stub; keep lightweight history
        out := p converse(msg, history)
        // append minimal turn history
        history append("U:" .. msg)
        history append("A:" .. out)
        out
    )
    run := method(
        writeln("--- Persona Chat (type 'exit' to quit, '/p NAME' to switch persona) ---")
        while(true,
            "You> " print
            line := File standardInput readLine
            if(line == nil, break)
            line = line asString
            if(line == "exit", break)
            if(line beginsWithSeq("/p "),
                n := line exSlice(3) strip
                if(n size > 0, personaName = n; writeln("[persona set to ", n, "]"))
                continue
            )
            out := send(line)
            writeln(personaName, "> ", out)
        )
        "bye"
    )
)

// Prototypal purity: treat the just-defined Telos as a prototype; clone a fresh living instance
do(
    // Preserve a handle to the behavior prototype
    TelosProto := Telos
    // Clone to create the living organism instance and rebind the global name to it
    Telos = TelosProto clone
    // Optional breadcrumb for DOE visibility
    Telos mark("init.clone", Map clone)
)

// Initialize Telos zygote to define base slots (world, morphs, flags) on the instance
do(
    err := try(Telos init)
    if(err,
        Telos logs append("logs/autorun_error.log", "[init] error @" .. Date clone now asString .. " :: " .. err asString)
    )
)
// Post-init breadcrumb for DOE: verify we reached this point
do(
    Telos logs append("logs/autorun_run.log", "[autorun] post-init reached @" .. Date clone now asString)
    writeln("[post-init] Telos init complete")
)

// --- Minimal Autorun Seam ---
// If a path is present in logs/autorun.txt, attempt to doFile it on startup.
do(
    berr := nil
    berr = try(
    // Breadcrumb: entering autorun scan
    Telos logs append("logs/autorun_run.log", "[autorun] scan begin @" .. Date clone now asString)
    // Discover autorun instruction file from common locations
    arCandidates := list("logs/autorun.txt", "/mnt/c/EntropicGarden/logs/autorun.txt")
    arFile := nil
    arCandidates foreach(c,
        fc := File with(c)
        if(fc exists and arFile == nil, arFile = fc)
    )
    if(arFile != nil,
        p := arFile contents asString asMutable strip
        if(p size > 0,
            // Log start of autorun regardless
            Telos logs append("logs/autorun_run.log", "[autorun] begin " .. p .. " @" .. Date clone now asString)
            // Only attempt doFile if target exists to avoid exceptions
            // Normalize Windows path to WSL if needed
            np := p asString
            if(np beginsWithSeq("C:"),
                // Replace backslashes with slashes and prefix /mnt/c
                np = np asMutable replaceSeq("\\", "/")
                np = "/mnt/c" .. np exSlice(2)
            )
            tf := File with(np)
            if(tf exists,
                writeln("[autorun] executing ", np)
                err2 := try(doFile(np))
                if(err2,
                    Telos logs append("logs/autorun_error.log", "[autorun] error " .. np .. " @" .. Date clone now asString .. " :: " .. err2 asString)
                )
                Telos logs append("logs/autorun_run.log", "[autorun] done " .. np .. " @" .. Date clone now asString)
            ,
                Telos logs append("logs/autorun_run.log", "[autorun] missing " .. np .. " @" .. Date clone now asString)
                writeln("[autorun] missing ", np)
            )
        )
    ,
        // No autorun file found
        Telos logs append("logs/autorun_run.log", "[autorun] none @" .. Date clone now asString)
    )
    )
    if(berr,
        Telos logs append("logs/autorun_error.log", "[autorun] block error @" .. Date clone now asString .. " :: " .. berr asString)
    )
)

// Optional: Auto-exit gracefully after autorun for CI/DOE smokes
do(
    eerr := nil
    eerr = try(
    Telos logs append("logs/autorun_run.log", "[autorun-exit] scan begin @" .. Date clone now asString)
    exitCandidates := list("logs/autorun_exit.txt", "/mnt/c/EntropicGarden/logs/autorun_exit.txt")
    ef := nil
    exitCandidates foreach(c,
        fc := File with(c)
        if(fc exists and ef == nil, ef = fc)
    )
    if(ef != nil,
        writeln("[autorun-exit] triggering graceful exit")
        Telos logs append("logs/autorun_run.log", "[autorun-exit] trigger @" .. Date clone now asString)
        rmi := Map clone; rmi atPut("reason", "autorun")
        Telos runAndExit(rmi)
    ,
        Telos logs append("logs/autorun_run.log", "[autorun-exit] none @" .. Date clone now asString)
    )
    )
    if(eerr,
        Telos logs append("logs/autorun_error.log", "[autorun-exit] block error @" .. Date clone now asString .. " :: " .. eerr asString)
    )
)

// Diagnostic: Force graceful exit if logs/force_exit.txt exists (bypasses autorun)
do(
    ferr := nil
    ferr = try(
        fc := File with("logs/force_exit.txt")
        if(fc exists,
            writeln("[force-exit] forcing Telos.runAndExit()")
            Telos logs append("logs/autorun_run.log", "[force-exit] trigger @" .. Date clone now asString)
            info := Map clone; info atPut("reason", "force")
            Telos runAndExit(info)
        )
    )
    if(ferr,
        Telos logs append("logs/autorun_error.log", "[force-exit] block error @" .. Date clone now asString .. " :: " .. ferr asString)
    )
)