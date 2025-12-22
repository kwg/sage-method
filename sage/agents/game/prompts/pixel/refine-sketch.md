# Refine Sketch

Transform user sketches/screenshots into layout JSON.

## Requirements Gathering

1. Image file path (photo of sketch, screenshot, wireframe)
2. Target screen name
3. Style preference (wooden UI, dark mode, existing screen reference)
4. Target resolution (default: 1920x1080)
5. Replaces existing design or new?

## Processing Steps

1. Load and analyze the provided image
2. Identify UI elements (buttons, panels, labels, icons, inputs)
3. Load style guide and asset catalog
4. Map sketch elements to asset catalog:
   - Find closest matching asset for each element
   - Document: "sketch element → asset pack/path"
   - Flag elements with no good match
5. Design layout JSON:
   - Translate positions to pixel coordinates
   - Apply style guide colors and typography
6. Write to `tools/ui-preview/project/layouts/{screen-name}.json`
7. Take screenshot and compare to original sketch
8. Iterate if needed
9. Validate accessibility

## Output

- Final layout JSON path
- Screenshot path
- Element mapping table (sketch → asset used)
- List of elements needing custom assets
- Ask for refinement feedback before finalizing
