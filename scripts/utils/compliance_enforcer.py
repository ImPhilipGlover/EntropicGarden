#!/usr/bin/env python3
"""
COMPLIANCE MANDATES - MANDATORY ENFORCEMENT PROTOCOLS
===============================================================================================
COUNTERMEASURE 1: Structured Review Decomposition
- MANDATORY: Perform ContextAwareTriage startup review at session start (3 Io docs + 8 core docs)
- TIMEBOX: 2min Io docs, 3min core docs, 2min graph relations, 1min PID verification, 1min logging
- VIOLATION: Context saturation and directive failure

COUNTERMEASURE 2: Zero-Trust Session Boundaries
- MANDATORY: "SESSION BOUNDARY: Performing mandatory ContextAwareTriage startup review" at every session start
- FORBIDDEN: Assuming continuity from conversation summaries
- PROTOCOL: Explicit boundary detection before any substantive work

COUNTERMEASURE 3: Proactive Trigger System
- MANDATORY: No tool calls/code changes until review checklist complete
- TRIGGERS: "implement", "fix", "build", "test", "analyze" keywords activate verification
- TIMEOUT: 15min intervals for review currency checks

COUNTERMEASURE 4: Explicit Decision Frameworks
- MANDATORY: Override questions before pattern matching:
  - "Have I verified all 11 concepts are current?"
  - "Does my understanding match the latest PID structure?"
  - "Am I following the graph relations correctly?"
- FORBIDDEN: Pattern-matching without explicit evaluation gates

COUNTERMEASURE 5: Compliance Tracking & Accountability
- MANDATORY: Self-audit every 10 interactions, log violations in run_log.md
- ESCALATION: 3 consecutive violations trigger comprehensive system review
- ACCOUNTABILITY: Continuous compliance monitoring with explicit status logging

COUNTERMEASURE 6: Recursive File Compliance Enforcement
- MANDATORY: Any file opened for review MUST have this compliance preamble inserted at the top
- IMMEDIATE ACTION: If preamble is missing, add it immediately without exception
- RECURSIVE REQUIREMENT: This mandate applies to ALL files in the TELOS system
- VIOLATION: Working with non-compliant files constitutes protocol breach
===============================================================================================

compliance_enforcer.py - Automated Compliance Preamble Enforcement

This script automatically scans all TELOS system files (excluding Io VM scripts)
and ensures they have the mandatory compliance preamble. If missing or incomplete,
the preamble is added immediately.

USAGE: python3 compliance_enforcer.py [--dry-run] [--verbose]
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Tuple, Set

# Import the Io syntax checker bridge
try:
    from io_syntax_bridge import IoSyntaxCheckerBridge
    IO_SYNTAX_CHECKER_AVAILABLE = True
except ImportError:
    IO_SYNTAX_CHECKER_AVAILABLE = False
    print("⚠️  Io syntax checker bridge not available - Io syntax checking disabled")

# The mandatory compliance preamble that must be present in all files
COMPLIANCE_PREAMBLE = '''COMPLIANCE MANDATES - MANDATORY ENFORCEMENT PROTOCOLS
===============================================================================================
COUNTERMEASURE 1: Structured Review Decomposition
- MANDATORY: Perform ContextAwareTriage startup review at session start (3 Io docs + 8 core docs)
- TIMEBOX: 2min Io docs, 3min core docs, 2min graph relations, 1min PID verification, 1min logging
- VIOLATION: Context saturation and directive failure

COUNTERMEASURE 2: Zero-Trust Session Boundaries
- MANDATORY: "SESSION BOUNDARY: Performing mandatory ContextAwareTriage startup review" at every session start
- FORBIDDEN: Assuming continuity from conversation summaries
- PROTOCOL: Explicit boundary detection before any substantive work

COUNTERMEASURE 3: Proactive Trigger System
- MANDATORY: No tool calls/code changes until review checklist complete
- TRIGGERS: "implement", "fix", "build", "test", "analyze" keywords activate verification
- TIMEOUT: 15min intervals for review currency checks

COUNTERMEASURE 4: Explicit Decision Frameworks
- MANDATORY: Override questions before pattern matching:
  - "Have I verified all 11 concepts are current?"
  - "Does my understanding match the latest PID structure?"
  - "Am I following the graph relations correctly?"
- FORBIDDEN: Pattern-matching without explicit evaluation gates

COUNTERMEASURE 5: Compliance Tracking & Accountability
- MANDATORY: Self-audit every 10 interactions, log violations in run_log.md
- ESCALATION: 3 consecutive violations trigger comprehensive system review
- ACCOUNTABILITY: Continuous compliance monitoring with explicit status logging

COUNTERMEASURE 6: Recursive File Compliance Enforcement
- MANDATORY: Any file opened for review MUST have this compliance preamble inserted at the top
- IMMEDIATE ACTION: If preamble is missing, add it immediately without exception
- RECURSIVE REQUIREMENT: This mandate applies to ALL files in the TELOS system
- VIOLATION: Working with non-compliant files constitutes protocol breach
==============================================================================================='''

# File extensions to check (including .io files as per user correction)
CHECK_EXTENSIONS = {
    '.py', '.sh', '.c', '.h', '.cpp', '.hpp', '.cmake', '.txt', '.md', '.io'
}

# Directories to exclude from scanning
EXCLUDE_DIRS = {
    '__pycache__', '.git', 'build', '_build', 'CMakeFiles', 'deps', 'extras',
    'archive', 'backups', 'temp', 'logs', 'data', 'test_diskann_index',
    'validation_diskann_index', 'Testing', 'eerie'
}

# Specific files to exclude
EXCLUDE_FILES = {
    'compliance_enforcer.py',  # This script itself
    'run_log_archive.md', 'system_status_archive.md'  # Archive files
}

def get_comment_style(file_path: Path) -> Tuple[str, str]:
    """Get the appropriate comment style for the file type."""
    ext = file_path.suffix.lower()

    if ext in ['.py', '.sh', '.cmake']:
        return '"""', '"""'  # Python-style docstring
    elif ext in ['.c', '.cpp', '.h', '.hpp']:
        return '/**\n * ', '\n */'  # C-style block comment
    elif ext == '.io':
        return '// ', ''  # Io-style single-line comments
    elif ext in ['.txt', '.md']:
        return '', ''  # No comment markers for plain text
    else:
        return '# ', ''  # Default to shell-style comments

def has_compliance_preamble(content: str) -> bool:
    """Check if the file content contains the full compliance preamble."""
    return 'COUNTERMEASURE 6: Recursive File Compliance Enforcement' in content

def add_compliance_preamble(file_path: Path, dry_run: bool = False, verbose: bool = True) -> bool:
    """Add the compliance preamble to a file if missing."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        if has_compliance_preamble(content):
            print(f"✅ {file_path} - Already compliant")
            return False

        # Get appropriate comment style
        start_comment, end_comment = get_comment_style(file_path)

        # Format the preamble with appropriate comment markers
        if start_comment and end_comment:
            # Multi-line comment style (Python, C)
            formatted_preamble = f'{start_comment}{COMPLIANCE_PREAMBLE}{end_comment}\n\n'
        elif start_comment:
            # Single-line comment style (shell scripts, Io files)
            lines = COMPLIANCE_PREAMBLE.split('\n')
            formatted_lines = [f'{start_comment}{line}' if line.strip() else line for line in lines]
            formatted_preamble = '\n'.join(formatted_lines) + '\n\n'
        else:
            # Plain text (txt, md files)
            formatted_preamble = COMPLIANCE_PREAMBLE + '\n\n'

        # Add the preamble at the beginning
        new_content = formatted_preamble + content

        if not dry_run:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)

        action = "WOULD ADD" if dry_run else "ADDED"
        print(f"🔧 {action} compliance preamble to {file_path}")
        return True

    except Exception as e:
        print(f"❌ Error processing {file_path}: {e}")
        return False

