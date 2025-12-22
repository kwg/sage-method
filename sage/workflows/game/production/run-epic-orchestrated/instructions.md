# Run Epic (Orchestrated Subagents) - Chunked Execution Workflow

```xml
<critical>VERSION 2.2: Chunked execution with per-story integration tests (FULL_QA moved to separate workflow)</critical>
<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Main agent is ORCHESTRATOR ONLY - all cognitive work done by subagents</critical>
<critical>Orchestrator handles: git operations, file writes, state tracking, user interaction, metrics logging</critical>
<critical>Subagents handle: planning, implementation, testing, reviewing (stateless, fresh context, SMALL scope)</critical>

<workflow>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- METRICS LOGGING - Initialize at start, update throughout                    -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <metrics-schema>
    <!-- All metrics stored in {{epic_metrics}} dictionary for retrospective analysis -->
    {
      "epic_id": "string",
      "epic_title": "string",
      "workflow_version": "2.2-chunked",
      "start_time": "ISO timestamp",
      "end_time": "ISO timestamp",
      "stories": [
        {
          "story_id": "string",
          "chunks_planned": "int",
          "chunks_completed": "int",
          "chunks_failed": "int",
          "chunks_skipped_dependency": "int",
          "planner_duration_ms": "int",
          "total_implementation_duration_ms": "int",
          "chunk_metrics": [
            {
              "chunk_id": "string",
              "tasks_count": "int",
              "files_created": "int",
              "files_modified": "int",
              "subagent_duration_ms": "int",
              "context_size_estimate": "small|medium|large",
              "success": "bool",
              "failure_reason": "string|null",
              "retry_count": "int"
            }
          ],
          "test_attempts": "int",
          "review_iterations": "int",
          "issues_found": {"critical": 0, "high": 0, "medium": 0, "low": 0},
          "tests_passed": "bool",
          "final_status": "completed|failed|skipped"
        }
      ],
      "summary": {
        "total_stories": "int",
        "completed_stories": "int",
        "failed_stories": "int",
        "skipped_stories": "int",
        "total_chunks": "int",
        "avg_chunk_duration_ms": "int",
        "context_compaction_events": "int"
      }
    }
  </metrics-schema>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 1: EPIC INITIALIZATION                                                -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="0" goal="Load epic and initialize orchestrator state" tag="init">
    <critical>Parse epic to build story execution queue</critical>
    <critical>Create epic branch to isolate all story work from dev</critical>
    <critical>Initialize metrics tracking for retrospective analysis</critical>
    <critical>WARN if any stories are not ready-for-dev</critical>

    <action>Load epic file from: {{epic_path}} OR find from sprint-status.yaml</action>
    <action>Parse epic structure:
      - Epic ID and title (e.g., epic_id = "4", epic_title = "Run Structure")
      - List of stories with IDs and dependencies
      - Epic-level constraints and notes
    </action>

    <action>Build {{story_queue}} ordered list:
      - Respect story dependencies (story X depends on story Y = Y runs first)
      - Default to numeric order if no explicit dependencies
    </action>

    <!-- LOW FIX: Warn about skipped stories -->
    <action>Scan {{story_queue}} for stories NOT in "ready-for-dev" or "in-progress" status</action>
    <check if="any stories will be skipped">
      <output>⚠️ **WARNING: The following stories will be SKIPPED** (not ready-for-dev):
{{skipped_stories_list}}

These stories will NOT be implemented during this run.
To include them, mark them as "ready-for-dev" in sprint-status.yaml before running.
      </output>
      <action>Update epic_metrics.summary.skipped_stories = count of non-ready stories</action>
    </check>

    <action>Initialize orchestrator state:
      - {{epic_branch}} = "epic-{{epic_id}}" (e.g., "epic-4")
      - {{current_story_index}} = 0
      - {{completed_stories}} = []
      - {{failed_stories}} = []
      - {{epic_start_time}} = current timestamp
    </action>

    <action>Initialize metrics:
      - {{epic_metrics}} = new metrics dictionary per schema above
      - Set epic_metrics.epic_id, epic_title, workflow_version, start_time
      - Set epic_metrics.summary.total_stories = length({{story_queue}})
    </action>

    <!-- CREATE EPIC BRANCH -->
    <action>Create epic branch from dev:
      - git checkout dev
      - git pull origin dev
      - Check if {{epic_branch}} exists: git branch --list {{epic_branch}}
      - If exists: git checkout {{epic_branch}} && git merge dev --no-edit
      - If NOT exists: git checkout -b {{epic_branch}}
    </action>

    <output>🎯 **Epic Orchestrator Initialized (v2.1 Chunked)**

Epic: {{epic_id}} - {{epic_title}}
Epic Branch: {{epic_branch}}
Stories to execute: {{story_count}} ({{skipped_count}} will be skipped)
Order: {{story_queue_summary}}

Workflow: Chunked execution with PLANNER subagent
Metrics: Logging enabled for retrospective analysis

Beginning orchestrated execution...
    </output>

    <goto step="1">Start first story</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 2: STORY EXECUTION LOOP                                               -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="1" goal="Load next story from queue" tag="story-loop">
    <check if="{{current_story_index}} >= length({{story_queue}})">
      <goto step="20">All stories complete - finalize epic</goto>
    </check>

    <action>Get {{current_story}} = {{story_queue}}[{{current_story_index}}]</action>
    <action>Load story file: {{story_dir}}/{{current_story}}.md</action>
    <action>Parse story: Acceptance Criteria, Tasks, Constraints, Dev Notes</action>
    <action>Initialize story metrics entry in {{epic_metrics}}.stories</action>

    <check if="story status != 'ready-for-dev' AND status != 'in-progress'">
      <output>⏭️ Skipping {{current_story}} - status is "{{status}}" (not ready-for-dev)</output>
      <action>Update story metrics: final_status = "skipped"</action>
      <action>Increment {{current_story_index}}</action>
      <goto step="1">Next story</goto>
    </check>

    <output>📖 **Story {{current_story_index + 1}}/{{story_count}}: {{current_story}}**</output>

    <goto step="2">Create branch and plan</goto>
  </step>

  <step n="2" goal="Create feature branch FROM EPIC BRANCH" tag="git-branch">
    <critical>Story branches are created FROM the epic branch, NOT from dev</critical>

    <action>Determine branch name: {{current_story}} (e.g., "4-1-map-generation")</action>

    <!-- ENSURE WE'RE ON EPIC BRANCH FIRST -->
    <action>git checkout {{epic_branch}}</action>

    <action>Check if story branch exists: git branch --list {{branch_name}}</action>

    <check if="branch exists">
      <action>git checkout {{branch_name}}</action>
      <action>git merge {{epic_branch}} --no-edit (pull in any prior story changes)</action>
    </check>

    <check if="branch does NOT exist">
      <action>git checkout -b {{branch_name}} (creates from current {{epic_branch}})</action>
    </check>

    <!-- MEDIUM FIX: Commit sprint-status update -->
    <action>Update story status to "in-progress" in sprint-status.yaml</action>
    <action>git add docs/sprint-artifacts/sprint-status.yaml</action>
    <action>git commit -m "{{current_story}}: start implementation"</action>

    <output>🌿 Branch ready: {{branch_name}} (from {{epic_branch}})</output>

    <goto step="3">Spawn PLANNER subagent</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 3: STORY DECOMPOSITION (PLANNER SUBAGENT)                             -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="3" goal="Spawn PLANNER subagent to decompose story into chunks" tag="plan">
    <critical>PLANNER reads the whole story but DOES NOT implement</critical>
    <critical>PLANNER identifies logical chunks, dependencies, and shared patterns</critical>
    <critical>Each chunk should be completable without hitting context limits</critical>

    <action>Record {{planner_start_time}} = current timestamp</action>

    <output>📋 **Spawning PLANNER Subagent...**</output>

    <action>Use Task tool with subagent_type="general-purpose" and prompt:</action>

    <subagent-prompt id="planner">
You are a STORY DECOMPOSITION SPECIALIST. Your job is to break down a story into small, focused implementation chunks.

## Story File
Read this file completely: {{story_path}}

## Architecture Reference
Key patterns from: {{architecture_doc_path}}

## Your Goal
Analyze the story and create an execution plan with SMALL, FOCUSED chunks that:
- Can each be implemented by a stateless subagent with minimal context
- Have clear boundaries (specific tasks, specific files)
- Respect dependencies (chunk B needs chunk A's output)
- Identify shared patterns that all chunks should follow

## Chunking Guidelines
- Each chunk should create/modify 1-3 files maximum
- Each chunk should cover 1-5 related tasks
- Group tasks that work on the same file together
- Put foundation work (resources, types, constants) in early chunks
- Put dependent work (systems using those resources) in later chunks
- Consider: "Could a developer implement this chunk in 30 minutes with clear instructions?"

## Output Format

Return JSON ONLY (no markdown, no explanation):
```json
{
  "story_summary": "Brief description of what this story delivers",
  "total_tasks": 10,
  "chunks": [
    {
      "id": "chunk-1",
      "name": "Human-readable chunk name",
      "description": "What this chunk accomplishes",
      "tasks": ["1.1", "1.2", "2.1"],
      "task_descriptions": ["Create MathProblem resource", "Add MathType enum", "Add class_name"],
      "files_to_create": ["resources/math_problem.gd"],
      "files_to_modify": [],
      "files_to_read": [],
      "depends_on": [],
      "estimated_complexity": "small"
    },
    {
      "id": "chunk-2",
      "name": "Generator core implementation",
      "description": "Create MathProblemGenerator with base structure",
      "tasks": ["3.1", "3.2"],
      "task_descriptions": ["Create generator class", "Add static generate method"],
      "files_to_create": ["systems/math/math_problem_generator.gd"],
      "files_to_modify": [],
      "files_to_read": ["resources/math_problem.gd"],
      "depends_on": ["chunk-1"],
      "estimated_complexity": "medium"
    }
  ],
  "shared_patterns": [
    "Use static methods for stateless utilities",
    "Extend Resource for data classes",
    "Use class_name for all new classes"
  ],
  "execution_order": ["chunk-1", "chunk-2", "chunk-3"],
  "notes": "Any special considerations for implementation"
}
```
    </subagent-prompt>

    <action>Parse PLANNER subagent response</action>
    <action>Record {{planner_end_time}} = current timestamp</action>
    <action>Update story metrics: planner_duration_ms = {{planner_end_time}} - {{planner_start_time}}</action>

    <check if="PLANNER response invalid or error">
      <output>❌ PLANNER failed - falling back to single-chunk execution</output>
      <action>Create single fallback chunk containing all tasks</action>
    </check>

    <action>Store {{chunk_plan}} = parsed response</action>
    <action>Store {{chunk_queue}} = chunk_plan.execution_order</action>
    <action>Store {{shared_patterns}} = chunk_plan.shared_patterns</action>
    <action>Set {{current_chunk_index}} = 0</action>
    <action>Initialize {{completed_chunks}} = []</action>
    <action>Initialize {{failed_chunks}} = []</action>
    <action>Update story metrics: chunks_planned = length({{chunk_queue}})</action>

    <!-- LOW FIX: Validate chunks not empty -->
    <check if="length({{chunk_queue}}) == 0">
      <output>⚠️ PLANNER returned no chunks - story may have structural issues</output>
      <action>Update story metrics: final_status = "failed", failure_reason = "no_chunks"</action>
      <action>Add {{current_story}} to {{failed_stories}}</action>
      <action>Increment {{current_story_index}}</action>
      <goto step="1">Next story</goto>
    </check>

    <output>✅ PLANNER complete:
- Chunks: {{chunk_count}}
- Execution order: {{chunk_queue}}
- Shared patterns: {{shared_patterns_summary}}
    </output>

    <goto step="4">Execute first chunk</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 4: CHUNK EXECUTION LOOP                                               -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="4" goal="Load next chunk from queue" tag="chunk-loop">
    <check if="{{current_chunk_index}} >= length({{chunk_queue}})">
      <goto step="10">All chunks complete - run tests and review</goto>
    </check>

    <action>Get {{current_chunk}} = {{chunk_plan}}.chunks[{{chunk_queue}}[{{current_chunk_index}}]]</action>

    <!-- MEDIUM FIX: Initialize retry count for this chunk -->
    <action>Set {{chunk_retry_count}} = 0</action>

    <!-- CRITICAL FIX: Check if chunk dependencies are satisfied -->
    <check if="{{current_chunk.depends_on}} is not empty">
      <action>For each dependency_id in {{current_chunk.depends_on}}:
        - Check if dependency_id is in {{completed_chunks}}
        - If ANY dependency is in {{failed_chunks}}, this chunk cannot run
      </action>

      <check if="any dependency is in {{failed_chunks}}">
        <output>⏭️ Skipping chunk {{current_chunk.id}} - dependency failed: {{failed_dependency}}</output>
        <action>Update chunk metrics: success = false, failure_reason = "dependency_failed"</action>
        <action>Add {{current_chunk.id}} to {{failed_chunks}}</action>
        <action>Update story metrics: chunks_skipped_dependency++</action>
        <action>Increment {{current_chunk_index}}</action>
        <goto step="4">Next chunk</goto>
      </check>
    </check>

    <output>🧩 **Chunk {{current_chunk_index + 1}}/{{chunk_count}}: {{current_chunk.name}}**
Tasks: {{current_chunk.tasks}}
Files: {{current_chunk.files_to_create}} {{current_chunk.files_to_modify}}
Dependencies: {{current_chunk.depends_on}} (all satisfied ✓)
    </output>

    <goto step="5">Spawn IMPLEMENTER for this chunk</goto>
  </step>

  <step n="5" goal="Spawn IMPLEMENTER subagent for current chunk" tag="implement-chunk">
    <critical>IMPLEMENTER gets ONLY this chunk's scope - minimal context</critical>
    <critical>IMPLEMENTER reads dependency files (already committed) from disk</critical>

    <action>Record {{chunk_start_time}} = current timestamp</action>
    <action>Initialize chunk metrics entry</action>

    <output>🔨 **Spawning IMPLEMENTER for chunk: {{current_chunk.name}}** (attempt {{chunk_retry_count + 1}}/3)</output>

    <action>Use Task tool with subagent_type="general-purpose" and prompt:</action>

    <subagent-prompt id="implementer">
You are an IMPLEMENTATION SPECIALIST. Implement ONLY this specific chunk.

## Chunk Definition
Name: {{current_chunk.name}}
Description: {{current_chunk.description}}

## Tasks to Complete
{{current_chunk.task_descriptions as numbered list}}

## Files to Create
{{current_chunk.files_to_create}}

## Files to Modify
{{current_chunk.files_to_modify}}

## Files to Read First (dependencies from prior chunks)
{{current_chunk.files_to_read}}

## Shared Patterns (apply to ALL code)
{{shared_patterns as bulleted list}}

## Architecture Context
Key patterns: {{brief_architecture_summary}}

## Instructions

1. Read any dependency files listed above (they exist on disk)
2. Implement ONLY the tasks listed for THIS chunk
3. Apply ALL shared patterns consistently
4. Apply defensive programming:
   - Validate parameters
   - Check null returns
   - Guard async operations after await
   - Add _exit_tree() cleanup if connecting signals
   - Prevent signal double-connection

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "files": [
    {
      "path": "relative/path/to/file.gd",
      "action": "create|modify",
      "content": "FULL file content here"
    }
  ],
  "tasks_completed": ["1.1", "1.2"],
  "summary": "Brief description of what was implemented",
  "blockers": []
}
```

