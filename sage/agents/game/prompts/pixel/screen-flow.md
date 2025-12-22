# Screen Flow

Create navigation flow documentation showing screen relationships.

## Requirements Gathering

1. List of screens in this flow
2. Starting screen
3. User actions that trigger transitions
4. New flow or update to existing?
5. Conditional branches (e.g., "if logged in → dashboard, else → login")

## Processing Steps

1. Load style guide for terminology consistency
2. For each screen, check if layout JSON exists
3. Document transitions: Source → Action → Destination
4. Document conditional logic with decision tree format
5. Generate text-based flow diagram in Markdown

## Output Format

Save to: `docs/design/flows/{flow-name}-flow.md`

```markdown
# Screen Flow: {Flow Name}

## Overview
{Brief description}

## Entry Point
**Screen:** {StartScreen}
**Context:** {When user enters}

## Flow Steps
### 1. {Screen}
- **Layout:** path (status)
- **Actions:** [Button] → Destination

## Conditional Branches
- After X: If Y → A, else → B

## Screen Inventory
| Screen | Layout Status | Screenshot | Notes |
```

## After Completion

- List screens needing design work
- Offer to create missing layouts
