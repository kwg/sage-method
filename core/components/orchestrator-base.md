# Orchestrator Base Pattern

**Version:** 1.0
**Purpose:** Domain-agnostic base pattern for phased workflow orchestration

---

## Overview

The Orchestrator Base provides a thin orchestration loop that domain-specific orchestrators inherit. It handles state management, phase transitions, and component integration while delegating cognitive work to phase files.

---

## Core Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR LOOP                         │
│                                                              │
│   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐     │
│   │ 1. Read │──▶│ 2. Todo │──▶│ 3. Exec │──▶│ 4.Merge │     │
│   │  State  │   │ Update  │   │  Phase  │   │  State  │     │
│   └─────────┘   └─────────┘   └─────────┘   └─────────┘     │
│        ▲                                          │          │
│        │                                          ▼          │
│        │              ┌─────────┐   ┌─────────┐              │
│        └──────────────│ 7.Check │◀──│ 6.Output│◀─────────────┘
│                       │Continue │   │ Summary │              │
│                       └─────────┘   └─────────┘              │
│                            │                                 │
│                            ▼                                 │
│                       ┌─────────┐                            │
│                       │ 5.Write │                            │
│                       │  State  │                            │
│                       └─────────┘                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Base Structure

Domain orchestrators extend this pattern:

```yaml
# orchestrator.md (domain-specific)

extends: sage/core/components/orchestrator-base.md

domain: software | game | research

phases:
  - "00-init"
  - "01-story-start"
  - "02-plan"
  # ... domain-specific phases
  - "done"

components:
  - state-manager
  - retry-handler
  - metrics-collector
  - learning-recorder
  - subagent-spawner

phase_directory: "./phases/"
state_directory: "./state/"
```

---

## Loop Steps

### Step 1: Read State

```xml
<loop-step n="1" name="read-state">
  <action>
    state_manager:
      action: read
      state_file: "state/{{workflow_id}}-state.json"
  </action>

  <check if="read failed">
    <check if="file not found AND is_resume">
      <error>State file not found. Cannot resume.</error>
      <action>Prompt: start fresh or provide state?</action>
    </check>
    <check if="parse error">
      <error>State corrupted. Outputting raw for recovery.</error>
      <action>Output raw file content</action>
    </check>
  </check>

  <result>{{state}} object available for loop</result>
</loop-step>
```

### Step 2: Update TodoWrite

```xml
<loop-step n="2" name="update-todos">
  <action>
    Map current state to TodoWrite:

    - Workflow: {{workflow_id}} - {{title}}
      - [{{status}}] Phase: {{phase}}
      - [{{status}}] Item: {{current_item}}

    Status mapping:
    - completed → "completed"
    - current → "in_progress"
    - future → "pending"
  </action>
</loop-step>
```

### Step 3: Execute Phase

```xml
<loop-step n="3" name="execute-phase">
  <action>
    Determine phase file: {{phase_directory}}/{{state.phase}}.md
  </action>

  <action>
    Read and execute phase file with:
    - state: {{state}}
    - components: available component interfaces
  </action>

  <result>
    Phase returns:
    {
      "next_phase": "phase-name",
      "state_updates": { ... partial state ... },
      "output": "Human-readable summary"
    }
  </result>
</loop-step>
```

### Step 4: Merge State

```xml
<loop-step n="4" name="merge-state">
  <action>
    state_manager:
      action: merge
      state_file: "state/{{workflow_id}}-state.json"
      updates:
        phase: {{phase_output.next_phase}}
        ...{{phase_output.state_updates}}
        last_updated: {{current_iso_timestamp}}
  </action>
</loop-step>
```

### Step 5: Write State

```xml
<loop-step n="5" name="write-state">
  <action>
    state_manager:
      action: write
      state_file: "state/{{workflow_id}}-state.json"
      state: {{merged_state}}
  </action>

  <check if="write failed">
    <error>Failed to persist state</error>
    <action>Output full state JSON for manual recovery</action>
  </check>
</loop-step>
```

### Step 6: Output Summary

