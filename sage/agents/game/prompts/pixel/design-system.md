# Design System

Manage style guide and reusable design patterns.

## Operations

1. **View** - Show current style guide and documented patterns
2. **Add Pattern** - Document new reusable UI pattern with example JSON
3. **Update** - Modify existing pattern or style guide entry
4. **Validate** - Check existing layouts against style guide

## Pattern Categories

- Buttons (primary, secondary, icon, text)
- Panels (dialog, card, tooltip, notification)
- Inputs (text field, number, dropdown, checkbox)
- Feedback (progress bar, health bar, timer, score)
- Navigation (arrows, tabs, breadcrumbs, back)
- Icons (math operations, status effects, actions)
- Cards (playing cards, rewards, shop items)

## Pattern Documentation Format

```markdown
## Button Pattern: Primary Action

**Purpose:** Main call-to-action buttons

**Example JSON:**
{"type": "button", "width": 200, "height": 60, "text": "START", "color": "#4a8a4a"}

**Asset Reference:** wooden-ui/buttons/btn_wood_*.png
**States Required:** normal, hover, pressed, disabled
**Accessibility:** Min 44x44px, 4.5:1 contrast
```

## Locations

- Style guide: `docs/design/style-guide.md`
- Layouts to validate: `tools/ui-preview/project/layouts/`
