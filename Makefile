# ============================================================================
# Oracle Inspection Workflow - Formal Verification Makefile
# ============================================================================
# This Makefile automates building, verification, and testing of the
# inspection workflow formal specifications.
# ============================================================================

.PHONY: all help clean nusmv spin formula test visualize process-diagram diagrams report

# Default target
all: nusmv spin formula test diagrams report

# Help target
help:
	@echo "============================================================================"
	@echo "Oracle Inspection Workflow - Formal Verification"
	@echo "============================================================================"
	@echo ""
	@echo "Available targets:"
	@echo "  make all        - Run all verifications, tests, and generate report"
	@echo "  make nusmv      - Run NuSMV model checker"
	@echo "  make spin       - Run SPIN model checker"
	@echo "  make formula    - Run FORMULA verification"
	@echo "  make test       - Run Python test suite"
	@echo "  make visualize  - Generate state diagrams (Python)"
	@echo "  make process-diagram - Generate process diagram (Graphviz)"
	@echo "  make diagrams   - Generate all diagrams"
	@echo "  make report     - Generate formal specification report"
	@echo "  make clean      - Clean generated files"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - NuSMV: http://nusmv.fbk.eu/"
	@echo "  - FORMULA: https://github.com/VUISIS/formula"
	@echo "  - SPIN: http://spinroot.com/"
	@echo "  - Python 3.x with packages: pip install -r requirements.txt"
	@echo "  - Graphviz: https://graphviz.org/"
	@echo ""
	@echo "============================================================================"

# Create results directory
results:
	@mkdir -p results

# NuSMV verification
nusmv: results
	@echo "============================================================================"
	@echo "Running NuSMV verification..."
	@echo "============================================================================"
	@if command -v NuSMV >/dev/null 2>&1; then \
		./verify_nusmv.sh; \
	else \
		echo "✗ NuSMV not found - skipping"; \
		echo "Install from: http://nusmv.fbk.eu/"; \
	fi
	@echo ""

# SPIN verification
spin: results
	@echo "============================================================================"
	@echo "Running SPIN verification..."
	@echo "============================================================================"
	@if command -v spin >/dev/null 2>&1; then \
		./verify_spin.sh; \
	else \
		echo "✗ SPIN not found - skipping"; \
		echo "Install from: http://spinroot.com/"; \
	fi
	@echo ""

# FORMULA verification
formula: results
	@echo "============================================================================"
	@echo "Running FORMULA verification..."
	@echo "============================================================================"
	@if command -v formula >/dev/null 2>&1; then \
		./verify_formula.sh; \
	else \
		echo "✗ FORMULA not found - skipping"; \
		echo "Install from: https://github.com/VUISIS/formula"; \
		echo "Or via dotnet: dotnet tool install --global formula"; \
	fi
	@echo ""

# P verification (note: requires P compiler)
p: results
	@echo "============================================================================"
	@echo "Running P verification..."
	@echo "============================================================================"
	@if command -v pc >/dev/null 2>&1; then \
		pc InspectionWorkflow.p; \
		./InspectionWorkflow.exe > results/p_results.txt; \
		echo "✓ P verification complete"; \
	else \
		echo "⚠ P compiler not found - skipping"; \
		echo "Install from: https://github.com/p-org/P"; \
	fi
	@echo ""

# Run test suite
test:
	@echo "============================================================================"
	@echo "Running test suite..."
	@echo "============================================================================"
	@if command -v python3 >/dev/null 2>&1; then \
		python3 test_scenarios.py; \
	else \
		echo "✗ Python 3 not found"; \
	fi
	@echo ""

# Generate state diagrams (Python)
visualize: results
	@echo "============================================================================"
	@echo "Generating state diagrams..."
	@echo "============================================================================"
	@if command -v python3 >/dev/null 2>&1; then \
		python3 visualize_states.py; \
	else \
		echo "✗ Python 3 not found"; \
	fi
	@echo ""

# Generate process diagram (Graphviz)
process-diagram: results
	@echo "============================================================================"
	@echo "Generating process diagram..."
	@echo "============================================================================"
	@if command -v dot >/dev/null 2>&1; then \
		./generate_process_diagram.sh; \
	else \
		echo "✗ Graphviz (dot) not found"; \
		echo "Install: sudo apt-get install graphviz  (Linux)"; \
		echo "         brew install graphviz  (macOS)"; \
	fi
	@echo ""

# Generate all diagrams
diagrams: visualize process-diagram

# Generate report
report: results
	@echo "============================================================================"
	@echo "Generating formal specification report..."
	@echo "============================================================================"
	@if command -v python3 >/dev/null 2>&1; then \
		python3 generate_report.py; \
		echo ""; \
		echo "✓ Report generated: FORMAL_SPECIFICATION_REPORT.md"; \
	else \
		echo "✗ Python 3 not found"; \
	fi
	@echo ""

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -f pan pan.* _spin_nvr.tmp *.trail
	@rm -rf results/*
	@rm -f FORMAL_SPECIFICATION_REPORT.md
	@rm -f *.pyc __pycache__
	@echo "✓ Clean complete"

# Quick verification (NuSMV only)
quick: results
	@echo "Running quick verification (NuSMV only)..."
	@$(MAKE) nusmv
	@$(MAKE) report

# Full verification with all tools
full: results
	@echo "============================================================================"
	@echo "Running full verification suite..."
	@echo "============================================================================"
	@$(MAKE) nusmv
	@$(MAKE) spin
	@$(MAKE) formula
	@$(MAKE) p
	@$(MAKE) test
	@$(MAKE) diagrams
	@$(MAKE) report
	@echo ""
	@echo "============================================================================"
	@echo "Full verification complete!"
	@echo "============================================================================"
	@echo "Results:"
	@echo "  - NuSMV:        results/nusmv_results.txt"
	@echo "  - SPIN:         results/spin_results.txt"
	@echo "  - FORMULA:      results/formula_results.txt"
	@echo "  - P:            results/p_results.txt"
	@echo "  - Test Suite:   (console output)"
	@echo "  - Diagrams:     results/*.png"
	@echo "  - Report:       FORMAL_SPECIFICATION_REPORT.md"
	@echo "============================================================================"

# Install Python dependencies
install-deps:
	@echo "Installing Python dependencies..."
	@if command -v pip3 >/dev/null 2>&1; then \
		pip3 install -r requirements.txt; \
		echo "✓ Dependencies installed"; \
	else \
		echo "✗ pip3 not found"; \
	fi

# Check prerequisites
check:
	@echo "============================================================================"
	@echo "Checking prerequisites..."
	@echo "============================================================================"
	@echo -n "NuSMV:     "
	@if command -v NuSMV >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Not found (http://nusmv.fbk.eu/)"; \
	fi
	@echo -n "SPIN:      "
	@if command -v spin >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Not found (http://spinroot.com/)"; \
	fi
	@echo -n "FORMULA:   "
	@if command -v formula >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Not found (https://github.com/VUISIS/formula)"; \
	fi
	@echo -n "GCC:       "
	@if command -v gcc >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Not found (required for SPIN)"; \
	fi
	@echo -n "Python 3:  "
	@if command -v python3 >/dev/null 2>&1; then \
		python3 --version | sed 's/Python /✓ /'; \
	else \
		echo "✗ Not found"; \
	fi
	@echo -n "Graphviz:  "
	@if command -v dot >/dev/null 2>&1; then \
		echo "✓ Found"; \
	else \
		echo "✗ Not found (https://graphviz.org/)"; \
	fi
	@echo "============================================================================"

# ============================================================================
# END OF MAKEFILE
# ============================================================================
