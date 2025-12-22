# Protocol: Show Checkpoint

**Purpose**: Display current checkpoint state in human-readable format.

## Checkpoint Location

`.sage/state/checkpoint.json`

## Execution Steps

### Step 1: Check Checkpoint Exists

```bash
if [ -f .sage/state/checkpoint.json ]; then
  # proceed
else
  echo "No checkpoint found"
fi
```

### Step 2: Load and Parse

Read checkpoint JSON and extract:
- `timestamp` - When checkpoint was created
- `epic` - Current epic context
- `story` - Current story being worked
- `step` - Current step in workflow
- `state` - Agent state (idle, working, hitl-waiting, error)
- `context` - Preserved context data
- `git_ref` - Git commit at checkpoint

### Step 3: Display Formatted

```
Checkpoint State
═══════════════════════════════════════
Created: {timestamp}
Age: {time_since}

Epic: {epic_id} - {epic_name}
Story: {story_key} - {story_title}
Step: {step_number} of {total_steps}
State: {state}

Git Reference: {git_ref}
Branch: {branch_name}

Context Size: {context_bytes} bytes
Keys: {context_keys}
═══════════════════════════════════════

Actions:
  *resume  - Resume from this checkpoint
  *clear   - Clear checkpoint and start fresh
```

## TODO

- [ ] Add checkpoint diff from current state
- [ ] Show multiple checkpoint history
- [ ] Add checkpoint validation
