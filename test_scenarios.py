#!/usr/bin/env python3
"""
============================================================================
Oracle Inspection Workflow - Test Scenarios
============================================================================
This module provides comprehensive test scenarios for verifying the
inspection workflow formal specifications.
============================================================================
"""

import unittest
from dataclasses import dataclass
from typing import List, Optional
from enum import Enum


class WorkflowState(Enum):
    """Workflow state enumeration"""
    UNINSPECTED = "uninspected"
    INSPECTION_WINDOW_OPEN = "inspection_window_open"
    DATA_ENTRY = "data_entry"
    QUALITY_ENTRY = "quality_entry"
    SAVED = "saved"
    CANCELLED = "cancelled"


class InspectionDecision(Enum):
    """Inspection decision enumeration"""
    NONE = "none"
    ACCEPT = "accept"
    REJECT = "reject"


@dataclass
class InspectionData:
    """Data structure for inspection quantities"""
    quantity_total: int = 100
    quantity_inspected: int = 0
    quantity_accepted: int = 0
    quantity_rejected: int = 0
    quantity_uninspected: int = 100

    def validate_conservation(self) -> bool:
        """Verify quantity conservation property"""
        return (self.quantity_accepted + self.quantity_rejected +
                self.quantity_uninspected == self.quantity_total)


@dataclass
class FieldsData:
    """Data structure for required fields"""
    quality_code_entered: bool = False
    reason_code_entered: bool = False
    uom_entered: bool = False
    date_entered: bool = True  # Defaults to system date
    supplier_lot_entered: bool = False
    comment_entered: bool = False


@dataclass
class IntegrationConfig:
    """Configuration for Oracle integrations"""
    oracle_quality_installed: bool = False
    mandatory_quality_plan: bool = False
    quality_results_entered: bool = False
    opm_enabled: bool = False
    process_organization: bool = False
    secondary_uom_entered: bool = False
    secondary_quantity_entered: bool = False


class InspectionWorkflow:
    """
    Simulated inspection workflow for testing.
    This mirrors the behavior specified in the formal models.
    """

    def __init__(self):
        self.state = WorkflowState.UNINSPECTED
        self.decision = InspectionDecision.NONE
        self.data = InspectionData()
        self.fields = FieldsData()
        self.config = IntegrationConfig()
        self.can_requery = True
        self.errors: List[str] = []

    def click_inspect(self) -> bool:
        """Navigate to inspection window"""
        if self.state != WorkflowState.UNINSPECTED:
            self.errors.append("Can only click inspect from uninspected state")
            return False
        self.state = WorkflowState.INSPECTION_WINDOW_OPEN
        return True

    def select_accept(self) -> bool:
        """Select accept decision"""
        if self.state != WorkflowState.INSPECTION_WINDOW_OPEN:
            self.errors.append("Must be in inspection window to select accept")
            return False
        self.decision = InspectionDecision.ACCEPT
        self.state = WorkflowState.DATA_ENTRY
        return True

    def select_reject(self) -> bool:
        """Select reject decision"""
        if self.state != WorkflowState.INSPECTION_WINDOW_OPEN:
            self.errors.append("Must be in inspection window to select reject")
            return False
        self.decision = InspectionDecision.REJECT
        self.state = WorkflowState.DATA_ENTRY
        return True

    def enter_quantity(self, quantity: int) -> bool:
        """Enter inspection quantity"""
        if self.state != WorkflowState.DATA_ENTRY:
            self.errors.append("Must be in data entry to enter quantity")
            return False
        if quantity <= 0:
            self.errors.append("Quantity must be positive")
            return False
        if quantity > self.data.quantity_uninspected:
            self.errors.append("Cannot inspect more than uninspected quantity")
            return False
        self.data.quantity_inspected = quantity
        return True

    def enter_required_fields(self) -> bool:
        """Enter all required fields"""
        if self.state != WorkflowState.DATA_ENTRY:
            self.errors.append("Must be in data entry to enter fields")
            return False
        self.fields.quality_code_entered = True
        self.fields.uom_entered = True
        self.fields.reason_code_entered = True
        self.fields.supplier_lot_entered = True
        return True

    def enter_quality_results(self) -> bool:
        """Enter quality results"""
        if self.state != WorkflowState.QUALITY_ENTRY:
            self.errors.append("Must be in quality entry to enter results")
            return False
        self.config.quality_results_entered = True
        self.state = WorkflowState.DATA_ENTRY
        return True

    def enter_secondary_fields(self) -> bool:
        """Enter OPM secondary fields"""
        if self.state != WorkflowState.DATA_ENTRY:
            self.errors.append("Must be in data entry to enter secondary fields")
            return False
        if not (self.config.opm_enabled and self.config.process_organization):
            self.errors.append("Secondary fields only for OPM process organizations")
            return False
        self.config.secondary_uom_entered = True
        self.config.secondary_quantity_entered = True
        return True

    def validate_save(self) -> bool:
        """Validate all conditions for save"""
        # Check required fields
        if not self.fields.quality_code_entered:
            self.errors.append("Quality code required")
            return False
        if not self.fields.uom_entered:
            self.errors.append("UOM required")
            return False

        # Check mandatory quality results
        if self.config.mandatory_quality_plan and not self.config.quality_results_entered:
            self.errors.append("Mandatory quality results required")
            return False

        # Check OPM secondary fields
        if self.config.opm_enabled and self.config.process_organization:
            if not (self.config.secondary_uom_entered and
                    self.config.secondary_quantity_entered):
                self.errors.append("OPM secondary fields required")
                return False

        # Check quantity
        if self.data.quantity_inspected <= 0:
            self.errors.append("Must inspect at least one item")
            return False

        return True

    def save(self) -> bool:
        """Save inspection"""
        if self.state not in [WorkflowState.DATA_ENTRY, WorkflowState.QUALITY_ENTRY]:
            self.errors.append("Can only save from data entry or quality entry")
            return False

        if not self.validate_save():
            return False

        # Update quantities based on decision
        if self.decision == InspectionDecision.ACCEPT:
            self.data.quantity_accepted += self.data.quantity_inspected
        elif self.decision == InspectionDecision.REJECT:
            self.data.quantity_rejected += self.data.quantity_inspected
        else:
            self.errors.append("Must make accept/reject decision")
            return False

        self.data.quantity_uninspected -= self.data.quantity_inspected

        # Verify conservation
        if not self.data.validate_conservation():
            self.errors.append("Quantity conservation violated!")
            return False

        # Reset for next inspection
        self.data.quantity_inspected = 0
        self.fields = FieldsData()
        self.config.quality_results_entered = False
        self.config.secondary_uom_entered = False
        self.config.secondary_quantity_entered = False
        self.decision = InspectionDecision.NONE
        self.state = WorkflowState.SAVED
        self.can_requery = self.data.quantity_uninspected > 0

        return True

    def cancel(self) -> bool:
        """Cancel inspection"""
        if self.state not in [WorkflowState.INSPECTION_WINDOW_OPEN,
                               WorkflowState.DATA_ENTRY,
                               WorkflowState.QUALITY_ENTRY]:
            self.errors.append("Cannot cancel from this state")
            return False
        self.state = WorkflowState.CANCELLED
        return True

    def requery(self) -> bool:
        """Re-query for more inspection"""
        if self.state != WorkflowState.SAVED:
            self.errors.append("Can only requery from saved state")
            return False
        if not self.can_requery:
            self.errors.append("No uninspected items remaining")
            return False
        self.state = WorkflowState.INSPECTION_WINDOW_OPEN
        return True