If you encounter blockers, set success=false and describe in blockers array.
    </subagent-prompt>

    <action>Parse IMPLEMENTER subagent response</action>
    <action>Record {{chunk_end_time}} = current timestamp</action>

    <!-- CRITICAL + MEDIUM FIX: Improved failure handling with metrics -->
    <check if="success == false">
      <output>❌ Chunk implementation blocked: {{blockers}}</output>

      <check if="{{chunk_retry_count}} < 2">
        <!-- MEDIUM FIX: Clarified retry logic -->
        <output>⚠️ Retrying chunk (attempt {{chunk_retry_count + 2}}/3)...</output>
        <action>Increment {{chunk_retry_count}}</action>
        <action>Add blocker context to next attempt:
          - Previous blockers: {{blockers}}
          - Hint: Check if files_to_read exist and are accessible
        </action>
        <goto step="5">Retry implementation</goto>
      </check>

      <!-- CRITICAL FIX: Update metrics BEFORE skipping to next chunk -->
      <output>❌ Chunk {{current_chunk.id}} failed after 3 attempts</output>
      <action>Update chunk metrics:
        - success = false
        - failure_reason = {{blockers}}
        - retry_count = {{chunk_retry_count}}
        - subagent_duration_ms = {{chunk_end_time}} - {{chunk_start_time}}
      </action>
      <action>Add {{current_chunk.id}} to {{failed_chunks}}</action>
      <action>Update story metrics: chunks_failed++</action>
      <action>Increment {{current_chunk_index}}</action>
      <goto step="4">Next chunk (will check dependencies)</goto>
    </check>

    <check if="success == true">
      <action>For EACH file in response:
        - If action == "create": Use Write tool
        - If action == "modify": Read file first, then use Edit tool
      </action>

      <action>Update chunk metrics:
        - success = true
        - files_created = count of create actions
        - files_modified = count of modify actions
        - subagent_duration_ms = {{chunk_end_time}} - {{chunk_start_time}}
        - retry_count = {{chunk_retry_count}}
      </action>

      <output>✅ Chunk {{current_chunk.name}} implemented - {{file_count}} files</output>
    </check>

    <goto step="6">Micro-commit and update tasks</goto>
  </step>

  <step n="6" goal="Micro-commit chunk and update story tasks" tag="chunk-commit">
    <critical>Commit after EACH successful chunk - provides checkpoints and enables task tracking</critical>

    <!-- MICRO-COMMIT -->
    <action>git add .</action>
    <action>Prepare commit message: "{{current_story}}: {{current_chunk.name}}"</action>
    <action>git commit -m "{{commit_message}}"</action>

    <check if="commit fails (pre-commit hook)">
      <action>Run pre-commit fixes if possible</action>
      <action>git add . && git commit --amend</action>
    </check>

    <output>📝 Committed: {{current_chunk.name}}</output>

    <!-- UPDATE STORY FILE TASK CHECKBOXES -->
    <action>Read story file once</action>
    <action>For EACH task in {{current_chunk.tasks}}:
      - Find task line matching task number (e.g., "- [ ] **Task 1.1:" or "- [ ] 1.1:")
      - Replace "- [ ]" with "- [x]"
    </action>
    <action>Write story file once (single read-modify-write)</action>

    <action>git add {{story_file_path}}</action>
    <action>git commit -m "{{current_story}}: mark chunk {{current_chunk.id}} tasks complete"</action>

    <output>☑️ Tasks marked complete: {{current_chunk.tasks}}</output>

    <!-- UPDATE TRACKING -->
    <action>Add {{current_chunk.id}} to {{completed_chunks}}</action>
    <action>Update story metrics: chunks_completed++</action>
    <action>Increment {{current_chunk_index}}</action>

    <goto step="4">Next chunk in queue</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 5: TESTING AND REVIEW                                                 -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="10" goal="Run tests after all chunks complete" tag="test">
    <action>Check if test framework exists in project</action>

    <check if="no test framework configured">
      <output>ℹ️ No test framework - skipping test execution</output>
      <action>Update story metrics: tests_passed = null</action>
      <goto step="11">Skip to review</goto>
    </check>

    <output>🧪 **Running Tests...**</output>

    <action>Set {{test_attempt}} = 1</action>
    <action>Run test command: {{run_tests_command}}</action>

    <!-- MEDIUM FIX: Full FIX subagent definition -->
    <check if="tests fail AND {{test_attempt}} < 3">
      <output>⚠️ Tests failed (attempt {{test_attempt}}/3) - spawning FIX subagent</output>

      <action>Use Task tool with subagent_type="general-purpose" and prompt:</action>

      <subagent-prompt id="fixer">
