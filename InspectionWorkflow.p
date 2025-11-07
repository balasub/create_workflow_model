/**
 * ============================================================================
 * Oracle Purchasing Inspection Workflow - P Language Model
 * ============================================================================
 * This P model specifies the inspection workflow using event-driven
 * state machines for modeling and verification.
 * ============================================================================
 */

/* ============================================================================
 * EVENTS
 * ============================================================================ */

event eInspectClicked;
event eAcceptSelected;
event eRejectSelected;
event eQuantityEntered: int;
event eUOMEntered;
event eQualityCodeEntered;
event eReasonCodeEntered;
event eDateEntered;
event eSupplierLotEntered;
event eCommentEntered;
event eSecondaryUOMEntered;
event eSecondaryQuantityEntered;
event eQualityResultsEntered;
event eSaveClicked;
event eCancelClicked;
event eRequeryRequested;
event eSaveSuccess;
event eSaveFailed: string;
event eValidationPassed;
event eValidationFailed: string;

/* ============================================================================
 * DATA STRUCTURES
 * ============================================================================ */

type InspectionData = (
    quantityTotal: int,
    quantityInspected: int,
    quantityAccepted: int,
    quantityRejected: int,
    quantityUninspected: int
);

type FieldsData = (
    qualityCodeEntered: bool,
    reasonCodeEntered: bool,
    uomEntered: bool,
    dateEntered: bool,
    supplierLotEntered: bool,
    commentEntered: bool
);

type IntegrationConfig = (
    oracleQualityInstalled: bool,
    mandatoryQualityPlan: bool,
    qualityResultsEntered: bool,
    opmEnabled: bool,
    processOrganization: bool,
    secondaryUOMEntered: bool,
    secondaryQuantityEntered: bool
);

/* ============================================================================
 * INSPECTION WORKFLOW STATE MACHINE
 * ============================================================================ */

