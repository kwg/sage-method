# Create Mockup

Create a new UI layout using the UI Preview Tool.

## Input Mode (ask first)

1. **From scratch** - Design new screen from requirements
2. **From sketch** - Transform a sketch/image into layout → use `*refine-sketch` instead
3. **From existing layout** - Create variant of existing design

## Requirements Gathering

1. Screen name and purpose
2. User flow context (what happens before/after this screen)
3. Required elements (buttons, displays, inputs, etc.)
4. Target resolution (default: 1920x1080)
5. Style preference (reference existing screens or asset packs)
6. For mode 3: Which existing layout to reference?

## Design Process

1. Load style guide from `docs/design/style-guide.md`
2. Search asset catalog for appropriate assets
3. Plan layout structure (positions, spacing, states)
4. Write layout JSON to `tools/ui-preview/project/layouts/{screen-name}.json`
   - Include `"resolution": {"width": 1920, "height": 1080}`
   - Also write to `current.json` for live preview
5. Take screenshot: `GET http://localhost:8085/api/screenshot?layout={screen-name}&resolution=1920x1080`
6. Read `/tmp/ui-preview/screenshot.png` to verify
7. Iterate until satisfied
8. Document: positions, asset refs, states, accessibility
9. Validate accessibility (contrast 4.5:1, touch targets 44x44px)
10. Export final to `docs/design/specs/{screen-name}-layout.json`

## After Completion

- Offer `*review-screen` for feedback
- Offer `*export-specs` for developer handoff
