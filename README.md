# Oracle Purchasing Inspection Workflow - Formal Specifications

This repository contains formal specifications for the Oracle Purchasing "Inspecting Received Items" workflow using multiple formal verification tools.

## Overview

The inspection workflow has been formally modeled and verified using:

- **NuSMV** - Symbolic model checking with CTL (Computational Tree Logic)
- **SPIN** - Protocol verification with LTL (Linear Temporal Logic)
- **FORMULA** - Domain-specific language specifications with constraint solving
- **P** - Event-driven state machine modeling

The formal specifications verify critical properties including:
- Quantity conservation
- Required field validation
- Integration constraints (Oracle Quality, OPM)
- State transition correctness
- Liveness and progress guarantees

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd create_workflow_model

# Install Python dependencies
pip install -r requirements.txt

# Check prerequisites
make check

# Run all verifications
make all

# Or use the interactive script
./run_all_verifications.sh
```

## Prerequisites

### Required Tools

1. **Python 3.x**
   - Ubuntu/Debian: `sudo apt-get install python3 python3-pip`
   - macOS: `brew install python3`
   - Windows: https://www.python.org/downloads/

2. **NuSMV** (for model checking)
   - Download: http://nusmv.fbk.eu/
   - Ubuntu/Debian: `sudo apt-get install nusmv`
   - macOS: `brew install nusmv`

3. **SPIN** (for protocol verification)
   - Download: http://spinroot.com/
   - Ubuntu/Debian: `sudo apt-get install spin`
   - macOS: `brew install spin`

4. **FORMULA** (for domain specification and constraint solving)
   - GitHub: https://github.com/VUISIS/formula
   - Install via dotnet: `dotnet tool install --global formula`
   - Requires .NET SDK: https://dotnet.microsoft.com/download

5. **GCC** (required for SPIN)
   - Ubuntu/Debian: `sudo apt-get install build-essential`
   - macOS: `xcode-select --install`

6. **Graphviz** (for visualization)
   - Ubuntu/Debian: `sudo apt-get install graphviz`
   - macOS: `brew install graphviz`
   - Windows: https://graphviz.org/download/

### Python Dependencies

Install Python packages:

```bash
pip install -r requirements.txt
```

Required packages:
- `graphviz` - For state diagram generation

## Repository Structure

```
.
├── inspection_workflow.smv          # NuSMV model specification
├── inspection_workflow.pml          # SPIN/Promela model specification
├── inspection_workflow.4ml          # FORMULA domain specification
├── inspection_workflow_process.dot  # Graphviz process diagram source
├── InspectionWorkflow.p             # P language model specification
├── test_scenarios.py                # Python test suite
├── visualize_states.py              # State diagram generator
├── generate_process_diagram.sh      # Process diagram generator
├── generate_report.py               # Report generator
├── verify_nusmv.sh                  # NuSMV verification script
├── verify_spin.sh                   # SPIN verification script
├── verify_formula.sh                # FORMULA verification script
├── run_all_verifications.sh         # Complete verification suite
├── Makefile                         # Build automation
├── requirements.txt                 # Python dependencies
├── README.md                        # This file
├── FORMAL_SPECIFICATION_REPORT.md   # Generated report (after running)
├── SPIN_FIXES.md                    # Documentation of SPIN fixes
└── results/                         # Generated verification results
    ├── nusmv_results.txt
    ├── spin_results.txt
    ├── formula_results.txt
    ├── state_diagram.png
    ├── detailed_state_diagram.png
    ├── properties_diagram.png
    ├── inspection_workflow_process.png
    ├── inspection_workflow_process.svg
    └── inspection_workflow_process.pdf
```

## Usage

### Option 1: Using Make (Recommended)

```bash
# Run everything (verification + tests + report)
make all

# Run specific verifications
make nusmv          # NuSMV only
make spin           # SPIN only
make formula        # FORMULA only
make test           # Test suite only
make visualize      # Generate state diagrams only
make process-diagram # Generate process diagram only
make diagrams       # Generate all diagrams
make report         # Generate report only

# Run quick verification (NuSMV + report)
make quick

# Run full verification suite
make full

# Check prerequisites
make check

# Install Python dependencies
make install-deps

# Clean generated files
make clean

# Show help
make help
```

### Option 2: Using Individual Scripts

```bash
# Run NuSMV verification
./verify_nusmv.sh

# Run SPIN verification
./verify_spin.sh

# Run FORMULA verification
./verify_formula.sh

# Run test suite
python3 test_scenarios.py

# Generate state diagrams
python3 visualize_states.py

# Generate process diagram
./generate_process_diagram.sh

# Generate report
python3 generate_report.py

