# Protocol: Parse Output

**ID:** parse_output
**Critical:** OUTPUT_PARSING
**Purpose:** Parses structured XML output from subagent

---

## Input/Output

**Input:** task_id
**Output:** parsed result dict or error

---

## Steps

### Step 1: Read Output File

Read `.sage/output/{task_id}.xml`

IF file not found: Return `{status: "timeout", error: "No output file"}`

### Step 2: Validate XML

Parse XML structure.

IF malformed:
- Log error: `Malformed output from {task_id}`
- Return `{status: "error", error: "Malformed XML", raw: content}`

### Step 3: Extract Required Fields

| Field | Path |
|-------|------|
| status | result/status |
| summary | result/summary |
| files_modified | result/files-modified/file (list) |

### Step 4: Extract Optional Fields

| Field | Path |
|-------|------|
| tests | result/tests |
| failures | result/tests/failures |
| blockers | result/blockers |
| notes | result/notes |
| recommended_action | result/recommended-action |

### Step 5: Normalize Result

Return:

```json
{
  "task_id": "...",
  "subagent": "...",
  "status": "success|failure|blocked|timeout",
  "summary": "...",
  "files_modified": [...],
  "tests": {"passed": N, "failed": N, "skipped": N},
  "failures": [{"test": "...", "error": "...", "file": "...", "line": N}, ...],
  "blockers": [...],
  "notes": "...",
  "recommended_action": "..."
}
```
