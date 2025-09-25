#!/bin/bash

echo "=== Emergency TelOS Process Killer ==="
echo "Killing any stuck io processes..."

# Kill any io processes
pkill -f "_build/binaries/io" 2>/dev/null || echo "No io processes found"
pkill -f "io.*telos" 2>/dev/null || echo "No telos processes found"

# Kill any SDL2 processes that might be stuck
pkill -f "SDL" 2>/dev/null || echo "No SDL processes found"

echo "Process cleanup complete"
echo "Any stuck SDL2 windows should now be closed"