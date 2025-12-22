# Step 1: Epic Discovery - Find Completed Epic with Priority Logic

**Goal:** Identify which epic to retrospect using priority-based discovery

---

## Prerequisites

```xml
<action>Set {{sprint_status}} = {sprint_status_file}</action>
<invoke-protocol name="init_sprint_tracking" />
```

---

## Discovery Priority Order

### Priority 1: Sprint Status File Detection

```xml
<check if="{{sprint_tracking}} == 'enabled'">
  <action>Load FULL file: {sprint_status_file}</action>
  <action>Read ALL development_status entries</action>
  <action>Find the highest epic number with at least one story marked "done"</action>
  <action>Extract epic number from keys like "epic-X-retrospective" or story keys like "X-Y-story-name"</action>
  <action>Set {{detected_epic}} = highest epic number found with completed stories</action>
</check>
```

**If detected:** Present finding to user for confirmation
**If confirmed:** Set `{{epic_number}} = {{detected_epic}}`
**If user provides different:** Set `{{epic_number}} = user-provided number`

### Priority 2: Direct User Input

If sprint status detection fails:
```xml
<output>
Bob (Scrum Master): "I'm having trouble detecting the completed epic from {sprint_status_file}.
{user_name}, which epic number did you just complete?"
</output>
<action>WAIT for {user_name} to provide epic number</action>
<action>Set {{epic_number}} = user-provided number</action>
```

### Priority 3: Story Folder Scan

If still not determined:
```xml
<action>Scan {story_directory} for highest numbered story files</action>
<action>Extract epic numbers from story filenames (pattern: epic-X-Y-story-name.md)</action>
<action>Set {{detected_epic}} = highest epic number found</action>
<action>Present to user for confirmation</action>
```

---

## Epic Completion Verification

Once `{{epic_number}}` is determined:

```xml
<action>Find all stories for epic {{epic_number}} in {sprint_status_file}:
  - Look for keys starting with "{{epic_number}}-" (e.g., "1-1-", "1-2-", etc.)
  - Exclude epic key itself ("epic-{{epic_number}}")
  - Exclude retrospective key ("epic-{{epic_number}}-retrospective")
</action>

<action>Count total stories found for this epic</action>
<action>Count stories with status = "done"</action>
<action>Collect list of pending story keys (status != "done")</action>
<action>Determine if complete: true if all stories are done, false otherwise</action>
```

---

## Incomplete Epic Handling

```xml
<check if="epic is not complete">
  <output>
**Epic Status:**
- Total Stories: {{total_stories}}
- Completed (Done): {{done_stories}}
- Pending: {{pending_count}}

**Pending Stories:**
{{pending_story_list}}

**Options:**
1. Complete remaining stories before running retrospective (recommended)
2. Continue with partial retrospective (not ideal, but possible)
3. Run sprint-planning to refresh story tracking
  </output>

  <ask if="{{non_interactive}} == false">Continue with incomplete epic? (yes/no)</ask>

  <check if="user says no">
    <action>HALT</action>
  </check>

  <action if="user says yes">Set {{partial_retrospective}} = true</action>
</check>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{epic_number}}` | Confirmed epic number to retrospect |
| `{{total_stories}}` | Count of stories in the epic |
| `{{done_stories}}` | Count of completed stories |
| `{{partial_retrospective}}` | Boolean if proceeding with incomplete epic |
