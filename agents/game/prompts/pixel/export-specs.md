# Export Specs

Export design specifications for developer implementation.

## Requirements Gathering

1. Which layout to export? (layout JSON path or recent design)
2. Target Godot version? (default: 4.x)
3. Include responsive variants? (mobile, tablet, desktop)
4. Export format? (Markdown, JSON, or both)
5. Include theme resource snippets? (yes/no)

## Generate Specification

1. **Screen overview** - Purpose, user flow, target resolution(s), style guide refs
2. **Element inventory** - All UI elements with positions, asset refs, interactive states
3. **Layout structure** - Container hierarchy, spacing, alignment rules
4. **Interactions** - Button actions, signal names, transitions, animations
5. **Godot hints** - Node structure, theme refs, signal connections

## Output

- Markdown: `docs/design/specs/{screen-name}-spec.md`
- JSON (if requested): `docs/design/specs/{screen-name}-spec.json`

## After Completion

Offer `*implement-guidance` for full Godot code generation
