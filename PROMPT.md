Instructions for Claude Code: Formal Specification of Oracle Purchasing Inspection Workflow
Overview
Build formal specifications for the Oracle Purchasing "Inspecting Received Items" workflow using multiple formal verification tools (NuSMV, SPIN, and P). The goal is to create models that can verify safety, liveness, and temporal properties of the inspection process.

Source Material
The workflow documentation is available at: https://docs.oracle.com/cd/E26401_01/doc.122/e48931/T446883T443958.htm#t_insp

Key workflow steps (from "Inspecting Received Items" section):

Navigate to Inspection Details window via Inspect button in Receiving Transactions window
Select Accept or Reject for each line
Enter Quantity (accepted or rejected) - defaults to uninspected quantity
Enter UOM for inspected item
Enter Quality Code
Enter Reason Code
Enter Supplier Lot number
Enter inspection Date (defaults to system date)
If OPM enabled and process organization: enter Secondary UOM and Secondary Quantity
Enter Comment
Save work OR Cancel to return to Receiving Transactions window
Important constraints:

After saving, receipts are no longer available for inspection
To inspect again after saving, must requery using Find Receiving Transactions window
If Oracle Quality installed and mandatory collection plans exist, quality results must be entered before saving
Quantity conservation: accepted + rejected + uninspected = total received
Task 1: Create NuSMV Model (Primary Model)
File: inspection_workflow.smv
Create a complete NuSMV model with the following structure:

1.1 Define Main Module
State variables:
workflow_state: {uninspected, inspection_window_open, data_entry, quality_entry, saved, cancelled}
inspection_decision: {none, accept, reject}
quantity_total: 0..1000 (total received)
quantity_inspected: 0..1000 (currently being inspected)
quantity_accepted: 0..1000
quantity_rejected: 0..1000
quantity_uninspected: 0..1000
quality_code_entered: boolean
reason_code_entered: boolean
uom_entered: boolean
date_entered: boolean
mandatory_quality_plan: boolean
quality_results_entered: boolean
oracle_quality_installed: boolean
opm_enabled: boolean
process_organization: boolean
secondary_fields_entered: boolean
can_requery: boolean
1.2 Define Initial State
ASSIGN
  init(workflow_state) := uninspected;
  init(quantity_total) := 100;  -- example
  init(quantity_uninspected) := 100;
  init(quantity_inspected) := 0;
  init(quantity_accepted) := 0;
  init(quantity_rejected) := 0;
  init(mandatory_quality_plan) := FALSE;
  init(oracle_quality_installed) := FALSE;
  init(opm_enabled) := FALSE;
1.3 Define Transitions
Model these key transitions:

Navigate to inspection: uninspected → inspection_window_open
Select Accept/Reject: inspection_window_open → data_entry
Enter required fields: data_entry → data_entry (loop until complete)
Enter quality results (if mandatory): data_entry → quality_entry
Save: data_entry/quality_entry → saved
Cancel: inspection_window_open/data_entry/quality_entry → cancelled
Re-query: saved → inspection_window_open (if more inspection needed)
1.4 Define Invariants
INVAR quantity_accepted + quantity_rejected + quantity_uninspected = quantity_total;
INVAR quantity_inspected <= quantity_total;
INVAR !(inspection_decision = accept & inspection_decision = reject);
INVAR (opm_enabled & process_organization) -> secondary_fields_entered;
1.5 Define CTL Properties
Safety Properties:

-- Property 1: Quantity conservation
SPEC AG(quantity_accepted + quantity_rejected + quantity_uninspected = quantity_total)

-- Property 2: No negative quantities
SPEC AG(quantity_accepted >= 0 & quantity_rejected >= 0 & quantity_uninspected >= 0)

-- Property 3: Cannot accept and reject same item
SPEC AG(!(inspection_decision = accept & inspection_decision = reject))

-- Property 4: Cannot save without required fields
SPEC AG((workflow_state = data_entry & !(quality_code_entered & uom_entered)) -> 
        AX(workflow_state != saved))

