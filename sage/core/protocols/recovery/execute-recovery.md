# Protocol: Execute Recovery

**ID:** recovery_execute
**Critical:** GIT_REVERT
**Purpose:** Executes git reset to restore checkpoint state

---

## Input/Output

**Input:** failure_metadata
**Output:** RECOVERY_COMPLETE signal or FATAL_ERROR

---

## Steps

### Step 1: Read Checkpoint Commit

Parse `.sage/state/{epic_id}.json`
Extract `git.last_checkpoint_commit`

Validate: 40-character hex string

Verify commit exists:
```bash
git cat-file -t {commit}
```

IF commit not found:
- Log FATAL: `Checkpoint commit not in history`
- **HALT** - do NOT attempt reset

### Step 2: Safety Check

```bash
git status --porcelain
```

IF output not empty (uncommitted changes):
- Log WARNING: `Uncommitted changes detected - creating safety stash`
- Execute: `git stash save "pre-recovery-safety-{timestamp}"`
- Continue with recovery

### Step 3: Execute Git Reset

```bash
git reset --hard {checkpoint_commit}
```

Check exit code.

IF non-zero exit:
- Log FATAL: `Git reset failed`
- **HALT** - repository may be in inconsistent state

### Step 4: Verify Reset Success

```bash
git rev-parse HEAD
```

Compare with checkpoint_commit.

IF mismatch:
- Log FATAL: `HEAD does not match checkpoint after reset`
- **HALT**

```bash
git status
```

Verify working tree is clean (no modified, staged, or untracked files).

### Step 5: Log Failure

Call `recovery_log_failure` with failure_metadata.

### Step 6: Signal Recovery Complete

```
═══════════════════════════════════════════════════════════════════
SIGNAL: RECOVERY_COMPLETE
CHECKPOINT_FILE: .sage/state/{epic_id}.json
REVERTED_TO: {checkpoint_commit}
FAILURE_TYPE: {failure_type}
NEXT_ACTION: resume
═══════════════════════════════════════════════════════════════════
```
