/**
 * ============================================================================
 * Oracle Purchasing Inspection Workflow - SPIN/Promela Model
 * ============================================================================
 * This Promela model specifies the inspection workflow with focus on
 * concurrency, protocol verification, and event-driven behavior.
 * ============================================================================
 */

/* Message types for workflow events */
mtype = {
    INSPECT_BUTTON_CLICKED,
    ACCEPT_SELECTED,
    REJECT_SELECTED,
    QUANTITY_ENTERED,
    UOM_ENTERED,
    QUALITY_CODE_ENTERED,
    REASON_CODE_ENTERED,
    DATE_ENTERED,
    SUPPLIER_LOT_ENTERED,
    COMMENT_ENTERED,
    SECONDARY_UOM_ENTERED,
    SECONDARY_QUANTITY_ENTERED,
    QUALITY_RESULTS_ENTERED,
    SAVE_CLICKED,
    CANCEL_CLICKED,
    REQUERY_REQUESTED,
    SAVE_SUCCESS,
    SAVE_FAILED,
    VALIDATION_OK,
    VALIDATION_FAILED
};

/* Workflow states */
#define UNINSPECTED 0
#define WINDOW_OPEN 1
#define DATA_ENTRY 2
#define QUALITY_ENTRY 3
#define SAVED 4
#define CANCELLED 5

/* Global state variables */
byte workflow_state = UNINSPECTED;
byte inspection_decision = 0;  /* 0=none, 1=accept, 2=reject */

/* Quantity tracking */
short quantity_total = 100;
short quantity_inspected = 0;
short quantity_accepted = 0;
short quantity_rejected = 0;
short quantity_uninspected = 100;

/* Field entry flags */
bool quality_code_entered = false;
bool reason_code_entered = false;
bool uom_entered = false;
bool date_entered = true;  /* Defaults to system date */
bool supplier_lot_entered = false;
bool comment_entered = false;

/* Quality integration */
bool oracle_quality_installed = false;
bool mandatory_quality_plan = false;
bool quality_results_entered = false;

/* OPM integration */
bool opm_enabled = false;
bool process_organization = false;
bool secondary_uom_entered = false;
bool secondary_quantity_entered = false;

/* System state */
bool can_requery = true;
bool validation_passed = false;

/* Communication channels */
chan user_events = [10] of {mtype};
chan system_events = [10] of {mtype};

/**
 * Helper macro to check if all required fields are entered
 */
#define required_fields_complete \
    (quality_code_entered && uom_entered && \
     (!mandatory_quality_plan || quality_results_entered) && \
     (!opm_enabled || !process_organization || \
      (secondary_uom_entered && secondary_quantity_entered)))

/**
 * Inspector Process
 * Models user interactions with the inspection workflow
 */
