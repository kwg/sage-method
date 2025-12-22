# Sketch-to-Mockup Workflow

**Version:** 2.0
**Agent:** Pixel (game-uiux)
**Menu Command:** `*refine-sketch`

---

## Overview

Transform user sketches, screenshots, or wireframes into polished layout JSON using the UI Preview Tool, asset catalog, and style guide.

## Workflow Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `image_path` | Yes | Path to sketch/screenshot/wireframe image |
| `screen_name` | Yes | Name for the target screen |
| `style_preference` | No | Style reference (wooden UI, dark mode, etc.) |
| `resolution` | No | Target resolution (default: 1920x1080) |
| `replace_existing` | No | Whether this replaces an existing design |

## Workflow Outputs

| Output | Description |
|--------|-------------|
| Layout JSON | JSON file at tools/ui-preview/project/layouts/{screen-name}.json |
| PNG preview | Screenshot for visual verification |
| Element mapping document | Mapping of sketch elements to final assets |
| Ready for `*export-specs` | Layout ready for specification export |

---

## Step 1: Image Analysis

**Goal:** Identify UI elements in the provided sketch/image.

### Supported Image Formats

- **Photos**: JPEG, PNG photos of paper sketches
- **Screenshots**: PNG, JPEG screenshots of existing UIs
- **Wireframes**: PNG, SVG wireframe exports
- **Scans**: PDF scans (first page only)

### Analysis Prompt Template

```markdown
Analyze this UI sketch/screenshot. For each UI element you identify:

1. **Element Type**: button, panel, text-label, icon, input-field, image, progress-bar, etc.
2. **Position**: Grid position (top-left, top-center, top-right, center-left, center, center-right, bottom-left, bottom-center, bottom-right)
3. **Size**: Relative size (full-width, half-width, quarter-width, small, medium, large)
4. **Content**: Any visible text, symbols, or descriptions
5. **Grouping**: Which elements belong together (e.g., "header group", "button row")
6. **Hierarchy**: Parent-child relationships if visible

## Identified Elements

| # | Type | Position | Size | Content | Group |
|---|------|----------|------|---------|-------|
| 1 | panel | center | full-width | - | main-container |
| 2 | text-label | top-center | medium | "Title" | header |
| 3 | button | bottom-center | medium | "Start" | actions |
| ... | ... | ... | ... | ... | ... |
```

### Clarification Questions

After analysis, ask:
1. "Did I miss any elements in the sketch?"
2. "Are any element types incorrect?"
3. "What is this screen's purpose in the game?"
4. "Are there any interactive behaviors not visible in the sketch?"

---

## Step 2: Element Mapping

**Goal:** Map identified elements to assets from the catalog.

### Asset Catalog Query Process

```
1. Load asset catalog: assets/catalog/asset-catalog.json
2. For each identified element:
   a. Determine category (button, panel, icon, etc.)
   b. Search catalog by category
   c. Filter by style tags matching user preference
   d. Select best match based on size/purpose
   e. Identify alternative options
```

### Mapping Presentation Format

```markdown
## Element Mapping

| # | Sketch Element | Type | Suggested Asset | Alternative | Status |
|---|----------------|------|-----------------|-------------|--------|
| 1 | Main panel | panel | wooden-ui/panel_wood_large.png | fantasy-buttons/panel_01.png | mapped |
| 2 | Title text | text | (style guide: heading-1) | - | mapped |
| 3 | Start button | button | wooden-ui/btn_wood_blue_*.png | fantasy-buttons/btn_primary_*.png | mapped |
| 4 | Unknown icon | icon | ? | ? | needs-input |

### Questions

- Element 4: I see a circular shape in the sketch - is this a close button, settings icon, or something else?
- Should buttons use the "wooden" or "fantasy" style?
- The sketch shows 3 buttons - should they all be the same size?

### Unmapped Elements

The following elements need custom assets (not in catalog):
- None identified

Do you approve this mapping? Reply with:
- "approved" to proceed
- Specific changes (e.g., "Use fantasy-buttons for all buttons")
```

---

## Step 3: Layout Generation

**Goal:** Create the layout JSON using mapped assets and UI Preview Tool.

### Resolution Selection

| Preset | Resolution | Use Case |
|--------|------------|----------|
| desktop | 1920x1080 | Default, full desktop |
| laptop | 1280x720 | Smaller desktop/laptop |
| tablet | 1024x768 | Tablet landscape |
| mobile | 390x844 | Mobile portrait (iPhone 14) |
| custom | User-specified | Any custom resolution |

### UI Preview Tool Workflow

```python
# 1. Build layout JSON structure
layout = {
    "name": screen_name,
    "resolution": {"width": resolution_width, "height": resolution_height},
    "background_color": style_guide_background_color,
    "elements": []
}

# 2. Add elements (bottom-to-top for proper layering)
for element in sorted_elements_by_layer:
    if element.type == "panel":
        layout["elements"].append({
            "id": element.name,
            "type": "panel",
            "x": element.x, "y": element.y,
            "width": element.width, "height": element.height,
            "color": element.color,
            "corner_radius": 8
        })
    elif element.type == "text":
        layout["elements"].append({
            "id": element.name,
            "type": "label",
            "x": element.x, "y": element.y,
            "width": element.width, "height": element.height,
            "text": element.text,
            "font_size": element.font_size,
            "color": element.color,
            "align": element.align or "center"
        })
    elif element.type == "button":
        layout["elements"].append({
            "id": element.name,
            "type": "button",
            "x": element.x, "y": element.y,
            "width": element.width, "height": element.height,
            "text": element.text,
            "color": element.color
        })

# 3. Write layout JSON to disk
Write(
    file_path=f"tools/ui-preview/project/layouts/{screen_name}.json",
    content=json.dumps(layout, indent=2)
)

# 4. Call screenshot API to capture visual preview
curl "http://localhost:8080/api/screenshot?layout={screen_name}&path=/tmp/{screen_name}-preview.png"

# 5. Read screenshot to verify layout
Read(file_path=f"/tmp/{screen_name}-preview.png")
```

