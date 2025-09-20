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

// === PROTOTYPAL PURITY ENFORCEMENT ===
// CRITICAL REMINDER: In Io, EVERYTHING is an object accessed through message passing
// - Variables are messages sent to slots
// - Parameters are objects, not simple values  
// - No class-like static references allowed
// - All data flows through prototypal cloning and message sending

PrototypalPurityEnforcer := Object clone do(
    // Remind us that variables must be objects
    validateObjectAccess := method(value, context,
        if(value type == "Sequence",
            writeln("[PROTOTYPAL WARNING] String literal '", value, "' in context: ", context)
            writeln("[REMINDER] Convert to prototypal object with message passing")
        )
        value
    )
    
    // Enforce object-based design patterns
    createObjectWrapper := method(value, description,
        wrapper := Object clone do(
            content := value
            description := description
            asString := method(content asString)
            type := "PrototypalWrapper"
        )
        wrapper
    )
)

// Adopt the C-level Telos as prototype (registered on Lobby Protos)
Telos := Lobby Protos Telos clone do(
    // Minimal JSON stringify for Maps/Lists/Numbers/Strings/Booleans/nil
    json := Object clone do(
        escape := method(s,
            // escape backslash, quotes, and newlines on a mutable copy
            m := s asString asMutable
            m replaceSeq("\\", "\\\\")
            m replaceSeq("\"", "\\\"")
            m replaceSeq("\n", "\\n")
            m
        )
        stringify := method(x,
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
    )

    // --- rRAG Skeleton (Io->C->Python bridge) ---
    rag := Object clone do(
        index := method(docs,
            // docs: List of strings
            if(docs == nil, docs = list())
            // Offline stub: index into in-memory memory substrate and persist size
            Telos memory index(docs)
            Telos transactional_setSlot(Telos, "lastRagIndexSize", docs size asString)
            "ok"
        )
        query := method(q, k,
            if(q == nil, q = "")
            if(k == nil, k = 3)
            hits := Telos memory search(q, k)
            rec := Map clone
            rec atPut("tool", "rag.query")
            rec atPut("q", q)
            rec atPut("k", k)
            rec atPut("t", Date clone now asNumber)
            Telos logs append(Telos logs tools, Telos json stringify(rec))
            Telos transactional_setSlot(Telos, "lastRagQuery", q)
            hits
        )
    )


    // TelOS zygote state - immediately available (prototypal)
    world := nil
    morphs := List clone
    morphIndex := Map clone  
    isReplaying := false
    autoReplay := false
    verbose := false

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
        // Initialize C-side world, but keep an Io-level World as the UI root
        resend
        // Use the World prototype if available, otherwise fall back to Morph
        worldProto := Lobby getSlot("World")
        if(worldProto == nil, worldProto = Lobby getSlot("Morph"))
        self world := worldProto clone do(
            x := 0; y := 0; submorphs := List clone
        )
        writeln("Telos: Morphic World initialized - living canvas ready")
        // Auto-replay persistence if enabled (guard if slot missing)
        if(self hasSlot("autoReplay") and (self autoReplay == true), self replayWal)
        world
    )

    // Start the main event loop - the heart of the living interface
    mainLoop := method(
        if(world == nil, return "Telos: No world exists - call createWorld first")
        writeln("Telos: Starting Morphic main loop (direct manipulation active)")
        resend
        "Telos: Main loop completed"
    )

    // Create a new morph - a living visual object
    createMorph := method(morphTypeObj,
        // Support optional type parameter - morphTypeObj is a prototypal object
        typeResolver := Object clone
        typeResolver typeName := if(morphTypeObj == nil, "Morph", morphTypeObj asString)
        typeResolver proto := Lobby getSlot(typeResolver typeName) ifNil(Morph)
        proto := typeResolver proto
        
        // Create an Io-level morph and register in both Io and C worlds
        m := proto clone
        if(m hasSlot("submorphs") not, m submorphs := List clone)
        morphs append(m)
        // Append into C world so C draw loop can see it
        if(self hasSlot("addMorphToWorld"), self addMorphToWorld(m))
        // Index by id
        if(self hasSlot("morphIndex") not, self morphIndex := Map clone)
        self morphIndex atPut(m id asString, m)
        writeln("Telos: Living morph created and added to ecosystem")
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
        "Telos: Morph added to living hierarchy"
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
            if(handled == true, writeln("Telos: Io handled event ", event))
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
        if(Lobby hasSlot("Telos_rawLogAppend"),
            Telos_rawLogAppend("telos.wal", line),
            do(
                f := File with("telos.wal"); f openForAppending; f write(line .. "\n"); f close; "ok"
            )
        )
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
        if(path == nil, path = "telos.wal")
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

    // Single-line WAL marker
    mark := method(tag, info,
        if(tag == nil, tag = "mark")
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        walAppend("MARK " .. tag .. " " .. json stringify(info))
    )

    // === PROTOTYPAL PURITY VALIDATION ===
    validatePrototypalPurity := method(methodName, 
        writeln("[PROTOTYPAL CHECK] Method: ", methodName)
        writeln("[REMINDER] All parameters are objects. Access through message passing.")
        writeln("[REMINDER] Variables are slots. No class-like static references.")
        writeln("[REMINDER] Everything clones from prototypes, nothing initializes.")
        "prototypal_validation_complete"
    )
    
    // WAL rotation utility: if file exceeds maxBytes, rotate to .1 (single slot)
    rotateWal := method(path := "telos.wal", maxBytes := 1048576,
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
        if(path == nil, path = "telos.wal")
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

    // VSA-RAG Memory API (Phase 7) - stubbed now
    memory := Object clone do(
        // Minimal in-memory index for offline demos
        db := List clone
        addContext := method(item,
            // Store raw strings only; ignore non-strings for now
            if(item != nil,
                db append(item asString)
            )
            true
        )
        addConcept := method(concept,
            // Concepts may have 'summary' slot; index that
            if(concept and (concept hasSlot("summary")),
                db append(concept summary asString)
            )
            true
        )
        index := method(items,
            if(items == nil, return 0)
            // items: List of strings
            count := 0
            items foreach(it, db append(it asString); count = count + 1)
            count
        )
        search := method(query, k,
            if(k == nil, k = 5)
            // Rank by naive substring presence and length proximity
            scored := List clone
            db foreach(s,
                score := 0
                // presence boost
                if((s asLowercase) containsSeq(query asString asLowercase), score = score + 2)
                // smaller length diff yields slight bonus
                score = score + (1 / (1 + (s size - (query asString) size) abs))
                rec := Map clone
                rec atPut("text", s)
                rec atPut("score", score)
                scored append(rec)
            )
            // Select top-k by score (descending) - prototypal pattern
            res := List clone
            // Use k directly in the for loop to avoid scope issues
            for(i, 0, (k min(scored size)) - 1,
                bestIdx := nil; bestVal := -1
                scored foreach(j, m,
                    v := m at("score")
                    if(v > bestVal, bestVal = v; bestIdx = j)
                )
                if(bestIdx != nil,
                    res append(scored at(bestIdx)); scored removeAt(bestIdx)
                )
            )
            res map(m, m at("text"))
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
        streamingLlm := base .. "/streaming_llm.jsonl"
        tools := base .. "/tool_use.jsonl"
        curation := base .. "/curation_queue.jsonl"
        ui := base .. "/ui_snapshot.txt"
        append := method(path, line,
            if(Lobby hasSlot("Telos_rawLogAppend"),
                Telos_rawLogAppend(path, line),
                do(
                    // Fallback: ensure directory exists and append line
                    parts := path split("/")
                    if(parts size > 1,
                        do(
                            dir := parts exSlice(0, parts size - 1) join("/")
                            d := Directory with(dir)
                            if(d exists not, d create)
                        )
                    )
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
        
        streamingLlm := method(logObj,
            json := Telos json stringify(logObj)
            self append(streamingLlm, json)
        )
    )

    // Persona Consistency Scorer (offline heuristic)
    // Estimate alignment of output 'text' with a persona's ethos/speakStyle/routingHints.
    consistencyScoreFor := method(personaName, text,
        if(text == nil, return 0)
        if(personaName == nil, return 0.5)
        p := self personaCodex get(personaName)
        if(p == nil, return 0.5) // neutral if unknown persona
        // Build a simple bag of hint tokens from persona descriptors
        hints := List clone
        addHints := method(s,
            if(s != nil and s size > 0,
                parts := s asString asLowercase split(" ")
                parts foreach(w,
                    w2 := w strip
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

    // Prototypal streaming response object - yields chunks through message passing
    StreamingResponse := Object clone
    StreamingResponse with := method(provider, chunks,
        response := self clone
        response provider := provider
        response chunks := chunks clone
        response currentIndex := 0
        response isComplete := false
        response
    )
    StreamingResponse nextChunk := method(
        if(currentIndex >= chunks size,
            isComplete = true
            return nil
        )
        chunk := chunks at(currentIndex)
        currentIndex = currentIndex + 1
        chunk
    )
    StreamingResponse hasMore := method(isComplete not)
    StreamingResponse getAllChunks := method(chunks)
    StreamingResponse getFullText := method(chunks join(""))

    // LLM streaming call: yields partial responses through prototypal streaming object
    llmCallStream := method(spec,
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

        // Merge generation options
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
        chunks := List clone

        if(useOllama == true,
            optsJson := "{}"
            if(options size > 0,
                parts := List clone
                options foreach(k, v,
                    parts append("\"" .. k .. "\":" .. v asString)
                )
                optsJson = "{" .. parts join(",") .. "}"
            )
            if(Telos hasSlot("Telos_rawOllamaGenerateStream"),
                chunksResult := Telos_rawOllamaGenerateStream(baseUrl, model, prompt, system, optsJson)
                if(chunksResult type == "List",
                    chunks = chunksResult,
                    chunks append(chunksResult asString)
                )
            ,
                chunks append("[OLLAMA_STREAM_ERROR] bridge missing")
            )
        ,
            // Offline fallback with simulated streaming chunks
            chunks append("[OFFLINE")
            chunks append("_STUB")
            chunks append("_STREAMING")
            chunks append("_COMPLETION]")
        )

        response := StreamingResponse with("ollama", chunks)
        
        // Log streaming event to JSONL
        durationMs := (Date clone now asNumber - startedAt) * 1000
        logObj := Map clone
        logObj atPut("timestamp", Date clone now asString)
        logObj atPut("provider", if(useOllama, "ollama", "offline"))
        logObj atPut("model", model)
        logObj atPut("persona", personaName)
        logObj atPut("prompt", prompt exSlice(0, 200))
        logObj atPut("system", system exSlice(0, 100))
        logObj atPut("streaming", true)
        logObj atPut("chunkCount", chunks size)
        logObj atPut("fullText", response getFullText exSlice(0, 500))
        logObj atPut("durationMs", durationMs)
        
        logs streamingLlm(logObj)
        
        response
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
            // snapshots & WAL
            if(name == "snapshot", return Telos saveSnapshot(args atIfAbsent(0, nil)))
            if(name == "snapshot.json", return Telos saveSnapshotJson(args atIfAbsent(0, nil)))
            if(name == "export.json", return Telos saveWorldJson(args atIfAbsent(0, nil)))
            if(name == "import.json", return Telos loadWorldJson(args atIfAbsent(0, nil)))
            if(name == "replay", return Telos replayWal(args atIfAbsent(0, "telos.wal")))
            if(name == "rotateWal", return Telos rotateWal(args atIfAbsent(0, "telos.wal"), args atIfAbsent(1, 1048576)))
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
        list := method( list("snapshot", "snapshot.json", "export.json", "import.json", "replay", "rotateWal", "heartbeat", "newRect", "newText", "move", "resize", "color", "front", "toggleGrid") )
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
            if(Telos hasSlot("morphs") not, return 0)
            writeln("Telos: World heartbeat (morphs: ", Telos morphs size, ")")
            1
        )
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

// --- Fractal Reasoning Prototypes ---

// ContextFractal: atomic shard of context (text, data, signal)
ContextFractal := Object clone do(
    // Immediately available state (prototypal)
    id := System uniqueId
    payload := ""
    meta := Map clone

    // Fresh identity emerges through cloning
    clone := method(
        newContext := resend
        newContext id = System uniqueId
        newContext meta = Map clone
        newContext
    )

    with := method(text,
        f := self clone
        f id = System uniqueId  // Fresh identity on clone
        f payload = text
        f meta atPut("type", "text")
        f
    )
    vectorize := method(
        // stub: log and return a fake small vector
        writeln("[fractal] vectorize context: ", payload)
        list(0.1, 0.2, 0.3)
    )
)

// ConceptFractal: composition/binding of contexts and concepts (emergent structure)
ConceptFractal := Object clone do(
    // Immediately available state (prototypal)
    id := System uniqueId
    parts := List clone // mixture of ContextFractal/ConceptFractal
    summary := ""
    meta := Map clone

    // Fresh identity emerges through cloning
    clone := method(
        newConcept := resend
        newConcept id = System uniqueId
        newConcept parts = List clone
        newConcept meta = Map clone
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
    // Immediately available state (prototypal)
    name := "Unnamed"
    role := ""
    ethos := ""
    speakStyle := ""
    tools := List clone
    memoryTags := List clone
    contextKernel := ""
    weights := Map clone atPut("alpha", 1) atPut("beta", 1) atPut("gamma", 1) atPut("delta", 1)
    budget := Map clone // placeholders
    risk := "low"
    routingHints := ""
    genOptions := Map clone // default generation params per persona (temperature, top_p, etc.)

    with := method(spec,
        p := self clone
        // Fresh identity emerges through cloning - no init needed
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
    // Immediately available state (prototypal)
    registry := Map clone
    default := nil

    // Fresh identity emerges through cloning
    clone := method(
        newCodex := resend
        newCodex registry = Map clone
        newCodex default = nil
        newCodex
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
Morph := Object clone do(

    // Immediately available state (prototypal)
    id := System uniqueId
    x := 100
    y := 100
    width := 50
    height := 50
    color := list(1, 0, 0, 1)  // Red by default
    submorphs := List clone
    owner := nil
    dragging := false
    dragDX := 0
    dragDY := 0
    zIndex := 0
    persistedIdentity := false

    // Fresh identity emerges through cloning
    clone := method(
        newMorph := resend
        newMorph id = System uniqueId
        newMorph submorphs = List clone
        newMorph owner = nil
        newMorph dragging = false
        newMorph dragDX = 0
        newMorph dragDY = 0
        newMorph persistedIdentity = false
        newMorph
    )

    // Set the morph id (for persistence and lookup)
    setId := method(newId,
        self id = newId
        // Update morphIndex if available
        if(Telos hasSlot("morphIndex"), Telos morphIndex atPut(id asString, self))
        self
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

    // Add a submorph to this morph (alias for compatibility)
    addSubmorph := method(child,
        addMorph(child)
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
// Button morph - rectangle with label and action slot
ButtonMorph := RectangleMorph clone do(
    // Immediately available state (prototypal)  
    label := nil
    action := nil

    // Fresh identity emerges through cloning
    clone := method(
        newButton := resend
        // Create a fresh label and configure it properly
        newLabel := TextMorph clone
        newLabel moveTo(newButton x + 8, newButton y + 8)
        newLabel setText("Button")
        newButton label = newLabel
        newButton addMorph(newLabel)
        newButton action = nil
        // Default click handler
        newButton onClick = method(owner,
            if(owner action != nil, owner action call(owner))
        )
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

// Text morph - for displaying text
TextMorph := Morph clone do(
    // Immediately available state (prototypal)
    text := "Hello TelOS"
    fontSize := 12

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

// Text input morph - minimal placeholder for user input
TextInputMorph := TextMorph clone do(
    // Immediately available state (prototypal)
    inputBuffer := ""
    onSubmit := nil
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
    // Immediately available state (prototypal)
    isOpen := false
    title := "The Entropic Garden"
    width := 640
    height := 480
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
    // Immediately available state (prototypal)
    personaName := "ROBIN"
    history := List clone

    // Fresh identity emerges through cloning
    clone := method(
        newConsole := resend
        newConsole history = List clone
        newConsole
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

// ===== GENERATIVE KERNEL: Forward Protocol =====
// Transform missing messages into growth opportunities through adaptive behavior synthesis

Telos forward := method(
    // Capture the unknown message and arguments
    msg := call message
    args := call evalArgs
    selector := msg name
    
    self mark("telos.generative.invoke", Map clone atPut("selector", selector) atPut("args", args asString))
    
    // Log the synthesis attempt
    writeln("Telos: Generative synthesis of '" .. selector .. "' with args: " .. args asString)
    
    // Enhanced pattern recognition with context analysis
    context := self analyzeGenerativeContext(selector, args)
    
    // Try memory-based synthesis first (VSA-RAG integration)
    memoryResult := self synthesizeFromMemory(selector, args, context)
    if(memoryResult != nil, return memoryResult)
    
    // Pattern-based synthesis
    if(context at("category") == "creation",
        return self synthesizeCreation(selector, args, context)
    )
    
    if(context at("category") == "query",
        return self synthesizeQuery(selector, args, context)
    )
    
    if(context at("category") == "action",
        return self synthesizeAction(selector, args, context)
    )
    
    if(context at("category") == "morphic",
        return self synthesizeMorphic(selector, args, context)
    )
    
    if(context at("category") == "persistence",
        return self synthesizePersistence(selector, args, context)
    )
    
    // Enhanced placeholder with learning
    return self synthesizePlaceholder(selector, args, context)
)

// Enhanced context analysis for better synthesis decisions
Telos analyzeGenerativeContext := method(selector, args,
    context := Map clone
    
    // Pattern classification
    if(selector beginsWithSeq("create") or selector beginsWithSeq("new") or selector beginsWithSeq("make"),
        context atPut("category", "creation")
    ,
        if(selector containsSeq("find") or selector containsSeq("search") or selector containsSeq("get") or selector containsSeq("query"),
            context atPut("category", "query")
        ,
            if(selector endsWithSeq("Action") or selector containsSeq("do") or selector containsSeq("execute") or selector containsSeq("run"),
                context atPut("category", "action")
            ,
                if(selector containsSeq("morph") or selector containsSeq("Morph") or selector containsSeq("ui") or selector containsSeq("draw"),
                    context atPut("category", "morphic")
                ,
                    if(selector containsSeq("save") or selector containsSeq("load") or selector containsSeq("persist") or selector containsSeq("wal"),
                        context atPut("category", "persistence"),
                        context atPut("category", "unknown")
                    )
                )
            )
        )
    )
    
    // Intent analysis
    context atPut("intent", selector)
    context atPut("argCount", args size)
    context atPut("complexity", if(args size > 2, "high", if(args size > 0, "medium", "low")))
    
    context
)

// Memory-based synthesis using VSA-RAG substrate
Telos synthesizeFromMemory := method(selector, args, context,
    if(self memory == nil, return nil)
    
    // Query memory for similar patterns
    query := selector .. " " .. (args map(a, a asString) join(" "))
    hits := self memory search(query, 3)
    
    if(hits size > 0,
        // Learn from memory patterns but prefer actual synthesis
        pattern := hits at(0)
        writeln("Telos: Memory context found: '" .. pattern .. "' - applying contextual synthesis")
        
        // Use memory context to enhance synthesis but don't return memory object directly
        context atPut("memoryPattern", pattern)
        context atPut("memoryGuided", true)
    )
    
    // Always return nil to let specific synthesizers handle creation with memory context
    nil
)

Telos synthesizeCreation := method(selector, args, context,
    // Enhanced creation with context awareness
    if(selector == "createPersona" and args size > 0,
        // Create a persona using the existing prototype system
        personaSpec := Map clone
        personaSpec atPut("name", args at(0) ifNil("GeneratedPersona"))
        personaSpec atPut("role", args atIfAbsent(1, "Synthesized Agent"))
        personaSpec atPut("ethos", "adaptive, generative, prototypal")
        personaSpec atPut("speakStyle", "exploratory, creative")
        
        // If Persona prototype exists, use it; otherwise create a basic persona object
        if(Persona != nil,
            persona := Persona with(personaSpec)
        ,
            persona := Object clone
            persona name := personaSpec at("name")
            persona role := personaSpec at("role")
            persona ethos := personaSpec at("ethos")
            persona speakStyle := personaSpec at("speakStyle")
            persona describe := method("Persona: " .. name .. " (" .. role .. ")")
        )
        writeln("Telos: Synthesized persona '" .. persona name .. "'")
        return persona
    )
    
    if(selector containsSeq("Morph") or context at("category") == "morphic",
        // Enhanced morph creation with type inference - prototypal object approach
        typeAnalyzer := Object clone
        typeAnalyzer baseName := selector
        typeAnalyzer resolvedType := if(selector containsSeq("Rectangle"), "RectangleMorph",
                        if(selector containsSeq("Text"), "TextMorph",
                        if(selector containsSeq("Circle"), "CircleMorph", 
                        if(selector containsSeq("Button"), "ButtonMorph", selector))))
        
        newMorph := self createMorph(typeAnalyzer resolvedType)
        newMorph synthesizedType := typeAnalyzer resolvedType
        newMorph generationContext := context
        
        // Apply arguments if provided (position, size, etc.)
        if(args size >= 2,
            newMorph moveTo(args at(0) asNumber, args at(1) asNumber)
        )
        if(args size >= 4,
            newMorph resizeTo(args at(2) asNumber, args at(3) asNumber)
        )
        
        writeln("Telos: Synthesized " .. typeAnalyzer resolvedType .. " with context")
        return newMorph
    )
    
    // Handle specific positioned creation methods
    if(selector beginsWithSeq("create") and selector endsWithSeq("At"),
        // Extract morph type from method name - prototypal object approach  
        positionedTypeAnalyzer := Object clone
        positionedTypeAnalyzer defaultType := "RectangleMorph"
        positionedTypeAnalyzer resolvedType := if(selector containsSeq("Rectangle"), "RectangleMorph",
                                if(selector containsSeq("Text"), "TextMorph", 
                                if(selector containsSeq("Circle"), "CircleMorph",
                                if(selector containsSeq("Button"), "ButtonMorph", positionedTypeAnalyzer defaultType))))
        
        newMorph := self createMorph(positionedTypeAnalyzer resolvedType)
        newMorph synthesizedType := positionedTypeAnalyzer resolvedType
        newMorph generationContext := context
        
        // Apply position and size from arguments
        if(args size >= 2,
            newMorph moveTo(args at(0) asNumber, args at(1) asNumber)
        )
        if(args size >= 4,
            newMorph resizeTo(args at(2) asNumber, args at(3) asNumber)
        )
        
        writeln("Telos: Synthesized positioned " .. positionedTypeAnalyzer resolvedType)
        return newMorph
    )
    
    if(selector containsSeq("Fractal"),
        // Create context or concept fractals
        if(selector containsSeq("Context"),
            fractal := ContextFractal with(args atIfAbsent(0, "synthesized context"))
            writeln("Telos: Synthesized ContextFractal")
            return fractal
        )
        if(selector containsSeq("Concept"),
            fractal := ConceptFractal clone
            writeln("Telos: Synthesized ConceptFractal")
            return fractal
        )
    )
    
    // Default enhanced creation
    created := Object clone
    created synthesizedFrom := selector
    created generationContext := context
    created args := args
    created timestamp := Date clone now asNumber
    
    // Add basic behavior based on intent
    created describe := method("Synthesized object: " .. synthesizedFrom .. " with " .. args size .. " args")
    
    writeln("Telos: Synthesized object from '" .. selector .. "' with enhanced context")
    return created
)

Telos synthesizeQuery := method(selector, args, context,
    // Enhanced query synthesis with pattern matching
    
    // Morphic queries
    if(selector containsSeq("morph") or selector containsSeq("Morph"),
        if(selector containsSeq("At") and args size >= 2,
            // Query morphs at position
            return self morphsAt(args at(0) asNumber, args at(1) asNumber)
        )
        if(selector containsSeq("ByType") and args size > 0,
            // Query morphs by type
            typeName := args at(0)
            return self morphs select(m, m type == typeName)
        )
        if(selector containsSeq("ByColor"),
            // Query morphs by color similarity
            return self morphs select(m, m hasSlot("color"))
        )
        return self morphs // All morphs
    )
    
    // Memory queries
    if(selector containsSeq("memory") or selector containsSeq("Memory"),
        if(args size > 0,
            query := args at(0)
            k := args atIfAbsent(1, 5)
            return self memory search(query, k)
        )
        return self memory db // All memory
    )
    
    // Persona queries
    if(selector containsSeq("persona") or selector containsSeq("Persona"),
        if(args size > 0,
            name := args at(0)
            return self personaCodex get(name)
        )
        return self personaCodex registry values
    )
    
    // WAL/persistence queries  
    if(selector containsSeq("wal") or selector containsSeq("WAL"),
        if(selector containsSeq("Frames"),
            return self walListCompleteFrames
        )
        // Return WAL tail
        return self logs tail("telos.wal", args atIfAbsent(0, 10))
    )
    
    // Fractal queries
    if(selector containsSeq("fractal") or selector containsSeq("Fractal"),
        // Could integrate with concept/context search here
        writeln("Telos: Fractal query synthesis - integrate with VSA-RAG")
        return List clone
    )
    
    // Default enhanced query
    writeln("Telos: Synthesized query '" .. selector .. "' - returning structured result")
    result := Map clone
    result atPut("query", selector)
    result atPut("args", args)
    result atPut("timestamp", Date clone now asNumber)
    result atPut("results", List clone)
    return result
)

Telos synthesizeAction := method(selector, args, context,
    // Enhanced action synthesis with context and memory
    
    // Animation actions
    if(selector containsSeq("animate") or selector containsSeq("move"),
        if(self world != nil and self world hasSlot("submorphs"),
            dx := args atIfAbsent(0, 10) asNumber
            dy := args atIfAbsent(1, 5) asNumber
            count := 0
            self world submorphs foreach(morph,
                if(morph hasSlot("moveTo"),
                    morph moveTo(morph x + dx, morph y + dy)
                    count = count + 1
                )
            )
            writeln("Telos: Synthesized animation - moved " .. count .. " morphs")
            return "Animation applied to " .. count .. " morphs"
        )
    )
    
    // Cleanup actions
    if(selector containsSeq("reset") or selector containsSeq("clear") or selector containsSeq("clean"),
        if(selector containsSeq("world") or selector containsSeq("World"),
            if(self world != nil,
                count := self world submorphs size
                self world submorphs := List clone
                writeln("Telos: Synthesized world reset - cleared " .. count .. " morphs")
                return "World reset: " .. count .. " morphs cleared"
            )
        )
        if(selector containsSeq("memory") or selector containsSeq("Memory"),
            if(self memory != nil,
                self memory db := List clone
                writeln("Telos: Synthesized memory reset")
                return "Memory cleared"
            )
        )
        if(selector containsSeq("wal") or selector containsSeq("WAL"),
            File with("telos.wal") setContents("")
            writeln("Telos: Synthesized WAL reset")
            return "WAL cleared"
        )
    )
    
    // Layout actions
    if(selector containsSeq("layout") or selector containsSeq("organize") or selector containsSeq("arrange"),
        if(self world != nil and self world hasSlot("submorphs") and self world submorphs size > 0,
            layout := if(selector containsSeq("Row"), RowLayout clone, ColumnLayout clone)
            if(args size > 0, layout spacing = args at(0) asNumber)
            count := layout apply(self world)
            writeln("Telos: Synthesized layout action - organized " .. count .. " morphs")
            return "Layout applied: " .. count .. " morphs organized"
        )
    )
    
    // Persistence actions
    if(selector containsSeq("save") or selector containsSeq("snapshot"),
        if(selector containsSeq("world") or selector containsSeq("World"),
            path := self saveWorldJson
            writeln("Telos: Synthesized world save to " .. path)
            return "World saved to " .. path
        )
        if(selector containsSeq("memory") or selector containsSeq("Memory"),
            // Could implement memory snapshot here
            writeln("Telos: Synthesized memory save")
            return "Memory snapshot saved"
        )
    )
    
    // Persona actions  
    if(selector containsSeq("persona") or selector containsSeq("Persona"),
        if(selector containsSeq("switch") or selector containsSeq("activate"),
            personaName := args atIfAbsent(0, "ROBIN")
            persona := self personaCodex get(personaName)
            if(persona != nil,
                writeln("Telos: Synthesized persona switch to " .. personaName)
                return "Activated persona: " .. personaName
            )
        )
    )
    
    // Default enhanced action
    writeln("Telos: Synthesized action '" .. selector .. "' with context")
    result := Map clone
    result atPut("action", selector)
    result atPut("status", "completed")
    result atPut("context", context)
    result atPut("timestamp", Date clone now asNumber)
    return result
)

// Morphic-specific synthesis
Telos synthesizeMorphic := method(selector, args, context,
    writeln("Telos: Morphic synthesis for '" .. selector .. "'")
    
    // Drawing and rendering
    if(selector containsSeq("draw") or selector containsSeq("render"),
        if(self world != nil,
            self world draw
            return "Morphic drawing completed"
        )
    )
    
    // UI event synthesis
    if(selector containsSeq("click") or selector containsSeq("tap"),
        if(args size >= 2,
            self click(args at(0) asNumber, args at(1) asNumber)
            return "Click synthesized at (" .. args at(0) .. "," .. args at(1) .. ")"
        )
    )
    
    // Canvas operations
    if(selector containsSeq("canvas") or selector containsSeq("Canvas"),
        if(selector containsSeq("open"),
            cv := Canvas clone
            cv open
            return cv
        )
        if(selector containsSeq("heartbeat"),
            beats := args atIfAbsent(0, 5) asNumber
            return self ui heartbeat(beats)
        )
    )
    
    // Default morphic response
    return "Morphic operation: " .. selector
)

// Persistence-specific synthesis  
Telos synthesizePersistence := method(selector, args, context,
    writeln("Telos: Persistence synthesis for '" .. selector .. "'")
    
    // WAL operations
    if(selector containsSeq("wal") or selector containsSeq("WAL"),
        if(selector containsSeq("commit"),
            tag := args atIfAbsent(0, "synthesized")
            info := Map clone atPut("generated", true)
            self walCommit(tag, info, nil)
            return "WAL commit: " .. tag
        )
        if(selector containsSeq("replay"),
            result := self replayWal
            return "WAL replay: " .. result
        )
    )
    
    // Snapshot operations
    if(selector containsSeq("snapshot"),
        path := self saveSnapshot
        return "Snapshot saved: " .. path
    )
    
    // Backup operations
    if(selector containsSeq("backup"),
        // Could implement backup synthesis here
        return "Backup operation synthesized"
    )
    
    // Default persistence response
    return "Persistence operation: " .. selector
)

Telos synthesizePlaceholder := method(selector, args, context,
    // Enhanced placeholder with learning capability
    
    // Create a dynamic method that learns from usage
    methodBody := """method(
        writeln("Telos: Dynamic method '""" .. selector .. """' called with args: " .. call evalArgs asString)
        
        // Log usage for learning
        usage := Map clone
        usage atPut("selector", """" .. selector .. """")
        usage atPut("args", call evalArgs)
        usage atPut("timestamp", Date clone now asNumber)
        
        // Store in learning context
        if(Telos hasSlot("learningContext") not, Telos learningContext := List clone)
        Telos learningContext append(usage)
        
        return "Dynamic response from """ .. selector .. """" 
    )"""
    
    // Store the synthesized method for future use
    if(self hasSlot("synthesizedMethods") not, self synthesizedMethods := Map clone)
    self synthesizedMethods atPut(selector, methodBody)
    
    // Add to memory for future pattern matching
    if(self memory != nil,
        contextStr := "synthesized method: " .. selector .. " with " .. args size .. " args"
        self memory addContext(contextStr)
    )
    
    writeln("Telos: Synthesized learning placeholder '" .. selector .. "'")
    
    result := Object clone
    result selector := selector
    result isPlaceholder := true
    result context := context
    result usage := method("Placeholder method: " .. selector)
    
    return result
)

// Add forward protocol to Morph hierarchy
Morph forward := method(
    msg := call message
    args := call evalArgs  
    selector := msg name
    
    writeln("Morph#" .. id .. ": Generative synthesis of '" .. selector .. "'")
    
    // Morph-specific synthesis patterns
    if(selector beginsWithSeq("become"),
        // Transform this morph into something else
        newType := selector afterSeq("become") ifNil("Unknown")
        self synthesizedType := newType
        writeln("Morph#" .. id .. ": Became " .. newType)
        return self
    )
    
    if(selector beginsWithSeq("grow") or selector beginsWithSeq("expand"),
        // Growth behavior
        self width = self width * 1.2
        self height = self height * 1.2
        writeln("Morph#" .. id .. ": Grew larger")
        return self
    )
    
    if(selector beginsWithSeq("shrink") or selector beginsWithSeq("contract"),
        // Shrinkage behavior
        self width = self width * 0.8
        self height = self height * 0.8
        writeln("Morph#" .. id .. ": Shrank smaller")
        return self
    )
    
    // Default: delegate to Telos for system-wide synthesis
    return Telos forward
)

// World prototype - the root container for all morphic elements
World := Morph clone
World width := 800
World height := 600
World backgroundColor := list(0.9, 0.9, 0.9, 1)

World draw := method(
    writeln("World (" .. width .. "x" .. height .. ") background=" .. backgroundColor asString)
    if(hasSlot("submorphs"),
        submorphs foreach(morph, morph draw)
    )
)

// Enhanced World forward protocol for better synthesis
World forward := method(
    msg := call message
    args := call evalArgs
    selector := msg name
    
    writeln("World: Generative synthesis of '" .. selector .. "'")
    
    // World-specific synthesis patterns
    if(selector containsSeq("clear") or selector containsSeq("reset"),
        self submorphs := List clone
        writeln("World: Cleared all morphs")
        return self
    )
    
    if(selector containsSeq("organize") or selector containsSeq("layout"),
        // Simple grid layout
        if(hasSlot("submorphs") and submorphs size > 0,
            cols := (submorphs size sqrt) ceil
            rows := (submorphs size / cols) ceil
            cellWidth := width / cols
            cellHeight := height / rows
            
            submorphs foreach(i, morph,
                col := i % cols
                row := (i / cols) floor
                morph moveTo(col * cellWidth + 20, row * cellHeight + 20)
            )
            writeln("World: Organized " .. submorphs size .. " morphs in grid")
        )
        return self
    )
    
    // Enhanced spawn synthesis
    if(selector containsSeq("spawn") or selector containsSeq("populate"),
        // Create multiple morphs
        count := args at(0) ifNil(3)
        if(count type != "Number", count = 3)
        
        count repeat(
            rnd := Random value
            morph := Telos createMorph("RectangleMorph")
            morph moveTo((rnd * 300) + 50, (rnd * 200) + 50)
            morph setColor(rnd, (1 - rnd), 0.5, 1)
            self addSubmorph(morph)
        )
        writeln("World: Spawned " .. count .. " morphs via synthesis")
        return self
    )
    
    // Default: delegate to Telos
    return Telos forward
)

// Telos zygote is ready - all slots immediately available through prototypal inheritance