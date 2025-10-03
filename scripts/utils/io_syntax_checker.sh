#!/bin/bash
# Io Syntax Error Detector - Identifies Map clone do() patterns that should be Map clone with atPut()

echo "🔍 Io Syntax Error Detector"
echo "=========================="
echo ""

# Find all Io files with Map clone do() patterns
echo "Scanning for Map clone do() patterns (potential syntax errors)..."
echo ""

find . -name "*.io" -exec grep -l "Map clone do(" {} \; | while read file; do
    echo "📁 $file"
    grep -n "Map clone do(" "$file" | head -3 | while IFS=: read line_num pattern; do
        echo "  Line $line_num: $pattern"
    done
    echo ""
done

echo "✅ Scan complete. Files with Map clone do() patterns may need conversion to Map clone with atPut() calls."
echo ""
echo "💡 Recommendation: Replace 'Map clone do(' with 'Map clone' followed by atPut() calls"
echo "   Example: Map clone do( key := value ) → Map clone atPut(\"key\", value)"