machine InspectionWorkflow {
    var inspectionData: InspectionData;
    var fields: FieldsData;
    var config: IntegrationConfig;
    var inspectionDecision: int;  // 0=none, 1=accept, 2=reject
    var canRequery: bool;

    /* ------------------------------------------------------------------------
     * INITIALIZATION
     * ------------------------------------------------------------------------ */
    start state Uninspected {
        entry {
            // Initialize inspection data
            inspectionData = (
                quantityTotal = 100,
                quantityInspected = 0,
                quantityAccepted = 0,
                quantityRejected = 0,
                quantityUninspected = 100
            );

            // Initialize fields
            fields = (
                qualityCodeEntered = false,
                reasonCodeEntered = false,
                uomEntered = false,
                dateEntered = true,  // Defaults to system date
                supplierLotEntered = false,
                commentEntered = false
            );

            // Initialize configuration
            config = (
                oracleQualityInstalled = false,
                mandatoryQualityPlan = false,
                qualityResultsEntered = false,
                opmEnabled = false,
                processOrganization = false,
                secondaryUOMEntered = false,
                secondaryQuantityEntered = false
            );

            inspectionDecision = 0;  // none
            canRequery = true;

            print "InspectionWorkflow: Initialized in Uninspected state";
        }

        on eInspectClicked do {
            print "User clicked Inspect button";
        }
        on eInspectClicked goto InspectionWindowOpen;
    }

    /* ------------------------------------------------------------------------
     * INSPECTION WINDOW OPEN STATE
     * ------------------------------------------------------------------------ */
    state InspectionWindowOpen {
        entry {
            print "InspectionWorkflow: Inspection window opened";
        }

        on eAcceptSelected do {
            inspectionDecision = 1;
            print "User selected ACCEPT";
        }
        on eAcceptSelected goto DataEntry;

        on eRejectSelected do {
            inspectionDecision = 2;
            print "User selected REJECT";
        }
        on eRejectSelected goto DataEntry;

        on eCancelClicked do {
            print "User cancelled from inspection window";
        }
        on eCancelClicked goto Cancelled;
    }

    /* ------------------------------------------------------------------------
     * DATA ENTRY STATE
     * ------------------------------------------------------------------------ */
    state DataEntry {
        entry {
            print "InspectionWorkflow: Entering data entry mode";
            assert inspectionDecision == 1 || inspectionDecision == 2,
                   "Inspection decision must be made before data entry";
        }

        on eQuantityEntered do (qty: int) {
            assert qty > 0, "Quantity must be positive";
            assert qty <= inspectionData.quantityUninspected,
                   "Cannot inspect more than uninspected quantity";

            inspectionData.quantityInspected = qty;
            print format("User entered quantity: {0}", qty);
        }

        on eQualityCodeEntered do {
            fields.qualityCodeEntered = true;
            print "User entered quality code";
        }

        on eReasonCodeEntered do {
            fields.reasonCodeEntered = true;
            print "User entered reason code";
        }

        on eUOMEntered do {
            fields.uomEntered = true;
            print "User entered UOM";
        }

        on eSupplierLotEntered do {
            fields.supplierLotEntered = true;
            print "User entered supplier lot";
        }

        on eCommentEntered do {
            fields.commentEntered = true;
            print "User entered comment";
        }

        on eSecondaryUOMEntered do {
            assert config.opmEnabled && config.processOrganization,
                   "Secondary UOM only for OPM process organizations";
            config.secondaryUOMEntered = true;
            print "User entered secondary UOM";
        }

        on eSecondaryQuantityEntered do {
            assert config.opmEnabled && config.processOrganization,
                   "Secondary quantity only for OPM process organizations";
            config.secondaryQuantityEntered = true;
            print "User entered secondary quantity";
        }

        on eSaveClicked do {
            print "User clicked Save - validating...";
            if (ValidateRequiredFields()) {
                send this, eValidationPassed;
            } else {
                send this, eValidationFailed, "Required fields missing";
            }
        }

        on eValidationPassed goto ValidatingSave;

        on eValidationFailed do (reason: string) {
            print format("Validation failed: {0}", reason);
            // Stay in DataEntry state
        }

        on eCancelClicked do {
            print "User cancelled from data entry";
        }
        on eCancelClicked goto Cancelled;

        on eQualityResultsEntered do {
            // Transition to quality entry if needed
            if (config.mandatoryQualityPlan && !config.qualityResultsEntered) {
                print "Mandatory quality results required";
            }
        }
    }

    /* ------------------------------------------------------------------------
     * QUALITY ENTRY STATE
     * ------------------------------------------------------------------------ */
    state QualityEntry {
        entry {
            print "InspectionWorkflow: Entering quality entry mode";
            assert config.oracleQualityInstalled && config.mandatoryQualityPlan,
                   "Quality entry only for mandatory quality plans";
        }

        on eQualityResultsEntered do {
            config.qualityResultsEntered = true;
            print "User entered quality results";
        }
        on eQualityResultsEntered goto DataEntry;

        on eCancelClicked do {
            print "User cancelled from quality entry";
        }
        on eCancelClicked goto Cancelled;
    }

    /* ------------------------------------------------------------------------
     * VALIDATING SAVE STATE
     * ------------------------------------------------------------------------ */
    state ValidatingSave {
        entry {
            print "InspectionWorkflow: Validating save operation";

            // Perform all validation checks
            if (!PerformSaveValidation()) {
                send this, eSaveFailed, "Validation checks failed";
                goto DataEntry;
            }

            // Update quantities
            if (inspectionDecision == 1) {
                // Accept
                inspectionData.quantityAccepted = inspectionData.quantityAccepted +
                                                   inspectionData.quantityInspected;
            } else {
                // Reject
                inspectionData.quantityRejected = inspectionData.quantityRejected +
                                                   inspectionData.quantityInspected;
            }

            inspectionData.quantityUninspected = inspectionData.quantityUninspected -
                                                  inspectionData.quantityInspected;

            // Verify quantity conservation
            assert inspectionData.quantityAccepted + inspectionData.quantityRejected +
                   inspectionData.quantityUninspected == inspectionData.quantityTotal,
                   "Quantity conservation violated";

            send this, eSaveSuccess;
        }

        on eSaveSuccess do {
            print "Save successful";
        }
        on eSaveSuccess goto Saved;

        on eSaveFailed do (reason: string) {
            print format("Save failed: {0}", reason);
        }
        on eSaveFailed goto DataEntry;
    }

    /* ------------------------------------------------------------------------
     * SAVED STATE
     * ------------------------------------------------------------------------ */
    state Saved {
        entry {
            print "InspectionWorkflow: Inspection saved successfully";

            // Reset fields for next inspection
            ResetFields();

            // Check if more inspection needed
            if (inspectionData.quantityUninspected > 0) {
                canRequery = true;
                print format("Remaining uninspected: {0}",
                           inspectionData.quantityUninspected);
            } else {
                canRequery = false;
                print "All items inspected";
            }
        }

        on eRequeryRequested do {
            assert canRequery, "Cannot requery - no uninspected items";
            print "User requested requery for more inspection";
        }
        on eRequeryRequested goto InspectionWindowOpen;

        ignore eSaveClicked, eCancelClicked;
    }

    /* ------------------------------------------------------------------------
     * CANCELLED STATE
     * ------------------------------------------------------------------------ */
    state Cancelled {
        entry {
            print "InspectionWorkflow: Inspection cancelled";
            ResetFields();
        }

        ignore eInspectClicked, eSaveClicked, eCancelClicked;
    }

    /* ------------------------------------------------------------------------
     * HELPER FUNCTIONS
     * ------------------------------------------------------------------------ */

    fun ValidateRequiredFields(): bool {
        // Check required fields
        if (!fields.qualityCodeEntered) {
            return false;
        }
        if (!fields.uomEntered) {
            return false;
        }

        // Check mandatory quality results
        if (config.mandatoryQualityPlan && !config.qualityResultsEntered) {
            return false;
        }

        // Check OPM secondary fields
        if (config.opmEnabled && config.processOrganization) {
            if (!config.secondaryUOMEntered || !config.secondaryQuantityEntered) {
                return false;
            }
        }

        return true;
    }

    fun PerformSaveValidation(): bool {
        // Verify inspection decision
        if (inspectionDecision != 1 && inspectionDecision != 2) {
            return false;
        }

        // Verify quantity bounds
        if (inspectionData.quantityInspected <= 0 ||
            inspectionData.quantityInspected > inspectionData.quantityUninspected) {
            return false;
        }

        // Verify no negative quantities
        if (inspectionData.quantityAccepted < 0 ||
            inspectionData.quantityRejected < 0 ||
            inspectionData.quantityUninspected < 0) {
            return false;
        }

        return true;
    }

    fun ResetFields() {
        fields.qualityCodeEntered = false;
        fields.reasonCodeEntered = false;
        fields.uomEntered = false;
        fields.supplierLotEntered = false;
        fields.commentEntered = false;
        config.qualityResultsEntered = false;
        config.secondaryUOMEntered = false;
        config.secondaryQuantityEntered = false;
        inspectionData.quantityInspected = 0;
        inspectionDecision = 0;
    }
}

