# Step 05: Validate and Report

**Goal:** Perform validation checks and report final summary.

---

## EMBEDDED RULES

- All validation checks must pass
- Provide clear next steps to user
- This is the final step - workflow completes here

---

## ACTIONS

### 1. Validation Checks

Perform these validation checks:

- [ ] Every epic in epic files appears in sprint-status.yaml
- [ ] Every story in epic files appears in sprint-status.yaml
- [ ] Every epic has a corresponding retrospective entry
- [ ] No orphaned items in sprint-status.yaml that don't exist in epic files
- [ ] All status values are legal (match state machine definitions)
- [ ] File is valid YAML syntax

### 2. Count Totals

Calculate summary statistics:

- Total epics: `{{epic_count}}`
- Total stories: `{{story_count}}`
- Epics in-progress: `{{epics_in_progress_count}}`
- Stories done: `{{stories_done_count}}`
- Stories in backlog: `{{stories_backlog_count}}`

### 3. Display Summary

Present completion summary to `{user_name}` in `{communication_language}`:

> **Sprint Status Generated Successfully**
>
> | Metric | Value |
> |--------|-------|
> | File Location | `{sprint_artifacts}/sprint-status.yaml` |
> | Total Epics | {{epic_count}} |
> | Total Stories | {{story_count}} |
> | Epics In Progress | {{epics_in_progress_count}} |
> | Stories Completed | {{stories_done_count}} |
>
> **Next Steps:**
> 1. Review the generated sprint-status.yaml
> 2. Use this file to track development progress
> 3. Agents will update statuses as they work
> 4. Re-run this workflow to refresh auto-detected statuses

### 4. Update Final State

```json
{
  "current_step": 5,
  "completed_steps": ["01-discover", "02-parse", "03-detect", "04-generate", "05-validate"],
  "workflow_complete": true,
  "summary": {
    "epics": {{epic_count}},
    "stories": {{story_count}},
    "in_progress": {{epics_in_progress_count}},
    "done": {{stories_done_count}}
  }
}
```

---

## WORKFLOW COMPLETE

The sprint planning workflow has completed. The sprint-status.yaml file is ready for use.
