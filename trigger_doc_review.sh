#!/bin/bash

# TelOS Mandatory Documentation Review Script
# CRITICAL: Forces AI to review all mandatory documentation on errors
# Outputs VS Code-compatible error messages for proper task integration

echo "=========================================="
echo "MANDATORY DOCUMENTATION REVIEW TRIGGERED"
echo "=========================================="
echo "Build error or prototype violation detected."
echo "AI MUST review all mandatory documentation files NOW"
echo ""

# Create documentation review flag file
REVIEW_FLAG=".documentation_review_required"
echo "Creating documentation review requirement flag..."
cat > "$REVIEW_FLAG" << 'EOF'
MANDATORY DOCUMENTATION REVIEW REQUIRED
======================================

CRITICAL VIOLATION DETECTED: Build error or prototype violation occurred.

AI ASSISTANT MUST IMMEDIATELY:
1. Read ALL mandatory documentation files in their entirety
2. Acknowledge understanding of each file's content
3. Verify compliance with architectural requirements
4. Only proceed with development after full review

MANDATORY DOCUMENTATION FILES:
EOF

# List of mandatory documentation files
MANDATORY_DOCS=(
    "AI System Design Instructions.txt"
    "Building TelOS with Io and Morphic.txt"
    "Io Morphic UI with WSLg SDL2.txt"
    "Io Prototype Programming Training Guide.txt"
    "Io, C, and Python System Design.txt"
    "Mathematical Functions For Knowledge Discovery.txt"
    "Morphic UI Framework Training Guide Extension.txt"
    "Neuro-Symbolic Reasoning Cycle Implementation Plan.txt"
    "Prototypal Emulation Layer Design.txt"
    "Researching AI System Design Appendix.txt"
    "docs/IoCodingStandards.html"
    "docs/IoGuide.html"
    "docs/IoTutorial.html"
    ".github/copilot-instructions.md"
)

# Add files to review flag
for doc in "${MANDATORY_DOCS[@]}"; do
    echo "1. $doc" >> "$REVIEW_FLAG"
done

echo "" >> "$REVIEW_FLAG"
echo "REVIEW STATUS: NOT STARTED" >> "$REVIEW_FLAG"
echo "AI must read each file and update this status to 'COMPLETED'" >> "$REVIEW_FLAG"

# Output VS Code-compatible error messages for each missing/unreviewed file
echo ""
echo "=========================================="
echo "VS CODE PROBLEM REPORT"
echo "=========================================="

# Generate error messages in GCC format that VS Code can parse
for doc in "${MANDATORY_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        # File exists but needs review - report as error
        echo "$doc:1:1: error: Mandatory documentation file '$doc' requires immediate review by AI assistant"
        echo "$doc:1:1: error: CRITICAL VIOLATION: Documentation review not completed for '$doc'"
        echo "$doc:1:1: error: AI must read and understand all architectural requirements in '$doc'"
    else
        # File missing - critical error
        echo "MISSING_DOC:1:1: error: CRITICAL VIOLATION: Mandatory documentation file '$doc' is missing from workspace"
        echo "MISSING_DOC:1:1: error: SEVERE ARCHITECTURAL VIOLATION: Required file '$doc' not found"
    fi
done

# Additional critical errors for the review process
echo "REVIEW_PROCESS:1:1: error: CRITICAL VIOLATION: Documentation review status is 'NOT STARTED'"
echo "REVIEW_PROCESS:1:1: error: AI ASSISTANT MUST: Read all mandatory documentation files immediately"
echo "REVIEW_PROCESS:1:1: error: AI ASSISTANT MUST: Acknowledge understanding of architectural requirements"
echo "REVIEW_PROCESS:1:1: error: AI ASSISTANT MUST: Update .documentation_review_required status to 'COMPLETED'"
echo "REVIEW_PROCESS:1:1: error: DEVELOPMENT FORBIDDEN: No code changes allowed until review completed"

# Final VS Code error to ensure task shows as failed
echo "BUILD_BLOCKED:1:1: error: CRITICAL VIOLATION: Build blocked until documentation review completed"
echo "BUILD_BLOCKED:1:1: error: AI assistant must acknowledge full review before any development activity"

# Exit with error code to ensure VS Code task shows as failed
exit 1