# Run complete verification suite (interactive)
./run_all_verifications.sh
```

### Option 3: Manual Verification

#### NuSMV

```bash
NuSMV inspection_workflow.smv > results/nusmv_results.txt
```

#### SPIN

```bash
# Compile Promela model
spin -a inspection_workflow.pml

# Compile verifier
gcc -o pan pan.c

# Run verification
./pan -a
```

#### FORMULA

```bash
# Check model syntax
formula check inspection_workflow.4ml

# Verify domain
formula verify InspectionWorkflow inspection_workflow.4ml

# Verify specific models
formula verify NormalAcceptFlow inspection_workflow.4ml
formula verify NormalRejectFlow inspection_workflow.4ml
```

#### P Language

```bash
# Requires P compiler (https://github.com/p-org/P)
pc InspectionWorkflow.p
./InspectionWorkflow.exe
```

## Formal Models

### NuSMV Model (`inspection_workflow.smv`)

The NuSMV model provides:
- **22 CTL properties** covering safety, liveness, and temporal ordering
- **6 invariants** that must always hold
- State variables for workflow state, quantities, fields, and configuration
- Non-deterministic state transitions

Key properties verified:
- Quantity conservation always holds
- Required fields must be entered before save
- Mandatory quality results enforced
- OPM secondary fields required when applicable
- Progress guarantees (eventually saved or cancelled)

### SPIN Model (`inspection_workflow.pml`)

The SPIN model provides:
- **3 concurrent processes**: Inspector, System, Monitor
- **10 LTL properties** for protocol verification
- Event-driven communication via channels
- Runtime assertion checking

Key properties verified:
- Progress to terminal state
- Quality results before save when mandatory
- Quantity conservation across all operations
- Proper event sequencing

### FORMULA Model (`inspection_workflow.4ml`)

The FORMULA model provides:
- **Domain-based specification** with type definitions and constraints
- **13 conformance constraints** (must-not-occur conditions)
- **3 partial models** for different scenarios
- **2 complete models** showing concrete workflow traces
- **Algebraic data types** for workflow state and quantities

Key features:
- Type-safe domain modeling with constructors
- Logic programming-style constraint rules
- Quantity conservation enforced at type level
- Required field validation through conformance rules
- Integration configuration (Oracle Quality, OPM) modeled explicitly
- Partial models with requirements for synthesis
- Complete models demonstrating accept/reject flows

### P Model (`InspectionWorkflow.p`)

The P model provides:
- **State machine with 6 states**
- **Event-driven architecture**
- **5 specifications** for key properties
- Data structures for quantities and configuration

Key properties verified:
- Quantity conservation after save
- Mandatory quality check enforcement
- Progress guarantee
- No negative quantities
- OPM secondary fields when required

## Test Suite

The Python test suite (`test_scenarios.py`) includes:

### Normal Flow Tests
- Accept with all required fields
- Reject with all required fields
- Partial inspection with re-query
- Cancel operation

### Edge Case Tests
- Save without quality code (should fail)
- Save without UOM (should fail)
- Mandatory quality not entered (should fail)
- Inspect after save without re-query (should fail)
- Negative quantity (should fail)
- Excessive quantity (should fail)

### Integration Tests
- Oracle Quality integration
- OPM process organization
- OPM without secondary fields (should fail)

### Property Tests
- Quantity conservation across multiple inspections
- Conservation after accept
- Conservation after reject

Run tests:
```bash
python3 test_scenarios.py
```

## Visualization

The formal specification suite includes multiple visualization tools:

### State Machine Diagrams (Python)

The Python visualization script generates three diagrams:

1. **State Diagram** - Main workflow states and transitions
2. **Detailed State Diagram** - With guards and conditions
3. **Properties Diagram** - Safety and liveness properties

Generate visualizations:
```bash
python3 visualize_states.py
# OR
make visualize
```

Output files:
- `results/state_diagram.png`
- `results/detailed_state_diagram.png`
- `results/properties_diagram.png`

### Overall Process Diagram (Graphviz)

A comprehensive Graphviz diagram showing the complete inspection workflow process including:
- All workflow states and transitions
- Decision points and user actions
- Integration flows (Oracle Quality, OPM)
- Quantity tracking examples
- Key constraints and properties
- Verification tools overview

Generate process diagram:
```bash
./generate_process_diagram.sh
# OR
make process-diagram
```

Manual generation:
```bash
# PNG format
dot -Tpng inspection_workflow_process.dot -o results/inspection_workflow_process.png

# SVG format (scalable)
dot -Tsvg inspection_workflow_process.dot -o results/inspection_workflow_process.svg

