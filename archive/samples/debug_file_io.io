writeln("--- File I/O Debug ---")

// Test if the logs directory is accessible
logsDir := Directory with("/mnt/c/EntropicGarden/logs")
writeln("logs/ exists: ", logsDir exists)

// Define the file path
filePath := "/mnt/c/EntropicGarden/logs/iotest.txt"
writeln("Attempting to write to: ", filePath)

try(
    // Create a File object
    testFile := File with(filePath)
    
    // Ensure parent directory exists
    parentDirPath := "/mnt/c/EntropicGarden/logs"
    parentDir := Directory with(parentDirPath)
    if(parentDir exists not, parentDir create)

    // Create if missing, then open for updating and truncate before writing
    if(testFile exists not, testFile create)
    testFile openForUpdating
    testFile truncateToSize(0)
    
    // Write a simple string
    testFile write("Hello from Io file I/O test.")
    
    // Close the file
    testFile close
    
    writeln("Test complete: File write attempt finished"),

    // Exception handling
    e,
    writeln("Test complete: File write encountered exception")
    writeln("  Exception: ", e type, " - ", e description)
)

// Verify file creation
verifyFile := File with(filePath)
if(verifyFile exists,
    writeln("Verification: file exists at ", filePath),
    writeln("Verification: file missing at ", filePath)
)

writeln("--- File I/O Debug Complete ---")
