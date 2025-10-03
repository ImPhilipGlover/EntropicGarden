#!/usr/local/bin/io

// IoSyntaxChecker.io - Working Io syntax checker
// Based on Io language guide syntax rules

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

        // Check basic syntax elements
        errors appendSeq(checkBrackets(content))
        errors appendSeq(checkStrings(content))
        errors appendSeq(checkComments(content))

        if(errors size == 0,
            list("✓ Syntax appears valid for " .. fileName)
        ,
            errors
        )
    )

    checkBrackets := method(content,
        errors := list()
        parens := 0
        braces := 0
        brackets := 0
        inString := false
        inComment := false
        i := 0

        while(i < content size,
            char := content at(i)

            // Handle strings
            if(inString not and char == "\"",
                inString := true
            ,
                if(inString and char == "\"",
                    inString := false
                )
            )

            // Skip comments
            if(inComment not and i + 1 < content size and content exSlice(i, i+2) == "/*",
                inComment := true
                i := i + 1
            ,
                if(inComment and i + 1 < content size and content exSlice(i, i+2) == "*/",
                    inComment := false
                    i := i + 1
                )
            )

            // Skip // comments
            if(inComment not and i + 1 < content size and content exSlice(i, i+2) == "//",
                while(i < content size and char != "\n",
                    i := i + 1
                    if(i < content size, char := content at(i))
                )
            )

            // Count brackets only outside strings and comments
            if(inString not and inComment not,
                if(char == "(", parens := parens + 1)
                if(char == ")", parens := parens - 1)
                if(char == "{", braces := braces + 1)
                if(char == "}", braces := braces - 1)
                if(char == "[", brackets := brackets + 1)
                if(char == "]", brackets := brackets - 1)

                // Check for negative counts (more closing than opening)
                if(parens < 0,
                    errors append("Unexpected closing parenthesis at position " .. i)
                    parens := 0
                )
                if(braces < 0,
                    errors append("Unexpected closing brace at position " .. i)
                    braces := 0
                )
                if(brackets < 0,
                    errors append("Unexpected closing bracket at position " .. i)
                    brackets := 0
                )
            )

            i := i + 1
        )

        if(parens > 0, errors append("Missing " .. parens .. " closing parentheses"))
        if(braces > 0, errors append("Missing " .. braces .. " closing braces"))
        if(brackets > 0, errors append("Missing " .. brackets .. " closing brackets"))

        errors
    )

    checkStrings := method(content,
        errors := list()
        i := 0
        inString := false
        stringStart := 0
        tripleQuote := false

        while(i < content size,
            char := content at(i)

            if(inString not,
                // Check for string start
                if(char == 34,  // ASCII for "
                    if(i + 2 < content size and content exSlice(i, i+3) == "\"\"\"",
                        tripleQuote := true
                        inString := true
                        stringStart := i
                        i := i + 2  // Skip the extra quotes
                    ,
                        inString := true
                        stringStart := i
                    )
                )
            ,
                // In string, check for end
                if(tripleQuote,
                    if(char == 34 and i + 2 < content size and content exSlice(i, i+3) == "\"\"\"",
                        inString := false
                        tripleQuote := false
                        i := i + 2  // Skip the extra quotes
                    )
                ,
                    if(char == 34,  // ASCII for "
                        inString := false
                    ,
                        // Check for unescaped newlines in single-line strings
                        if(char == 10 and tripleQuote not,  // ASCII for \n
                            errors append("Unterminated string literal starting at position " .. stringStart)
                            inString := false
                        )
                    )
                )
            )

            i := i + 1
        )

        if(inString,
            errors append("Unterminated string literal starting at position " .. stringStart)
        )

        errors
    )

    checkComments := method(content,
        errors := list()

        // Basic check for properly formed comments
        i := 0
        while(i < content size,
            if(i + 1 < content size,
                twoChars := content exSlice(i, i+2)
                if(twoChars == "//",
                    // Skip to end of line
                    while(i < content size and content at(i) != "\n", i := i + 1)
                )
                if(twoChars == "/*",
                    // Find matching */
                    start := i
                    i := i + 2
                    foundEnd := false
                    while(i + 1 < content size,
                        if(content exSlice(i, i+2) == "*/",
                            foundEnd := true
                            i := i + 2
                            break
                        )
                        i := i + 1
                    )
                    if(foundEnd not,
                        errors append("Unterminated /* comment starting at position " .. start)
                    )
                )
            )
            i := i + 1
        )

        errors
    )
)

// Convenience method for command line usage
checkFile := method(filePath,
    checker := IoSyntaxChecker clone
    result := checker validateFile(filePath)
    result foreach(error, error println)
)

// Batch check multiple files
checkAllFiles := method(filePaths,
    validFiles := list()
    invalidFiles := list()
    errors := Map clone

    filePaths foreach(filePath,
        if(filePath endsWithSeq(".io"),
            checker := IoSyntaxChecker clone
            result := checker validateFile(filePath)
            if(result size == 1 and result at(0) beginsWithSeq("✓"),
                validFiles append(filePath)
            ,
                invalidFiles append(filePath)
                errors atPut(filePath, result)
            )
        )
    )

    // Print summary
    "\n" println
    "=== SYNTAX CHECK SUMMARY ===" println
    ("Total .io files checked: " .. (validFiles size + invalidFiles size)) println
    ("✓ Valid files: " .. validFiles size) println
    ("✗ Files with errors: " .. invalidFiles size) println

    if(invalidFiles size > 0,
        "\nFiles needing correction:" println
        invalidFiles foreach(file,
            ("  ✗ " .. file) println
            fileErrors := errors at(file)
            fileErrors foreach(error,
                if(error beginsWithSeq("ERROR:") not and error beginsWithSeq("✓") not,
                    ("    - " .. error) println
                )
            )
        )
    ,
        "\n✓ All .io files have valid syntax!" println
    )
)

// If run directly, check command line arguments
if(System args size > 0,
    if(System args contains("--all") or System args contains("-a"),
        // Find all .io files in current directory and subdirectories
        allFiles := Directory with(System launchPath) items select(item,
            item type == "File" and item name endsWithSeq(".io")
        ) map(name)

        // Also check subdirectories recursively
        subDirs := Directory with(System launchPath) items select(item,
            item type == "Directory"
        )

        subDirs foreach(dir,
            dirItems := Directory with(dir path) items select(item,
                item type == "File" and item name endsWithSeq(".io")
            )
            allFiles appendSeq(dirItems map(item, dir path .. "/" .. item name))
        )

        checkAllFiles(allFiles)
    ,
        // Check specific files from command line (skip the script name)
        System args foreach(i, arg,
            if(i > 0 and arg endsWithSeq(".io"),
                checkFile(arg)
            )
        )
    )
)