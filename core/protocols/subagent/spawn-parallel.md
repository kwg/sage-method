# Protocol: Spawn Parallel

**ID:** spawn_parallel
**Critical:** PARALLEL_SPAWN
**Purpose:** Spawns multiple subagents in parallel for independent tasks

---

## Input/Output

**Input:** batch_tasks (list of parallel-safe task objects)
**Output:** merged_result dict

---

## Preconditions

- `checkpoint.parallel_plan.approved_parallel == true`
- All tasks have `file_conflicts == "none"`
- Tasks are in same phase (all implement, all test, etc.)

---

## Steps

### Step 1: Verify Parallel Safety

Check `checkpoint.parallel_plan.approved_parallel == true`
IF false: Error - parallel spawn not approved
Verify no file overlaps between tasks.

### Step 2: Generate All Contexts

For each task in batch_tasks, generate context with `<parallel-info>` section:

```xml
<parallel-info>
  <batch-id>{batch_id}</batch-id>
  <parallel-with>
    <task>{other_task_ids}</task>
  </parallel-with>
  <file-isolation>
    <exclusive>{files this task exclusively modifies}</exclusive>
  </file-isolation>
</parallel-info>
```

### Step 3: Spawn All Subagents in Single Message

Use Claude Code's parallel tool calling:
- All spawn calls in one message
- Claude executes them concurrently

### Step 4: Collect All Outputs

Wait for all subagents to complete.
Read all output files from `.sage/output/`

### Step 5: Parse All Outputs

Parse each output file.
Collect results in list.

### Step 6: Merge State

Aggregate files_modified from all tasks.

Check for conflicts:
- IF same file in multiple outputs: **FATAL_ERROR** - file conflict in parallel merge

Merge test results (sum counts).
Merge notes.

### Step 7: Create Single Checkpoint

Update checkpoint with:
- All files modified (merged list)
- batch_id recorded
- parallel_plan cleared (batch complete)

Commit checkpoint.

### Step 8: Return Merged Result

```json
{
  "status": "success|partial",
  "tasks_completed": [...],
  "tasks_failed": [...],
  "files_modified": [...],
  "next_action": "continue|spawn-fixer"
}
```

- `success`: All tasks succeeded
- `partial`: Some tasks failed
