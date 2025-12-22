# Protocol: Run Epic

**Purpose**: Resume or continue executing an existing epic.

## Prerequisites

- Epic exists in `{sprint_artifacts}/epic-{id}/`
- Epic has `epic-context.yaml`

## Execution Steps

### Step 1: List Available Epics

Scan `{sprint_artifacts}/` for epic directories:
```
Available Epics:
1. epic-1-user-auth (in-progress, phase: implementation)
2. epic-2-dashboard (paused, phase: planning)
3. epic-3-api-v2 (blocked, phase: solutioning)
```

### Step 2: Load Epic Context

Read `epic-context.yaml` from selected epic.

### Step 3: Check for Checkpoint

If `.sage/state/checkpoint.json` exists for this epic:
- Show checkpoint details
- Ask: Resume from checkpoint or start fresh?

### Step 4: Determine Next Action

Based on `current_phase` and sprint-status:
1. Find next ready story
2. Or advance to next phase
3. Or complete epic

### Step 5: Spawn Appropriate Agent

- **analysis**: Analyst, PM
- **planning**: PM, Architect, UX Designer
- **solutioning**: PM, SM, Architect
- **implementation**: SM (drafting), Dev (coding)

### Step 6: Monitor Progress

- Update checkpoint after each step
- Check for HitL signals
- Handle failures with recovery protocol

## TODO

- [ ] Implement parallel story execution
- [ ] Add progress visualization
- [ ] Support epic dependencies
