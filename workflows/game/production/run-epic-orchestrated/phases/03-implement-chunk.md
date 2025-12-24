# Phase 03: Implement Chunk (IMPLEMENTER Subagent)

```xml
<phase id="03-implement-chunk" name="Implement Current Chunk">

  <purpose>
    Spawn IMPLEMENTER subagent with minimal context to implement ONE chunk.
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
              "next_phase": "03-implement-chunk",
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
      <action>Record chunk_start_time = current timestamp (ms)</action>

      <output>🔨 **Implementing chunk {{current_chunk_index + 1}}/{{chunk_queue.length}}: {{current_chunk.name}}**
Tasks: {{current_chunk.tasks | join(", ")}}
Files: {{current_chunk.files_to_create | join(", ")}} {{current_chunk.files_to_modify | join(", ")}}
Attempt: {{chunk_retry_count + 1}}/3
      </output>

      <action>Use Task tool with subagent_type="general-purpose"</action>

      <subagent-prompt>
You are an IMPLEMENTATION SPECIALIST. Implement ONLY this specific chunk.

## Chunk Definition
Name: {{current_chunk.name}}
Description: {{current_chunk.description}}

## Tasks to Complete
{{for i, task in current_chunk.task_descriptions}}
{{i + 1}}. {{task}}
{{endfor}}

## Files to Create
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
2. Implement ONLY the tasks listed for THIS chunk
3. Apply ALL shared patterns consistently
4. Apply defensive programming:
   - Validate parameters where appropriate
   - Check null returns from methods that can fail
   - Guard async operations after await (check node still exists)
   - Add _exit_tree() cleanup if connecting signals
   - Prevent signal double-connection with is_connected() checks

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "files": [
    {
      "path": "relative/path/to/file.gd",
      "action": "create",
      "content": "FULL file content here - not a snippet"
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
      <action>Record chunk_end_time = current timestamp (ms)</action>
      <action>Parse IMPLEMENTER response</action>

      <check if="success == false">
        <output>❌ Chunk blocked: {{response.blockers | join(", ")}}</output>

        <check if="chunk_retry_count < 2">
          <output>⚠️ Retrying chunk (attempt {{chunk_retry_count + 2}}/3)...</output>
          <return>
            {
              "next_phase": "03-implement-chunk",
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
        <return>
          {
            "next_phase": "03-implement-chunk",
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

    <step n="6" name="write-files">
      <action>For EACH file in response.files:
        - If action == "create": Write new file
        - If action == "modify": Read existing file, apply changes
      </action>

      <check if="any file write fails">
        <error>Failed to write file: {{file_path}}</error>
        <action>Set state.error = "file_write_failed"</action>
      </check>
    </step>

    <step n="7" name="micro-commit">
      <action>git add .</action>
      <action>Commit message: "{{current_story}}: {{current_chunk.name}}"</action>
      <action>git commit -m "{{commit_message}}"</action>

      <check if="commit fails (pre-commit hook)">
        <action>Attempt to fix (run formatter, etc.)</action>
        <action>git add . && git commit -m "{{commit_message}}"</action>
      </check>

      <output>📝 Committed: {{current_chunk.name}}</output>
    </step>

    <step n="8" name="update-story-tasks">
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

    <step n="9" name="update-state">
      <action>Add chunk_id to completed_chunks</action>
      <action>Update story metrics:
        - chunks_completed++
        - Add chunk duration to total_implementation_duration_ms
      </action>
    </step>

  </execution>

  <output>
✅ **Chunk Complete: {{current_chunk.name}}**

Files: {{response.files.length}} written
Tasks: {{response.tasks_completed | join(", ")}}
Duration: {{chunk_duration_ms}}ms

Progress: {{completed_chunks.length + 1}}/{{chunk_queue.length}} chunks
  </output>

  <return>
    {
      "next_phase": "03-implement-chunk",
      "state_updates": {
        "current_chunk_index": {{current_chunk_index + 1}},
        "completed_chunks": {{updated_completed_chunks}},
        "chunk_retry_count": 0,
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
