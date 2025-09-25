/*
 * Test program to verify the fixed FFI subprocess execution
 * This replicates the IoTelosFFI_pyEval logic in isolation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main() {
    printf("Testing fixed FFI subprocess execution...\n");
    
    const char *code = "print('FFI test successful')";
    
    // Use subprocess to execute Python with timeout
    char command[4096];
    snprintf(command, sizeof(command), 
        "timeout 10s python3 -c \"import sys; sys.path.append('/mnt/c/EntropicGarden/python'); %s\"", 
        code);
    
    printf("Executing command: %s\n", command);
    
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        printf("ERROR: Failed to execute Python subprocess\n");
        return 1;
    }
    
    // Read output from Python subprocess with safer approach
    char buffer[8192];
    size_t total_read = 0;
    
    buffer[0] = '\0';
    
    // Use fgets instead of fread for line-by-line reading
    char line[1024];
    while (fgets(line, sizeof(line), pipe) && total_read < sizeof(buffer) - 1) {
        size_t line_len = strlen(line);
        if (total_read + line_len >= sizeof(buffer) - 1) {
            break; // Prevent buffer overflow
        }
        strcpy(buffer + total_read, line);
        total_read += line_len;
    }
    
    int exit_code = pclose(pipe);
    
    // Handle timeout (exit code 124 from timeout command)
    if (exit_code == 124) {
        printf("ERROR: Python execution timed out (10s limit)\n");
        return 1;
    }
    
    if (exit_code != 0) {
        printf("ERROR: Python execution failed with exit code %d: %s\n", exit_code, buffer);
        return 1;
    }
    
    // Remove trailing newline if present
    if (total_read > 0 && buffer[total_read-1] == '\n') {
        buffer[total_read-1] = '\0';
    }
    
    printf("SUCCESS: Python output: '%s'\n", buffer);
    
    printf("FFI subprocess execution fix verified!\n");
    
    return 0;
}
