#!/usr/bin/env bash
# Anti-Hang Io runner: prevents stdin waits and enforces timeouts
# Usage: tools/run_io.sh <timeout_sec> <script_or_-e> [args...]
set -euo pipefail

TIMEOUT="${1:-15}"; shift || true
CMD=("$@")

# Ensure repo root
cd "$(dirname "$0")/.."

BIN="build/_build/binaries/io"
if [[ ! -x "$BIN" ]]; then
  echo "Io binary not found at $BIN" >&2
  exit 127
fi

# Non-interactive mode to guard stdin reads
export TELOS_NONINTERACTIVE=1

# Run with stdin from /dev/null and timeout
if command -v timeout >/dev/null 2>&1; then
  timeout --preserve-status --signal=INT --kill-after=2s "$TIMEOUT" "$BIN" "${CMD[@]}" < /dev/null
else
  "$BIN" "${CMD[@]}" < /dev/null &
  pid=$!
  sleep "$TIMEOUT" || true
  if ps -p $pid >/dev/null 2>&1; then
    kill -INT $pid 2>/dev/null || true
    sleep 2
    kill -KILL $pid 2>/dev/null || true
    echo "Timed out after ${TIMEOUT}s" >&2
    exit 124
  fi
fi
