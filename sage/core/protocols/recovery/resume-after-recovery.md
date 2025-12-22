# Protocol: Resume After Recovery

**ID:** recovery_resume
**Critical:** CLEAN_RESTART
**Purpose:** Resumes execution after recovery

---

## Trigger

Triggered by: Hook detecting RECOVERY_COMPLETE signal

---

## Steps

### Step 1: Hook Clears Context

Hook sends `/clear` command.
Waits 500ms.

### Step 2: Hook Reloads Assistant

Hook sends `/assistant` command.
Assistant enters on-load sequence.

### Step 3: Assistant Reads Checkpoint

Detects failure_history for current task.
Checks retry_count against max_retries.

**IF retry_count < max_retries:**
- Increment retry_count
- Retry task execution
- Log: `Retrying task {task_id} after recovery (attempt {retry_count})`

**IF retry_count >= max_retries:**
- Mark task as permanently failed
- Update checkpoint: `current.status = "failed"`
- Create HitL issue:
  - Title: `Task Failed: {task_id} - Manual Intervention Required`
  - Body: Include error history, last output, recovery attempts
- Signal HITL_REQUIRED
- Log: `Task {task_id} failed after {retry_count} attempts - HitL required`

### Step 4: Prevent Recovery Loops

**IF same task fails >5 times:**
- Log FATAL: `Recovery loop detected for {task_id}`
- Halt execution
- Create HitL issue with full failure log
