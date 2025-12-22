# Step 4: Preview Next Epic with Change Detection

**Goal:** Understand upcoming work and identify preparation needs

---

## Next Epic Loading

```xml
<action>Calculate next epic number: {{next_epic_num}} = {{epic_number}} + 1</action>
```

### Try Sharded First (More Specific)

```xml
<action>Check if file exists: {output_folder}/epic*/epic-{{next_epic_num}}.md</action>

<check if="sharded epic file found">
  <action>Load {output_folder}/*epic*/epic-{{next_epic_num}}.md</action>
  <action>Set {{next_epic_source}} = "sharded"</action>
</check>
```

### Fallback to Whole Document

```xml
<check if="sharded epic not found">
  <action>Check if file exists: {output_folder}/epic*.md</action>

  <check if="whole epic file found">
    <action>Load entire epics document</action>
    <action>Extract Epic {{next_epic_num}} section</action>
    <action>Set {{next_epic_source}} = "whole"</action>
  </check>
</check>
```

---

## Next Epic Analysis

If next epic found, analyze for:

| Aspect | What to Extract |
|--------|-----------------|
| Objectives | Epic title and objectives |
| Stories | Planned stories and complexity estimates |
| Dependencies | Dependencies on Epic `{{epic_number}}` work |
| Technical | New technical requirements or capabilities needed |
| Risks | Potential risks or unknowns |
| Success | Business goals and success criteria |

---

## Dependency Identification

```xml
<action>Identify dependencies on completed work:</action>
- What components from Epic {{epic_number}} does Epic {{next_epic_num}} rely on?
- Are all prerequisites complete and stable?
- Any incomplete work that creates blocking dependencies?
```

---

## Preparation Gaps

```xml
<action>Note potential gaps or preparation needed:</action>
- Technical setup required (infrastructure, tools, libraries)
- Knowledge gaps to fill (research, training, spikes)
- Refactoring needed before starting next epic
- Documentation or specifications to create
```

---

## Technical Prerequisites

```xml
<action>Check for technical prerequisites:</action>
- APIs or integrations that must be ready
- Data migrations or schema changes needed
- Testing infrastructure requirements
- Deployment or environment setup
```

---

## No Next Epic Handling

```xml
<check if="next epic NOT found">
  <action>Set {{next_epic_exists}} = false</action>
  <output>
Bob (Scrum Master): "I don't see Epic {{next_epic_num}} defined yet. We'll still do a
thorough retro on Epic {{epic_number}}. The lessons will be valuable whenever we plan
the next work."
  </output>
</check>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{next_epic_num}}` | Next epic number |
| `{{next_epic_exists}}` | Boolean if next epic is defined |
| `{{next_epic_title}}` | Title of next epic |
| `{{next_epic_source}}` | "sharded" or "whole" |
| `{{dependency_description}}` | Dependencies on current epic |
