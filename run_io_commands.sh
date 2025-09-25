#!/bin/bash

# TelOS Interactive Script Executor
# This script creates .io files and executes them with the Io interpreter

SCRIPT_DIR="/mnt/c/EntropicGarden"
TEMP_SCRIPT="$SCRIPT_DIR/temp_command.io"

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 'io_command1' ['io_command2'] ..."
    echo "Example: $0 'Telos type println' '1 + 1'"
    exit 1
fi

# Create temporary script file
echo "// Auto-generated TelOS command script" > "$TEMP_SCRIPT"
echo "" >> "$TEMP_SCRIPT"

# Add all commands to the script
for cmd in "$@"; do
    echo "$cmd" >> "$TEMP_SCRIPT"
done

echo "" >> "$TEMP_SCRIPT"
echo "// Script execution complete" >> "$TEMP_SCRIPT"

echo "Created script with commands:"
for cmd in "$@"; do
    echo "  $cmd"
done

echo ""
echo "Executing script..."
echo "========================"

# Execute the script with the Io interpreter
cd "$SCRIPT_DIR" && "./build/_build/binaries/io" "$TEMP_SCRIPT"

echo "========================"
echo "Execution complete."

# Clean up
rm -f "$TEMP_SCRIPT"