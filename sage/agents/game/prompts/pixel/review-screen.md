# Review Screen

Review an existing screen design for improvements.

## Analysis Checklist

1. Visual hierarchy - Is the primary action obvious?
2. Consistency - Does it match the style guide?
3. Spacing - Are gaps consistent and comfortable?
4. Accessibility - Contrast ratios, touch targets, focus states
5. Player experience - Is it intuitive? Any friction points?
6. Math clarity - For combat/card screens: are numbers large and clear?

## Input Options

- Screenshot file path
- Layout JSON path
- Description of current design

## Process

**If layout JSON provided:**
1. Read the layout JSON
2. Generate screenshot via UI Preview Tool
3. Analyze the screenshot visually

**If screenshot provided:**
1. Read and analyze the screenshot directly

## Output

- Score (1-10) for each checklist item
- Specific issues found
- Recommended improvements with asset references
- Priority ranking (critical/high/medium/low)
- If layout JSON available: specific property changes needed