-- Property 5: Mandatory quality results must be entered
SPEC AG((mandatory_quality_plan & !quality_results_entered) -> workflow_state != saved)

-- Property 6: After save, not available for inspection without requery
SPEC AG(workflow_state = saved -> AX(!can_requery | workflow_state = inspection_window_open))
Liveness Properties:

-- Property 7: Inspection eventually completes (saved or cancelled)
SPEC AG(workflow_state = inspection_window_open -> AF(workflow_state = saved | workflow_state = cancelled))

-- Property 8: If mandatory quality plan exists, quality results eventually entered
SPEC AG((mandatory_quality_plan & workflow_state = data_entry) -> AF(quality_results_entered))

-- Property 9: Uninspected items can eventually be inspected
SPEC AG(quantity_uninspected > 0 -> EF(workflow_state = inspection_window_open))
Temporal Ordering Properties:

-- Property 10: Inspect button must be clicked before data entry
SPEC AG(workflow_state = data_entry -> EX(workflow_state = inspection_window_open))

-- Property 11: Quality results before save when mandatory
SPEC AG((mandatory_quality_plan & !quality_results_entered) -> A[!quality_results_entered U workflow_state != saved])

-- Property 12: Save before making unavailable
SPEC AG(workflow_state != saved -> can_requery)
1.6 Create Verification Script
Create verify_nusmv.sh:

#!/bin/bash
echo "Verifying NuSMV model..."
NuSMV inspection_workflow.smv > verification_results.txt
echo "Results saved to verification_results.txt"
grep -E "(is true|is false)" verification_results.txt
Task 2: Create SPIN/Promela Model
File: inspection_workflow.pml
Create a Promela model focusing on concurrency and protocol verification:

2.1 Define Message Types
mtype = {
    INSPECT_BUTTON_CLICKED,
    ACCEPT_SELECTED,
    REJECT_SELECTED,
    QUANTITY_ENTERED,
    UOM_ENTERED,
    QUALITY_CODE_ENTERED,
    REASON_CODE_ENTERED,
    QUALITY_RESULTS_ENTERED,
    SAVE_CLICKED,
    CANCEL_CLICKED,
    REQUERY_REQUESTED
}
2.2 Define Global State
byte workflow_state = 0;  // 0=uninspected, 1=window_open, 2=data_entry, 3=saved, 4=cancelled
short quantity_total = 100;
short quantity_accepted = 0;
short quantity_rejected = 0;
short quantity_uninspected = 100;
bool quality_code_entered = false;
bool uom_entered = false;
bool mandatory_quality_plan = false;
bool quality_results_entered = false;
chan events = [10] of {mtype};
2.3 Define Inspector Process
proctype Inspector() {
    // Model the inspection workflow as a process
    // Include timing, events, and state transitions
    // Handle both normal flow and error cases
}
2.4 Define System Process
proctype System() {
    // Model system responses to inspector actions
    // Enforce business rules
    // Handle Oracle Quality integration
}
2.5 Define LTL Properties
// Property 1: Progress - inspection eventually completes
ltl progress { []((workflow_state == 1) -> <>(workflow_state == 3 || workflow_state == 4)) }

// Property 2: No deadlock
ltl no_deadlock { []<>(workflow_state == 3 || workflow_state == 4) }

// Property 3: Mandatory quality before save
ltl quality_before_save { []((mandatory_quality_plan && !quality_results_entered) -> !(workflow_state == 3)) }

// Property 4: Quantity conservation
ltl conservation { [](quantity_accepted + quantity_rejected + quantity_uninspected == quantity_total) }

// Property 5: Proper ordering of events
ltl event_order { [](SAVE_CLICKED -> (QUANTITY_ENTERED && UOM_ENTERED && QUALITY_CODE_ENTERED)) }
2.6 Create Verification Script
Create verify_spin.sh:

