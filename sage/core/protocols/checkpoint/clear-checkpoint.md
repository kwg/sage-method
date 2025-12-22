# Protocol: Clear Checkpoint

**Purpose**: Clear current checkpoint state, allowing fresh start.

## Warning

This is a destructive operation. The current checkpoint will be deleted
and cannot be recovered.

## Execution Steps

### Step 1: Confirm with User

```
WARNING: This will delete the current checkpoint.

Current checkpoint:
  Epic: {epic_id}
  Story: {story_key}
  Step: {step_number}
  Created: {timestamp}

Are you sure you want to clear this checkpoint? (yes/no)
```

### Step 2: Backup (Optional)

If user wants backup:
```bash
cp .sage/state/checkpoint.json .sage/state/checkpoint-backup-{timestamp}.json
```

### Step 3: Clear State

```bash
rm .sage/state/checkpoint.json
```

### Step 4: Clear Related State

Optionally clear:
- `.sage/state/context.json` - Preserved context
- `.sage/state/signals/` - Pending signals

### Step 5: Confirm

```
Checkpoint cleared.

You can now:
  *start-epic  - Start a new epic
  *run-epic    - Run an existing epic from beginning
  *status      - View current status
```

## Safety Checks

- Never clear if there are uncommitted changes
- Warn if clearing would lose work
- Offer to create backup

## TODO

- [ ] Add selective clearing (keep context, clear step)
- [ ] Add restore from backup
- [ ] Integrate with git stash
