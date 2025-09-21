// Minimal test to isolate syntax error

ColorParser := Object clone do(
    parseColor := method(colorValue,
        colorObject := Object clone
        colorObject components := List clone
        colorObject components := if(colorValue type == "List",
            colorValue,
            if(colorValue type == "Sequence",
                colorString := Object clone
                colorString raw := colorValue asString strip
                colorString bracketContent := colorString raw afterSeq("[") beforeSeq("]")
                colorString parts := colorString bracketContent split(",")
                
                colorComponents := List clone
                colorComponents append(colorString parts atIfAbsent(0, "0") asNumber)
                colorComponents append(colorString parts atIfAbsent(1, "0") asNumber)
                colorComponents append(colorString parts atIfAbsent(2, "0") asNumber)
                colorComponents append(if(colorString parts size > 3, colorString parts at(3) asNumber, 1))
                colorComponents
                ,
                list(1,0,0,1)
            )
        )
        colorObject
    )
)

// ContextFractal test
ContextFractal := Object clone do(
    id := System uniqueId
    payload := ""
    meta := Map clone
    
    clone := method(
        newSelf := resend
        newSelf id := System uniqueId
        newSelf meta := Map clone
        newSelf
    )
    
    with := method(textContent,
        newInstance := self clone
        newInstance payload := textContent
        newInstance meta atPut("type", "text")
        newInstance
    )
    
    vectorize := method(
        writeln("[fractal] vectorize context: ", payload)
        components := list(0.1, 0.2, 0.3)
        components
    )
)

writeln("Syntax test complete")