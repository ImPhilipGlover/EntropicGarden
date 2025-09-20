// Telos clipboard copy/paste demo
Telos do(
    println("-- clipboard_demo --")
    loadConfig(list(
        Map clone atPut("type","RectangleMorph") atPut("x",30) atPut("y",30) atPut("width",80) atPut("height",50) atPut("id","a"),
        Map clone atPut("type","RectangleMorph") atPut("x",140) atPut("y",60) atPut("width",60) atPut("height",60) atPut("id","b")
    ))
    // Select both by coordinates
    selectAt(35, 35); selectAt(145, 65)
    println("selected count: " .. selection size)
    copySelection
    mark("clipboard", Map clone atPut("count", selection size))
    // Paste at a new location
    pasted := pasteAt(220, 120)
    println("pasted: " .. pasted)
    saveSnapshot
    println("-- end --")
)
