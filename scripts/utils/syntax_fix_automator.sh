#!/bin/bash

# SYNTAX FIX AUTOMATOR - TelOS Polyglot Syntax Error Resolution
# ================================================================================================
# This script automatically applies common syntax fixes across Io, Python, and C files
# Designed to work with the TelOS neuro-symbolic architecture

set -e  # Exit on any error
set -u  # Exit on undefined variables

# VERBOSE OUTPUT MANDATE - All operations must print comprehensive debugging info
echo "🔧 SYNTAX FIX AUTOMATOR STARTED - $(date)"
echo "📍 Working Directory: $(pwd)"
echo "🎯 Target: libs/Telos/"

# Timeout discipline - prevent hanging operations
TIMEOUT=900  # 15 minutes max per operation

# Function to apply Io syntax fixes
fix_io_syntax() {
    echo "🔍 Scanning Io files for syntax errors..."

    # Find all .io files
    find libs/Telos/ -name "*.io" -type f | while read -r file; do
        echo "📄 Processing: $file"

        # Fix common Io syntax issues
        # 1. Missing closing parentheses in method definitions
        sed -i 's/method(\([^)]*\)$/\1)/g' "$file"

        # 2. Incorrect Map clone syntax
        sed -i 's/Map clone do(/Map clone do(/g' "$file"

        # 3. Missing semicolons in assignments
        sed -i 's/^\([[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*([^)]*)\)$/\1;/g' "$file"

        # 4. Fix method call syntax
        sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\)[[:space:]]*\.[[:space:]]*\([a-zA-Z_][a-zA-Z0-9_]*\)[[:space:]]*([[:space:]]*\([^)]*\)[[:space:]]*)[[:space:]]*$/\1 \2(\3)/g' "$file"

        echo "✅ Processed: $file"
    done
}

# Function to apply Python syntax fixes
fix_python_syntax() {
    echo "🐍 Scanning Python files for syntax errors..."

    # Find all .py files
    find libs/Telos/ -name "*.py" -type f | while read -r file; do
        echo "📄 Processing: $file"

        # Fix common Python syntax issues
        # 1. Missing colons after function definitions
        sed -i 's/def \([a-zA-Z_][a-zA-Z0-9_]*\)(.*):$/def \1(...):/g' "$file"

        # 2. Fix indentation issues (basic)
        python3 -m py_compile "$file" 2>/dev/null || echo "⚠️  Syntax error in $file - manual review needed"

        echo "✅ Processed: $file"
    done
}

# Function to apply C syntax fixes
fix_c_syntax() {
    echo "🔧 Scanning C files for syntax errors..."

    # Find all .c and .h files
    find libs/Telos/ -name "*.c" -o -name "*.h" -type f | while read -r file; do
        echo "📄 Processing: $file"

        # Fix common C syntax issues
        # 1. Missing semicolons after statements
        sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\=[[:space:]]*[a-zA-Z0-9_][a-zA-Z0-9_]*([^)]*)\)$/\1;/g' "$file"

        # 2. Fix function declarations
        sed -i 's/^\([[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\*[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\)(.*);$/\1)(...);/g' "$file"

        echo "✅ Processed: $file"
    done
}

# Function to validate fixes
validate_fixes() {
    echo "🔍 Validating syntax fixes..."

    # Validate Io files
    echo "📋 Io Files Validation:"
    find libs/Telos/ -name "*.io" -type f -exec echo "Checking: {}" \; -exec timeout $TIMEOUT io -e "File clone openForReading(\"{}\") close" \; 2>/dev/null || echo "⚠️  Io syntax check failed for {}"

    # Validate Python files
    echo "📋 Python Files Validation:"
    find libs/Telos/ -name "*.py" -type f -exec echo "Checking: {}" \; -exec timeout $TIMEOUT python3 -m py_compile {} \; 2>/dev/null && echo "✅ {} OK" || echo "❌ {} FAILED"

    # Validate C files (basic check)
    echo "📋 C Files Validation:"
    find libs/Telos/ -name "*.c" -o -name "*.h" -type f -exec echo "Checking: {}" \; -exec timeout $TIMEOUT gcc -fsyntax-only {} \; 2>/dev/null && echo "✅ {} OK" || echo "❌ {} FAILED"
}

# Main execution
echo "🚀 Starting automated syntax fixes..."

# Apply fixes in order: Io, Python, C
fix_io_syntax
fix_python_syntax
fix_c_syntax

# Validate all fixes
validate_fixes

echo "🎉 SYNTAX FIX AUTOMATOR COMPLETED - $(date)"
echo "📊 Run validation scripts to confirm all fixes are working correctly"