proctype Inspector() {
    mtype event;
    byte field_entry_count = 0;  /* Limit iterations to ensure progress */

    do
    :: workflow_state == UNINSPECTED ->
        /* Navigate to inspection window */
        user_events!INSPECT_BUTTON_CLICKED;
        workflow_state = WINDOW_OPEN;
        printf("Inspector: Opened inspection window\n");

    :: workflow_state == WINDOW_OPEN ->
        /* Select accept or reject */
        if
        :: user_events!ACCEPT_SELECTED;
           inspection_decision = 1;
           workflow_state = DATA_ENTRY;
           field_entry_count = 0;  /* Reset counter */
           printf("Inspector: Selected ACCEPT\n");

        :: user_events!REJECT_SELECTED;
           inspection_decision = 2;
           workflow_state = DATA_ENTRY;
           field_entry_count = 0;  /* Reset counter */
           printf("Inspector: Selected REJECT\n");

        :: user_events!CANCEL_CLICKED;
           workflow_state = CANCELLED;
           printf("Inspector: Cancelled inspection\n");
           break;
        fi

    :: workflow_state == DATA_ENTRY ->
        /* Enter required data */
        if
        :: !quality_code_entered && field_entry_count < 10 ->
           user_events!QUALITY_CODE_ENTERED;
           quality_code_entered = true;
           field_entry_count++;
           printf("Inspector: Entered quality code\n");

        :: !uom_entered && field_entry_count < 10 ->
           user_events!UOM_ENTERED;
           uom_entered = true;
           field_entry_count++;
           printf("Inspector: Entered UOM\n");

        :: !reason_code_entered && field_entry_count < 10 ->
           user_events!REASON_CODE_ENTERED;
           reason_code_entered = true;
           field_entry_count++;
           printf("Inspector: Entered reason code\n");

        :: !supplier_lot_entered && field_entry_count < 10 ->
           user_events!SUPPLIER_LOT_ENTERED;
           supplier_lot_entered = true;
           field_entry_count++;
           printf("Inspector: Entered supplier lot\n");

        :: quantity_inspected < quantity_uninspected && field_entry_count < 10 ->
           user_events!QUANTITY_ENTERED;
           quantity_inspected = quantity_inspected + 10;
           if
           :: quantity_inspected > quantity_uninspected ->
              quantity_inspected = quantity_uninspected;
           :: else -> skip;
           fi
           field_entry_count++;
           printf("Inspector: Entered quantity %d\n", quantity_inspected);

        :: opm_enabled && process_organization && !secondary_uom_entered && field_entry_count < 10 ->
           user_events!SECONDARY_UOM_ENTERED;
           secondary_uom_entered = true;
           field_entry_count++;
           printf("Inspector: Entered secondary UOM\n");

        :: opm_enabled && process_organization && !secondary_quantity_entered && field_entry_count < 10 ->
           user_events!SECONDARY_QUANTITY_ENTERED;
           secondary_quantity_entered = true;
           field_entry_count++;
           printf("Inspector: Entered secondary quantity\n");

        :: mandatory_quality_plan && !quality_results_entered && field_entry_count < 10 ->
           /* Must enter quality results */
           workflow_state = QUALITY_ENTRY;
           printf("Inspector: Navigating to quality entry\n");

        :: required_fields_complete || field_entry_count >= 10 ->
           /* Attempt to save (forced after 10 field entries to ensure progress) */
           user_events!SAVE_CLICKED;
           system_events?event;
           if
           :: event == SAVE_SUCCESS ->
              workflow_state = SAVED;
              printf("Inspector: Save successful\n");

              /* Update quantities */
              if
              :: inspection_decision == 1 ->  /* Accept */
                 quantity_accepted = quantity_accepted + quantity_inspected;
              :: inspection_decision == 2 ->  /* Reject */
                 quantity_rejected = quantity_rejected + quantity_inspected;
              fi
              quantity_uninspected = quantity_uninspected - quantity_inspected;
              quantity_inspected = 0;

              /* Reset fields */
              quality_code_entered = false;
              reason_code_entered = false;
              uom_entered = false;
              supplier_lot_entered = false;
              comment_entered = false;
              quality_results_entered = false;
              secondary_uom_entered = false;
              secondary_quantity_entered = false;
              inspection_decision = 0;
              field_entry_count = 0;

              /* Check if more inspection needed */
              if
              :: quantity_uninspected > 0 ->
                 can_requery = true;
              :: else ->
                 can_requery = false;
                 break;
              fi

           :: event == SAVE_FAILED ->
              printf("Inspector: Save failed - validation error\n");
              field_entry_count = 0;  /* Reset to try again */
           fi

        :: true ->  /* Always allow cancel to ensure progress */
           user_events!CANCEL_CLICKED;
           workflow_state = CANCELLED;
           printf("Inspector: Cancelled inspection\n");
           break;
        fi

    :: workflow_state == QUALITY_ENTRY ->
        /* Enter quality results */
        if
        :: !quality_results_entered ->
           user_events!QUALITY_RESULTS_ENTERED;
           quality_results_entered = true;
           workflow_state = DATA_ENTRY;
           printf("Inspector: Entered quality results\n");

        :: user_events!CANCEL_CLICKED;
           workflow_state = CANCELLED;
           printf("Inspector: Cancelled from quality entry\n");
           break;
        fi

    :: workflow_state == SAVED && can_requery ->
        /* Re-query for more inspection */
        user_events!REQUERY_REQUESTED;
        workflow_state = WINDOW_OPEN;
        printf("Inspector: Re-queried for more inspection\n");

    :: workflow_state == SAVED && !can_requery ->
        printf("Inspector: All items inspected - workflow complete\n");
        break;

    :: workflow_state == CANCELLED ->
        printf("Inspector: Workflow cancelled\n");
        break;

    :: timeout ->
        printf("Inspector: Timeout\n");
        break;
    od
}

