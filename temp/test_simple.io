doFile("libs/Telos/io/IoSyntaxChecker.io")
checker := IoSyntaxChecker clone
"About to call checkFile" println
result := checker checkFile("test_io_syntax.io")
"checkFile completed" println
