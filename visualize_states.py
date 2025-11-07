#!/usr/bin/env python3
"""
============================================================================
Oracle Inspection Workflow - State Machine Visualization
============================================================================
This script generates visual representations of the inspection workflow
state machine using Graphviz.
============================================================================
"""

import sys
import os


def create_state_diagram():
    """Create visual representation of inspection workflow states"""
    try:
        import graphviz
    except ImportError:
        print("Error: graphviz package not installed")
        print("Install with: pip install graphviz")
        return False

    # Create directed graph
    dot = graphviz.Digraph(
        'InspectionWorkflow',
        comment='Oracle Purchasing Inspection Workflow State Machine',
        format='png'
    )

    # Set graph attributes
    dot.attr(rankdir='TB', size='12,16')
    dot.attr('node', shape='box', style='rounded,filled', fillcolor='lightblue',
             fontname='Arial', fontsize='11')
    dot.attr('edge', fontname='Arial', fontsize='9')

    # Define states
    states = {
        'uninspected': {
            'label': 'Uninspected\n(Initial State)',
            'fillcolor': 'lightgreen'
        },
        'inspection_window_open': {
            'label': 'Inspection Window Open\n(User navigated to inspection)',
            'fillcolor': 'lightyellow'
        },
        'data_entry': {
            'label': 'Data Entry\n(Entering inspection details)',
            'fillcolor': 'lightcyan'
        },
        'quality_entry': {
            'label': 'Quality Entry\n(Mandatory quality results)',
            'fillcolor': 'lavender'
        },
        'saved': {
            'label': 'Saved\n(Inspection completed)',
            'fillcolor': 'lightgreen'
        },
        'cancelled': {
            'label': 'Cancelled\n(Inspection cancelled)',
            'fillcolor': 'lightcoral'
        }
    }

    # Add states to graph
    for state_id, attrs in states.items():
        dot.node(state_id, attrs['label'], fillcolor=attrs['fillcolor'])

    # Add initial state marker
    dot.node('start', '', shape='circle', fillcolor='black', width='0.3')
    dot.edge('start', 'uninspected')

    # Define transitions
    transitions = [
        # From uninspected
        {
            'from': 'uninspected',
            'to': 'inspection_window_open',
            'label': 'Click Inspect Button'
        },

        # From inspection_window_open
        {
            'from': 'inspection_window_open',
            'to': 'data_entry',
            'label': 'Select Accept'
        },
        {
            'from': 'inspection_window_open',
            'to': 'data_entry',
            'label': 'Select Reject'
        },
        {
            'from': 'inspection_window_open',
            'to': 'cancelled',
            'label': 'Click Cancel'
        },

        # From data_entry
        {
            'from': 'data_entry',
            'to': 'quality_entry',
            'label': 'Mandatory Quality Plan\n& Quality Not Entered'
        },
        {
            'from': 'data_entry',
            'to': 'saved',
            'label': 'Click Save\n[All Required Fields Entered]\n[No Mandatory Quality OR\nQuality Results Entered]\n[OPM Secondary Fields If Needed]',
            'color': 'darkgreen',
            'fontcolor': 'darkgreen'
        },
        {
            'from': 'data_entry',
            'to': 'cancelled',
            'label': 'Click Cancel'
        },

        # From quality_entry
        {
            'from': 'quality_entry',
            'to': 'data_entry',
            'label': 'Enter Quality Results'
        },
        {
            'from': 'quality_entry',
            'to': 'cancelled',
            'label': 'Click Cancel'
        },

        # From saved (re-query)
        {
            'from': 'saved',
            'to': 'inspection_window_open',
            'label': 'Re-query\n[Uninspected Items > 0]',
            'style': 'dashed',
            'color': 'blue'
        }
    ]

    # Add transitions to graph
    for trans in transitions:
        edge_attrs = {
            'label': trans['label'],
            'color': trans.get('color', 'black'),
            'fontcolor': trans.get('fontcolor', 'black'),
            'style': trans.get('style', 'solid')
        }
        dot.edge(trans['from'], trans['to'], **edge_attrs)

    # Save the graph
    output_dir = 'results'
    os.makedirs(output_dir, exist_ok=True)

    try:
        # Render as PNG
        dot.render(os.path.join(output_dir, 'state_diagram'), cleanup=True)
        print(f"✓ State diagram saved to: {output_dir}/state_diagram.png")

        # Also save DOT source
        with open(os.path.join(output_dir, 'state_diagram.dot'), 'w') as f:
            f.write(dot.source)
        print(f"✓ DOT source saved to: {output_dir}/state_diagram.dot")

        return True
    except Exception as e:
        print(f"✗ Error rendering diagram: {e}")
        return False


