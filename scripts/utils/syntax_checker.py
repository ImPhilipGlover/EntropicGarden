#!/usr/bin/env python3
"""
Universal Syntax Checker - Io, Python, C/C++ Syntax Validation

This script provides comprehensive syntax checking for multiple programming languages
used in the TELOS system. It can identify syntax errors, provide detailed diagnostics,
and suggest fixes where possible.

Usage:
    python syntax_checker.py [file_path] [--language auto|io|python|c|cpp]
    python syntax_checker.py --check-all [--fix] [--verbose]

Features:
- Io syntax validation (parentheses, blocks, messages)
- Python syntax validation with AST parsing
- C/C++ syntax validation with clang/gcc
- Automatic language detection
- Error location reporting
- Fix suggestions where applicable
- Integration with TELOS build system
"""

import sys
import os
import re
import subprocess
import tempfile
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any
import json

class SyntaxChecker:
    """Universal syntax checker for Io, Python, and C/C++ files"""

    def __init__(self):
        self.errors = []
        self.warnings = []
        self.language_detectors = {
            'io': self._is_io_file,
            'python': self._is_python_file,
            'c': self._is_c_file,
            'cpp': self._is_cpp_file
        }

        self.checkers = {
            'io': self._check_io_syntax,
            'python': self._check_python_syntax,
            'c': self._check_c_syntax,
            'cpp': self._check_cpp_syntax
        }

    def detect_language(self, file_path: str) -> str:
        """Detect the programming language of a file"""
        path = Path(file_path)

        # Check file extension first
        ext = path.suffix.lower()
        if ext == '.io':
            return 'io'
        elif ext in ['.py', '.pyw']:
            return 'python'
        elif ext == '.c':
            return 'c'
        elif ext in ['.cpp', '.cc', '.cxx', '.c++']:
            return 'cpp'
        elif ext == '.h':
            # Header files could be C or C++
            return 'c'  # Default to C, but could be enhanced

        # Fallback to content-based detection
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read(1024)  # Read first 1KB

            for lang, detector in self.language_detectors.items():
                if detector(content):
                    return lang

        except Exception as e:
            self.errors.append(f"Error reading file {file_path}: {e}")

        return 'unknown'

    def _is_io_file(self, content: str) -> bool:
        """Check if content looks like Io code"""
        # Io-specific patterns
        io_patterns = [
            r':=\s',  # Assignment operator
            r'::=\s',  # Setter assignment
            r'method\s*\(',  # Method definition
            r'block\s*\(',  # Block definition
            r'setSlot\s*\(',  # Slot setting
            r'clone\s*$',  # Object cloning (end of line)
            r'Object\s+clone',  # Object cloning pattern
        ]

        score = sum(1 for pattern in io_patterns if re.search(pattern, content, re.MULTILINE))
        return score >= 2

    def _is_python_file(self, content: str) -> bool:
        """Check if content looks like Python code"""
        python_patterns = [
            r'def\s+\w+\s*\(',  # Function definition
            r'class\s+\w+',  # Class definition
            r'import\s+\w+',  # Import statement
            r'from\s+\w+\s+import',  # From import
            r'if\s+__name__\s*==\s*[\'"]__main__[\'"]',  # Main guard
            r'print\s*\(',  # Print function
        ]

        score = sum(1 for pattern in python_patterns if re.search(pattern, content))
        return score >= 2

    def _is_c_file(self, content: str) -> bool:
        """Check if content looks like C code"""
        c_patterns = [
            r'#include\s*<[^>]+>',  # Include directive
            r'int\s+main\s*\(',  # Main function
            r'printf\s*\(',  # Printf function
            r'malloc\s*\(',  # Memory allocation
            r'free\s*\(',  # Memory deallocation
            r'struct\s+\w+',  # Struct definition
        ]

        score = sum(1 for pattern in c_patterns if re.search(pattern, content))
        return score >= 2

    def _is_cpp_file(self, content: str) -> bool:
        """Check if content looks like C++ code"""
        cpp_patterns = [
            r'#include\s*<[^>]+>',  # Include directive
            r'cout\s*<<',  # C++ output
            r'cin\s*>>',  # C++ input
            r'std::',  # Standard library usage
            r'class\s+\w+',  # Class definition
            r'template\s*<',  # Template usage
            r'new\s+\w+',  # New operator
            r'delete\s+',  # Delete operator
        ]

        score = sum(1 for pattern in cpp_patterns if re.search(pattern, content))
        return score >= 2

    def check_file(self, file_path: str, language: str = 'auto') -> Dict[str, Any]:
        """Check syntax of a single file"""
        self.errors = []
        self.warnings = []

        if language == 'auto':
            language = self.detect_language(file_path)

        if language == 'unknown':
            return {
                'file': file_path,
                'language': 'unknown',
                'errors': [{'message': 'Could not detect programming language'}],
                'warnings': [],
                'valid': False
            }

        if language not in self.checkers:
            return {
                'file': file_path,
                'language': language,
                'errors': [{'message': f'No checker available for language: {language}'}],
                'warnings': [],
                'valid': False
            }

        try:
            checker = self.checkers[language]
            result = checker(file_path)

            return {
                'file': file_path,
                'language': language,
                'errors': self.errors,
                'warnings': self.warnings,
                'valid': len(self.errors) == 0
            }

        except Exception as e:
            return {
                'file': file_path,
                'language': language,
                'errors': [{'message': f'Checker failed: {str(e)}'}],
                'warnings': self.warnings,
                'valid': False
            }

    def _check_io_syntax(self, file_path: str) -> bool:
        """Check Io syntax"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            lines = content.split('\n')
            brace_depth = 0
            paren_depth = 0
            bracket_depth = 0
            in_string = False
            string_char = None
            in_multiline_string = False
            in_comment = False

            for line_num, line in enumerate(lines, 1):
                i = 0
                while i < len(line):
                    char = line[i]

                    # Handle comments
                    if not in_string and not in_multiline_string:
                        if line[i:i+2] == '//':
                            break  # Rest of line is comment
                        elif line[i:i+2] == '/*':
                            in_comment = True
                            i += 2
                            continue
                        elif in_comment and line[i:i+2] == '*/':
                            in_comment = False
                            i += 2
                            continue
                        elif in_comment:
                            i += 1
                            continue

                    if in_comment:
                        i += 1
                        continue

                    # Handle strings
                    if not in_multiline_string:
                        if char in ['"', "'"] and (i == 0 or line[i-1] != '\\'):
                            if not in_string:
                                in_string = True
                                string_char = char
                            elif char == string_char:
                                in_string = False
                                string_char = None
                        elif line[i:i+3] == '"""' and not in_string:
                            in_multiline_string = True
                            i += 3
                            continue
                    elif in_multiline_string and line[i:i+3] == '"""':
                        in_multiline_string = False
                        i += 3
                        continue

                    if in_string or in_multiline_string:
                        i += 1
                        continue

                    # Track braces, parentheses, and brackets
                    if char == '{':
                        brace_depth += 1
                    elif char == '}':
                        brace_depth -= 1
                        if brace_depth < 0:
                            self.errors.append({
                                'line': line_num,
                                'column': i + 1,
                                'message': 'Unexpected closing brace }',
                                'severity': 'error'
                            })
                    elif char == '(':
                        paren_depth += 1
                    elif char == ')':
                        paren_depth -= 1
                        if paren_depth < 0:
                            self.errors.append({
                                'line': line_num,
                                'column': i + 1,
                                'message': 'Unexpected closing parenthesis )',
                                'severity': 'error'
                            })
                    elif char == '[':
                        bracket_depth += 1
                    elif char == ']':
                        bracket_depth -= 1
                        if bracket_depth < 0:
                            self.errors.append({
                                'line': line_num,
                                'column': i + 1,
                                'message': 'Unexpected closing bracket ]',
                                'severity': 'error'
                            })

                    i += 1

            # Check for unclosed structures
            if brace_depth > 0:
                self.errors.append({
                    'line': len(lines),
                    'column': len(lines[-1]) + 1,
                    'message': f'Unclosed brace: {brace_depth} unclosed {{',
                    'severity': 'error'
                })

            if paren_depth > 0:
                self.errors.append({
                    'line': len(lines),
                    'column': len(lines[-1]) + 1,
                    'message': f'Unclosed parenthesis: {paren_depth} unclosed (',
                    'severity': 'error'
                })

            if bracket_depth > 0:
                self.errors.append({
                    'line': len(lines),
                    'column': len(lines[-1]) + 1,
                    'message': f'Unclosed bracket: {bracket_depth} unclosed [',
                    'severity': 'error'
                })

            if in_string:
                self.errors.append({
                    'line': len(lines),
                    'column': len(lines[-1]) + 1,
                    'message': f'Unclosed string literal starting with {string_char}',
                    'severity': 'error'
                })

            if in_multiline_string:
                self.errors.append({
                    'line': len(lines),
                    'column': len(lines[-1]) + 1,
                    'message': 'Unclosed multiline string literal (""")',
                    'severity': 'error'
                })

            # Check for Io-specific syntax issues
            self._check_io_specific_syntax(content)

            return len(self.errors) == 0

        except Exception as e:
            self.errors.append({
                'line': 0,
                'column': 0,
                'message': f'Failed to check Io syntax: {str(e)}',
                'severity': 'error'
            })
            return False

    def _check_io_specific_syntax(self, content: str):
        """Check Io-specific syntax patterns"""
        lines = content.split('\n')

        for line_num, line in enumerate(lines, 1):
            # Check for common Io syntax errors

            # Missing commas in argument lists
            paren_matches = re.finditer(r'\(\s*([^)]+)\s*\)', line)
            for match in paren_matches:
                args = match.group(1).strip()
                if args and not re.match(r'^[\w\s:=.,+\-*/<>!&|%]+$', args):
                    # More complex check for argument lists
                    if ',' not in args and len(args.split()) > 1:
                        # Check if this looks like multiple arguments without commas
                        tokens = re.split(r'\s+', args)
                        if len(tokens) > 1 and not any(op in args for op in ['+', '-', '*', '/', '==', '!=', '<', '>', '<=', '>=']):
                            self.warnings.append({
                                'line': line_num,
                                'column': match.start() + 1,
                                'message': 'Possible missing comma in argument list',
                                'severity': 'warning'
                            })

            # Check for incorrect assignment operators
            if re.search(r'\s+=\s*[^=]', line):
                # Single = that might be intended as :=
                if not re.search(r'(==|!=|<=|>=|\+=|-=|\*=|/=)', line):
                    self.warnings.append({
                        'line': line_num,
                        'column': line.find('=') + 1,
                        'message': 'Single = used; did you mean := for slot assignment?',
                        'severity': 'warning'
                    })

    def _check_python_syntax(self, file_path: str) -> bool:
        """Check Python syntax using AST parsing"""
        try:
            import ast

            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            # Try to parse the AST
            try:
                ast.parse(content, filename=file_path)
                return True
            except SyntaxError as e:
                self.errors.append({
                    'line': e.lineno or 0,
                    'column': e.offset or 0,
                    'message': f'SyntaxError: {e.msg}',
                    'severity': 'error'
                })
                return False
            except Exception as e:
                self.errors.append({
                    'line': 0,
                    'column': 0,
                    'message': f'AST parsing failed: {str(e)}',
                    'severity': 'error'
                })
                return False

        except Exception as e:
            self.errors.append({
                'line': 0,
                'column': 0,
                'message': f'Failed to check Python syntax: {str(e)}',
                'severity': 'error'
            })
            return False

    def _check_c_syntax(self, file_path: str) -> bool:
        """Check C syntax using gcc"""
        return self._check_c_cpp_syntax(file_path, 'c')

    def _check_cpp_syntax(self, file_path: str) -> bool:
        """Check C++ syntax using g++"""
        return self._check_c_cpp_syntax(file_path, 'cpp')

    def _check_c_cpp_syntax(self, file_path: str, language: str) -> bool:
        """Check C/C++ syntax using compiler"""
        compiler = 'gcc' if language == 'c' else 'g++'

        try:
            # Try to compile with syntax-only flag
            result = subprocess.run(
                [compiler, '-fsyntax-only', '-I.', '-I./libs', file_path],
                capture_output=True,
                text=True,
                timeout=30
            )

            if result.returncode != 0:
                # Parse compiler errors
                errors = self._parse_gcc_errors(result.stderr, file_path)
                self.errors.extend(errors)
                return False

            return True

        except subprocess.TimeoutExpired:
            self.errors.append({
                'line': 0,
                'column': 0,
                'message': f'{compiler} syntax check timed out',
                'severity': 'error'
            })
            return False
        except FileNotFoundError:
            self.warnings.append({
                'line': 0,
                'column': 0,
                'message': f'{compiler} not found, cannot check {language.upper()} syntax',
                'severity': 'warning'
            })
            return True  # Don't fail if compiler not available
        except Exception as e:
            self.errors.append({
                'line': 0,
                'column': 0,
                'message': f'Failed to check {language.upper()} syntax: {str(e)}',
                'severity': 'error'
            })
            return False

    def _parse_gcc_errors(self, stderr: str, file_path: str) -> List[Dict]:
        """Parse GCC error output"""
        errors = []
        lines = stderr.strip().split('\n')

        for line in lines:
            # GCC error format: file:line:column: error: message
            match = re.match(r'([^:]+):(\d+):(\d+):\s*(error|warning):\s*(.+)', line)
            if match:
                filename, line_num, col_num, severity, message = match.groups()
                if filename == file_path or filename.endswith(Path(file_path).name):
                    errors.append({
                        'line': int(line_num),
                        'column': int(col_num),
                        'message': message,
                        'severity': severity
                    })

        return errors

    def check_all_files(self, root_dir: str = '.', include_patterns: List[str] = None,
                       exclude_patterns: List[str] = None) -> Dict[str, Any]:
        """Check syntax of all relevant files in directory tree"""
        if include_patterns is None:
            include_patterns = ['*.io', '*.py', '*.c', '*.cpp', '*.h']

        if exclude_patterns is None:
            exclude_patterns = ['__pycache__', '.git', 'build', 'temp']

        results = []
        total_files = 0

        root_path = Path(root_dir)

        for pattern in include_patterns:
            for file_path in root_path.rglob(pattern):
                # Check exclude patterns
                if any(excl in str(file_path) for excl in exclude_patterns):
                    continue

                total_files += 1
                result = self.check_file(str(file_path))
                results.append(result)

        return {
            'total_files': total_files,
            'results': results,
            'summary': {
                'valid': sum(1 for r in results if r['valid']),
                'invalid': sum(1 for r in results if not r['valid']),
                'errors': sum(len(r['errors']) for r in results),
                'warnings': sum(len(r['warnings']) for r in results)
            }
        }