You are a TEST FIX SPECIALIST. Fix the failing tests by correcting the implementation.

## Test Output
```
{{test_failure_output}}
```

## Files That May Need Fixing
{{list_of_implementation_files_from_this_story}}

## Story Context
{{story_path}} - Read for acceptance criteria context

## Instructions
1. Analyze the test failure output carefully
2. Identify the root cause (likely in implementation, not tests)
3. Fix the implementation code to make tests pass
4. Apply minimal changes - don't refactor unrelated code
5. If tests themselves are wrong, explain why in diagnosis

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "diagnosis": "Brief explanation of what went wrong and how you fixed it",
  "files": [
    {
      "path": "relative/path/to/file.gd",
      "action": "modify",
      "content": "FULL file content with fix applied"
    }
  ],
  "tests_were_wrong": false,
  "notes": "Any additional context"
}
```
      </subagent-prompt>

      <action>Parse FIX subagent response</action>

      <check if="FIX success == true">
        <action>Apply file changes from FIX subagent</action>
        <action>git add . && git commit -m "{{current_story}}: fix test failures (attempt {{test_attempt}})"</action>
      </check>

      <action>Increment {{test_attempt}}</action>
      <action>Re-run tests: {{run_tests_command}}</action>

      <check if="tests still fail AND {{test_attempt}} < 3">
        <goto step="10.retry">Retry test fix loop</goto>
      </check>
    </check>

    <check if="tests fail AND {{test_attempt}} >= 3">
      <output>❌ Tests still failing after 3 fix attempts - proceeding to review with known issues</output>
      <action>Update story metrics: tests_passed = false, test_attempts = {{test_attempt}}</action>
    </check>

    <check if="tests pass">
      <output>✅ Tests passing</output>
      <action>Update story metrics: tests_passed = true, test_attempts = {{test_attempt}}</action>
    </check>

    <goto step="10.5">Visual integration test</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 5.5: VISUAL INTEGRATION TEST                                          -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="10.5" goal="Run visual integration tests to verify implementation" tag="integration-test">
    <critical>TESTER subagent launches game and verifies story changes work visually</critical>
    <critical>This step verifies what manual QA would check: can you see it? can you click it?</critical>

    <check if="story has no agent_tests section">
      <output>ℹ️ No agent_tests defined for this story - skipping visual verification</output>
      <goto step="11">Skip to review</goto>
    </check>

    <output>🎮 **Spawning TESTER Subagent for Visual Verification...**</output>

    <action>Use Task tool with subagent_type="general-purpose" and prompt:</action>

    <subagent-prompt id="tester">
You are a VISUAL INTEGRATION TESTER. Your job is to verify the story implementation works as expected by running the game.

## Story File
{{story_path}}

## Agent Tests Section
{{agent_tests_from_story}}

## Testing Framework Reference
Read: docs/workflows/agent-testing-workflow.md

## Your Task

1. Launch the game in agent mode:
   ```bash
   CMDFILE="$HOME/.local/share/godot/app_userdata/Critical Calculations/agent_commands.txt"
   rm -f "$CMDFILE"
   godot4 --path {{project_path}} -- --agent-mode 2>&1 &
   GAME_PID=$!
   sleep 4
   ```

2. Execute the test commands defined in agent_tests section:
   - Send each command to the command file: `echo "command" >> "$CMDFILE"`
   - Wait appropriate time between commands
   - Capture screenshots at verification points

3. Parse game output for:
   - AGENT_STATE_* blocks for state verification
   - SCRIPT ERROR for failures
   - Expected state values per the verify section

4. Cleanup:
   ```bash
   kill $GAME_PID 2>/dev/null || true
   ```

5. Read any captured screenshots to verify visual state

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "tests_run": 3,
  "tests_passed": 3,
  "tests_failed": 0,
  "results": [
    {
      "name": "test_name",
      "passed": true,
      "commands_executed": 5,
      "verifications": [
        {"check": "SCENE_TYPE: map", "found": true}
      ],
      "screenshots": ["screenshot_path"],
      "notes": "optional notes"
    }
  ],
  "errors": [],
  "summary": "All visual tests passed. Map displays correctly, nodes are visible."
}
```
    </subagent-prompt>

    <action>Parse TESTER subagent response</action>
    <action>Update story metrics: integration_tests = response</action>

    <check if="TESTER reports failures">
      <output>⚠️ Visual tests failed:
{{failure_details}}

