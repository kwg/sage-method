# Protocol: Log Failure

**ID:** recovery_log_failure
**Critical:** LEARNING
**Purpose:** Logs failure details for debugging and ML analysis

---

## Input/Output

**Input:** failure_metadata
**Output:** updated checkpoint, error log file

---

## Steps

### Step 1: Update Checkpoint Failure History

Read current checkpoint.

Append to `failure_history` array:

```json
{
  "timestamp": "{iso8601}",
  "task_id": "{task_id}",
  "failure_type": "{test_failure|timeout|unrecoverable_error}",
  "error_message": "{message}",
  "retry_count": "{count}",
  "reverted_to": "{commit_hash}",
  "recovered": true
}
```

Write updated checkpoint.

### Step 2: Create Detailed Error Log

Create directory: `.sage/errors/` (if not exists)

Write to: `.sage/errors/{epic_id}-{timestamp}.json`

Format:

```json
{
  "version": "1.0",
  "timestamp": "{iso8601}",
  "error": {
    "type": "{failure_type}",
    "severity": "fatal",
    "message": "{error_message}",
    "stack_trace": "{if available}"
  },
  "context": {
    "epic_id": "{epic_id}",
    "story_id": "{story_id}",
    "task_id": "{task_id}",
    "task_step": "{step}",
    "retry_count": "{count}"
  },
  "git": {
    "branch": "{branch}",
    "pre_failure_commit": "{before_reset}",
    "checkpoint_commit": "{after_reset}",
    "dirty": false
  },
  "subagent": {
    "type": "{TESTER|IMPLEMENTER|etc}",
    "output": "{last 500 lines}",
    "exit_code": "{code}",
    "duration_seconds": "{duration}"
  },
  "recovery": {
    "action": "git_reset_hard",
    "restored_to": "{checkpoint_commit}",
    "success": true
  }
}
```

### Step 3: Update Metrics

Increment `checkpoint.metrics.recoveries_performed`
Calculate recovery_rate = recoveries / total_tasks
Write updated checkpoint.