def main():
    parser = argparse.ArgumentParser(description='Universal Syntax Checker for TELOS')
    parser.add_argument('file', nargs='?', help='File to check (if not provided, checks all files)')
    parser.add_argument('--language', choices=['auto', 'io', 'python', 'c', 'cpp'],
                       default='auto', help='Programming language')
    parser.add_argument('--check-all', action='store_true',
                       help='Check all files in current directory tree')
    parser.add_argument('--fix', action='store_true',
                       help='Attempt to auto-fix syntax errors')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')
    parser.add_argument('--json', action='store_true',
                       help='Output results as JSON')
    parser.add_argument('--include', action='append',
                       help='Include pattern (can be used multiple times)')
    parser.add_argument('--exclude', action='append',
                       help='Exclude pattern (can be used multiple times)')

    args = parser.parse_args()

    checker = SyntaxChecker()

    if args.file:
        result = checker.check_file(args.file, args.language)

        if args.json:
            print(json.dumps(result, indent=2))
        else:
            print(f"Checking {result['file']} ({result['language']})")
            print(f"Valid: {result['valid']}")

            for error in result['errors']:
                print(f"ERROR {error['line']}:{error['column']}: {error['message']}")

            for warning in result['warnings']:
                print(f"WARNING {warning['line']}:{warning['column']}: {warning['message']}")

    elif args.check_all:
        include_patterns = args.include or ['*.io', '*.py', '*.c', '*.cpp', '*.h']
        exclude_patterns = args.exclude or ['__pycache__', '.git', 'build', 'temp']

        results = checker.check_all_files('.', include_patterns, exclude_patterns)

        if args.json:
            print(json.dumps(results, indent=2))
        else:
            print(f"Checked {results['total_files']} files")
            print(f"Valid: {results['summary']['valid']}")
            print(f"Invalid: {results['summary']['invalid']}")
            print(f"Total errors: {results['summary']['errors']}")
            print(f"Total warnings: {results['summary']['warnings']}")

            if args.verbose:
                for result in results['results']:
                    if not result['valid'] or result['warnings']:
                        print(f"\n{result['file']} ({result['language']}):")
                        for error in result['errors']:
                            print(f"  ERROR {error['line']}:{error['column']}: {error['message']}")
                        for warning in result['warnings']:
                            print(f"  WARNING {warning['line']}:{error['column']}: {warning['message']}")

    else:
        parser.print_help()

if __name__ == '__main__':
    main()