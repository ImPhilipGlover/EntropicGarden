#!/bin/bash

# TelOS Build Wrapper with Mandatory Documentation Review
# CRITICAL: Forces VS Code Task to show documentation review errors on ANY build failure
# This ensures AI assistant reviews all architectural requirements on every failure

echo "=========================================="
echo "TelOS Build Process Starting"
echo "=========================================="

# Always attempt the build first - no pre-check blocking
cd build
make "$@"

# Capture exit code
BUILD_EXIT_CODE=$?

cd ..

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo ""
    echo "=========================================="
    echo "BUILD FAILED - EXIT CODE: $BUILD_EXIT_CODE"
    echo "=========================================="
    echo "CRITICAL VIOLATION: Build failure detected!"
    echo "MANDATORY DOCUMENTATION REVIEW REQUIRED"
    echo ""

    # ALWAYS trigger comprehensive documentation review on ANY failure
    # This will output VS Code-compatible errors and exit with code 1
    # Making the VS Code Task reliably show problems
    ./trigger_doc_review.sh

    echo ""
    echo "=========================================="
    echo "MANDATORY REVIEW COMPLETED"
    echo "=========================================="
    echo "VS Code should now show documentation review errors in Problems panel."
    echo "AI assistant must acknowledge full review before any development activity."
    echo ""

    # Exit with error to ensure VS Code task shows as failed
    exit 1

else
    echo ""
    echo "=========================================="
    echo "BUILD SUCCESSFUL"
    echo "=========================================="
fi

# Return the original build exit code
exit $BUILD_EXIT_CODE