/**
 * System Process
 * Models system responses and business rule enforcement
 */
proctype System() {
    mtype event;

    do
    :: user_events?event ->
        if
        :: event == SAVE_CLICKED ->
            /* Validate before save */
            validation_passed = required_fields_complete;

            if
            :: validation_passed ->
               /* Check quantity conservation */
               assert(quantity_accepted + quantity_rejected + quantity_uninspected == quantity_total);
               system_events!SAVE_SUCCESS;
               printf("System: Save validation passed\n");

            :: !validation_passed ->
               system_events!SAVE_FAILED;
               printf("System: Save validation failed\n");
            fi

        :: event == QUALITY_RESULTS_ENTERED ->
            printf("System: Quality results recorded\n");

        :: else ->
            printf("System: Processed event\n");
        fi

    :: timeout ->
        break;
    od
}

/**
 * Monitor Process
 * Monitors invariants and properties during execution
 */
proctype Monitor() {
    do
    :: true ->
        /* Check quantity conservation */
        assert(quantity_accepted + quantity_rejected + quantity_uninspected == quantity_total);

        /* Check no negative quantities */
        assert(quantity_accepted >= 0);
        assert(quantity_rejected >= 0);
        assert(quantity_uninspected >= 0);
        assert(quantity_inspected >= 0);

        /* Check inspected quantity bounds */
        assert(quantity_inspected <= quantity_uninspected);

        /* Check decision exclusivity */
        assert(!(inspection_decision == 1 && inspection_decision == 2));

        /* Check mandatory quality requirement */
        assert(!(workflow_state == SAVED && mandatory_quality_plan && !quality_results_entered));

        /* Check OPM requirements */
        assert(!(workflow_state == SAVED && opm_enabled && process_organization &&
                 (!secondary_uom_entered || !secondary_quantity_entered)));
    od
}

/**
 * Initialization
 */
init {
    /* Start processes */
    atomic {
        run Inspector();
        run System();
        run Monitor();
    }
}

/**
 * ============================================================================
 * LTL Properties for SPIN Verification
 * ============================================================================
 */

/* Property 1: Progress - inspection eventually completes */
ltl progress {
    [](workflow_state == WINDOW_OPEN -> <>(workflow_state == SAVED || workflow_state == CANCELLED))
}

/* Property 2: Eventually reach terminal state */
ltl termination {
    <>(workflow_state == SAVED || workflow_state == CANCELLED)
}

/* Property 3: Mandatory quality before save */
ltl quality_before_save {
    []((mandatory_quality_plan && !quality_results_entered) -> !(workflow_state == SAVED))
}

/* Property 4: Quantity conservation always holds */
ltl conservation {
    [](quantity_accepted + quantity_rejected + quantity_uninspected == quantity_total)
}

/* Property 5: No negative quantities */
ltl no_negative_quantities {
    [](quantity_accepted >= 0 && quantity_rejected >= 0 && quantity_uninspected >= 0)
}

/* Property 6: Save requires required fields */
ltl save_requires_fields {
    [](workflow_state == SAVED -> quality_code_entered && uom_entered)
}

/* Property 7: OPM fields when required */
ltl opm_fields_required {
    []((opm_enabled && process_organization && workflow_state == SAVED) ->
       (secondary_uom_entered && secondary_quantity_entered))
}

/* Property 8: Cannot save with incomplete inspection decision */
ltl decision_required {
    [](workflow_state == SAVED -> (inspection_decision == 1 || inspection_decision == 2))
}

/* Property 9: Proper state sequence */
ltl state_sequence {
    [](workflow_state == DATA_ENTRY -> (X(workflow_state != UNINSPECTED) U workflow_state == SAVED))
}

/* Property 10: Cancel is always possible before save */
ltl can_cancel {
    []((workflow_state == WINDOW_OPEN || workflow_state == DATA_ENTRY || workflow_state == QUALITY_ENTRY) ->
       <>(workflow_state == CANCELLED || workflow_state == SAVED))
}

/**
 * ============================================================================
 * END OF SPECIFICATION
 * ============================================================================
 */
