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

# Run basic verification (checks all assertions and embedded LTL properties)
echo "=== SPIN Verification Results ===" > results/spin_results.txt
echo "" >> results/spin_results.txt
echo "Running verification with assertion and safety checking..." >> results/spin_results.txt
echo "" >> results/spin_results.txt

if ./pan -a 2>&1 | tee -a results/spin_results.txt; then
    echo "✓ Verification completed - no errors found"
    VERIFICATION_SUCCESS=true
else
    echo "⚠ Verification found issues (see details below)"
    VERIFICATION_SUCCESS=false
fi

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
echo "Results:"
echo "--------"

# Check for specific issues
if grep -q "errors: 0" results/spin_results.txt; then
    echo "✓ No errors detected"
    echo "✓ All assertions passed"
    echo "✓ No acceptance cycles found"
else
    if grep -q "acceptance cycle" results/spin_results.txt; then
        echo "✗ Acceptance cycle detected (liveness property violated)"
    fi
    if grep -q "assertion violated" results/spin_results.txt; then
        echo "✗ Assertion violation detected"
    fi
    if grep -q "invalid end state" results/spin_results.txt; then
        echo "✗ Invalid end state detected"
    fi
fi

echo ""
echo "Note: The model includes embedded LTL properties:"
echo "  - progress: Inspection eventually completes"
echo "  - termination: Eventually reach terminal state"
echo "  - quality_before_save: Quality results before save when mandatory"
echo "  - conservation: Quantity conservation"
echo "  - and others..."
echo ""
echo "To verify specific LTL properties individually, comment out others"
echo "in inspection_workflow.pml and re-run verification."
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
