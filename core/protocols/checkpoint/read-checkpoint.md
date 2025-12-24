# Protocol: Read Checkpoint

**ID:** read_checkpoint
**Purpose:** Reads and parses checkpoint JSON file

---

## Input/Output

**Input:** epic_id (optional - auto-detect if single checkpoint exists)
**Output:** checkpoint_state object or null

---

## Steps

### Step 1: Check for Checkpoint Files

List files in `.sage/state/*.json`

- IF no files found: Return null
- IF multiple files and no epic_id specified:
  - List available checkpoints
  - Prompt user to select or specify epic_id
  - Return selected checkpoint

### Step 2: Read Checkpoint File

Read `.sage/state/{epic_id}.json`

IF file not found: Return null with message `Checkpoint not found: {epic_id}`

### Step 3: Parse and Validate JSON

Parse JSON content.

IF parse fails:
- Log error: `Checkpoint file corrupted: {epic_id}.json`
- Suggest: `Run 'git show HEAD:.sage/state/{epic_id}.json' to recover`
- Return null

### Step 4: Validate Schema

Check version field = "1.0"

Check required fields exist:
- `epic.id`
- `current.story_id`
- `current.task_index`
- `git.last_checkpoint_commit`
- `next_action.type`

IF validation fails:
- Log error: `Checkpoint schema invalid. Missing: {field_name}`
- Return null

### Step 5: Return Checkpoint State

Return parsed checkpoint object with all fields accessible.