def create_detailed_transition_diagram():
    """Create detailed diagram showing all transitions and guards"""
    try:
        import graphviz
    except ImportError:
        return False

    dot = graphviz.Digraph(
        'DetailedWorkflow',
        comment='Detailed Inspection Workflow with Guards',
        format='png'
    )

    dot.attr(rankdir='LR', size='16,12')
    dot.attr('node', shape='box', style='rounded', fontname='Arial', fontsize='10')
    dot.attr('edge', fontname='Arial', fontsize='8')

    # Create subgraph for main flow
    with dot.subgraph(name='cluster_main') as c:
        c.attr(label='Main Inspection Flow', style='rounded', color='blue')

        c.node('S0', 'Uninspected\n\nquantity_uninspected = total')
        c.node('S1', 'Window Open\n\nAwaiting decision')
        c.node('S2', 'Data Entry\n\nEntering fields')
        c.node('S4', 'Saved\n\nInspection recorded')

        c.edge('S0', 'S1', label='eInspectClicked')
        c.edge('S1', 'S2', label='eAcceptSelected |\neRejectSelected')
        c.edge('S2', 'S4',
               label='eSaveClicked\n[quality_code_entered]\n[uom_entered]\n'
                     '[!mandatory_quality | quality_results]\n'
                     '[!opm | secondary_fields]')

    # Create subgraph for quality flow
    with dot.subgraph(name='cluster_quality') as c:
        c.attr(label='Quality Results Flow', style='rounded', color='purple')

        c.node('S3', 'Quality Entry\n\nEntering quality results')
        c.edge('S2', 'S3',
               label='[mandatory_quality_plan]\n[!quality_results_entered]',
               style='dashed')
        c.edge('S3', 'S2', label='eQualityResultsEntered')

    # Create subgraph for terminal states
    with dot.subgraph(name='cluster_terminal') as c:
        c.attr(label='Terminal States', style='rounded', color='gray')

        c.node('S5', 'Cancelled', fillcolor='lightcoral', style='filled,rounded')
        c.node('S6', 'Completed\n\nAll items inspected',
               fillcolor='lightgreen', style='filled,rounded')

    # Add cancel transitions
    dot.edge('S1', 'S5', label='eCancelClicked', color='red')
    dot.edge('S2', 'S5', label='eCancelClicked', color='red')
    dot.edge('S3', 'S5', label='eCancelClicked', color='red')

    # Add re-query loop
    dot.edge('S4', 'S1',
             label='eRequeryRequested\n[quantity_uninspected > 0]',
             style='dashed', color='blue')

    # Add completion
    dot.edge('S4', 'S6',
             label='[quantity_uninspected = 0]',
             color='green', style='bold')

    # Save the graph
    output_dir = 'results'
    try:
        dot.render(os.path.join(output_dir, 'detailed_state_diagram'), cleanup=True)
        print(f"✓ Detailed state diagram saved to: {output_dir}/detailed_state_diagram.png")
        return True
    except Exception as e:
        print(f"✗ Error rendering detailed diagram: {e}")
        return False


def create_property_diagram():
    """Create diagram showing key properties and invariants"""
    try:
        import graphviz
    except ImportError:
        return False

    dot = graphviz.Digraph(
        'Properties',
        comment='Inspection Workflow Properties',
        format='png'
    )

    dot.attr(rankdir='TB', size='10,12')
    dot.attr('node', shape='box', fontname='Arial', fontsize='10')

    # Main workflow node
    dot.node('workflow', 'Inspection Workflow',
             shape='ellipse', fillcolor='lightblue', style='filled')

    # Safety properties
    with dot.subgraph(name='cluster_safety') as c:
        c.attr(label='Safety Properties', style='rounded', color='red')

        c.node('P1', 'Quantity Conservation\naccepted + rejected +\nuninspected = total',
               fillcolor='lightgreen', style='filled')
        c.node('P2', 'No Negative Quantities\nall quantities >= 0',
               fillcolor='lightgreen', style='filled')
        c.node('P3', 'Required Fields\nquality_code && uom',
               fillcolor='lightgreen', style='filled')
        c.node('P4', 'Mandatory Quality\nresults entered if required',
               fillcolor='lightgreen', style='filled')

    # Liveness properties
    with dot.subgraph(name='cluster_liveness') as c:
        c.attr(label='Liveness Properties', style='rounded', color='blue')

        c.node('L1', 'Progress\neventually saved or cancelled',
               fillcolor='lightyellow', style='filled')
        c.node('L2', 'Quality Entry\neventually entered if mandatory',
               fillcolor='lightyellow', style='filled')
        c.node('L3', 'Inspection Completion\nall items eventually inspected',
               fillcolor='lightyellow', style='filled')

    # Connect workflow to properties
    for node in ['P1', 'P2', 'P3', 'P4', 'L1', 'L2', 'L3']:
        dot.edge('workflow', node, style='dashed', arrowhead='none')

    # Save the graph
    output_dir = 'results'
    try:
        dot.render(os.path.join(output_dir, 'properties_diagram'), cleanup=True)
        print(f"✓ Properties diagram saved to: {output_dir}/properties_diagram.png")
        return True
    except Exception as e:
        print(f"✗ Error rendering properties diagram: {e}")
        return False


def main():
    """Main entry point"""
    print("=" * 80)
    print("Oracle Inspection Workflow - State Machine Visualization")
    print("=" * 80)
    print()

    # Check for graphviz
    try:
        import graphviz
        print("✓ Graphviz package found")
    except ImportError:
        print("✗ Graphviz package not installed")
        print("\nInstall with:")
        print("  pip install graphviz")
        print("\nNote: Also requires Graphviz system package")
        print("  Ubuntu/Debian: sudo apt-get install graphviz")
        print("  macOS: brew install graphviz")
        print("  Windows: https://graphviz.org/download/")
        return 1

    print()

    # Create diagrams
    success = True

    print("Creating state diagram...")
    if not create_state_diagram():
        success = False
        print("✗ Failed to create state diagram")

    print("\nCreating detailed transition diagram...")
    if not create_detailed_transition_diagram():
        success = False
        print("✗ Failed to create detailed diagram")

    print("\nCreating properties diagram...")
    if not create_property_diagram():
        success = False
        print("✗ Failed to create properties diagram")

    print()
    print("=" * 80)
    if success:
        print("✓ All diagrams generated successfully")
        print("Diagrams saved to: results/")
        print("  - state_diagram.png")
        print("  - detailed_state_diagram.png")
        print("  - properties_diagram.png")
    else:
        print("⚠ Some diagrams failed to generate")
    print("=" * 80)

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
