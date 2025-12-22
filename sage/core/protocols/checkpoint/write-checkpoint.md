# Protocol: Write Checkpoint

**ID:** write_checkpoint
**Critical:** ALWAYS_COMMIT
**Purpose:** Writes checkpoint JSON and creates git commit

---

## Input/Output

**Input:** current_state (orchestration state object)
**Output:** checkpoint_file path, commit_hash

---

## Steps

### Step 1: Prepare Checkpoint JSON

Build checkpoint object with schema:

```json
{
  "version": "1.0",
  "created": "{original_creation_timestamp or now}",
  "updated": "{current_timestamp_iso8601}",
  "project": {
    "name": "{project_name from config}",
    "root": "{project_root from config}"
  },
  "git": {
    "branch": "{current_branch}",
    "last_checkpoint_commit": "{will_be_filled_after_commit}",
    "commit_message": "checkpoint: {epic_id}-story-{story_num}-task-{task_num}-{step}"
  },
  "lifecycle": {
    "phase": "{phase_number}",
    "phase_name": "{DESIGN|PLAN|BUILD|VALIDATE}"
  },
  "epic": {
    "id": "{epic_id}",
    "file": "{epic_file_path}",
    "status": "{in_progress|paused|blocked}",
    "stories_total": "{total_stories}",
    "stories_complete": "{completed_stories}"
  },
  "current": {
    "story_id": "{current_story_id}",
    "story_file": "{story_file_path}",
    "task_index": "{current_task_number}",
    "task_total": "{total_tasks_in_story}",
    "step": "{plan|implement|test|review}",
    "retry_count": "{retry_attempts}"
  },
  "parallel_plan": {
    "batch_id": null,
    "tasks": [],
    "approved_parallel": false,
    "file_conflicts": "none"
  },
  "completed": [
    {"story_id": "...", "status": "done", "checkpoint_commit": "..."}
  ],
  "last_output": {
    "subagent": null,
    "result": null,
    "action_required": null
  },
  "failure_history": [],
  "metrics": {
    "tokens_used": "{estimated_tokens}",
    "subagents_spawned": "{count}",
    "clears_performed": "{count}",
    "recoveries_performed": "{count}",
    "time_elapsed_minutes": "{elapsed}"
  },
  "next_action": {
    "type": "{continue|retry|hitl|spawn|complete}",
    "description": "{human_readable_next_step}",
    "subagent": "{subagent_id if type=spawn}"
  }
}
```

### Step 2: Write Checkpoint File

Write JSON to: `.sage/state/{epic_id}.json`
- Pretty-print with 2-space indent
- Validate JSON is well-formed before writing

### Step 3: Stage All Changes

```bash
git add -A
```

Check for errors.

### Step 4: Create Checkpoint Commit

Build commit message: `checkpoint: {epic_id}-story-{story_num}-task-{task_num}-{step}`

```bash
git commit -m "{commit_message}"
```

Capture exit code - if non-zero, handle error.

### Step 5: Get Commit Hash and Update Checkpoint

```bash
git rev-parse HEAD
```

Update checkpoint JSON with commit hash in `git.last_checkpoint_commit`.
Re-write checkpoint file with complete data.

### Step 6: Signal Checkpoint Complete

Output EXACTLY this format (for hook detection):

```
═══ SAGE_SIGNAL:CHECKPOINT ═══
CHECKPOINT_FILE: .sage/state/{epic_id}.json
COMMIT: {commit_hash}
NEXT_ACTION: {next_action.type}
═══════════════════════════════
```

---

## Error Handling

- If git not initialized: `ERROR: Not a git repository. Cannot checkpoint.`
- If write fails: `ERROR: Cannot write checkpoint. Check disk space and permissions.`
- If commit fails: `ERROR: Git commit failed. Check for conflicts or hooks.`
- On any error: Preserve previous checkpoint, report error, allow retry
