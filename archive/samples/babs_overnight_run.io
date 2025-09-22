// BABS Overnight Run: Ingest BAT OS archives then run exploratory queries
// Usage (WSL): nohup ./build/_build/binaries/io /mnt/c/EntropicGarden/samples/telos/babs_overnight_run.io > /mnt/c/EntropicGarden/logs/babs/overnight.out 2>&1 &

logDir := "logs/babs"
Directory with(logDir) create

// Phase 1: Ingest
writeln("[BABS] Overnight: starting ingestion...")
doFile("samples/telos/babs_ingest_batos.io")
writeln("[BABS] Overnight: ingestion finished.")

// Phase 2: Queries
queries := list(
    "watercourse way prototypal purity",
    "antifragile healing WAL replay",
    "Morphic direct manipulation canvas",
    "society of minds personas BRICK ROBIN BABS ALFRED"
)

qlog := File with(logDir .. "/queries.out")
qlog openForAppending
queries foreach(q,
    qlog write("\n[BABS] ---- Query: " .. q .. "\n")
    // run query script in the same VM
    System setArgs(list(q))
    doFile("samples/telos/babs_query_batos.io")
)
qlog close

writeln("[BABS] Overnight: queries finished. See logs under ", logDir)