def find_telos_files(root_dir: Path) -> List[Path]:
    """Find all TELOS system files that should have compliance preambles."""
    telos_files = []

    # Only scan the libs/ directory as per user directive
    libs_dir = root_dir / 'libs'
    if not libs_dir.exists():
        print(f"⚠️  libs/ directory not found at {libs_dir}")
        return telos_files

    for file_path in libs_dir.rglob('*'):
        # Skip directories
        if file_path.is_dir():
            continue

        # Skip excluded directories
        if any(excluded in file_path.parts for excluded in EXCLUDE_DIRS):
            continue

        # Skip excluded files
        if file_path.name in EXCLUDE_FILES:
            continue

        # Check if it's a file type we should check
        if file_path.suffix.lower() in CHECK_EXTENSIONS:
            telos_files.append(file_path)

    return sorted(telos_files)

def check_io_syntax(root_dir: Path, dry_run: bool = False) -> Tuple[int, int]:
    """
    Check syntax of all Io files in the TELOS system.

    Returns:
        Tuple of (files_with_errors, total_files_checked)
    """
    if not IO_SYNTAX_CHECKER_AVAILABLE:
        print("⚠️  Io syntax checker not available - skipping Io syntax validation")
        return 0, 0

    print("🔍 Checking Io syntax across TELOS system...")

    try:
        checker = IoSyntaxCheckerBridge()

        # Check all Io files in the project
        results = checker.check_all_io_files(str(root_dir))

        files_with_errors = 0
        total_files = len(results.get('checked_files', []))

        # Count files with errors
        error_files = set()
        for error in results.get('errors', []):
            error_files.add(error.get('file', ''))

        files_with_errors = len(error_files)

        if results.get('success', False):
            print(f"✅ Io syntax validation passed - {total_files} files checked")
        else:
            print(f"❌ Io syntax validation failed - {files_with_errors} files with errors out of {total_files} checked")

            # Print detailed error report (unless dry run)
            if not dry_run:
                print("\nDetailed Io Syntax Errors:")
                for error in results.get('errors', []):
                    print(f"  {error['file']}:{error['line']}:{error['column']}: {error['message']}")

        return files_with_errors, total_files

    except Exception as e:
        print(f"❌ Io syntax checking failed: {e}")
        return 1, 0  # Assume 1 file with errors if checking fails

