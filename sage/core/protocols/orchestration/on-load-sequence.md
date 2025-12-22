# On-Load Sequence Protocol

**Protocol ID:** orchestration/on-load-sequence
**Category:** Orchestration
**Purpose:** Initialize assistant and detect resume state

---

## When Triggered

This protocol runs when:
1. Assistant agent is loaded via `/assistant` command
2. Orchestrator v2 resumes with `/assistant *resume`

---

## Preferred Method: Checkpoint Script

```bash
# Check for existing checkpoint
checkpoint-write.sh read --field status

# Exit codes:
# 0 = checkpoint found and valid
# 4 = no checkpoint found
```

---

## Execution Steps

### Step 0: Detect Orchestrator Mode

Check environment variable SAGE_ORCHESTRATOR.

```bash
echo $SAGE_ORCHESTRATOR
```

- If `SAGE_ORCHESTRATOR == "1"`: Set ORCHESTRATOR_MODE = true
- Else: Set ORCHESTRATOR_MODE = false

When in orchestrator mode:
- Log: `[ORCHESTRATOR MODE] Running under external orchestrator - user prompts disabled`
- All HitL prompts are bypassed
- Auto-resume is enabled

### Step 1: Ensure State Directory

```bash
mkdir -p .sage/state/
```

### Step 2: Check for Checkpoint Files

```bash
ls -t .sage/state/*.json 2>/dev/null | head -1
```

- If NO .json files found → Go to Step 5 (fresh start)
- If .json files found → Continue to Step 3

### Step 3: Load Most Recent Checkpoint

```bash
checkpoint-write.sh read
```

Parse JSON and extract:
- `epic_id`
- `story_id`
- `phase`
- `task_index`
- `status`
- `commit_hash`

If JSON is malformed:
- Log warning: "Previous checkpoint invalid - starting fresh"
- Go to Step 5

### Step 4: Resume or Show Menu

**Orchestrator Mode (`SAGE_ORCHESTRATOR=1`):**
- Log: `[ORCHESTRATOR MODE] Auto-resuming from checkpoint`
- Display brief status
- Execute resume-checkpoint immediately

**Interactive Mode:**
- Display resume prompt:
  ```
  Found checkpoint for epic {{epic_id}}, story {{story_id}}
  Phase: {{phase}}, Task: {{task_index}}
  Last commit: {{commit_hash}}

  Resume from checkpoint? [Y/n]
  ```
- Wait for user response:
  - `y` or Enter → Execute resume-checkpoint
  - `n` → Show menu (Step 6)

### Step 5: Fresh Start

**Orchestrator Mode:**
- Output: `SAGE_SIGNAL:FATAL_ERROR:NO_CHECKPOINT`
- Halt execution

**Interactive Mode:**
- Display greeting:
  ```
  🎯 SAGE Assistant
  No active checkpoint. Select an option from the menu.
  ```
- Continue to Step 6

### Step 6: Show Menu

Display menu and wait for user input.

See: `menu` section in assistant.md

---

## State Transitions

| Current State | Condition | Next State |
|---------------|-----------|------------|
| Loading | No checkpoint | idle (menu) |
| Loading | Valid checkpoint + interactive | idle (prompt) |
| Loading | Valid checkpoint + orchestrator | orchestrating |
| Loading | Invalid checkpoint | idle (fresh) |

---

## Error Handling

| Error | Action |
|-------|--------|
| State directory creation fails | Log error, continue with memory-only mode |
| Checkpoint file corrupt | Log warning, offer fresh start |
| Git state mismatch | Offer recovery or manual resolution |
| Unknown orchestrator signal | Log and halt |

---

## Signals Emitted

- `SAGE_SIGNAL:CHECKPOINT:LOADED` - Checkpoint successfully loaded
- `SAGE_SIGNAL:CHECKPOINT:MISSING` - No checkpoint found (interactive only)
- `SAGE_SIGNAL:FATAL_ERROR:NO_CHECKPOINT` - Orchestrator mode with no checkpoint
