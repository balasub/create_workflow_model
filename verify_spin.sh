#!/bin/bash
# ============================================================================
# SPIN Verification Script for Oracle Inspection Workflow
# ============================================================================
# This script compiles and runs the SPIN model checker on the inspection
# workflow Promela specification.
# ============================================================================

set -e  # Exit on error

echo "============================================"
echo "SPIN Verification - Oracle Inspection Workflow"
echo "============================================"
echo ""

# Create results directory
mkdir -p results

# Check if SPIN is installed
if ! command -v spin &> /dev/null; then
    echo "ERROR: SPIN is not installed or not in PATH"
    echo "Please install SPIN from: http://spinroot.com/"
    exit 1
fi

# Check if model file exists
if [ ! -f "inspection_workflow.pml" ]; then
    echo "ERROR: inspection_workflow.pml not found"
    exit 1
fi

# Check if gcc is installed
if ! command -v gcc &> /dev/null; then
    echo "ERROR: gcc is not installed (required for SPIN verification)"
    exit 1
fi

echo "Step 1: Compiling Promela model..."
if spin -a inspection_workflow.pml 2>&1 | tee results/spin_compile.txt; then
    echo "✓ Promela model compiled successfully"
else
    echo "✗ Compilation failed"
    exit 1
fi

echo ""
echo "Step 2: Compiling pan verifier..."
if gcc -DMEMLIM=2048 -O2 -DXUSAFE -w -o pan pan.c 2>&1 | tee -a results/spin_compile.txt; then
    echo "✓ Pan verifier compiled successfully"
else
    echo "✗ Pan compilation failed"
    exit 1
fi

echo ""
echo "Step 3: Running verification..."
echo "This may take several minutes..."
echo ""

# Run basic verification
echo "=== Basic Verification ===" > results/spin_results.txt
if ./pan -a -N progress 2>&1 | tee -a results/spin_results.txt; then
    echo "✓ Basic verification completed"
else
    echo "⚠ Verification found issues (see results)"
fi

echo ""
echo "Step 4: Verifying LTL properties..."

# List of LTL properties to verify
LTL_PROPERTIES=(
    "progress"
    "termination"
    "quality_before_save"
    "conservation"
    "no_negative_quantities"
    "save_requires_fields"
    "opm_fields_required"
    "decision_required"
    "state_sequence"
    "can_cancel"
)

for prop in "${LTL_PROPERTIES[@]}"; do
    echo "" >> results/spin_results.txt
    echo "=== Verifying LTL Property: $prop ===" >> results/spin_results.txt

    # Generate verifier for specific LTL property
    if spin -a -N $prop inspection_workflow.pml >> results/spin_results.txt 2>&1; then
        gcc -DMEMLIM=2048 -O2 -DXUSAFE -w -o pan pan.c >> results/spin_results.txt 2>&1

        # Run verification
        if ./pan -a >> results/spin_results.txt 2>&1; then
            echo "  ✓ $prop: VERIFIED"
        else
            echo "  ✗ $prop: VIOLATED (counterexample available)"
        fi
    else
        echo "  ⚠ $prop: Compilation failed"
    fi
done

echo ""
echo "============================================"
echo "Verification Results Summary"
echo "============================================"
echo ""

# Extract statistics
if [ -f results/spin_results.txt ]; then
    echo "Statistics:"
    grep -E "(State-vector|states, stored|transitions)" results/spin_results.txt | tail -5 || echo "No statistics available"
fi

echo ""
echo "Property Results:"
echo "----------------"

# Count verified and violated properties
VERIFIED=0
VIOLATED=0

for prop in "${LTL_PROPERTIES[@]}"; do
    if grep -q "errors: 0" results/spin_results.txt; then
        VERIFIED=$((VERIFIED + 1))
    else
        VIOLATED=$((VIOLATED + 1))
    fi
done

echo "Total properties checked: ${#LTL_PROPERTIES[@]}"
echo ""

# Check for errors
if grep -q "error" results/spin_results.txt; then
    echo "⚠ WARNING: Errors found during verification"
    echo "Review results/spin_results.txt for details"
    echo ""
fi

# Check for assertion violations
if grep -q "assertion violated" results/spin_results.txt; then
    echo "⚠ WARNING: Assertion violations detected"
    echo "Review results/spin_results.txt for counterexamples"
    echo ""
fi

echo "Full results saved to: results/spin_results.txt"
echo "============================================"

# Generate trail file if verification failed
if [ -f pan.trail ]; then
    echo ""
    echo "Counterexample trace available: pan.trail"
    echo "To view: spin -t -p inspection_workflow.pml"
fi

echo ""
echo "Verification complete!"

exit 0
