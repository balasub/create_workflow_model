#!/bin/bash
# ============================================================================
# NuSMV Verification Script for Oracle Inspection Workflow
# ============================================================================
# This script runs the NuSMV model checker on the inspection workflow
# specification and generates a detailed verification report.
# ============================================================================

set -e  # Exit on error

echo "============================================"
echo "NuSMV Verification - Oracle Inspection Workflow"
echo "============================================"
echo ""

# Create results directory if it doesn't exist
mkdir -p results

# Check if NuSMV is installed
if ! command -v NuSMV &> /dev/null; then
    echo "ERROR: NuSMV is not installed or not in PATH"
    echo "Please install NuSMV from: http://nusmv.fbk.eu/"
    exit 1
fi

# Check if model file exists
if [ ! -f "inspection_workflow.smv" ]; then
    echo "ERROR: inspection_workflow.smv not found"
    exit 1
fi

echo "Running NuSMV model checker..."
echo "This may take a few moments..."
echo ""

# Run NuSMV and save output
if NuSMV inspection_workflow.smv > results/nusmv_results.txt 2>&1; then
    echo "✓ NuSMV verification completed successfully"
else
    echo "✗ NuSMV verification encountered errors"
    echo "See results/nusmv_results.txt for details"
    exit 1
fi

echo ""
echo "============================================"
echo "Verification Results Summary"
echo "============================================"
echo ""

# Count properties
TOTAL_PROPS=$(grep -c "^-- specification" results/nusmv_results.txt || echo "0")
TRUE_PROPS=$(grep -c "is true" results/nusmv_results.txt || echo "0")
FALSE_PROPS=$(grep -c "is false" results/nusmv_results.txt || echo "0")

echo "Total properties verified: $TOTAL_PROPS"
echo "Properties proven TRUE:    $TRUE_PROPS"
echo "Properties proven FALSE:   $FALSE_PROPS"
echo ""

# Show each property result
echo "Property Details:"
echo "----------------"
grep -A 1 "^-- specification" results/nusmv_results.txt | grep -E "(specification|is true|is false)" || echo "No results found"

echo ""
echo "============================================"

# Check for counterexamples
if grep -q "is false" results/nusmv_results.txt; then
    echo ""
    echo "⚠ WARNING: Some properties failed verification"
    echo "Counterexamples available in results/nusmv_results.txt"
    echo ""
fi

echo "Full results saved to: results/nusmv_results.txt"
echo "============================================"

exit 0
