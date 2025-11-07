#!/bin/bash
# ============================================================================
# Oracle Inspection Workflow - Complete Verification Suite
# ============================================================================
# This script runs all formal verification tools, tests, and generates
# a comprehensive report.
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_step() {
    echo -e "${BLUE}[$1/$2]${NC} $3"
}

# Track results
declare -i TOTAL_STEPS=6
declare -i COMPLETED_STEPS=0
declare -i FAILED_STEPS=0

# Create results directory
mkdir -p results

# Main header
clear
print_header "Oracle Inspection Workflow - Formal Verification Suite"
echo ""
echo "This script will:"
echo "  1. Run NuSMV model checker"
echo "  2. Run SPIN model checker"
echo "  3. Run Python test suite"
echo "  4. Generate state diagrams"
echo "  5. Generate formal specification report"
echo "  6. Summarize all results"
echo ""
echo "Estimated time: 2-5 minutes"
echo ""
read -p "Press Enter to continue..."
echo ""

# Step 1: NuSMV Verification
print_step 1 $TOTAL_STEPS "Running NuSMV verification..."
echo ""

if command -v NuSMV &> /dev/null; then
    if ./verify_nusmv.sh; then
        print_success "NuSMV verification completed"
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    else
        print_error "NuSMV verification failed"
        FAILED_STEPS=$((FAILED_STEPS + 1))
    fi
else
    print_warning "NuSMV not found - skipping"
    print_warning "Install from: http://nusmv.fbk.eu/"
    FAILED_STEPS=$((FAILED_STEPS + 1))
fi

echo ""
echo "Press Enter to continue to SPIN verification..."
read
echo ""

# Step 2: SPIN Verification
print_step 2 $TOTAL_STEPS "Running SPIN verification..."
echo ""

if command -v spin &> /dev/null; then
    if command -v gcc &> /dev/null; then
        if ./verify_spin.sh; then
            print_success "SPIN verification completed"
            COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
        else
            print_error "SPIN verification failed"
            FAILED_STEPS=$((FAILED_STEPS + 1))
        fi
    else
        print_error "GCC not found (required for SPIN)"
        FAILED_STEPS=$((FAILED_STEPS + 1))
    fi
else
    print_warning "SPIN not found - skipping"
    print_warning "Install from: http://spinroot.com/"
    FAILED_STEPS=$((FAILED_STEPS + 1))
fi

echo ""
echo "Press Enter to continue to test suite..."
read
echo ""

# Step 3: Test Suite
print_step 3 $TOTAL_STEPS "Running Python test suite..."
echo ""

if command -v python3 &> /dev/null; then
    if python3 test_scenarios.py; then
        print_success "Test suite completed"
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    else
        print_error "Some tests failed"
        FAILED_STEPS=$((FAILED_STEPS + 1))
    fi
else
    print_error "Python 3 not found"
    FAILED_STEPS=$((FAILED_STEPS + 1))
fi

echo ""
echo "Press Enter to continue to visualization..."
read
echo ""

# Step 4: Generate Visualizations
print_step 4 $TOTAL_STEPS "Generating state diagrams..."
echo ""

if command -v python3 &> /dev/null; then
    if python3 visualize_states.py; then
        print_success "State diagrams generated"
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    else
        print_warning "Visualization failed (graphviz may not be installed)"
        FAILED_STEPS=$((FAILED_STEPS + 1))
    fi
else
    print_error "Python 3 not found"
    FAILED_STEPS=$((FAILED_STEPS + 1))
fi

echo ""
echo "Press Enter to continue to report generation..."
read
echo ""

# Step 5: Generate Report
print_step 5 $TOTAL_STEPS "Generating formal specification report..."
echo ""

if command -v python3 &> /dev/null; then
    if python3 generate_report.py; then
        print_success "Report generated: FORMAL_SPECIFICATION_REPORT.md"
        COMPLETED_STEPS=$((COMPLETED_STEPS + 1))
    else
        print_error "Report generation failed"
        FAILED_STEPS=$((FAILED_STEPS + 1))
    fi
else
    print_error "Python 3 not found"
    FAILED_STEPS=$((FAILED_STEPS + 1))
fi

echo ""
COMPLETED_STEPS=$((COMPLETED_STEPS + 1))  # For summary step

# Step 6: Summary
echo ""
print_header "Verification Complete!"
echo ""

print_step 6 $TOTAL_STEPS "Summary of Results"
echo ""

# Display summary
echo "Results Overview:"
echo "----------------"
echo "Steps completed:    $COMPLETED_STEPS / $TOTAL_STEPS"
echo "Steps failed:       $FAILED_STEPS"
echo ""

# Check what's available
echo "Available Results:"
echo ""

if [ -f "results/nusmv_results.txt" ]; then
    print_success "NuSMV Results: results/nusmv_results.txt"
    # Quick summary
    TRUE_PROPS=$(grep -c "is true" results/nusmv_results.txt || echo "0")
    FALSE_PROPS=$(grep -c "is false" results/nusmv_results.txt || echo "0")
    echo "  - Properties TRUE:  $TRUE_PROPS"
    echo "  - Properties FALSE: $FALSE_PROPS"
else
    print_warning "NuSMV results not available"
fi
echo ""

if [ -f "results/spin_results.txt" ]; then
    print_success "SPIN Results: results/spin_results.txt"
    if grep -q "error" results/spin_results.txt; then
        print_warning "  - Errors detected in SPIN verification"
    else
        echo "  - No errors detected"
    fi
else
    print_warning "SPIN results not available"
fi
echo ""

if [ -f "results/state_diagram.png" ]; then
    print_success "State Diagrams: results/*.png"
    ls results/*.png 2>/dev/null | sed 's/^/  - /'
else
    print_warning "State diagrams not available"
fi
echo ""

if [ -f "FORMAL_SPECIFICATION_REPORT.md" ]; then
    print_success "Formal Report: FORMAL_SPECIFICATION_REPORT.md"
else
    print_warning "Formal report not available"
fi
echo ""

# Display next steps
print_header "Next Steps"
echo ""
echo "1. Review the formal specification report:"
echo "   $ cat FORMAL_SPECIFICATION_REPORT.md"
echo ""
echo "2. View state diagrams (if generated):"
echo "   $ xdg-open results/state_diagram.png  # Linux"
echo "   $ open results/state_diagram.png      # macOS"
echo ""
echo "3. Review detailed verification results:"
echo "   $ cat results/nusmv_results.txt"
echo "   $ cat results/spin_results.txt"
echo ""
echo "4. Run specific verifications again:"
echo "   $ make nusmv    # Run NuSMV only"
echo "   $ make spin     # Run SPIN only"
echo "   $ make test     # Run tests only"
echo ""
echo "5. Check prerequisites if tools were not found:"
echo "   $ make check"
echo ""

print_header "Verification Suite Complete"
echo ""

if [ $FAILED_STEPS -eq 0 ]; then
    print_success "All verification steps completed successfully!"
    exit 0
else
    print_warning "Some verification steps failed or were skipped"
    print_warning "Run 'make check' to verify prerequisites"
    exit 1
fi
