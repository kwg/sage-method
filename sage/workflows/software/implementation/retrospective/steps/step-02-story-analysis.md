# Step 2: Deep Story Analysis - Extract Lessons from Implementation

**Goal:** Review all story records to surface patterns and themes for retrospective discussion

---

## Story File Reading

```xml
<action>For each story in epic {{epic_number}}, read the complete story file from
{story_directory}/{{epic_number}}-{{story_num}}-*.md</action>
```

---

## Extraction Categories

### Dev Notes and Struggles

Look for sections: `## Dev Notes`, `## Implementation Notes`, `## Challenges`, `## Development Log`

Extract:
- Where developers struggled or made mistakes
- Unexpected complexity or gotchas discovered
- Technical decisions that didn't work out as planned
- Where estimates were way off (too high or too low)

### Review Feedback Patterns

Look for sections: `## Review`, `## Code Review`, `## SM Review`, `## Scrum Master Review`

Extract:
- Recurring feedback themes across stories
- Which types of issues came up repeatedly
- Quality concerns or architectural misalignments
- Praise or exemplary work called out in reviews

### Lessons Learned

Look for sections: `## Lessons Learned`, `## Retrospective Notes`, `## Takeaways`

Extract:
- Explicit lessons documented during development
- "Aha moments" or breakthroughs
- What would be done differently
- Successful experiments or approaches

### Technical Debt Incurred

Look for sections: `## Technical Debt`, `## TODO`, `## Known Issues`, `## Future Work`

Extract:
- Shortcuts taken and why
- Debt items that affect next epic
- Severity and priority of debt items

### Testing and Quality Insights

Look for sections: `## Testing`, `## QA Notes`, `## Test Results`

Extract:
- Testing challenges or surprises
- Bug patterns or regression issues
- Test coverage gaps

---

## Pattern Synthesis

After reading all stories, synthesize:

### Common Struggles
- Issues that appeared in 2+ stories (e.g., "3 out of 5 stories had API authentication issues")
- Areas where team consistently struggled
- Where complexity was underestimated

### Recurring Review Feedback
- Feedback themes (e.g., "Error handling was flagged in every review")
- Quality patterns (positive and negative)
- Areas where team improved over the course of epic

### Breakthrough Moments
- Key discoveries (e.g., "Story 3 discovered the caching pattern we used for rest of epic")
- When team velocity improved dramatically
- Innovative solutions worth repeating

### Velocity Patterns
- Average completion time per story
- Velocity trends (e.g., "First 2 stories took 3x longer than estimated")
- Which types of stories went faster/slower

### Team Collaboration Highlights
- Moments of excellent collaboration mentioned in stories
- Where pair programming or mob programming was effective
- Effective problem-solving sessions

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{pattern_1_description}}` | First major pattern identified |
| `{{pattern_1_count}}` | Story count for pattern 1 |
| `{{pattern_2_description}}` | Second major pattern identified |
| `{{breakthrough_story_num}}` | Story with key breakthrough |
| `{{difficult_story_num}}` | Story with significant challenges |