Proceeding to review - reviewer will see integration test results.
      </output>
    </check>

    <check if="TESTER reports success">
      <output>✅ Visual integration tests passed: {{tests_passed}}/{{tests_run}}</output>
    </check>

    <goto step="11">Review</goto>
  </step>

  <step n="11" goal="Spawn REVIEWER subagent" tag="review">
    <critical>REVIEWER has FRESH CONTEXT - adversarial review</critical>
    <critical>Max 3 review iterations to prevent infinite loops</critical>

    <check if="{{review_iteration}} is NOT set">
      <action>Set {{review_iteration}} = 1</action>
    </check>

    <output>🔍 **Spawning REVIEWER (Iteration {{review_iteration}}/3)...**</output>

    <action>Use Task tool with subagent_type="general-purpose" and prompt:</action>

    <subagent-prompt id="reviewer">
You are an ADVERSARIAL Code Reviewer. You have NEVER seen this code. Find problems.

## Story File
{{story_path}}

## Files to Review
{{all_modified_files}}

## Review Checklist

**Integration:**
- Do scenes have functional scripts?
- Are @onready references valid?
- Are signals connected correctly?

**Scope:**
- Is there code for out-of-scope features?
- Are there signals/methods for future stories?

**Edge Cases:**
- Null handling?
- Scene freed mid-operation?
- Race conditions in async/await?
- _exit_tree() cleanup?
- Signal double-connection prevention?

