# Phase 03: Implement Chunk (IMPLEMENTER Subagent)

```xml
<phase id="03-implement" name="Implement Current Chunk">

  <purpose>
    Spawn IMPLEMENTER subagent with minimal context to implement ONE chunk.
    TDD Enforcement: Tests must be written BEFORE implementation code.
    After success: micro-commit and mark tasks complete.
    After all chunks: transition to testing.
  </purpose>

  <input>
    {{state}} with:
    - chunk_plan: full plan from PLANNER
    - chunk_queue: ordered chunk IDs
    - current_chunk_index: which chunk we're on
    - completed_chunks: successfully done
    - failed_chunks: chunks that failed
    - chunk_retry_count: retries for current chunk
  </input>

  <preconditions>
    - chunk_plan exists
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="check-queue">
      <check if="current_chunk_index >= length(chunk_queue)">
        <output>All chunks complete. Moving to testing.</output>
        <return>
          {
            "next_phase": "04-test",
            "state_updates": {},
            "output": "All {{completed_chunks.length}} chunks implemented. Running tests..."
          }
        </return>
      </check>
    </step>

    <step n="2" name="get-chunk">
      <action>Get chunk_id = chunk_queue[current_chunk_index]</action>
      <action>Get current_chunk = chunk_plan.chunks.find(c => c.id == chunk_id)</action>
    </step>

    <step n="3" name="check-dependencies">
      <check if="current_chunk.depends_on is not empty">
        <action>For each dep_id in current_chunk.depends_on:
          - If dep_id in failed_chunks → dependency failed
        </action>

        <check if="any dependency in failed_chunks">
          <output>⏭️ Skipping chunk {{chunk_id}} - dependency failed: {{failed_dep}}</output>
          <action>Add chunk_id to failed_chunks</action>
          <action>Update story metrics: chunks_skipped_dependency++</action>
          <return>
            {
              "next_phase": "03-implement",
              "state_updates": {
                "current_chunk_index": {{current_chunk_index + 1}},
                "failed_chunks": {{updated_failed_chunks}},
                "metrics": {{updated_metrics}}
              },
              "output": "Skipped {{chunk_id}} (dependency failed)"
            }
          </return>
        </check>
      </check>
    </step>

    <step n="4" name="spawn-implementer">
      <action>
        metrics_collector:
          action: record_start
          operation: "implementer"
          chunk_id: {{chunk_id}}
      </action>

      <output>🔨 **Implementing chunk {{current_chunk_index + 1}}/{{chunk_queue.length}}: {{current_chunk.name}}**
Tasks: {{current_chunk.tasks | join(", ")}}
Files: {{current_chunk.files_to_create | join(", ")}} {{current_chunk.files_to_modify | join(", ")}}
Tests: {{current_chunk.tests_to_create | join(", ")}}
Attempt: {{chunk_retry_count + 1}}/3
      </output>

      <action>
        subagent_spawner:
          action: spawn
          subagent_type: "IMPLEMENTER"
          context:
            chunk: {{current_chunk}}
            shared_patterns: {{chunk_plan.shared_patterns}}
          output_schema:
            type: "implementation_result"
      </action>

      <subagent-prompt>
You are an IMPLEMENTATION SPECIALIST using TDD (Test-Driven Development). Implement ONLY this specific chunk.

## CRITICAL: TDD Process
You MUST follow this order:
1. Write tests FIRST (files in tests_to_create)
2. Run tests - they should FAIL (no implementation yet)
3. Write implementation code (files in files_to_create/files_to_modify)
4. Run tests - they should PASS

## Chunk Definition
Name: {{current_chunk.name}}
Description: {{current_chunk.description}}

## Tasks to Complete
{{for i, task in current_chunk.task_descriptions}}
{{i + 1}}. {{task}}
{{endfor}}

## Tests to Create FIRST
{{current_chunk.tests_to_create | join("\n") or "None specified - create appropriate tests"}}

## Files to Create (after tests)
{{current_chunk.files_to_create | join("\n") or "None"}}

## Files to Modify
{{current_chunk.files_to_modify | join("\n") or "None"}}

## Files to Read First (dependencies from prior chunks)
{{current_chunk.files_to_read | join("\n") or "None"}}

## Shared Patterns (apply to ALL code)
{{for pattern in chunk_plan.shared_patterns}}
- {{pattern}}
{{endfor}}

## Instructions

1. Read any dependency files listed above (they exist on disk from prior chunks)
2. Write TEST files FIRST - they define expected behavior
3. Implement source files to make tests pass
4. Apply ALL shared patterns consistently
5. Apply defensive programming:
   - Validate parameters where appropriate
   - Handle edge cases and errors
   - Use appropriate type safety

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "tdd_compliant": true,
  "files": [
    {
      "path": "relative/path/to/file.test.ts",
      "action": "create",
      "content": "FULL file content here - not a snippet",
      "is_test": true
    },
    {
      "path": "relative/path/to/file.ts",
      "action": "create",
      "content": "FULL file content here - not a snippet",
      "is_test": false
    }
  ],
  "tasks_completed": ["1.1", "1.2"],
  "summary": "Brief description of what was implemented",
  "blockers": []
}
```