/* ============================================================================
 * SPECIFICATIONS
 * ============================================================================ */

/* Specification 1: Quantity Conservation */
spec QuantityConservation observes eQuantityEntered, eSaveSuccess {
    start state CheckConservation {
        on eSaveSuccess do {
            // This assertion should always hold after save
            assert inspectionData.quantityAccepted + inspectionData.quantityRejected +
                   inspectionData.quantityUninspected == inspectionData.quantityTotal,
                   "Quantity conservation violated after save";
        }
    }
}

/* Specification 2: Mandatory Quality Check */
spec MandatoryQualityCheck observes eSaveClicked, eQualityResultsEntered {
    start state ValidateQuality {
        on eSaveClicked do {
            // If mandatory quality plan and quality installed, results must be entered
            assert !(config.mandatoryQualityPlan && config.oracleQualityInstalled &&
                     !config.qualityResultsEntered),
                   "Mandatory quality results not entered before save";
        }
    }
}

/* Specification 3: Progress Guarantee */
spec ProgressGuarantee observes eInspectClicked, eSaveSuccess, eCancelClicked {
    start state WaitingForCompletion {
        on eInspectClicked goto InspectionStarted;
    }

    state InspectionStarted {
        on eSaveSuccess goto Completed;
        on eCancelClicked goto Completed;
    }

    state Completed {
        entry {
            print "Inspection completed (saved or cancelled)";
        }
    }
}

/* Specification 4: No Negative Quantities */
spec NoNegativeQuantities observes eQuantityEntered, eSaveSuccess {
    start state CheckQuantities {
        on eQuantityEntered, eSaveSuccess do {
            assert inspectionData.quantityAccepted >= 0,
                   "Accepted quantity cannot be negative";
            assert inspectionData.quantityRejected >= 0,
                   "Rejected quantity cannot be negative";
            assert inspectionData.quantityUninspected >= 0,
                   "Uninspected quantity cannot be negative";
        }
    }
}

/* Specification 5: OPM Secondary Fields Required */
spec OPMSecondaryFieldsRequired observes eSaveClicked {
    start state CheckOPMFields {
        on eSaveClicked do {
            // If OPM enabled and process org, secondary fields must be entered
            assert !(config.opmEnabled && config.processOrganization &&
                     (!config.secondaryUOMEntered || !config.secondaryQuantityEntered)),
                   "OPM secondary fields required but not entered";
        }
    }
}

/* ============================================================================
 * TEST HARNESS
 * ============================================================================ */

machine TestHarness {
    var workflow: machine;

    start state Init {
        entry {
            print "TestHarness: Starting inspection workflow tests";
            workflow = new InspectionWorkflow();
            goto TestNormalAcceptFlow;
        }
    }

    state TestNormalAcceptFlow {
        entry {
            print "Test: Normal accept flow";
            send workflow, eInspectClicked;
            send workflow, eAcceptSelected;
            send workflow, eQuantityEntered, 50;
            send workflow, eQualityCodeEntered;
            send workflow, eUOMEntered;
            send workflow, eSaveClicked;
            goto TestComplete;
        }
    }

    state TestComplete {
        entry {
            print "TestHarness: Test completed";
        }
    }
}

/* ============================================================================
 * END OF SPECIFICATION
 * ============================================================================ */