**Defensive Programming:**
- Parameter validation?
- Return value null checks?
- Async guards after await?

**AC Verification:**
- Is each AC implemented?
- Point to specific code (file:line) for each

## Output Format

Return JSON ONLY:
```json
{
  "issues_found": true,
  "critical": [{"file": "path", "line": 10, "issue": "description", "fix": "suggested fix code or approach"}],
  "high": [],
  "medium": [],
  "low": [],
  "ac_verification": [
    {"ac": "AC1", "status": "pass|fail", "evidence": "file:line or description"}
  ]
}
```
    </subagent-prompt>

    <action>Parse REVIEWER response</action>
    <action>Update story metrics: issues_found = counts per severity</action>
    <action>Update story metrics: review_iterations = {{review_iteration}}</action>

    <check if="critical_count == 0 AND high_count == 0">
      <output>✅ Review passed - no critical/high issues</output>
      <goto step="12">Final commit</goto>
    </check>

    <check if="(critical_count > 0 OR high_count > 0) AND {{review_iteration}} < 3">
      <output>⚠️ Found: {{critical_count}} critical, {{high_count}} high issues

Applying fixes...
      </output>

      <!-- LOW FIX: Clarify who fixes - orchestrator applies fixes from reviewer suggestions -->
      <action>For EACH critical and high issue:
        - Read the file specified in issue
        - Apply the suggested fix from reviewer
        - If fix is unclear, make minimal change to address the issue description
      </action>
      <action>git add . && git commit -m "{{current_story}}: fix review issues (iteration {{review_iteration}})"</action>
      <action>Increment {{review_iteration}}</action>
      <goto step="11">Re-review</goto>
    </check>

    <check if="{{review_iteration}} >= 3">
      <output>⚠️ Max review iterations reached - proceeding with {{critical_count}} critical, {{high_count}} high issues remaining</output>
      <goto step="12">Final commit</goto>
    </check>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 6: STORY COMPLETION                                                   -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="12" goal="Final story commit and status update" tag="story-complete">
    <action>Update story file:
      - Status: "review"
      - Add Dev Agent Record section with:
        - Agent Model Used: {{model_info}}
        - Completion Notes: Summary of implementation
        - Chunks completed: {{chunks_completed}}/{{chunks_planned}}
        - Issues remaining: {{remaining_issues_summary}}
    </action>

    <action>Update sprint-status.yaml:
      - Set {{current_story}} status to "review"
    </action>

    <action>git add . && git commit -m "{{current_story}}: story complete, ready for review"</action>

    <!-- MERGE STORY BRANCH INTO EPIC BRANCH -->
    <action>git checkout {{epic_branch}}</action>
    <action>git merge {{branch_name}} --no-edit</action>

    <output>🔀 Merged {{branch_name}} → {{epic_branch}}</output>

    <action>Add {{current_story}} to {{completed_stories}}</action>
    <action>Update story metrics:
      - final_status = "completed"
      - total_implementation_duration_ms = sum of all chunk durations
    </action>
    <action>Reset {{review_iteration}}, {{current_chunk_index}}, {{completed_chunks}}, {{failed_chunks}}</action>
    <action>Increment {{current_story_index}}</action>

    <output>✅ **Story Complete: {{current_story}}**
