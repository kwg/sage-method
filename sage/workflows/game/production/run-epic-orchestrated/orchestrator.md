# Epic Orchestrator (Game Module - Phased Execution Loop)

```xml
<critical>VERSION 3.1: Phased execution with persistent state and core components</critical>
<critical>This is the THIN ORCHESTRATOR - it only manages state and phase transitions</critical>
<critical>All cognitive work happens in phase files via subagents</critical>

<overview>
  The orchestrator runs a simple loop:
  1. Read state from JSON file
  2. Update TodoWrite for visibility
  3. Execute current phase file
  4. Phase returns next_phase + state_updates
  5. Merge updates, write state, loop

  Benefits:
  - Bounded context per phase (~100 lines vs 1000)
  - Resumable from any point (state persisted)
  - Visible progress via TodoWrite
  - Debuggable (inspect state file)

  Game-specific features:
  - Visual integration testing with Godot
  - Optional integration phase for agent_tests
  - Branch naming: {story_id} (no prefix)
</overview>

<components>
  This orchestrator uses core SAGE components (EPIC-002):
  - state-manager: JSON persistence, resume capability
  - retry-handler: Configurable retries per phase
  - metrics-collector: Timing, tokens, counts
  - learning-recorder: Failure context and classification
  - subagent-spawner: Bounded context spawning

  See: sage/core/components/
</components>

<state-file>
  Location: state/epic-{{epic_id}}-state.json
  Schema: state-schema.json

  The state file is the SINGLE SOURCE OF TRUTH.
  - Orchestrator reads it at loop start
  - Phase files receive it as input
  - Phase files return updates (not full state)
  - Orchestrator merges updates and writes back
</state-file>

<initialization>
  When starting a NEW epic run:

  <step n="1">Receive epic_path from user (or find from sprint-status.yaml)</step>
  <step n="2">Create initial state:
    {
      "phase": "00-init",
      "epic_id": null,
      "epic_branch": null,
      "story_queue": [],
      "current_story_index": 0,
      "completed_stories": [],
      "failed_stories": [],
      "learning_records": [],
      "cascade_detection": {
        "failures_in_window": 0,
        "last_failures": [],
        "cascade_detected": false
      },
      "metrics": {
        "workflow_version": "3.1-phased",
        "start_time": "{{current_iso_timestamp}}",
        "stories": [],
        "summary": {}
      }
    }
  </step>
  <step n="3">Write to state/epic-new-state.json (will be renamed after init parses epic_id)</step>
  <step n="4">Enter main loop</step>
</initialization>

<resumption>
  When RESUMING an existing epic run:

  <step n="1">Receive epic_id from user</step>
  <step n="2">Read state from state/epic-{{epic_id}}-state.json</step>
  <step n="3">Validate state exists and has valid phase</step>
  <step n="4">Output: "Resuming epic-{{epic_id}} from phase: {{phase}}"</step>
  <step n="5">Enter main loop</step>
</resumption>

<main-loop>
  <critical>This loop runs until phase == "done" or unrecoverable error</critical>

  <loop-step n="1" name="read-state">
    state_manager:
      action: read
      state_file: "state/epic-{{epic_id}}-state.json"

    <check if="file not found or invalid JSON">
      <error>State file corrupted or missing. Cannot continue.</error>
      <action>Ask user: start fresh or provide state file?</action>
    </check>
  </loop-step>

  <loop-step n="2" name="update-todos">
    Update TodoWrite to reflect current progress:

    - Epic {{epic_id}}: {{epic_title}}
      - [status] Phase: {{phase}}
      - [status] Story {{current_story_index + 1}}/{{story_queue.length}}: {{current_story}}
      - [status] Chunk {{current_chunk_index + 1}}/{{chunk_queue.length}} (if applicable)

    Status mapping:
    - completed phases/stories/chunks → "completed"
    - current item → "in_progress"
    - future items → "pending"
  </loop-step>

  <loop-step n="3" name="execute-phase">
    Determine phase file: phases/{{state.phase}}.md

    <action>Read and execute phase file</action>
    <action>Pass {{state}} as input context</action>

    Phase file will:
    - Perform its specific work (may spawn subagents)
    - Return JSON output with:
      {
        "next_phase": "phase-name",
        "state_updates": { ... partial state updates ... },
        "output": "Human-readable summary"
      }
  </loop-step>

  <loop-step n="4" name="merge-state">
    state_manager:
      action: merge
      state_file: "state/epic-{{epic_id}}-state.json"
      updates:
        phase: {{phase_output.next_phase}}
        ...{{phase_output.state_updates}}
        last_updated: {{current_iso_timestamp}}
  </loop-step>

  <loop-step n="5" name="write-state">
    state_manager:
      action: write
      state_file: "state/epic-{{epic_id}}-state.json"
      state: {{merged_state}}

    <check if="write fails">
      <error>Failed to persist state. Outputting state for manual recovery.</error>
      <action>Output full state JSON to console</action>
    </check>
  </loop-step>

  <loop-step n="6" name="output-summary">
    Output phase_output.output to user (the human-readable summary)
  </loop-step>

  <loop-step n="7" name="check-continue">
    <check if="state.phase == 'done'">
      <output>Epic execution complete!</output>
      <action>Exit loop</action>
    </check>

    <check if="state.error is set">
      <output>Error encountered: {{state.error}}</output>
      <action>Ask user: retry current phase, skip, or abort?</action>
    </check>

    <check if="cascade detected">
      learning_recorder:
        action: get_patterns
        scope: "workflow"

      <output>⚠️ Cascade failure detected. Recent patterns:</output>
      <action>Output learning patterns for diagnosis</action>
      <action>Ask user: continue, pause, or abort?</action>
    </check>

    <action>Continue to loop-step 1</action>
  </loop-step>
</main-loop>

<learning-integration>
  At story completion or failure, learning records are:
  1. Recorded with failure context
  2. Classified by category (syntax, logic, architecture, integration, environment)
  3. Aggregated at epic completion
  4. Used for cascade detection

  See: sage/core/components/learning-recorder.md
</learning-integration>

<phase-transitions>
  Normal flow:

  00-init → 01-story-start
  01-story-start → 02-plan (or 08-finalize if no more stories)
  02-plan → 03-implement-chunk
  03-implement-chunk → 03-implement-chunk (more chunks) | 04-test (all chunks done)
  04-test → 05-integration (tests pass) | 04-test (retry with FIX)
  05-integration → 06-review
  06-review → 06-review (issues found, retry) | 07-story-complete (clean)
  07-story-complete → 01-story-start (more stories) | 08-finalize (all done)
  08-finalize → done

  Error recovery:
  - Any phase can set state.error and stay on same phase
  - Orchestrator prompts user for action
  - User can: retry, skip to next story, or abort
</phase-transitions>

<git-safety>
  The orchestrator does NOT perform git operations directly.
  Each phase file handles its own git operations.

  State file considerations:
  - state/ directory should be in .gitignore (runtime state)
  - OR commit state file for team visibility (your choice)
  - Metrics are saved separately in docs/sprint-artifacts/
</git-safety>
</orchestrator>
```

## Usage

### Start New Epic

```
User: *run-epic
Agent: Which epic? (provide path or epic ID)
User: ms-1
Agent: Starting epic ms-1...
       [Creates initial state, enters loop]
```

### Resume Epic

```
User: *run-epic
Agent: Found existing state for epic-ms-1 at phase 03-implement-chunk.
       Resume from current position?
User: yes
Agent: Resuming...
       [Reads state, continues from phase]
```

### State Inspection

```
User: Show me the current state
Agent: [Reads and displays state/epic-ms-1-state.json]
```
