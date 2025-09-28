#!/usr/bin/env python3
"""Append a structured search-summary entry to run_log.md.
Usage: python scripts/log_search.py --query "..." --results-file results.json

This tool expects a JSON file with an array of up to 3 result objects:
[{"title": "...", "url": "...", "snippet": "..."}, ...]

If results-file is omitted, the script will read a simple JSON array from stdin.
"""
import argparse
import json
from datetime import datetime
from pathlib import Path

RUN_LOG = Path(__file__).resolve().parents[1] / 'run_log.md'

TEMPLATE = """

---
AutoPrompt External Search
Timestamp: {ts}
Query: {query}
Citations: {citations}
OS: {os}
Python: {python}
CMake: {cmake}
Tools: {tools}
Commit: {commit}
User: {user}

Top results:
{results_block}

Derived action: {action}
---
"""


def format_result(i, r):
    title = r.get('title') or r.get('name') or ''
    url = r.get('url') or r.get('link') or ''
    snippet = r.get('snippet') or r.get('excerpt') or ''
    return f"{i}. {title}\n   {url}\n   {snippet}\n"


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--query', required=True)
    p.add_argument('--results-file', help='JSON file with results (array)')
    p.add_argument('--action', default='(none)', help='Short note on derived action')
    p.add_argument('--cite', nargs='*', default=[], help='Short citations like domain.com YYYY-MM-DD')
    # optional metadata
    p.add_argument('--os', default='(unknown)', help='Operating system, e.g. Ubuntu 22.04')
    p.add_argument('--python', default='(unknown)', help='Python version, e.g. 3.10.6')
    p.add_argument('--cmake', default='(unknown)', help='CMake version, e.g. 3.25.0')
    p.add_argument('--tools', nargs='*', default=[], help='Other tools/versions used, e.g. clang-13, ollama-1.2')
    p.add_argument('--commit', default=None, help='Git commit SHA to record (auto-detected if omitted)')
    p.add_argument('--user', default=None, help='User performing the search (auto-detected from git config if omitted)')
    args = p.parse_args()

    if args.results_file:
        with open(args.results_file, 'r', encoding='utf-8') as f:
            results = json.load(f)
    else:
        try:
            results = json.load(sys.stdin)
        except Exception:
            results = []

    results = results[:3]
    results_block = ''.join(format_result(i+1, r) for i, r in enumerate(results)) or '  (no results)\n'
    citations = ', '.join(args.cite) if args.cite else '(none)'
    ts = datetime.utcnow().isoformat() + 'Z'

    tools = ', '.join(args.tools) if args.tools else '(none)'
    # auto-detect git commit and user if not supplied
    commit = args.commit
    user = args.user
    try:
        if commit is None:
            import subprocess
            commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=Path(__file__).resolve().parents[1], stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        commit = '(unknown)'
    try:
        if user is None:
            import subprocess
            user = subprocess.check_output(['git', 'config', 'user.name'], cwd=Path(__file__).resolve().parents[1], stderr=subprocess.DEVNULL).decode().strip()
            if not user:
                user = '(unknown)'
    except Exception:
        user = '(unknown)'

    entry = TEMPLATE.format(ts=ts, query=args.query, citations=citations, os=args.os, python=args.python, cmake=args.cmake, tools=tools, results_block=results_block, action=args.action, commit=commit, user=user)

    RUN_LOG.parent.mkdir(parents=True, exist_ok=True)
    # append to run_log.md
    with open(RUN_LOG, 'a', encoding='utf-8') as out:
        out.write(entry)

    print(f'Appended search summary to {RUN_LOG}')


if __name__ == '__main__':
    import sys
    main()