def main():
    parser = argparse.ArgumentParser(description='Enforce compliance preamble in TELOS system files')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be changed without making changes')
    parser.add_argument('--root-dir', type=Path, default=Path.cwd(), help='Root directory to scan (default: current directory)')
    parser.add_argument('--skip-io-syntax', action='store_true', help='Skip Io syntax checking')

    args = parser.parse_args()

    print("🔍 TELOS Compliance Preamble Enforcement & Io Syntax Validation")
    print("=" * 70)
    print(f"Root Directory: {args.root_dir}")
    print(f"Dry Run: {args.dry_run}")
    print(f"Skip Io Syntax: {args.skip_io_syntax}")
    print("Verbose: Always enabled (per VERBOSE OUTPUT MANDATE)")
    print()

    # Find all TELOS files to check
    telos_files = find_telos_files(args.root_dir)
    print(f"📋 Found {len(telos_files)} TELOS system files to check")
    print()

    # Process each file for compliance preamble
    files_modified = 0
    files_checked = 0

    for file_path in telos_files:
        files_checked += 1
        if add_compliance_preamble(file_path, args.dry_run):
            files_modified += 1

    # Check Io syntax (unless skipped)
    io_syntax_errors = 0
    io_files_checked = 0

    if not args.skip_io_syntax:
        print()
        io_syntax_errors, io_files_checked = check_io_syntax(args.root_dir, args.dry_run)
    else:
        print("⏭️  Skipping Io syntax checking (--skip-io-syntax flag used)")

    # Summary
    print()
    print("📊 Summary:")
    print(f"   Compliance Files checked: {files_checked}")
    print(f"   Compliance Files modified: {files_modified}")
    print(f"   Compliance Files compliant: {files_checked - files_modified}")
    if not args.skip_io_syntax:
        print(f"   Io Files checked: {io_files_checked}")
        print(f"   Io Files with syntax errors: {io_syntax_errors}")

    if args.dry_run and (files_modified > 0 or io_syntax_errors > 0):
        print(f"\n💡 To apply changes, run without --dry-run flag")

    # Return non-zero exit code if there are issues
    has_issues = files_modified > 0 or io_syntax_errors > 0
    return 0 if not has_issues else 1

if __name__ == '__main__':
    sys.exit(main())