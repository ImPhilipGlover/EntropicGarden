// Telos logs tail demo
Telos do(
    println("-- logs_tail_demo --")
    loadConfig(list(Map clone atPut("type","TextMorph") atPut("x",10) atPut("y",10) atPut("id","t") atPut("text","hello")))
    saveSnapshot
    lines := logs tail(logs ui, 5)
    println("tail lines: " .. lines size)
    lines foreach(l, println(l))
    println("-- end --")
)
