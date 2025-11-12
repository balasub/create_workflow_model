# Inspection Workflow Process Diagram - Guide

## Overview

The `inspection_workflow_process.dot` file contains a comprehensive Graphviz visualization of the complete Oracle Purchasing inspection workflow. This diagram provides a high-level view of the entire process, complementing the detailed formal specifications.

## What's Included

### 1. Workflow States
The diagram shows all major workflow states:
- **Uninspected** - Initial state with quantity information
- **Inspection Window Open** - User viewing receiving transactions
- **Data Entry** - Entering inspection details
- **Quality Entry** - Entering mandatory quality results (conditional)
- **Saved** - Inspection successfully recorded
- **Cancelled** - Inspection aborted
- **Complete** - All items inspected

### 2. Decision Points
Key decision points are shown as diamonds:
- **Select Accept or Reject?** - User chooses inspection outcome
- **All validations passed?** - System validation checkpoint
- **More items to inspect?** - Determines if re-query needed

### 3. User Actions
All user interactions are clearly marked:
- Click Inspect Button
- Select Accept / Select Reject
- Enter Quantity
- Enter Required Fields
- Enter Quality Results
- Enter OPM Secondary Fields
- Click Save
- Click Cancel
- Re-query for More Items

### 4. Integration Points

#### Oracle Quality Integration (Purple cluster)
- Shows conditional flow for Oracle Quality
- Checks for Oracle Quality installation
- Checks for mandatory quality plan
- Routes to Quality Entry state when required

#### OPM Integration (Blue cluster)
- Shows conditional flow for OPM
- Checks for OPM enabled and process organization
- Routes to secondary field entry when required

### 5. Validation Flow
The diagram shows the complete validation process:
- Validation checks performed
- All required conditions listed
- Pass/fail routing
- Error correction path back to data entry

### 6. Quantity Tracking
Example showing quantity evolution:
- **Initial**: total=100, uninspected=100, accepted=0, rejected=0
- **Inspect 50**: inspected=50
- **After Accept**: accepted=50, uninspected=50

### 7. Key Constraints & Properties
Panel showing 4 critical properties:
1. **Quantity Conservation**: accepted + rejected + uninspected = total (ALWAYS)
2. **Required Fields**: quality_code && uom (BEFORE SAVE)
3. **No Negative Quantities**: all quantities >= 0 (ALWAYS)
4. **Progress Guarantee**: eventually saved || cancelled (LIVENESS)

### 8. Verification Tools
Overview panel showing all formal methods:
- NuSMV (22 CTL properties)
- SPIN (10 LTL properties)
- FORMULA (13 constraints)
- P Language (5 specifications)

### 9. Legend
Color-coded legend explaining node types:
- **Workflow State** (light blue)
- **Decision Point** (light yellow diamond)
- **User Action** (light green)
- **Validation** (light coral)
- **Integration** (lavender)
- **Terminal State** (light gray)

## How to Generate

### Using Make (Recommended)
```bash
# Generate process diagram only
make process-diagram

# Generate all diagrams (state machines + process)
make diagrams

# Full verification with all diagrams
make all
```

### Using Script
```bash
./generate_process_diagram.sh
```

### Manual Generation
```bash
# PNG format (bitmap)
dot -Tpng inspection_workflow_process.dot -o results/inspection_workflow_process.png

# SVG format (vector, scalable)
dot -Tsvg inspection_workflow_process.dot -o results/inspection_workflow_process.svg

# PDF format (for documents)
dot -Tpdf inspection_workflow_process.dot -o results/inspection_workflow_process.pdf
```

## Output Files

After generation, you'll find:
- `results/inspection_workflow_process.png` - Bitmap image for viewing
- `results/inspection_workflow_process.svg` - Vector image (scalable, no quality loss)
- `results/inspection_workflow_process.pdf` - Document-ready PDF

## Viewing the Diagram

### Linux
```bash
xdg-open results/inspection_workflow_process.png
```

### macOS
```bash
open results/inspection_workflow_process.png
```

### Windows
```bash
start results/inspection_workflow_process.png
```

## Customizing the Diagram

The diagram is defined in DOT format, which is easy to edit. To customize:

1. **Edit the source file**: `inspection_workflow_process.dot`
2. **Modify elements**:
   - Change node labels
   - Adjust colors (fillcolor attribute)
   - Add/remove nodes or edges
   - Modify layout (rankdir, splines, etc.)
3. **Regenerate**: Run `make process-diagram`

### DOT Format Basics

```dot
// Node definition
nodename [label="Display Text", fillcolor=color, shape=shape];

// Edge definition
node1 -> node2 [label="Condition", color=color, style=style];

// Subgraph (cluster)
subgraph cluster_name {
    label="Cluster Label";
    node1; node2;
}
```

### Common Customizations

**Change colors**:
```dot
data_entry [label="Data Entry", fillcolor=lightcyan];
```

**Add new transition**:
```dot
state1 -> state2 [label="New transition", color=blue];
```

**Modify layout**:
```dot
rankdir=LR;  // Left to right instead of top to bottom
splines=curved;  // Curved instead of orthogonal
```

## Integration with Formal Models

This process diagram complements the formal specifications:

| Tool | Focus | Diagram Relationship |
|------|-------|---------------------|
| **NuSMV** | Model checking, CTL properties | Diagram shows states verified by CTL properties |
| **SPIN** | Protocol verification, LTL | Diagram shows transitions verified by LTL |
| **FORMULA** | Domain constraints | Diagram shows constraints enforced at various points |
| **P** | Event-driven behavior | Diagram shows events triggering state changes |

## Use Cases

### 1. Documentation
Use the PDF version in formal documentation:
```bash
dot -Tpdf inspection_workflow_process.dot -o workflow_diagram.pdf
```

### 2. Presentations
Use the PNG version for presentations and reports:
```bash
dot -Tpng -Gdpi=300 inspection_workflow_process.dot -o high_res_diagram.png
```

### 3. Web Pages
Use the SVG version for web pages (scalable, small file size):
```bash
dot -Tsvg inspection_workflow_process.dot -o workflow_diagram.svg
```

### 4. Requirements Analysis
Use the diagram to:
- Identify missing states or transitions
- Verify business rules are covered
- Validate integration points
- Review with stakeholders

## Troubleshooting

### Graphviz not installed
```bash
# Ubuntu/Debian
sudo apt-get install graphviz

# macOS
brew install graphviz

# Check installation
dot -V
```

### Diagram layout issues
If the diagram looks cluttered, try:
```bash
# Use neato layout instead of dot
neato -Tpng inspection_workflow_process.dot -o results/inspection_workflow_process.png

# Use fdp (force-directed placement)
fdp -Tpng inspection_workflow_process.dot -o results/inspection_workflow_process.png
```

### Text too small
Increase DPI for higher resolution:
```bash
dot -Tpng -Gdpi=300 inspection_workflow_process.dot -o results/inspection_workflow_process.png
```

## References

- **Graphviz Documentation**: https://graphviz.org/documentation/
- **DOT Language**: https://graphviz.org/doc/info/lang.html
- **Node Shapes**: https://graphviz.org/doc/info/shapes.html
- **Colors**: https://graphviz.org/doc/info/colors.html

## Related Files

- `visualize_states.py` - Python script for state machine diagrams
- `inspection_workflow.smv` - NuSMV formal model
- `inspection_workflow.pml` - SPIN formal model
- `inspection_workflow.4ml` - FORMULA domain specification
- `InspectionWorkflow.p` - P language specification
