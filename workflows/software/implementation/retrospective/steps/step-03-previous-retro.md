# Step 3: Load and Integrate Previous Epic Retrospective

**Goal:** Check previous retrospective for action item follow-through and lessons applied

---

## Previous Retro Detection

```xml
<action>Calculate previous epic number: {{prev_epic_num}} = {{epic_number}} - 1</action>

<check if="{{prev_epic_num}} >= 1">
  <action>Search for previous retrospective using pattern:
  {retrospectives_folder}/epic-{{prev_epic_num}}-retro-*.md</action>
</check>
```

---

## Extraction (If Found)

Read the complete previous retrospective file and extract:

| Element | Description |
|---------|-------------|
| Action items committed | What did the team agree to improve? |
| Lessons learned | What insights were captured? |
| Process improvements | What changes were agreed upon? |
| Technical debt flagged | What debt was documented? |
| Team agreements | What commitments were made? |
| Preparation tasks | What was needed for this epic? |

---

## Cross-Reference Analysis

### Action Item Follow-Through

For each action item from Epic `{{prev_epic_num}}` retro:
- Check if it was completed
- Look for evidence in current epic's story records
- Mark each: ✅ Completed, ⏳ In Progress, ❌ Not Addressed

### Lessons Applied

For each lesson from previous epic:
- Check if team applied it in Epic `{{epic_number}}`
- Look for evidence in dev notes, review feedback, or outcomes
- Document successes and missed opportunities

### Process Improvements Effectiveness

For each process change agreed to:
- Assess if it helped
- Did the change improve velocity, quality, or team satisfaction?
- Should we keep, modify, or abandon the change?

### Technical Debt Status

For each debt item from previous epic:
- Check if it was addressed
- Did unaddressed debt cause problems in Epic `{{epic_number}}`?
- Did the debt grow or shrink?

---

## Continuity Insights

Prepare for retrospective discussion:

**Wins** - Where previous lessons were applied successfully:
- Document specific examples of applied learnings
- Note positive impact on Epic `{{epic_number}}` outcomes
- Celebrate team growth and improvement

**Missed Opportunities** - Where previous lessons were ignored:
- Document where team repeated previous mistakes
- Note impact of not applying lessons (without blame)
- Explore barriers that prevented application

---

## First Retrospective Handling

```xml
<check if="{{prev_epic_num}} < 1 OR no previous retro found">
  <action>Set {{first_retrospective}} = true</action>
</check>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{first_retrospective}}` | Boolean if this is first retro |
| `{{action_count}}` | Previous retro action items count |
| `{{completed_count}}` | Action items completed |
| `{{in_progress_count}}` | Action items in progress |
| `{{not_addressed_count}}` | Action items not addressed |
