# Step 03: Detect Current Status

**Goal:** Apply intelligent status detection by checking existing files.

---

## EMBEDDED RULES

- Check for existing story files to upgrade status
- Never downgrade status (preserve more advanced states)
- Apply status state machine rules

---

## ACTIONS

### 1. Status Detection Logic

For each story in inventory, check file existence:

**Story File Detection:**
- Check: `{sprint_artifacts}/{story-key}.md`
- Example: `stories/1-1-user-authentication.md`
- If exists → upgrade status to at least `drafted`

**Story Context Detection:**
- Check: `{sprint_artifacts}/{story-key}-context.md`
- Example: `stories/1-1-user-authentication-context.md`
- If exists → upgrade status to at least `ready-for-dev`

### 2. Existing Status Preservation

If existing `{sprint_artifacts}/sprint-status.yaml` exists:
- Read current status values
- Only upgrade, never downgrade
- Preserve `done`, `in-progress`, `review` states

### 3. Status State Machine Reference

**Epic Status:**
```
backlog → in-progress → done
```

**Story Status:**
```
backlog → drafted → ready-for-dev → in-progress → review → done
```

**Retrospective Status:**
```
optional ↔ completed
```

### 4. Epic Status Rollup

For each epic, check its stories:
- If any story is `in-progress` or beyond → epic is `in-progress`
- If all stories are `done` → epic can be `done`
- Otherwise → epic remains `backlog`

### 5. Report Detection Results

Report to user:

> **Status Detection Complete**
> - Stories upgraded: {{upgraded_count}}
> - Existing statuses preserved: {{preserved_count}}

### 6. Update State

```json
{
  "current_step": 3,
  "completed_steps": ["01-discover", "02-parse", "03-detect"],
  "status_changes": [
    {"key": "story-key", "from": "backlog", "to": "drafted"}
  ]
}
```

---

## NEXT STEP

Load and execute `step-04-generate.md` to create the sprint status file.
