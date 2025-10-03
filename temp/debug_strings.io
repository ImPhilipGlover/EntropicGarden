content := "writeln(\"unterminated string"
("Content: '" .. content .. "'") println
("Length: " .. content size) println

i := 0
inString := false
stringStart := 0

while(i < content size,
    char := content at(i)
    charStr := char asCharacter
    ("i=" .. i .. " char='" .. charStr .. "' (" .. char .. ") inString=" .. inString) println

    if(inString not,
        if(char == 34,  // ASCII for "
            ("Found string start at " .. i) println
            inString := true
            stringStart := i
        )
    ,
        if(char == 34,  // ASCII for "
            ("Found string end at " .. i) println
            inString := false
        ,
            if(char == 10,  // ASCII for \n
                ("Found newline in string at " .. i) println
                "ERROR: Unterminated string" println
                inString := false
            )
        )
    )

    i := i + 1
)

("Final inString: " .. inString) println
if(inString, "ERROR: Unterminated string at end" println)