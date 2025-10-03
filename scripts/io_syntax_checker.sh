#!/bin/bash

# Io Syntax Checker
# Validates Io code for best practices and syntax

echo "🔍 Checking Io syntax..."

# Find all .io files
find . -name "*.io" -type f | while read -r file; do
    echo "Checking $file..."
    
    # Basic syntax check by trying to parse
    if ! io -e "doFile(\"$file\")" 2>/dev/null; then
        echo "❌ Syntax error in $file"
        exit 1
    fi
    
    # Check for forbidden patterns
    if grep -q 'class\|extends\|new\|super' "$file"; then
        echo "❌ Class-based patterns found in $file"
        exit 1
    fi
    
    # Check for triple quotes
    if grep -q '"""' "$file"; then
        echo "❌ Triple quotes found in $file"
        exit 1
    fi
    
    echo "✅ $file OK"
done

echo "✅ All Io files syntax-checked successfully!"