### Style Guide Application

From `docs/design/style-guide.md`:

| Property | Value | Usage |
|----------|-------|-------|
| Background | #1a1a2e | Frame background color |
| Primary text | #ffffff | Headings, important text |
| Secondary text | #b0b0b0 | Descriptions, labels |
| Accent color | #e94560 | Buttons, highlights |
| Spacing unit | 16px | Base spacing between elements |

### Position Calculation

Convert sketch positions to pixel coordinates:

```
Grid Position → Pixel Coordinates (1920x1080)

top-left:      x=margin, y=margin
top-center:    x=center-width/2, y=margin
top-right:     x=1920-margin-width, y=margin
center-left:   x=margin, y=center-height/2
center:        x=center-width/2, y=center-height/2
center-right:  x=1920-margin-width, y=center-height/2
bottom-left:   x=margin, y=1080-margin-height
bottom-center: x=center-width/2, y=1080-margin-height
bottom-right:  x=1920-margin-width, y=1080-margin-height

where:
  margin = 48px (3 spacing units)
  center = (1920/2, 1080/2) = (960, 540)
```

---

## Step 4: Iteration Loop

**Goal:** Refine layout based on user feedback.

### Change Request Format

User can request changes using natural language:
- "Move the title up"
- "Make the buttons larger"
- "Change the panel to use fantasy style"
- "Add a back button in top-left"
- "Remove the subtitle"

### Processing Changes

```
1. Parse change request
2. Identify affected elements in layout JSON
3. Calculate new positions/sizes/colors
4. Apply changes:
   - Edit layout JSON with updated element properties
   - Write updated JSON to disk
   - Call screenshot API to capture new preview
   - Read screenshot to verify changes
5. Present updated layout
```

### Re-Presentation Format

```markdown
## Updated Layout

**Changes Applied:**
- Moved "Title" from top-center to top-left
- Increased button size from 120x40 to 160x50
- Added back button at top-left corner

**Preview:** [Screenshot image displayed]

**Layout JSON:** tools/ui-preview/project/layouts/{screen-name}.json

---

Is this layout approved? Reply with:
- "approved" to finalize
- Additional changes needed
```

### Maximum Iterations

**Limit:** 10 iterations per layout session

After 10 iterations:
```markdown
We've made 10 rounds of changes. To prevent endless iteration:

1. **Approve current state** - Reply "approved" to finalize as-is
2. **Start fresh** - Run *refine-sketch again with clearer requirements
3. **Manual editing** - Edit layout JSON directly

Current layout: tools/ui-preview/project/layouts/{screen-name}.json
```

---

## Step 5: Output Generation

**Goal:** Generate final artifacts and prepare for handoff.

### Element Mapping Document

Save to: `docs/design/mappings/{screen-name}-mapping.md`

```markdown
# Element Mapping: {Screen Name}

**Generated:** {timestamp}
**Layout JSON:** tools/ui-preview/project/layouts/{screen-name}.json

## Source

- **Sketch:** {original_image_path}
- **Style:** {style_preference}
- **Resolution:** {resolution}

## Element Mapping

| Element | Type | Asset Used | Position | Size |
|---------|------|------------|----------|------|
| Main Panel | panel | wooden-ui/panel_large.png | center | 800x600 |
| Title | text | (sourcesanspro, 48px, #ffffff) | top-center | auto |
| Start Button | button | wooden-ui/btn_blue_*.png | bottom-center | 160x50 |

## Accessibility Notes

- Contrast ratios verified: All text passes 4.5:1
- Touch targets verified: All buttons >= 44x44px

## Next Steps

- Run `*export-specs` to generate implementation specification
- Run `*implement-guidance` for Godot scene structure
```

### Layout JSON Export

Final location: `docs/design/specs/{screen-name}-layout.json`

### PNG Export

Export location: `docs/design/mockups/{screen-name}-{resolution}.png`

---

## Error Handling

### Image Load Failure

```markdown
Could not load image at: {path}

Please verify:
1. File path is correct and accessible
2. File format is supported (JPEG, PNG, SVG, PDF)
3. File is not corrupted
```

### Asset Catalog Unavailable

```markdown
Could not load asset catalog at: assets/catalog/asset-catalog.json

Proceeding with placeholder rectangles. You can:
1. Fix catalog access and re-run
2. Continue with placeholders (manual asset assignment later)
```

### UI Preview Tool Connection Error

```markdown
Could not connect to UI Preview Tool.

Please verify:
1. UI Preview Tool server is running (http://localhost:8080)
2. Check server status: docker compose ps (if using Docker)
3. Check logs: docker compose logs -f ui-preview

Alternative: I can generate the layout JSON for manual preview later.
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-16 | Initial workflow definition |
| 2.0 | 2025-12-17 | Migrated to UI Preview Tool workflow |