#!/bin/bash
echo "Compiling Promela model..."
spin -a inspection_workflow.pml
gcc -o pan pan.c
echo "Running verification..."
./pan -a > spin_results.txt
echo "Results saved to spin_results.txt"
Task 3: Create P Model
File: InspectionWorkflow.p
Create a P language model for event-driven verification:

3.1 Define Events
event eInspectClicked;
event eAcceptSelected;
event eRejectSelected;
event eQuantityEntered: int;
event eQualityCodeEntered;
event eQualityResultsEntered;
event eSaveClicked;
event eCancelClicked;
event eRequeryRequested;
3.2 Define State Machine
machine InspectionWorkflow {
    var quantityTotal: int;
    var quantityAccepted: int;
    var quantityRejected: int;
    var quantityUninspected: int;
    var qualityCodeEntered: bool;
    var uomEntered: bool;
    var mandatoryQualityPlan: bool;
    var qualityResultsEntered: bool;
    
    start state Uninspected {
        on eInspectClicked goto InspectionWindowOpen;
    }
    
    state InspectionWindowOpen {
        on eAcceptSelected goto DataEntry;
        on eRejectSelected goto DataEntry;
        on eCancelClicked goto Cancelled;
    }
    
    state DataEntry {
        // Define entry and exit actions
        // Define transitions based on events
    }
    
    state QualityEntry {
        // Handle quality results entry
    }
    
    state Saved {
        // Handle post-save state
    }
    
    state Cancelled {
        // Handle cancellation
    }
}
3.3 Define Specifications
// Specification 1: Quantity Conservation
spec QuantityConservation observes eQuantityEntered {
    assert (quantityAccepted + quantityRejected + quantityUninspected == quantityTotal);
}

// Specification 2: Mandatory Quality Check
spec MandatoryQualityCheck observes eSaveClicked {
    assert (!mandatoryQualityPlan || qualityResultsEntered);
}

// Specification 3: Progress Guarantee
spec ProgressGuarantee observes eInspectClicked {
    assert (eventually (receives eSaveClicked || receives eCancelClicked));
}
Task 4: Create Test Suite
File: test_scenarios.py
Create Python test scenarios that can be used with all models:

4.1 Normal Flow Tests
def test_accept_normal_flow():
    """Test accepting items with all required fields"""
    
def test_reject_normal_flow():
    """Test rejecting items with all required fields"""
    
def test_partial_inspection():
    """Test inspecting partial quantity"""
4.2 Edge Case Tests
def test_save_without_quality_code():
    """Should fail - quality code required"""
    
def test_mandatory_quality_not_entered():
    """Should fail - mandatory quality results required"""
    
def test_inspect_after_save_without_requery():
    """Should fail - must requery"""
4.3 Integration Tests
def test_oracle_quality_integration():
    """Test with Oracle Quality installed"""
    
def test_opm_process_organization():
    """Test with OPM enabled and process organization"""
Task 5: Create Documentation
File: FORMAL_SPECIFICATION_REPORT.md
Create a comprehensive report including:

5.1 Introduction
Overview of the inspection workflow
Purpose of formal specification
Tools used (NuSMV, SPIN, P)
5.2 Workflow Description
State diagram (use Mermaid syntax)
Detailed state descriptions
Transition conditions
Business rules and constraints
5.3 Formal Properties
List all properties being verified
Classification (safety, liveness, temporal)
Formal specification in CTL/LTL
Plain English explanation
5.4 Verification Results
Summary of verification runs
Properties proven true/false
Counterexamples for failed properties
Performance metrics (states explored, time taken)
5.5 Analysis
Key findings
Potential bugs or ambiguities discovered
Recommendations for workflow improvement
Task 6: Create Build and Run Scripts
File: Makefile
Create a Makefile to automate all tasks:

.PHONY: all nusmv spin p test clean

all: nusmv spin p

nusmv:
	@echo "Running NuSMV verification..."
	NuSMV inspection_workflow.smv > results/nusmv_results.txt

