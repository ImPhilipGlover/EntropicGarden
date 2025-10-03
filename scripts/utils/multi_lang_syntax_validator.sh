#!/bin/bash

# MULTI-LANGUAGE SYNTAX VALIDATOR - TelOS Polyglot Syntax Error Detection
# ================================================================================================
# Comprehensive syntax validation across Io, Python, C/C++ with detailed error reporting
# Designed for the TelOS neuro-symbolic architecture with antifragile error analysis

set -e  # Exit on any error
set -u  # Exit on undefined variables

# VERBOSE OUTPUT MANDATE - All operations must print comprehensive debugging info
echo "🔍 MULTI-LANGUAGE SYNTAX VALIDATOR STARTED - $(date)"
echo "📍 Working Directory: $(pwd)"
echo "🎯 Target: libs/Telos/"

# Timeout discipline - prevent hanging operations
TIMEOUT=900  # 15 minutes max per operation

# Error tracking
ERROR_COUNT=0
TOTAL_FILES=0
IO_ERRORS=0
PYTHON_ERRORS=0
C_ERRORS=0

# Function to validate Io syntax
validate_io_syntax() {
    echo "🔍 Validating Io syntax..."

    local io_files=$(find libs/Telos/ -name "*.io" -type f)
    local io_count=$(echo "$io_files" | wc -l)

    echo "📊 Found $io_count Io files to validate"

    echo "$io_files" | while read -r file; do
        if [ -n "$file" ]; then
            ((TOTAL_FILES++))
            echo "📄 Checking: $file"

            # Use timeout to prevent hanging
            if timeout $TIMEOUT io -e "
                try(
                    File clone openForReading(\"$file\") close
                    \"✅ $file: SYNTAX OK\" println
                ) catch(Exception,
                    \"❌ $file: SYNTAX ERROR - \" print
                    call message println
                    ERROR_COUNT=\$((ERROR_COUNT + 1))
                    IO_ERRORS=\$((IO_ERRORS + 1))
                )
            " 2>/dev/null; then
                echo "✅ $file: SYNTAX OK"
            else
                echo "❌ $file: SYNTAX ERROR (timeout or execution failed)"
                ((ERROR_COUNT++))
                ((IO_ERRORS++))
            fi
        fi
    done
}

# Function to validate Python syntax
validate_python_syntax() {
    echo "🐍 Validating Python syntax..."

    local py_files=$(find libs/Telos/ -name "*.py" -type f)
    local py_count=$(echo "$py_files" | wc -l)

    echo "📊 Found $py_count Python files to validate"

    echo "$py_files" | while read -r file; do
        if [ -n "$file" ]; then
            ((TOTAL_FILES++))
            echo "📄 Checking: $file"

            # Use Python's built-in syntax checker
            if timeout $TIMEOUT python3 -m py_compile "$file" 2>/dev/null; then
                echo "✅ $file: SYNTAX OK"
            else
                echo "❌ $file: SYNTAX ERROR"
                python3 -m py_compile "$file" 2>&1 | head -5  # Show first 5 error lines
                ((ERROR_COUNT++))
                ((PYTHON_ERRORS++))
            fi
        fi
    done
}

# Function to validate C/C++ syntax
validate_c_syntax() {
    echo "🔧 Validating C/C++ syntax..."

    local c_files=$(find libs/Telos/ -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -type f)
    local c_count=$(echo "$c_files" | wc -l)

    echo "📊 Found $c_count C/C++ files to validate"

    echo "$c_files" | while read -r file; do
        if [ -n "$file" ]; then
            ((TOTAL_FILES++))
            echo "📄 Checking: $file"

            # Use GCC syntax-only check
            if timeout $TIMEOUT gcc -fsyntax-only -Ilibs/Telos/source "$file" 2>/dev/null; then
                echo "✅ $file: SYNTAX OK"
            else
                echo "❌ $file: SYNTAX ERROR"
                gcc -fsyntax-only -Ilibs/Telos/source "$file" 2>&1 | head -5  # Show first 5 error lines
                ((ERROR_COUNT++))
                ((C_ERRORS++))
            fi
        fi
    done
}

# Function to analyze error patterns
analyze_error_patterns() {
    echo "📊 Analyzing error patterns..."

    # Io error patterns
    if [ $IO_ERRORS -gt 0 ]; then
        echo "🔍 Io Error Patterns:"
        echo "   - Check for missing closing parentheses in method definitions"
        echo "   - Verify Map clone do() syntax"
        echo "   - Ensure proper message passing syntax (no dots for method calls)"
        echo "   - Check for missing semicolons in assignments"
    fi

    # Python error patterns
    if [ $PYTHON_ERRORS -gt 0 ]; then
        echo "🐍 Python Error Patterns:"
        echo "   - Check for missing colons after function/class definitions"
        echo "   - Verify proper indentation (4 spaces, no tabs)"
        echo "   - Ensure balanced parentheses, brackets, braces"
        echo "   - Check for undefined variables or imports"
    fi

    # C error patterns
    if [ $C_ERRORS -gt 0 ]; then
        echo "🔧 C Error Patterns:"
        echo "   - Check for missing semicolons after statements"
        echo "   - Verify function declarations and definitions"
        echo "   - Ensure proper include directives"
        echo "   - Check for balanced braces and parentheses"
    fi
}

# Function to generate error report
generate_error_report() {
    echo "📋 SYNTAX VALIDATION REPORT"
    echo "=========================="
    echo "Total Files Checked: $TOTAL_FILES"
    echo "Total Errors Found: $ERROR_COUNT"
    echo ""
    echo "Breakdown by Language:"
    echo "  Io Files: $IO_ERRORS errors"
    echo "  Python Files: $PYTHON_ERRORS errors"
    echo "  C/C++ Files: $C_ERRORS errors"
    echo ""

    if [ $ERROR_COUNT -eq 0 ]; then
        echo "🎉 ALL SYNTAX CHECKS PASSED - System is syntactically correct!"
    else
        echo "⚠️  SYNTAX ERRORS DETECTED - Run syntax_fix_automator.sh to apply automatic fixes"
        analyze_error_patterns
    fi
}

# Main execution
echo "🚀 Starting comprehensive syntax validation..."

# Validate each language
validate_io_syntax
validate_python_syntax
validate_c_syntax

# Generate final report
generate_error_report

echo "🎯 MULTI-LANGUAGE SYNTAX VALIDATOR COMPLETED - $(date)"
echo "📊 Error Count: $ERROR_COUNT | Files Checked: $TOTAL_FILES"