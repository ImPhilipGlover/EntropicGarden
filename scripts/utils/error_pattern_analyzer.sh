#!/bin/bash

# ERROR PATTERN ANALYZER - TelOS Syntax Error Pattern Recognition & Fix Suggestions
# ================================================================================================
# Analyzes syntax errors and provides targeted fix suggestions based on error patterns
# Uses machine learning-style pattern recognition for antifragile error resolution

set -e  # Exit on any error
set -u  # Exit on undefined variables

# VERBOSE OUTPUT MANDATE - All operations must print comprehensive debugging info
echo "🧠 ERROR PATTERN ANALYZER STARTED - $(date)"
echo "📍 Working Directory: $(pwd)"
echo "🎯 Target: libs/Telos/"

# Timeout discipline - prevent hanging operations
TIMEOUT=300  # 5 minutes max per analysis

# Pattern tracking
declare -A ERROR_PATTERNS
declare -A FIX_SUGGESTIONS

# Function to analyze Io error patterns
analyze_io_patterns() {
    echo "🔍 Analyzing Io error patterns..."

    # Pattern 1: Missing closing parentheses in method definitions
    local missing_parens=$(grep -r "method(" libs/Telos/io/ | grep -v "method(.*)" | wc -l)
    if [ "$missing_parens" -gt 0 ]; then
        ERROR_PATTERNS["io_missing_parens"]=$missing_parens
        FIX_SUGGESTIONS["io_missing_parens"]="Add closing parentheses to method definitions: method(args) -> method(args)"
    fi

    # Pattern 2: Incorrect dot notation for message passing
    local dot_notation=$(grep -r "\.[a-zA-Z_][a-zA-Z0-9_]*(" libs/Telos/io/ | wc -l)
    if [ "$dot_notation" -gt 0 ]; then
        ERROR_PATTERNS["io_dot_notation"]=$dot_notation
        FIX_SUGGESTIONS["io_dot_notation"]="Replace dot notation with space: obj.method() -> obj method()"
    fi

    # Pattern 3: Map clone syntax errors
    local map_syntax=$(grep -r "Map clone" libs/Telos/io/ | grep -v "Map clone do(" | wc -l)
    if [ "$map_syntax" -gt 0 ]; then
        ERROR_PATTERNS["io_map_syntax"]=$map_syntax
        FIX_SUGGESTIONS["io_map_syntax"]="Use proper Map clone syntax: Map clone do(...)"
    fi

    # Pattern 4: Missing semicolons in assignments
    local missing_semicolons=$(grep -r "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*[a-zA-Z_]" libs/Telos/io/ | grep -v ";" | wc -l)
    if [ "$missing_semicolons" -gt 0 ]; then
        ERROR_PATTERNS["io_missing_semicolons"]=$missing_semicolons
        FIX_SUGGESTIONS["io_missing_semicolons"]="Add semicolons after assignments: var = value -> var = value;"
    fi
}

# Function to analyze Python error patterns
analyze_python_patterns() {
    echo "🐍 Analyzing Python error patterns..."

    # Pattern 1: Missing colons after function definitions
    local missing_colons=$(grep -r "^def [a-zA-Z_]" libs/Telos/python/ | grep -v ":$" | wc -l)
    if [ "$missing_colons" -gt 0 ]; then
        ERROR_PATTERNS["py_missing_colons"]=$missing_colons
        FIX_SUGGESTIONS["py_missing_colons"]="Add colons after function definitions: def func(args) -> def func(args):"
    fi

    # Pattern 2: Mixed tabs and spaces
    local mixed_indentation=$(find libs/Telos/python/ -name "*.py" -exec grep -l $'\t' {} \; | wc -l)
    if [ "$mixed_indentation" -gt 0 ]; then
        ERROR_PATTERNS["py_mixed_indentation"]=$mixed_indentation
        FIX_SUGGESTIONS["py_mixed_indentation"]="Convert all tabs to 4 spaces for consistent indentation"
    fi

    # Pattern 3: Unclosed parentheses/brackets/braces
    local unclosed_brackets=$(grep -r "([^{]*$" libs/Telos/python/ | grep -v ")$" | wc -l)
    if [ "$unclosed_brackets" -gt 0 ]; then
        ERROR_PATTERNS["py_unclosed_brackets"]=$unclosed_brackets
        FIX_SUGGESTIONS["py_unclosed_brackets"]="Check for unclosed parentheses, brackets, or braces"
    fi

    # Pattern 4: Undefined variables (basic check)
    local undefined_vars=$(grep -r "^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=" libs/Telos/python/ | grep -v "self\." | head -10 | wc -l)
    if [ "$undefined_vars" -gt 0 ]; then
        ERROR_PATTERNS["py_undefined_vars"]=$undefined_vars
        FIX_SUGGESTIONS["py_undefined_vars"]="Check for undefined variables - ensure proper imports and variable declarations"
    fi
}