If you encounter blockers that prevent implementation, set success=false and describe in blockers array.
      </subagent-prompt>
    </step>

    <step n="5" name="process-response">
      <action>
        metrics_collector:
          action: record_end
          operation: "implementer"
          chunk_id: {{chunk_id}}
      </action>

      <action>Parse IMPLEMENTER response</action>

      <check if="success == false">
        <output>❌ Chunk blocked: {{response.blockers | join(", ")}}</output>

        <check if="chunk_retry_count < 2">
          <output>⚠️ Retrying chunk (attempt {{chunk_retry_count + 2}}/3)...</output>
          <return>
            {
              "next_phase": "03-implement",
              "state_updates": {
                "chunk_retry_count": {{chunk_retry_count + 1}}
              },
              "output": "Retry {{chunk_id}}: {{response.blockers}}"
            }
          </return>
        </check>

        <output>❌ Chunk {{chunk_id}} failed after 3 attempts</output>
        <action>Add chunk_id to failed_chunks</action>
        <action>Update story metrics: chunks_failed++</action>
        <action>
          learning_recorder:
            action: record_failure
            failure:
              type: "implementation"
              context:
                phase: "03-implement"
                chunk_id: {{chunk_id}}
                error: {{response.blockers | join(", ")}}
              retry_count: 3
        </action>
        <return>
          {
            "next_phase": "03-implement",
            "state_updates": {
              "current_chunk_index": {{current_chunk_index + 1}},
              "failed_chunks": {{updated_failed_chunks}},
              "chunk_retry_count": 0,
              "metrics": {{updated_metrics}}
            },
            "output": "Chunk {{chunk_id}} failed: {{response.blockers}}"
          }
        </return>
      </check>
    </step>

    <step n="6" name="track-tdd">
      <check if="response.tdd_compliant == true">
        <action>tdd_metrics.tests_written_first++</action>
      </check>
      <check if="response.tdd_compliant == false">
        <action>tdd_metrics.tests_written_after++</action>
        <output>⚠️ TDD violation: tests were not written first</output>
      </check>
    </step>

    <step n="7" name="write-files">
      <action>For EACH file in response.files:
        - If action == "create": Write new file
        - If action == "modify": Read existing file, apply changes
      </action>

      <check if="any file write fails">
        <error>Failed to write file: {{file_path}}</error>
        <action>Set state.error = "file_write_failed"</action>
      </check>
    </step>

    <step n="8" name="micro-commit">
      <action>git add .</action>
      <action>Commit message: "{{current_story}}: {{current_chunk.name}}"</action>
      <action>git commit -m "{{commit_message}}"</action>

      <check if="commit fails (pre-commit hook)">
        <action>Attempt to fix (run formatter, linter, etc.)</action>
        <action>git add . && git commit -m "{{commit_message}}"</action>
      </check>

      <output>📝 Committed: {{current_chunk.name}}</output>
    </step>

    <step n="9" name="update-story-tasks">
      <action>Read story file</action>
      <action>For each task in response.tasks_completed:
        - Find line: "- [ ] **Task {{task}}:" or "- [ ] {{task}}:"
        - Replace "- [ ]" with "- [x]"
      </action>
      <action>Write story file</action>

      <action>git add {{story_path}}</action>
      <action>git commit -m "{{current_story}}: mark {{current_chunk.id}} tasks complete"</action>

      <output>☑️ Tasks marked complete: {{response.tasks_completed | join(", ")}}</output>
    </step>

    <step n="10" name="update-state">
      <action>Add chunk_id to completed_chunks</action>
      <action>Update story metrics:
        - chunks_completed++
      </action>
    </step>

    <step n="11" name="github-progress-update">
      <check if="state.issue_number exists">
        <action>Run: gh-issue-progress {{state.issue_number}} task_complete --task "{{current_chunk.name}}" --message "Completed chunk {{completed_chunks.length}}/{{chunk_queue.length}}"</action>
        <output>📢 GitHub issue updated: task complete</output>
      </check>
    </step>

  </execution>

  <output>
✅ **Chunk Complete: {{current_chunk.name}}**

Files: {{response.files.length}} written
Tasks: {{response.tasks_completed | join(", ")}}
TDD Compliant: {{response.tdd_compliant ? "Yes ✓" : "No ⚠️"}}

Progress: {{completed_chunks.length + 1}}/{{chunk_queue.length}} chunks
  </output>

  <return>
    {
      "next_phase": "03-implement",
      "state_updates": {
        "current_chunk_index": {{current_chunk_index + 1}},
        "completed_chunks": {{updated_completed_chunks}},
        "chunk_retry_count": 0,
        "tdd_metrics": {{updated_tdd_metrics}},
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
