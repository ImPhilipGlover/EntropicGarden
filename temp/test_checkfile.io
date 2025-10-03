doFile("libs/Telos/io/IoSyntaxChecker.io")
checker := IoSyntaxChecker clone
result := checker checkFile("test_io_syntax.io")
results := checker getResults
results atPut("success", result)
results asJson println
