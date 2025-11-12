#!/bin/bash
# ============================================================================
# Generate Inspection Workflow Process Diagram
# ============================================================================
# This script renders the Graphviz DOT file into various image formats
# ============================================================================

set -e

echo "============================================"
echo "Generating Inspection Workflow Process Diagram"
echo "============================================"
echo ""

# Create results directory
mkdir -p results

# Check if Graphviz is installed
if ! command -v dot &> /dev/null; then
    echo "ERROR: Graphviz (dot) is not installed or not in PATH"
    echo ""
    echo "Installation:"
    echo "  Ubuntu/Debian: sudo apt-get install graphviz"
    echo "  macOS: brew install graphviz"
    echo "  Windows: https://graphviz.org/download/"
    echo ""
    exit 1
fi

# Check if input file exists
if [ ! -f "inspection_workflow_process.dot" ]; then
    echo "ERROR: inspection_workflow_process.dot not found"
    exit 1
fi

echo "Rendering workflow process diagram..."
echo ""

# Generate PNG (default)
if dot -Tpng inspection_workflow_process.dot -o results/inspection_workflow_process.png; then
    echo "✓ PNG diagram created: results/inspection_workflow_process.png"
else
    echo "✗ Failed to create PNG diagram"
    exit 1
fi

# Generate SVG (scalable)
if dot -Tsvg inspection_workflow_process.dot -o results/inspection_workflow_process.svg; then
    echo "✓ SVG diagram created: results/inspection_workflow_process.svg"
else
    echo "⚠ Failed to create SVG diagram"
fi

# Generate PDF (for documents)
if dot -Tpdf inspection_workflow_process.dot -o results/inspection_workflow_process.pdf; then
    echo "✓ PDF diagram created: results/inspection_workflow_process.pdf"
else
    echo "⚠ Failed to create PDF diagram"
fi

echo ""
echo "============================================"
echo "Diagram Generation Complete"
echo "============================================"
echo ""
echo "Generated files:"
echo "  - results/inspection_workflow_process.png (bitmap)"
echo "  - results/inspection_workflow_process.svg (vector)"
echo "  - results/inspection_workflow_process.pdf (document)"
echo ""
echo "View the diagram:"
echo "  Linux:   xdg-open results/inspection_workflow_process.png"
echo "  macOS:   open results/inspection_workflow_process.png"
echo "  Windows: start results/inspection_workflow_process.png"
echo ""
echo "============================================"

exit 0