class TestNormalFlow(unittest.TestCase):
    """Test normal workflow scenarios"""

    def test_accept_normal_flow(self):
        """Test accepting items with all required fields"""
        workflow = InspectionWorkflow()

        # Navigate to inspection
        self.assertTrue(workflow.click_inspect())
        self.assertEqual(workflow.state, WorkflowState.INSPECTION_WINDOW_OPEN)

        # Select accept
        self.assertTrue(workflow.select_accept())
        self.assertEqual(workflow.state, WorkflowState.DATA_ENTRY)
        self.assertEqual(workflow.decision, InspectionDecision.ACCEPT)

        # Enter data
        self.assertTrue(workflow.enter_quantity(50))
        self.assertTrue(workflow.enter_required_fields())

        # Save
        self.assertTrue(workflow.save())
        self.assertEqual(workflow.state, WorkflowState.SAVED)
        self.assertEqual(workflow.data.quantity_accepted, 50)
        self.assertEqual(workflow.data.quantity_uninspected, 50)
        self.assertTrue(workflow.data.validate_conservation())

    def test_reject_normal_flow(self):
        """Test rejecting items with all required fields"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_reject()
        workflow.enter_quantity(30)
        workflow.enter_required_fields()

        self.assertTrue(workflow.save())
        self.assertEqual(workflow.data.quantity_rejected, 30)
        self.assertEqual(workflow.data.quantity_uninspected, 70)
        self.assertTrue(workflow.data.validate_conservation())

    def test_partial_inspection(self):
        """Test inspecting partial quantity"""
        workflow = InspectionWorkflow()

        # First inspection - accept 40
        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(40)
        workflow.enter_required_fields()
        workflow.save()

        self.assertEqual(workflow.data.quantity_accepted, 40)
        self.assertEqual(workflow.data.quantity_uninspected, 60)
        self.assertTrue(workflow.can_requery)

        # Re-query for second inspection - reject 30
        self.assertTrue(workflow.requery())
        workflow.select_reject()
        workflow.enter_quantity(30)
        workflow.enter_required_fields()
        workflow.save()

        self.assertEqual(workflow.data.quantity_accepted, 40)
        self.assertEqual(workflow.data.quantity_rejected, 30)
        self.assertEqual(workflow.data.quantity_uninspected, 30)
        self.assertTrue(workflow.data.validate_conservation())

    def test_cancel_flow(self):
        """Test cancelling inspection"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()

        self.assertTrue(workflow.cancel())
        self.assertEqual(workflow.state, WorkflowState.CANCELLED)
        self.assertEqual(workflow.data.quantity_accepted, 0)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and error conditions"""

    def test_save_without_quality_code(self):
        """Should fail - quality code required"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        # Don't enter quality code

        self.assertFalse(workflow.save())
        self.assertIn("Quality code required", workflow.errors)

    def test_save_without_uom(self):
        """Should fail - UOM required"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.fields.quality_code_entered = True
        # Don't enter UOM

        self.assertFalse(workflow.save())
        self.assertIn("UOM required", workflow.errors)

    def test_mandatory_quality_not_entered(self):
        """Should fail - mandatory quality results required"""
        workflow = InspectionWorkflow()
        workflow.config.mandatory_quality_plan = True

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.enter_required_fields()
        # Don't enter quality results

        self.assertFalse(workflow.save())
        self.assertIn("Mandatory quality results required", workflow.errors)

    def test_inspect_after_save_without_requery(self):
        """Should fail - must requery"""
        workflow = InspectionWorkflow()

        # Complete first inspection
        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.enter_required_fields()
        workflow.save()

        # Try to click inspect without requery
        workflow.state = WorkflowState.UNINSPECTED  # Force invalid state
        self.assertFalse(workflow.click_inspect())

    def test_negative_quantity(self):
        """Should fail - quantity must be positive"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()

        self.assertFalse(workflow.enter_quantity(-10))
        self.assertIn("Quantity must be positive", workflow.errors)

    def test_excessive_quantity(self):
        """Should fail - cannot exceed uninspected quantity"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()

        self.assertFalse(workflow.enter_quantity(200))
        self.assertIn("Cannot inspect more than uninspected quantity", workflow.errors)


class TestIntegration(unittest.TestCase):
    """Test integration scenarios"""

    def test_oracle_quality_integration(self):
        """Test with Oracle Quality installed"""
        workflow = InspectionWorkflow()
        workflow.config.oracle_quality_installed = True
        workflow.config.mandatory_quality_plan = True

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.enter_required_fields()

        # Must enter quality results
        workflow.state = WorkflowState.QUALITY_ENTRY
        workflow.enter_quality_results()

        self.assertTrue(workflow.save())
        self.assertTrue(workflow.config.quality_results_entered)

    def test_opm_process_organization(self):
        """Test with OPM enabled and process organization"""
        workflow = InspectionWorkflow()
        workflow.config.opm_enabled = True
        workflow.config.process_organization = True

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.enter_required_fields()

        # Must enter secondary fields
        self.assertTrue(workflow.enter_secondary_fields())
        self.assertTrue(workflow.save())

    def test_opm_without_secondary_fields(self):
        """Should fail - OPM secondary fields required"""
        workflow = InspectionWorkflow()
        workflow.config.opm_enabled = True
        workflow.config.process_organization = True

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(50)
        workflow.enter_required_fields()
        # Don't enter secondary fields

        self.assertFalse(workflow.save())
        self.assertIn("OPM secondary fields required", workflow.errors)


class TestQuantityConservation(unittest.TestCase):
    """Test quantity conservation property"""

    def test_conservation_after_accept(self):
        """Verify conservation after accepting items"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(75)
        workflow.enter_required_fields()
        workflow.save()

        self.assertTrue(workflow.data.validate_conservation())

    def test_conservation_after_reject(self):
        """Verify conservation after rejecting items"""
        workflow = InspectionWorkflow()

        workflow.click_inspect()
        workflow.select_reject()
        workflow.enter_quantity(60)
        workflow.enter_required_fields()
        workflow.save()

        self.assertTrue(workflow.data.validate_conservation())

    def test_conservation_multiple_inspections(self):
        """Verify conservation across multiple inspections"""
        workflow = InspectionWorkflow()

        # Accept 40
        workflow.click_inspect()
        workflow.select_accept()
        workflow.enter_quantity(40)
        workflow.enter_required_fields()
        workflow.save()
        self.assertTrue(workflow.data.validate_conservation())

        # Reject 30
        workflow.requery()
        workflow.select_reject()
        workflow.enter_quantity(30)
        workflow.enter_required_fields()
        workflow.save()
        self.assertTrue(workflow.data.validate_conservation())

        # Accept remaining 30
        workflow.requery()
        workflow.select_accept()
        workflow.enter_quantity(30)
        workflow.enter_required_fields()
        workflow.save()
        self.assertTrue(workflow.data.validate_conservation())

        self.assertEqual(workflow.data.quantity_accepted, 70)
        self.assertEqual(workflow.data.quantity_rejected, 30)
        self.assertEqual(workflow.data.quantity_uninspected, 0)


def main():
    """Run all tests"""
    print("=" * 80)
    print("Oracle Inspection Workflow - Test Suite")
    print("=" * 80)
    print()

    # Run tests with verbose output
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Add all test cases
    suite.addTests(loader.loadTestsFromTestCase(TestNormalFlow))
    suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))
    suite.addTests(loader.loadTestsFromTestCase(TestIntegration))
    suite.addTests(loader.loadTestsFromTestCase(TestQuantityConservation))

    # Run with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    print()
    print("=" * 80)
    print(f"Tests run: {result.testsRun}")
    print(f"Successes: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print("=" * 80)

    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    exit(main())