Chunks: {{chunks_completed}}/{{chunks_planned}} ({{chunks_failed}} failed, {{chunks_skipped}} skipped)
Tests: {{tests_passed_status}}
Review iterations: {{review_iteration}}
Branch: {{branch_name}} → {{epic_branch}}

Moving to next story...
    </output>

    <goto step="1">Next story in queue</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 7: EPIC FINALIZATION                                                  -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <!-- NOTE: Full QA testing moved to separate workflow: full-qa                   -->
  <!-- Use the qa-tester agent with *full-qa command for comprehensive testing     -->

  <step n="20" goal="Epic completion, metrics report, and PR creation" tag="finalize">
    <critical>Generate metrics report for retrospective analysis</critical>
    <critical>Create PR from epic branch to dev</critical>

    <action>Record {{epic_end_time}} = current timestamp</action>
    <action>Update epic_metrics.end_time</action>

    <action>Calculate summary metrics:
      - epic_metrics.summary.completed_stories = length({{completed_stories}})
      - epic_metrics.summary.failed_stories = length({{failed_stories}})
      - epic_metrics.summary.total_chunks = sum of chunks_planned across all stories
      - epic_metrics.summary.avg_chunk_duration_ms = average of successful chunk durations
    </action>

    <action>Ensure on epic branch: git checkout {{epic_branch}}</action>

    <!-- SAVE METRICS TO FILE -->
    <action>Write metrics to: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json</action>
    <action>git add docs/sprint-artifacts/epic-{{epic_id}}-metrics.json</action>
    <action>git commit -m "epic-{{epic_id}}: workflow metrics for retrospective"</action>

    <!-- PUSH AND CREATE PR -->
    <action>git push -u origin {{epic_branch}}</action>
    <action>Create PR using gh CLI:
      gh pr create --base dev --head {{epic_branch}} \
        --title "Epic {{epic_id}}: {{epic_title}}" \
        --body "## Summary
