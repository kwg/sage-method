# Protocol: Spawn Sequential

**ID:** spawn_sequential
**Critical:** SPAWN_CONTROL
**Purpose:** Spawns single subagent with bounded context, waits for completion

---

## Input/Output

**Input:** task_id, subagent_type, task_data
**Output:** parsed_result dict

---

## Steps

### Step 1: Generate Context

Call `generate_context(task_id, subagent_type, task_data)`
Get context_file path.

### Step 2: Map Subagent Type to Agent File

| Subagent | Agent File |
|----------|------------|
| PLANNER | sage/agents/core/planner.md |
| IMPLEMENTER | sage/agents/software/dev.md |
| TESTER | sage/agents/core/tester.md |
| FIXER | sage/agents/core/fixer.md |
| REVIEWER | sage/agents/core/reviewer.md |

### Step 3: Invoke Subagent

Load agent file.
Inject context from context_file.
Execute agent with task.
Wait for completion.

### Step 4: Collect Output

Read subagent output from `.sage/output/{task_id}.xml`
IF file not found: Set status = "timeout"

### Step 5: Parse Output

Call `parse_output(task_id)`
Extract: status, summary, files_modified, tests, failures
IF parse fails: Log error, set status = "error"

### Step 6: Update Checkpoint State

Update `current.task_index`
Update `current.step`
Update `last_output` with parsed result

Determine next_action based on status:

| Status | Next Action |
|--------|-------------|
| success | continue (next task or checkpoint) |
| failure | spawn-fixer (if retry < 3) |
| blocked | hitl-clarification |
| timeout | retry (once) |

### Step 7: Return Result

```json
{
  "status": "...",
  "summary": "...",
  "files_modified": [...],
  "next_action": "..."
}
```
