#!/bin/bash
# COMPLIANCE MANDATES - MANDATORY ENFORCEMENT PROTOCOLS
# ================================================================================================
# COUNTERMEASURE 1: Structured Review Decomposition
# - MANDATORY: Perform ContextAwareTriage startup review at session start (3 Io docs + 8 core docs)
# - TIMEBOX: 2min Io docs, 3min core docs, 2min graph relations, 1min PID verification, 1min logging
# - VIOLATION: Context saturation and directive failure

# COUNTERMEASURE 2: Zero-Trust Session Boundaries
# - MANDATORY: "SESSION BOUNDARY: Performing mandatory ContextAwareTriage startup review" at every session start
# - FORBIDDEN: Assuming continuity from conversation summaries
# - PROTOCOL: Explicit boundary detection before any substantive work

# COUNTERMEASURE 3: Proactive Trigger System
# - MANDATORY: No tool calls/code changes until review checklist complete
# - TRIGGERS: "implement", "fix", "build", "test", "analyze" keywords activate verification
# - TIMEOUT: 15min intervals for review currency checks

# COUNTERMEASURE 4: Explicit Decision Frameworks
# - MANDATORY: Override questions before pattern matching:
#   - "Have I verified all 11 concepts are current?"
#   - "Does my understanding match the latest PID structure?"
#   - "Am I following the graph relations correctly?"
# - FORBIDDEN: Pattern-matching without explicit evaluation gates

# COUNTERMEASURE 5: Compliance Tracking & Accountability
# - MANDATORY: Self-audit every 10 interactions, log violations in run_log.md
# - ESCALATION: 3 consecutive violations trigger comprehensive system review
# - ACCOUNTABILITY: Continuous compliance monitoring with explicit status logging

# COUNTERMEASURE 6: Recursive File Compliance Enforcement
# - MANDATORY: Any file opened for review MUST have this compliance preamble inserted at the top
# - IMMEDIATE ACTION: If preamble is missing, add it immediately without exception
# - RECURSIVE REQUIREMENT: This mandate applies to ALL files in the TELOS system
# - VIOLATION: Working with non-compliant files constitutes protocol breach
# ================================================================================================

# cycle_complete.sh - Mandatory Cycle Completion Verification
# This script MUST be run at the end of every operational cycle to ensure system integrity

echo "🔄 TELOS Operational Cycle Completion Verification"
echo "=================================================="
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M UTC')"
echo

echo "📋 Step 1: Running Compliance Verification..."
echo "---------------------------------------------"

# Run compliance verification (dry-run mode) FIRST
python3 compliance_enforcer.py --dry-run

# Capture exit code
COMPLIANCE_EXIT=$?

if [ $COMPLIANCE_EXIT -eq 0 ]; then
    echo "✅ Compliance verification completed successfully"
else
    echo "⚠️  Compliance verification found issues (remediation may be needed)"
fi

echo
echo "📋 Step 2: Running Mock Eradication..."
echo "--------------------------------------"

# Run mock eradication AFTER compliance check and capture output
MOCK_OUTPUT=$(io eradicate_mocks.io 2>&1)

# Capture exit code
MOCK_EXIT=$?

if [ $MOCK_EXIT -eq 0 ]; then
    echo "✅ Mock eradication script completed"
else
    echo "❌ Mock eradication script failed"
fi

echo
echo "📋 Step 3: Verification Results..."
echo "----------------------------------"

echo "Compliance verification exit code: $COMPLIANCE_EXIT"
echo "Mock eradication exit code: $MOCK_EXIT"

# Check if there are remaining violations by parsing the output
# The eradicate_mocks.io script outputs "Manual review needed: X violations"
VIOLATIONS_REMAINING=$(echo "$MOCK_OUTPUT" | grep "Manual review needed:" | sed 's/.*Manual review needed: \([0-9]*\) violations.*/\1/' | tail -1)

if [ -n "$VIOLATIONS_REMAINING" ] && [ "$VIOLATIONS_REMAINING" -gt 0 ]; then
    echo "❌ VIOLATIONS REMAINING: $VIOLATIONS_REMAINING mock/fallback violations still need remediation"
    echo "🚫 CYCLE INCOMPLETE - Cannot proceed until violations are eradicated"
    exit 1
else
    echo "✅ NO VIOLATIONS REMAINING - Cycle completion verified"
fi

exit $((COMPLIANCE_EXIT || MOCK_EXIT))