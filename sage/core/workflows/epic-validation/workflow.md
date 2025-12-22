# Epic Validation Workflow (Phase 4)

```xml
<workflow id="epic-validation" phase="4">

  <purpose>
    Validate completed epic before merge to dev/main.
    This is the MANDATORY human checkpoint in the SAGE lifecycle.

    Phase 4 ensures:
    - Human reviews all changes before merge
    - Learning patterns are captured and persisted
    - Branch cleanup happens systematically
    - Quality gates are enforced
  </purpose>

  <triggers>
    - Automatic: After run-epic phase 08-finalize completes
    - Manual: User runs *validate-epic {epic_id}
  </triggers>

  <components>
    This workflow uses core SAGE components:
    - state-manager: Read epic state for summary
    - metrics-collector: Aggregate final metrics
    - learning-recorder: Generate learning summary
  </components>

  <initialization>
    <step n="1">Receive epic_id (or detect from current branch)</step>
    <step n="2">Read epic state from state/epic-{{epic_id}}-state.json</step>
    <step n="3">Validate epic is in "done" or "08-finalize" phase</step>
    <step n="4">Load first step file</step>
  </initialization>

  <step-sequence>
    01-review-summary → 02-human-checkpoint → 03-merge-automation → 04-learning-summary → 05-cleanup
  </step-sequence>

  <critical-rules>
    - NEVER auto-merge without human approval
    - ALWAYS generate learning summary before cleanup
    - PRESERVE metrics and learning files (they are NOT cleaned up)
    - VALIDATE PR exists and is mergeable before proceeding
  </critical-rules>

</workflow>
```

## Usage

### After Epic Completion

```
Agent: Epic ms-1 execution complete!
       Running validation workflow...

[Automatically loads step-01-review-summary.md]
```

### Manual Validation

```
User: *validate-epic ms-1
Agent: Loading epic validation for ms-1...
       [Loads step-01-review-summary.md]
```

### Resume After Pause

```
User: *validate-epic ms-1 --resume
Agent: Resuming from step 02-human-checkpoint...
       Awaiting your approval.
```

## Step Files

| Step | Purpose | Blocks? |
|------|---------|---------|
| 01-review-summary | Present epic results | No |
| 02-human-checkpoint | Require approval | **Yes** |
| 03-merge-automation | Execute merge | No |
| 04-learning-summary | Generate learnings | No |
| 05-cleanup | Clean branches | No |