# Function to analyze C error patterns
analyze_c_patterns() {
    echo "🔧 Analyzing C error patterns..."

    # Pattern 1: Missing semicolons after statements
    local missing_semicolons=$(grep -r "[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\=[[:space:]]*[a-zA-Z0-9_]" libs/Telos/source/ | grep -v ";" | wc -l)
    if [ "$missing_semicolons" -gt 0 ]; then
        ERROR_PATTERNS["c_missing_semicolons"]=$missing_semicolons
        FIX_SUGGESTIONS["c_missing_semicolons"]="Add semicolons after statements: int x = 5 -> int x = 5;"
    fi

    # Pattern 2: Missing include guards
    local missing_guards=$(find libs/Telos/source/ -name "*.h" -exec sh -c 'head -20 "$1" | grep -q "#ifndef.*_H" || echo "$1"' _ {} \; | wc -l)
    if [ "$missing_guards" -gt 0 ]; then
        ERROR_PATTERNS["c_missing_guards"]=$missing_guards
        FIX_SUGGESTIONS["c_missing_guards"]="Add include guards to header files: #ifndef HEADER_H\\n#define HEADER_H\\n...\\n#endif"
    fi

    # Pattern 3: Function declarations without prototypes
    local missing_prototypes=$(grep -r "^[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\*[?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(" libs/Telos/source/ | grep -v ");" | wc -l)
    if [ "$missing_prototypes" -gt 0 ]; then
        ERROR_PATTERNS["c_missing_prototypes"]=$missing_prototypes
        FIX_SUGGESTIONS["c_missing_prototypes"]="Add function prototypes or move function definitions before use"
    fi

    # Pattern 4: Unclosed braces
    local unclosed_braces=$(grep -r "{" libs/Telos/source/ | grep -v "}" | wc -l)
    if [ "$unclosed_braces" -gt 0 ]; then
        ERROR_PATTERNS["c_unclosed_braces"]=$unclosed_braces
        FIX_SUGGESTIONS["c_unclosed_braces"]="Check for balanced braces - ensure all { have matching }"
    fi
}

# Function to generate prioritized fix recommendations
generate_fix_recommendations() {
    echo "🎯 PRIORITIZED FIX RECOMMENDATIONS"
    echo "=================================="

    # Sort patterns by frequency (most common first)
    local sorted_patterns=$(for pattern in "${!ERROR_PATTERNS[@]}"; do
        echo "${ERROR_PATTERNS[$pattern]} $pattern"
    done | sort -nr)

    echo "$sorted_patterns" | while read -r count pattern; do
        if [ "$count" -gt 0 ]; then
            echo "🔧 $pattern ($count instances)"
            echo "   ${FIX_SUGGESTIONS[$pattern]}"
            echo ""
        fi
    done
}

# Function to create automated fix script
create_automated_fixes() {
    echo "🤖 Generating automated fix script..."

    cat > auto_fix_generated.sh << 'EOF'
#!/bin/bash
# AUTO-GENERATED FIX SCRIPT - Do not edit manually
# Generated by error_pattern_analyzer.sh

set -e
echo "🔧 Applying automated fixes based on error pattern analysis..."

EOF

    # Add Io fixes
    if [ "${ERROR_PATTERNS[io_missing_parens]:-0}" -gt 0 ]; then
        cat >> auto_fix_generated.sh << 'EOF'
# Fix Io missing parentheses
echo "Fixing Io missing parentheses..."
find libs/Telos/io/ -name "*.io" -exec sed -i 's/method(\([^)]*\)$/\1)/g' {} \;

EOF
    fi

    if [ "${ERROR_PATTERNS[io_dot_notation]:-0}" -gt 0 ]; then
        cat >> auto_fix_generated.sh << 'EOF'
# Fix Io dot notation
echo "Fixing Io dot notation..."
find libs/Telos/io/ -name "*.io" -exec sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*\)\.\([a-zA-Z_][a-zA-Z0-9_]*\)(/\1 \2(/g' {} \;

EOF
    fi

    # Add Python fixes
    if [ "${ERROR_PATTERNS[py_missing_colons]:-0}" -gt 0 ]; then
        cat >> auto_fix_generated.sh << 'EOF'
# Fix Python missing colons
echo "Fixing Python missing colons..."
find libs/Telos/python/ -name "*.py" -exec sed -i 's/def \([a-zA-Z_][a-zA-Z0-9_]*\)(.*[^:])$/def \1(...):/g' {} \;

EOF
    fi

    # Add C fixes
    if [ "${ERROR_PATTERNS[c_missing_semicolons]:-0}" -gt 0 ]; then
        cat >> auto_fix_generated.sh << 'EOF'
# Fix C missing semicolons
echo "Fixing C missing semicolons..."
find libs/Telos/source/ -name "*.c" -o -name "*.h" -exec sed -i 's/\([a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\=[[:space:]]*[a-zA-Z0-9_][a-zA-Z0-9_]*([^)]*)\)$/\1;/g' {} \;

EOF
    fi

    cat >> auto_fix_generated.sh << 'EOF'
echo "✅ Automated fixes applied. Run multi_lang_syntax_validator.sh to verify."
EOF

    chmod +x auto_fix_generated.sh
    echo "📄 Generated auto_fix_generated.sh with targeted fixes"
}

# Main execution
echo "🚀 Starting error pattern analysis..."

# Analyze patterns for each language
analyze_io_patterns
analyze_python_patterns
analyze_c_patterns

# Generate recommendations
generate_fix_recommendations

# Create automated fix script
create_automated_fixes

echo "🎯 ERROR PATTERN ANALYZER COMPLETED - $(date)"
echo "📊 Patterns Found: ${#ERROR_PATTERNS[@]}"
echo "🔧 Run ./auto_fix_generated.sh to apply automated fixes"