# PDF format (for documents)
dot -Tpdf inspection_workflow_process.dot -o results/inspection_workflow_process.pdf
```

Output files:
- `results/inspection_workflow_process.png` (bitmap)
- `results/inspection_workflow_process.svg` (vector, scalable)
- `results/inspection_workflow_process.pdf` (document-ready)

### Generate All Diagrams

```bash
make diagrams
```

This generates all visualizations in one command.

## Formal Specification Report

After running verifications, generate a comprehensive report:

```bash
python3 generate_report.py
# OR
make report
```

The report (`FORMAL_SPECIFICATION_REPORT.md`) includes:
- Introduction and workflow description
- State diagrams (Mermaid format)
- Formal models overview
- Verification results summary
- Properties verified with explanations
- Analysis and findings
- Implementation recommendations

## Verified Properties

### Safety Properties (must always hold)

1. **Quantity Conservation**: `accepted + rejected + uninspected = total`
2. **No Negative Quantities**: All quantities >= 0
3. **Decision Exclusivity**: Cannot accept and reject simultaneously
4. **Required Fields**: Quality code and UOM required before save
5. **Mandatory Quality**: Quality results required when mandatory plan exists
6. **OPM Fields**: Secondary fields required for OPM process organizations

### Liveness Properties (eventually hold)

7. **Progress**: Inspection eventually completes (saved or cancelled)
8. **Quality Entry**: Quality results eventually entered if mandatory
9. **Inspection Availability**: Uninspected items can eventually be inspected

### Temporal Ordering Properties

10. **Inspect Before Entry**: Must open inspection window before data entry
11. **Quality Before Save**: Quality results before save when mandatory
12. **Re-query After Save**: Must re-query to inspect more items after save

## Troubleshooting

### NuSMV not found
```bash
# Ubuntu/Debian
sudo apt-get install nusmv

# macOS
brew install nusmv

# Or download from http://nusmv.fbk.eu/
```

### SPIN not found
```bash
# Ubuntu/Debian
sudo apt-get install spin

# macOS
brew install spin

# Or download from http://spinroot.com/
```

### Graphviz visualization errors
```bash
# Install Graphviz system package
# Ubuntu/Debian
sudo apt-get install graphviz

# macOS
brew install graphviz

# Install Python package
pip install graphviz
```

### Python dependency errors
```bash
# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt
```

## Workflow Description

### Key Steps

1. **Navigate to Inspection**
   - User clicks Inspect button in Receiving Transactions window
   - System opens Inspection Details window

2. **Make Decision**
   - User selects Accept or Reject for each line

3. **Enter Data**
   - Enter quantity (accepted or rejected)
   - Enter UOM
   - Enter quality code (required)
   - Enter reason code
   - Enter supplier lot
   - Date defaults to system date
   - Enter comment (optional)

4. **OPM Integration** (if enabled)
   - Enter secondary UOM
   - Enter secondary quantity

5. **Quality Integration** (if mandatory)
   - Enter quality results before save

6. **Save or Cancel**
   - Save: Updates quantities, makes receipt unavailable
   - Cancel: Discards all entries, returns to Receiving Transactions

7. **Re-query** (if needed)
   - If uninspected items remain, user can re-query
   - Receipts become available for inspection again

### Critical Constraints

- **Quantity Conservation**: `accepted + rejected + uninspected = total` (ALWAYS)
- **Required Fields**: Quality code and UOM must be entered
- **Mandatory Quality**: Quality results required if mandatory collection plans exist
- **OPM Secondary Fields**: Required for OPM-enabled process organizations
- **Re-query Required**: After save, must re-query to inspect more items

## Contributing

When modifying formal specifications:

1. Update all three models (NuSMV, SPIN, P) consistently
2. Add corresponding test cases in `test_scenarios.py`
3. Run full verification: `make full`
4. Update documentation in report if properties change
5. Ensure all properties are verified successfully

## References

### Oracle Documentation
- Oracle Purchasing User's Guide: Inspecting Received Items

### Formal Methods Tools
- NuSMV: http://nusmv.fbk.eu/
- SPIN: http://spinroot.com/
- P Language: https://github.com/p-org/P

### Formal Verification Resources
- CTL (Computational Tree Logic): https://en.wikipedia.org/wiki/Computation_tree_logic
- LTL (Linear Temporal Logic): https://en.wikipedia.org/wiki/Linear_temporal_logic
- Model Checking: https://en.wikipedia.org/wiki/Model_checking

## License

[Specify license here]

## Authors

[Specify authors here]

## Acknowledgments

This formal specification was created to verify the correctness of the Oracle Purchasing inspection workflow and identify potential issues before implementation.
