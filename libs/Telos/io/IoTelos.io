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
            Telos logs append(Telos logs tools, Telos json stringify(map(tool: "rag.query", q: q, k: k, t: Date clone now asNumber)))
            Telos transactional_setSlot(Telos, "lastRagQuery", q)
            hits
        )
    )


    // Initialize the TelOS zygote - the computational embryo
    init := method(
        self world := nil
        self morphs := List clone
        self morphIndex := Map clone
        self isReplaying := false
    self autoReplay := false
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
        // Forward to C's handleEvent for logging/stub
        getSlot("handleEvent") call(event)
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

    // Single-line WAL marker
    mark := method(tag, info,
        if(tag == nil, tag = "mark")
        if(info == nil, info = Map clone)
        info atPut("t", Date clone now asNumber)
        walAppend("MARK " .. tag .. " " .. json stringify(info))
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
        // Read WAL and apply SET lines: SET <id>.<slot> TO <value>
        content := (File with(path)) contents
        if(content == nil, return "[empty-wal]")
        lines := content split("\n")
        lines foreach(line,
            if(line beginsWithSeq("SET "),
                rest := line exSlice(4) // after 'SET '
                parts := rest split(" TO ")
                if(parts size == 2,
                    lhs := parts at(0)
                    rhs := parts at(1)
                    lhsParts := lhs split(".")
                    if(lhsParts size >= 2,
                        mid := lhsParts at(0)
                        slot := lhsParts at(1)
                        m := index at(mid)
                        // Create missing morphs if type specified earlier or if we're setting type now
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
                            // m is nil; maybe this line declares type, or we need to create now
                            if(slot == "type",
                                // rhs is a type name, create morph and index it
                                tname := rhs strip
                                proto := Lobby getSlot(tname) ifNil(Lobby getSlot("Morph"))
                                nm := proto clone
                                nm setSlot("id", mid)
                                // Attach without C stub
                                nm owner = world
                                world submorphs append(nm)
                                index atPut(mid, nm)
                            )
                        )
                    )
                )
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
        search := method(query, k := 5,
            // Rank by naive substring presence and length proximity
            q := query asString asLowercase
            scored := List clone
            db foreach(s,
                t := s asLowercase
                score := 0
                if(t containsSeq(q), score = score + 2)
                // smaller length diff yields slight bonus
                score = score + (1 / (1 + (s size - q size) abs))
                scored append(map(text: s, score: score))
            )
            // Sort descending by score
            // Io List sortInPlace by comparator not in base; do simple selection of top-k
            res := List clone
            k := k min(scored size)
            k repeat(i,
                bestIdx := nil; bestVal := -1
                scored foreachIndex(j, m,
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
            env := map(kind: entryMap atIfAbsent("kind", "llm"),
                       key: entryMap atIfAbsent("key", System uniqueId),
                       path: entryMap atIfAbsent("path", Telos logs llm),
                       record: entryMap atIfAbsent("record", entryMap))
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

    // Offline-only LLM call stub (no network). Logs and enqueues records.
    llmCall := method(spec,
        if(spec == nil, spec = Map clone)
        personaName := spec atIfAbsent("persona", nil)
        model := spec atIfAbsent("model", "offline")
        prompt := spec atIfAbsent("prompt", "")
        system := spec atIfAbsent("system", "")
        // Merge generation options: use only per-call overrides safely
        options := Map clone
        if(spec hasSlot("temperature"), options atPut("temperature", spec at("temperature")))
        if(spec hasSlot("top_p"), options atPut("top_p", spec at("top_p")))
        startedAt := Date clone now asNumber
        out := "[OFFLINE_STUB_COMPLETION]"
        endedAt := Date clone now asNumber
        score := consistencyScoreFor(personaName, out)
        entry := map(
            t: endedAt,
            persona: personaName ifNil(""),
            provider: "offline",
            model: model ifNil(""),
            prompt: prompt,
            system: system,
            options: options,
            duration_ms: ((endedAt - startedAt) * 1000) floor,
            output: out,
            consistencyScore: score
        )
        Telos logs append(Telos logs llm, Telos json stringify(entry))
        curator enqueue(map(kind: "llm", key: (personaName ifNil("")) .. ":offline:" .. System uniqueId, path: Telos logs llm, record: entry))
        out
    )

    toolUse := method(toolSpec,
        writeln("[tools] offline stub: ", toolSpec)
        // echo back a dummy result
        res := map(result: "OK", tool: toolSpec)
        // Log tool use for future curation
        entry := map(t: Date clone now asNumber, tool: toolSpec, result: res)
        Telos logs append(Telos logs tools, Telos json stringify(entry))
        curator enqueue(map(kind: "tool", key: "tool:" .. System uniqueId, path: Telos logs tools, record: entry))
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
        map(S: S, C: C, I: I, R: R, G_hat: G, alpha: alpha, beta: beta, gamma: gamma, delta: delta)
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
    init := method(
        self id := System uniqueId
        self payload := ""
        self meta := Map clone
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

// ConceptFractal: composition/binding of contexts and concepts (emergent structure)
ConceptFractal := Object clone do(
    init := method(
        self id := System uniqueId
        self parts := List clone // mixture of ContextFractal/ConceptFractal
        self summary := ""
        self meta := Map clone
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
        res := Telos llmCall(map(prompt: "Summarize: " .. txt, provider: "offline"))
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
        Telos llmCall(map(prompt: full, persona: name))
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
        Telos llmCall(map(prompt: review, persona: name))
    )

    // Contract checking stub
    checkContracts := method(artifact,
        // offline: return a structured OK result
        map(status: "OK", notes: "Contracts respected (stub)", artifact: artifact)
    )

    // Load persona-specific context from codex (stubbed)
    loadPersonaContext := method(
        passages := Telos codex getPassages(name)
        self contextKernel := passages join("\n")
        self
    )

    // Compose a system prompt from kernel + vows
    composeSystemPrompt := method(
        kernel := contextKernel ifNil("")
        "You are " .. name .. " (" .. role .. ").\n" ..
        "Ethos: " .. ethos .. "\n" ..
        "Style: " .. speakStyle .. "\n" ..
        "Guidance:\n" .. kernel
    )

    // Converse with user using persona system prompt
    converse := method(userMsg, history := List clone,
        sys := composeSystemPrompt
        Telos llmCall(map(system: sys, prompt: userMsg, history: history, persona: name))
    )

    // ROBIN-specific: analyze UI and propose changes
    proposeUiChanges := method(goalText,
        snapshot := Telos captureScreenshot
        prompt := "Given this UI snapshot, propose morph changes: \n" .. snapshot .. "\nGoal: " .. goalText
        Telos llmCall(map(prompt: prompt, persona: name, model: "telos/robin"))
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
Telos personaCodex register(Persona with(map(
    name: "BRICK",
    role: "The Architect",
    ethos: "autopoiesis, prototypal purity, watercourse way, antifragility",
    speakStyle: "precise, concise, reflective",
    tools: list("summarizer", "diff", "planner"),
    memoryTags: list("architecture", "invariants", "roadmap"),
    weights: map(alpha: 1.25, beta: 0.8, gamma: 1.0, delta: 0.6),
    budget: map(mode: "offline"),
    risk: "low-moderate",
    routingHints: "design, refactors, codex",
    genOptions: map(temperature: 0.4, top_p: 0.9, top_k: 40, repeat_penalty: 1.1)
)))

Telos personaCodex register(Persona with(map(
    name: "ROBIN",
    role: "The Gardener",
    ethos: "direct manipulation, clarity, liveliness",
    speakStyle: "visual-first, concrete",
    tools: list("draw", "layout"),
    memoryTags: list("ui", "morphic", "canvas"),
    weights: map(alpha: 1.0, beta: 0.7, gamma: 0.85, delta: 0.7),
    budget: map(mode: "offline"),
    risk: "low",
    routingHints: "ui, demos",
    genOptions: map(temperature: 0.7, top_p: 0.95, top_k: 50, repeat_penalty: 1.05)
)))

Telos personaCodex register(Persona with(map(
    name: "BABS",
    role: "The Archivist-Researcher",
    ethos: "single source of truth; disciplined inquiry; bridge known↔unknown",
    speakStyle: "methodical, inquisitive",
    tools: list("wal.write", "wal.replay", "research.prompt", "ingest.report"),
    memoryTags: list("persistence", "recovery", "provenance", "research", "gaps"),
    weights: map(alpha: 0.9, beta: 0.6, gamma: 1.2, delta: 1.0),
    budget: map(mode: "offline"),
    risk: "low",
    routingHints: "durability, recovery, research triage",
    genOptions: map(temperature: 0.3, top_p: 0.85, top_k: 40, repeat_penalty: 1.15)
)))

Telos personaCodex register(Persona with(map(
    name: "ALFRED",
    role: "The Butler of Contracts",
    ethos: "alignment, consent, clarity; steward of invariants and budgets",
    speakStyle: "courteous, surgical, meta-aware",
    tools: list("contract.check", "policy.inspect", "summarizer"),
    memoryTags: list("contracts", "policies", "alignment"),
    weights: map(alpha: 0.95, beta: 0.7, gamma: 1.2, delta: 1.1),
    budget: map(mode: "offline"),
    risk: "low",
    routingHints: "contract checks, risk analysis, meta-commentary",
    genOptions: map(temperature: 0.2, top_p: 0.8, top_k: 40, repeat_penalty: 1.2)
)))


// Morph prototype - the fundamental living interface object
Morph := Object clone do(

    // Initialize a morph with living properties
    init := method(
        self id := System uniqueId
        self x := 100
        self y := 100
        self width := 50
        self height := 50
        self color := list(1, 0, 0, 1)  // Red by default
        self submorphs := List clone
        self owner := nil
        self dragging := false
        self dragDX := 0
        self dragDY := 0
        self zIndex := 0
        self persistedIdentity := false
    )

    // Ensure each clone has fresh identity and defaults
    clone := method(
        o := resend
        // Assign a fresh id and initialize defaults on the clone
        o id := System uniqueId
        o init
        o
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
// Button morph - rectangle with label and action slot
ButtonMorph := RectangleMorph clone do(
    init := method(
        resend
        self label := TextMorph clone
        label moveTo(x + 8, y + 8)
        label setText("Button")
        self addMorph(label)
        self action := nil
        // Default click handler
        self onClick := method(owner,
            if(owner action != nil, owner action call(owner))
        )
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
    init := method(
        resend
        self text := "Hello TelOS"
        self fontSize := 12
    )

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
    init := method(
        resend
        self inputBuffer := ""
        self onSubmit := nil
    )
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

// Initialize Telos zygote to define base slots (world, morphs, flags)
Telos init