Completed: {{completed_count}}/{{story_count}} stories
Skipped: {{skipped_count}} stories (not ready-for-dev)
Workflow: v2.1 Chunked Execution
Metrics: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json

## Stories
{{completed_stories_list}}

## Failed Stories (if any)
{{failed_stories_with_reasons}}

## Metrics Highlights
- Total chunks executed: {{total_chunks}}
- Average chunk duration: {{avg_chunk_duration}}ms
- Chunks failed: {{total_failed_chunks}}
- Chunks skipped (dependency): {{total_skipped_chunks}}
- Test fix attempts: {{total_test_attempts}}
- Review iterations: {{total_review_iterations}}

## Next Steps
1. Review PR
2. Run CI checks
3. Merge to dev when approved"
    </action>

    <output>🎉 **Epic Execution Complete (v2.1 Chunked)**

## Summary
- Epic: {{epic_id}} - {{epic_title}}
- Workflow: v2.1 Chunked Execution
- Stories: {{completed_count}}/{{story_count}} completed ({{skipped_count}} skipped)
- Duration: {{duration}}

## Metrics for Retrospective
Saved to: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json

| Metric | Value |
|--------|-------|
| Total Chunks | {{total_chunks}} |
| Chunks Completed | {{completed_chunks}} |
| Chunks Failed | {{failed_chunks}} |
| Chunks Skipped (deps) | {{skipped_chunks}} |
| Avg Chunk Duration | {{avg_chunk_duration}}ms |
| Planner Overhead | {{total_planner_time}}ms |
| Test Fix Attempts | {{total_test_attempts}} |
| Review Iterations | {{total_review_iterations}} |

