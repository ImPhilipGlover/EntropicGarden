#!/bin/bash

# TelOS Build Wrapper with Mandatory Documentation Review
# CRITICAL: Automatically triggers full documentation review on ANY build failure
# This ensures AI assistant reviews all architectural requirements before proceeding

echo "=========================================="
echo "TelOS Build Process Starting"
echo "=========================================="

# Run the actual build
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
    echo "AI ASSISTANT MUST REVIEW ALL FILES BEFORE PROCEEDING"
    echo ""

    # Trigger comprehensive documentation review
    ./trigger_doc_review.sh

    echo ""
    echo "=========================================="
    echo "MANDATORY REVIEW COMPLETED"
    echo "=========================================="
    echo "AI assistant has been presented with all documentation."
    echo "Development may only continue after full review and understanding."
    echo ""

    # Create persistent review flag for AI to check
    echo "MANDATORY_REVIEW_COMPLETED=false" > .last_build_failed
    echo "Build failed at: $(date)" >> .last_build_failed
    echo "AI must acknowledge review before next development action" >> .last_build_failed

else
    echo ""
    echo "=========================================="
    echo "BUILD SUCCESSFUL"
    echo "=========================================="

    # Clear any previous failure flags
    rm -f .last_build_failed
fi

# Return the original build exit code
exit $BUILD_EXIT_CODE