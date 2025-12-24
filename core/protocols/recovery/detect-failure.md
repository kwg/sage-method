# Protocol: Detect Failure

**ID:** detect_failure
**Critical:** FAILURE_DETECTION
**Purpose:** Detects unrecoverable failure conditions

---

## Failure Types

### 1. TEST_FAILURE_EXHAUSTED

**Condition:** `retry_count >= max_retries` AND tests still failing

**Detection:**
- Parse TESTER output for test results
- Check `checkpoint.current.retry_count`
- Compare against config max_retries (default: 3)

**Trigger:** FATAL_ERROR if condition met

### 2. SUBAGENT_TIMEOUT

**Condition:** Subagent execution exceeds timeout threshold

**Detection:**
- Record spawn_time when subagent starts
- Check elapsed = current_time - spawn_time
- Compare against timeout_threshold (default: 10 minutes)

**Trigger:** FATAL_ERROR with partial output if available

### 3. UNRECOVERABLE_ERROR

**Condition:** Fatal errors that cannot be retried

**Detection:** Parse subagent output for:
- Syntax errors preventing execution
- Missing dependencies that can't be resolved
- Git merge conflicts
- File permission errors

**Severity Levels:**
| Level | Action |
|-------|--------|
| warning | Log but continue |
| error | Retry allowed |
| fatal | Trigger recovery immediately |

**Trigger:** FATAL_ERROR only for fatal severity

---

## On Failure Detected

1. Capture failure metadata:
   - failure_type
   - timestamp
   - task_id
   - error_message
   - retry_count

2. Call `recovery_execute` protocol
