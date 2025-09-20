// BABS Ingestion: Index BAT OS Development archives into Context/Concept Fractals
// Usage (WSL): ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/babs_ingest_batos.io

root := "/mnt/c/EntropicGarden/TelOS-Python-Archive/BAT OS Development"
outDir := "logs/babs"
contextsPath := outDir .. "/contexts.jsonl"
conceptsPath := outDir .. "/concepts.jsonl"

// Ensure logs directory exists
dir := Directory with(outDir)
if(dir exists not, dir create)

writeln("[BABS] Ingest from: ", root)
Telos createWorld
// Progress log (avoid stdout buffering under nohup)
Telos logs append("logs/babs/run.log", "[BABS] start " .. Date clone now asString)

// Helpers
isTextFile := method(path,
    low := path asLowercase
    (low endsWithSeq(".md") or low endsWithSeq(".txt") or low endsWithSeq(".io") or low endsWithSeq(".py"))
)

// Bounded DFS to avoid long initial scans; returns up to 'cap' files
listLimitedFiles := method(path, cap,
    out := List clone
    walk := method(dirPath,
        if(out size >= cap, return)
        d := Directory with(dirPath)
        if(d exists not, return)
        // Files at this level
        d files foreach(fileObj,
            if(out size >= cap, return)
            p := fileObj path
            if(isTextFile(p), out append(p))
        )
        // Recurse into subdirectories
        d directories foreach(sub,
            if(out size >= cap, return)
            if(sub name == "." or sub name == "..", continue)
            walk(sub path)
        )
    )
    walk(path)
    out
)

chunkParagraphs := method(text, targetChars,
    if(targetChars isNil, targetChars = 900)
    paras := text split("\n\n")
    out := List clone
    acc := ""
    paras foreach(p,
        blk := (p asString) asMutable strip
        if(blk size == 0, continue)
        if(acc size + blk size + 2 > targetChars,
            out append(acc)
            acc = blk
        ,
            if(acc size == 0, acc = blk, acc = acc .. "\n\n" .. blk)
        )
    )
    if(acc size > 0, out append(acc))
    out
)

appendJsonl := method(path, map,
    Telos logs append(path, Telos json stringify(map))
)

ingestFile := method(path, maxChunks,
    if(maxChunks isNil, maxChunks = 50)
    fileRef := File with(path)
    if(fileRef exists not, return 0)
    txt := fileRef contents
    if(txt == nil, return 0)
    chunks := chunkParagraphs(txt, 900)
    count := 0
    tag := "ingest:" .. path
    Telos walCommit(tag, Map clone, block(
        i := 0
        while(i < chunks size and i < maxChunks,
            ctext := chunks at(i)
            // Create ContextFractal and vectorize (stub)
            cf := ContextFractal with(ctext)
            _ := cf vectorize
            // Persist context record
            rec := Map clone
            rec atPut("path", path)
            rec atPut("chunk", i)
            rec atPut("len", ctext size)
            rec atPut("text", ctext)
            appendJsonl(contextsPath, rec)
            // Add to memory index (stub memory)
            Telos memory addContext(ctext)
            count = count + 1
            i = i + 1
        )
        // Build a coarse summary from the first few chunks (naive)
        if(chunks size > 0,
            j := 0
            maxParts := (chunks size min(8))
            accSummary := ""
            while(j < maxParts,
                part := (chunks at(j)) asString
                // Keep summary bounded
                if(accSummary size + part size + 2 > 1600,
                    break
                ,
                    if(accSummary size == 0, accSummary = part, accSummary = accSummary .. "\n\n" .. part)
                )
                j = j + 1
            )
            summary := accSummary
            crec := Map clone
            crec atPut("path", path)
            crec atPut("parts", maxParts)
            crec atPut("summary", summary)
            appendJsonl(conceptsPath, crec)
        )
    ))
    count
)

maxFiles := 5 // keep small for smoke test; raise for overnight
files := listLimitedFiles(root, maxFiles)
writeln("[BABS] Files selected (capped): ", files size)
Telos logs append("logs/babs/run.log", "[BABS] files=" .. files size asString)
maxChunks := 10 // per file cap during smoke; raise for overnight

total := 0
files foreach(p,
    Telos logs append("logs/babs/run.log", "[BABS] ingest:" .. p)
    n := ingestFile(p, maxChunks)
    writeln("[BABS] ", p, " -> ", n, " chunks")
    Telos logs append("logs/babs/run.log", "[BABS] done:" .. p .. " chunks=" .. n asString)
    total = total + n
)

writeln("[BABS] Ingest complete. Contexts added: ", total)
Telos saveSnapshot(outDir .. "/ui_snapshot.txt")
// Persist memory index to default path (logs/fractals/memory.jsonl)
_ := Telos memory save(nil)
Telos logs append("logs/babs/run.log", "[BABS] complete total=" .. total asString)