```xml
<loop-step n="6" name="output-summary">
  <action>Output {{phase_output.output}} to user</action>
</loop-step>
```

### Step 7: Check Continue

```xml
<loop-step n="7" name="check-continue">
  <check if="state.phase == 'done'">
    <output>Workflow complete!</output>
    <action>Exit loop</action>
  </check>

  <check if="state.error is set">
    <output>Error: {{state.error}}</output>
    <action>Prompt: retry, skip, or abort?</action>
  </check>

  <action>Continue to step 1</action>
</loop-step>
```

---

## Initialization

### New Workflow

```xml
<initialization type="new">
  <step n="1">Receive workflow parameters (e.g., epic_id)</step>
  <step n="2">
    Create initial state:
    {
      "phase": "00-init",
      "workflow_id": null,
      "metrics": {
        "workflow_version": "1.0",
        "start_time": "{{timestamp}}"
      }
    }
  </step>
  <step n="3">Write to state/workflow-new-state.json</step>
  <step n="4">Enter main loop</step>
</initialization>
```

### Resume Workflow

```xml
<initialization type="resume">
  <step n="1">Receive workflow_id</step>
  <step n="2">Read state from state/{{workflow_id}}-state.json</step>
  <step n="3">Validate state has valid phase</step>
  <step n="4">Output: "Resuming from phase: {{phase}}"</step>
  <step n="5">Enter main loop</step>
</initialization>
```

---

## Phase File Contract

Each phase file MUST:

1. **Receive state** as input context
2. **Perform bounded work** (~100 lines of instruction)
3. **Return structured output**:

```json
{
  "next_phase": "string (next phase to execute)",
  "state_updates": {
    // Partial state updates to merge
  },
  "output": "string (human-readable summary)"
}
```

---

## Component Integration

Phases access components via standardized interfaces:

```xml
<phase id="03-implement">
  <!-- Spawn subagent -->
  <action>
    subagent_spawner:
      action: spawn
      subagent_type: "IMPLEMENTER"
      context: {{bounded_context}}
  </action>

  <!-- Record metrics -->
  <action>
    metrics_collector:
      action: record_count
      metric: "files_modified"
      value: {{count}}
  </action>

  <!-- Use retry handler -->
  <action>
    retry_handler:
      operation: "test"
      max_retries: 3
  </action>
</phase>
```

---

## Error Handling

### Phase Error

```json
{
  "next_phase": "{{current_phase}}",  // Stay on same phase
  "state_updates": {
    "error": "Description of error",
    "retry_count": 1
  },
  "output": "Error encountered: ..."
}
```

### Cascade Detection

When multiple failures occur:

```xml
<cascade-check>
  <condition>failures_in_window >= cascade_threshold</condition>
  <action>
    Set state.cascade_detected = true
    Pause execution
    Generate diagnosis from learning records
    Alert user with options: fix root cause, skip, abort
  </action>
</cascade-check>
```

---

## Domain Extension Template

```markdown
# {{Domain}} Epic Orchestrator

extends: sage/core/components/orchestrator-base.md

## Domain: {{domain}}

## Phases

| Phase | File | Purpose |
|-------|------|---------|
| 00-init | 00-init.md | Parse epic, build queue |
| 01-item-start | 01-item-start.md | Load item, create branch |
| ... | ... | ... |
| done | - | Workflow complete |

## Domain-Specific State

```json
{
  // Base state fields (from orchestrator-base)
  "phase": "...",
  "workflow_id": "...",

  // Domain-specific fields
  "epic_id": "...",
  "story_queue": [],
  "current_story": null,
  // ...
}
```

## Domain-Specific Components

- Additional subagent types
- Custom retry policies
- Domain metrics

## Phase Directory

./phases/
├── 00-init.md
├── 01-item-start.md
├── ...
└── 08-finalize.md
```

---

## Usage

1. **Create domain orchestrator**: Extend this base
2. **Define phases**: Create phase files in `./phases/`
3. **Define state schema**: Extend base schema with domain fields
4. **Configure components**: Set retry limits, metrics, etc.
5. **Test loop**: Verify phase transitions work correctly
