#!/bin/bash

# Script to send commands to running Io REPL
# Usage: ./send_to_io.sh "command"

if [ -z "$1" ]; then
    echo "Usage: $0 'io_command'"
    exit 1
fi

# Find the Io process PID
IO_PID=$(pgrep -f "build/_build/binaries/io")

if [ -z "$IO_PID" ]; then
    echo "No Io process found running"
    exit 1
fi

# Send the command to the Io process via stdin
echo "$1" | sudo tee /proc/$IO_PID/fd/0 > /dev/null

echo "Sent command: $1"