#!/usr/local/bin/io

// Simple Io Syntax Checker - Minimal working version

IoSyntaxChecker := Object clone do(

    validateFile := method(filePath,
        if(File exists(filePath) not,
            return list("ERROR: File does not exist: " .. filePath)
        )
        content := File clone openForReading(filePath) readToEnd
        validateString(content, filePath)
    )

    validateString := method(content, fileName,
        errors := list()
        errors appendSeq(checkBrackets(content))
        if(errors size == 0,
            list("✓ Syntax OK")
        ,
            errors
        )
    )

    checkBrackets := method(content,
        errors := list()
        parens := 0
        braces := 0
        brackets := 0

        i := 0
        while(i < content size,
            char := content at(i)
            if(char == "(", parens := parens + 1)
            if(char == ")", parens := parens - 1)
            if(char == "{", braces := braces + 1)
            if(char == "}", braces := braces - 1)
            if(char == "[", brackets := brackets + 1)
            if(char == "]", brackets := brackets - 1)
            i := i + 1
        )

        if(parens != 0, errors append("Unbalanced parentheses"))
        if(braces != 0, errors append("Unbalanced braces"))
        if(brackets != 0, errors append("Unbalanced brackets"))

        errors
    )
)

checkFile := method(filePath,
    checker := IoSyntaxChecker clone
    result := checker validateFile(filePath)
    result foreach(error, error println)
)

if(System args size > 0,
    System args foreach(arg,
        if(arg endsWithSeq(".io"),
            checkFile(arg)
        )
    )
)