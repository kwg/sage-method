# Protocol: Show Status

**Purpose**: Display current SAGE orchestration status to user.

## Execution Steps

1. **Check for active checkpoint**
   - Read `.sage/state/checkpoint.json` if exists
   - Extract: current_epic, current_story, step, state

2. **Check sprint status**
   - Read `{sprint_artifacts}/sprint-status.yaml` if exists
   - Count: stories by status (ready, in-progress, done, blocked)

3. **Check git status**
   - Current branch
   - Uncommitted changes count
   - Behind/ahead of remote

4. **Display formatted status**

```
SAGE Status
═══════════════════════════════════════
Checkpoint: {exists/none}
  Epic: {epic_name or "N/A"}
  Story: {story_key or "N/A"}
  Step: {step_number or "N/A"}
  State: {state or "idle"}

Sprint Progress:
  Ready: {count}
  In Progress: {count}
  Done: {count}
  Blocked: {count}

Git:
  Branch: {branch_name}
  Changes: {uncommitted_count} uncommitted
  Remote: {ahead}/{behind}
═══════════════════════════════════════
```

## TODO

- [ ] Implement full status aggregation
- [ ] Add GitHub issue/PR status
- [ ] Add subagent status tracking
