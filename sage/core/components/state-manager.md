# State Manager Component

**Version:** 1.0
**Purpose:** Persistent JSON state management for resumable workflow execution

---

## Overview

The State Manager provides a standardized interface for reading, writing, and managing persistent workflow state. It enables workflows to be paused and resumed from any point.

---

## Interface

### Initialize State

```yaml
state_manager:
  action: init
  state_file: "state/{workflow_id}-state.json"
  initial_state:
    phase: "00-init"
    workflow_id: null
    # ... domain-specific fields
```

**Output:**
```json
{
  "success": true,
  "state_file": "state/epic-123-state.json",
  "state": { ... initial state ... }
}
```

### Read State

```yaml
state_manager:
  action: read
  state_file: "state/{workflow_id}-state.json"
```

**Output:**
```json
{
  "success": true,
  "state": { ... current state ... },
  "last_updated": "2025-12-19T10:30:00Z"
}
```

**Error Output:**
```json
{
  "success": false,
  "error": "State file not found or corrupted",
  "recovery_options": ["start_fresh", "provide_backup"]
}
```

### Write State

```yaml
state_manager:
  action: write
  state_file: "state/{workflow_id}-state.json"
  state: { ... full state object ... }
```

**Output:**
```json
{
  "success": true,
  "state_file": "state/epic-123-state.json",
  "last_updated": "2025-12-19T10:35:00Z"
}
```

### Merge Updates

```yaml
state_manager:
  action: merge
  state_file: "state/{workflow_id}-state.json"
  updates:
    phase: "02-plan"
    current_item: "story-1"
```

**Behavior:**
- Reads current state
- Merges provided updates (shallow merge)
- Sets `last_updated` timestamp
- Writes back to file

**Output:**
```json
{
  "success": true,
  "state": { ... merged state ... },
  "fields_updated": ["phase", "current_item", "last_updated"]
}
```

---

## State File Location

States are stored in a `state/` directory relative to the workflow:

```
workflow-directory/
├── workflow.md
├── orchestrator.md
├── state/
│   ├── .gitkeep
│   ├── epic-123-state.json
│   └── epic-456-state.json
└── phases/
```

**Note:** The `state/` directory should typically be in `.gitignore` for runtime state. For team visibility, state can optionally be committed.

---

## State Schema Requirements

All workflow states MUST include:

```json
{
  "phase": "string (current phase identifier)",
  "workflow_id": "string (unique identifier for this run)",
  "last_updated": "string (ISO 8601 timestamp)",
  "error": "string|null (last error if any)"
}
```

Domain-specific fields are added as needed.

---

## Error Handling

### File Not Found
- Return error with recovery options
- Do not create empty state automatically

### JSON Parse Error
- Return error with file path
- Output raw content for manual recovery

### Write Failure
- Return error
- Output full state JSON to console for manual recovery

---

## Usage Example

```xml
<step n="1" name="read-state">
  <action>
    Read state from: state/{{workflow_id}}-state.json
    Parse JSON into {{state}} object
  </action>

  <check if="file not found or invalid JSON">
    <error>State file corrupted or missing. Cannot continue.</error>
    <action>Ask user: start fresh or provide state file?</action>
  </check>
</step>

<step n="4" name="merge-state">
  <action>state.phase = phase_output.next_phase</action>
  <action>For each key in phase_output.state_updates:
    state[key] = phase_output.state_updates[key]
  </action>
  <action>state.last_updated = current_iso_timestamp</action>
</step>

<step n="5" name="write-state">
  <action>Write updated state to: state/{{workflow_id}}-state.json</action>

  <check if="write fails">
    <error>Failed to persist state. Outputting state for manual recovery.</error>
    <action>Output full state JSON to console</action>
  </check>
</step>
```

---

## Integration with TodoWrite

State transitions should be reflected in TodoWrite for user visibility:

```xml
<step name="update-todos">
  Update TodoWrite to reflect current progress:

  - Workflow {{workflow_id}}: {{title}}
    - [status] Phase: {{phase}}
    - [status] Item {{current_index + 1}}/{{queue.length}}: {{current_item}}

  Status mapping:
  - completed phases/items → "completed"
  - current item → "in_progress"
  - future items → "pending"
</step>
```