spin:
	@echo "Running SPIN verification..."
	spin -a inspection_workflow.pml
	gcc -o pan pan.c
	./pan -a > results/spin_results.txt

p:
	@echo "Running P verification..."
	pc InspectionWorkflow.p
	./InspectionWorkflow.exe > results/p_results.txt

test:
	@echo "Running test suite..."
	python test_scenarios.py

clean:
	rm -f pan pan.* _spin_nvr.tmp *.trail
	rm -rf results/*
File: run_all_verifications.sh
#!/bin/bash

echo "====================================="
echo "Oracle Inspection Workflow Verification"
echo "====================================="

# Create results directory
mkdir -p results

# Run NuSMV
echo ""
echo "[1/3] Running NuSMV verification..."
if command -v NuSMV &> /dev/null; then
    ./verify_nusmv.sh
    echo "✓ NuSMV complete"
else
    echo "✗ NuSMV not found - skipping"
fi

# Run SPIN
echo ""
echo "[2/3] Running SPIN verification..."
if command -v spin &> /dev/null; then
    ./verify_spin.sh
    echo "✓ SPIN complete"
else
    echo "✗ SPIN not found - skipping"
fi

# Run P
echo ""
echo "[3/3] Running P verification..."
if [ -f "InspectionWorkflow.p" ]; then
    echo "Note: P verification requires P compiler"
else
    echo "✗ P model not found - skipping"
fi

# Generate report
echo ""
echo "Generating report..."
python generate_report.py

echo ""
echo "====================================="
echo "Verification complete!"
echo "See results/ directory for details"
echo "====================================="
Task 7: Create Visualization Tools
File: visualize_states.py
Create a Python script using Graphviz to visualize the state machine:

"""
Generate state machine diagram from formal specifications
"""
import graphviz

def create_state_diagram():
    """Create visual representation of inspection workflow states"""
    # Generate DOT format graph
    # Export as PDF and PNG
    # Include transitions, guards, and actions
Additional Requirements
Version Control:

Initialize git repository
Create .gitignore for generated files
Commit each model separately with descriptive messages
Dependencies:

Create requirements.txt for Python dependencies
Create README.md with installation instructions for NuSMV, SPIN, and P
Error Handling:

All scripts should include error handling
Provide clear error messages
Exit with appropriate codes
Documentation:

Comment all code thoroughly
Include examples for each property
Provide usage instructions
Deliverables Checklist

[object Object] - Complete NuSMV model

[object Object] - Complete SPIN/Promela model

[object Object] - Complete P model

[object Object] - Test suite

[object Object] - Comprehensive documentation

[object Object] - Build automation

[object Object] - Verification automation

[object Object] - NuSMV verification script

[object Object] - SPIN verification script

[object Object] - State diagram generator

[object Object] - Report generator

[object Object] - Setup and usage instructions

[object Object] - Python dependencies

[object Object] - Git ignore file
Success Criteria
All three formal models (NuSMV, SPIN, P) compile without errors
At least 12 properties specified and verified
All safety properties proven true
Liveness properties verified with counterexamples if false
Documentation clearly explains each property and result
Test suite covers normal flow, edge cases, and integration scenarios
Visualization clearly shows all states and transitions
Scripts are executable and include proper error handling
Notes
Focus first on the NuSMV model as it's the primary recommendation
Ensure quantity conservation is enforced in all models
Pay special attention to the mandatory quality results requirement
Model the re-query behavior correctly
Consider both Oracle Quality integration scenarios (installed/not installed)
Include OPM (Oracle Process Manufacturing) conditional behavior
Getting Started
Start with inspection_workflow.smv - this is the foundation
Verify the basic properties work before adding complex ones
Use the verification results to refine the model
Once NuSMV is working, adapt to SPIN and P
Build test suite alongside models
Generate documentation last, using actual verification results
Good luck! The formal specifications will help identify any ambiguities or potential issues in the Oracle inspection workflow.
