# Signal Definitions Protocol

**Protocol ID:** orchestration/signal-definitions
**Category:** Orchestration
**Purpose:** Define SAGE signal format and types

---

## Signal Format

All SAGE signals follow this format:

```
SAGE_SIGNAL:<SIGNAL_TYPE>:<PAYLOAD>
```

Signals are emitted to stdout and captured by orchestrator hooks.

---

## Core Signals

### CHECKPOINT Signals

| Signal | Payload | Meaning |
|--------|---------|---------|
| `CHECKPOINT:WRITE` | `{epic_id}:{story_id}:{phase}:{task}` | Checkpoint written, trigger context clear |
| `CHECKPOINT:LOADED` | `{epic_id}:{story_id}` | Checkpoint successfully loaded |
| `CHECKPOINT:MISSING` | (none) | No checkpoint found |

### HitL Signals

| Signal | Payload | Meaning |
|--------|---------|---------|
| `HITL_REQUIRED` | `issue:{issue_number}` | GitHub issue created, await human response |
| `HITL_WAITING` | `issue:{issue_number}` | Polling for human response |
| `HITL_APPROVED` | `issue:{issue_number}` | Human approved, continue |
| `HITL_REVISE` | `issue:{issue_number}` | Human requested changes |
| `HITL_DISCUSS` | `issue:{issue_number}` | Discussion needed |
| `HITL_HALT` | `issue:{issue_number}` | Human requested stop |
| `HITL_TIMEOUT` | `issue:{issue_number}` | No response within timeout |

### Epic Lifecycle Signals

| Signal | Payload | Meaning |
|--------|---------|---------|
| `EPIC_STARTED` | `{epic_id}` | New epic execution started |
| `EPIC_COMPLETE` | `{epic_id}:{status}` | Epic finished (success/partial) |
| `STORY_STARTED` | `{story_id}` | Story execution started |
| `STORY_COMPLETE` | `{story_id}:{status}` | Story finished |
| `PHASE_TRANSITION` | `{from_phase}:{to_phase}` | Phase change occurred |

### Recovery Signals

| Signal | Payload | Meaning |
|--------|---------|---------|
| `RECOVERY_STARTED` | `{reason}` | Recovery process initiated |
| `RECOVERY_COMPLETE` | `{commit_hash}` | Successfully recovered |
| `RECOVERY_FAILED` | `{error}` | Recovery failed |

### Error Signals

| Signal | Payload | Meaning |
|--------|---------|---------|
| `FATAL_ERROR` | `{error_code}:{message}` | Unrecoverable error, halt |
| `RECOVERABLE_ERROR` | `{error_code}:{message}` | Error that can be retried |

---

## Signal Emission Script

```bash
# Using lib/common.sh
emit_signal "CHECKPOINT" "epic-3:3-1:phase-2:5"

# Direct emission
echo "SAGE_SIGNAL:CHECKPOINT:epic-3:3-1:phase-2:5"
```

---

## Orchestrator Hook Integration

The orchestrator (orchestrate-v2.sh) captures signals from stdout:

```bash
# Signal detection pattern
if [[ "$line" =~ ^SAGE_SIGNAL:([^:]+):(.*)$ ]]; then
    signal_type="${BASH_REMATCH[1]}"
    signal_payload="${BASH_REMATCH[2]}"
    handle_signal "$signal_type" "$signal_payload"
fi
```

---

## Signal Handling by Type

### CHECKPOINT Signals

When orchestrator receives `CHECKPOINT:WRITE`:
1. Capture checkpoint info from payload
2. Allow session to exit cleanly
3. Restart with `/assistant *resume`

### HITL Signals

When orchestrator receives `HITL_REQUIRED`:
1. Record issue number
2. Start polling with `gh-wait-approval.sh`
3. On response, resume with appropriate action

### FATAL_ERROR Signals

When orchestrator receives `FATAL_ERROR`:
1. Log error details
2. Preserve state for debugging
3. Do not restart
4. Notify user if configured

---

## Error Codes

| Code | Meaning |
|------|---------|
| `NO_CHECKPOINT` | Expected checkpoint not found |
| `CHECKPOINT_CORRUPT` | Checkpoint file invalid |
| `GIT_STATE_MISMATCH` | Git HEAD doesn't match checkpoint |
| `GITHUB_AUTH_FAILED` | GitHub CLI not authenticated |
| `SUBAGENT_FAILED` | Subagent returned error |
| `MAX_RETRIES_EXCEEDED` | Retry limit reached |