## Pull Request
{{pr_url}}

## Retrospective Questions to Answer
1. Did chunked execution reduce context compaction events?
2. Was planner overhead worth the chunk coordination?
3. Did micro-commits improve task tracking accuracy?
4. What chunk size felt optimal?
5. How effective was the dependency skip logic?
6. Were the FIX subagent prompts effective for test failures?
    </output>
  </step>

</workflow>
```

## Branch Strategy (Unchanged)

```
dev (main development branch)
 │
 └── epic-{n} (created at workflow start)
      │
      ├── {story-1-id} (created from epic-{n})
      │   ├── start: "story-id: start implementation"
      │   ├── chunk-1: "story-id: chunk-name"
      │   ├── chunk-1 tasks: "story-id: mark chunk chunk-1 tasks complete"
      │   ├── chunk-2: ...
      │   ├── test fix (if needed): "story-id: fix test failures"
      │   ├── review fix (if needed): "story-id: fix review issues"
      │   └── complete: "story-id: story complete, ready for review"
      │   └── merged back to epic-{n} ✓
      │
      ├── {story-2-id} (has all story-1 changes)
      │   └── ...
      │
      └── PR: epic-{n} → dev
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.2 | 2025-12-15 | Per-story integration tests (step 10.5); FULL_QA extracted to separate full-qa workflow for qa-tester agent |
| 2.1 | 2025-12-15 | Applied all review fixes: dependency check, metrics on failure, FIX subagent, retry logic, sprint-status commit, empty chunks, skipped warnings |
| 2.0 | 2025-12-15 | Chunked execution with PLANNER subagent, micro-commits, metrics logging |
| 1.0 | 2025-12-13 | Original story-level subagent execution |

## Fixes Applied in v2.1

| Priority | Fix | Location |
|----------|-----|----------|
| CRITICAL | Failed chunks now update metrics before skipping | Step 5 |
| CRITICAL | Dependency check prevents running chunks with failed deps | Step 4 |
| MEDIUM | sprint-status.yaml committed after update | Step 2 |
| MEDIUM | retry_count initialized per chunk | Step 4 |
| MEDIUM | FIX subagent fully defined with prompt | Step 10 |
| MEDIUM | Retry logic clarified with context passing | Step 5 |
| LOW | Orchestrator applies review fixes (clarified) | Step 11 |
| LOW | Empty chunks validation added | Step 3 |
| LOW | Skipped stories warning at startup | Step 0 |

## Workflow Comparison

| Aspect | v1.0 (Story-level) | v2.0 (Chunked) | v2.1 (Fixed) |
|--------|-------------------|----------------|--------------|
| Subagent scope | Entire story | Single chunk | Single chunk |
| Context risk | High | Low | Low |
| Checkpoint granularity | Per story | Per chunk | Per chunk |
| Task tracking | Manual/missed | Automatic | Automatic |
| Dependency handling | None | None | Skip if dep failed |
| Failure metrics | None | Partial | Complete |
| Test fixing | Manual | Vague | Full FIX subagent |
| Retry logic | None | Vague | Clear with context |
