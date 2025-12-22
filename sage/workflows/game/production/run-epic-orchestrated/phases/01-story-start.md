# Phase 01: Story Start

```xml
<phase id="01-story-start" name="Start Next Story">

  <purpose>
    Load next story from queue, create feature branch from epic branch,
    update sprint status to in-progress.
  </purpose>

  <input>
    {{state}} with:
    - story_queue: ordered list of story IDs
    - current_story_index: which story we're on
    - epic_branch: parent branch for story branches
  </input>

  <preconditions>
    - On epic branch
    - story_queue has items
  </preconditions>

  <execution>

    <step n="1" name="check-queue">
      <check if="current_story_index >= length(story_queue)">
        <output>All stories processed. Moving to finalization.</output>
        <return>
          {
            "next_phase": "08-finalize",
            "state_updates": {},
            "output": "All stories complete. Finalizing epic..."
          }
        </return>
      </check>
    </step>

    <step n="2" name="load-story">
      <action>Get current_story = story_queue[current_story_index]</action>
      <action>Construct story_path = {{story_dir}}/{{current_story}}.md</action>
      <action>Read story file</action>

      <action>Parse story:
        - Title
        - Status (should be ready-for-dev or in-progress)
        - Acceptance Criteria
        - Tasks list
        - Constraints
        - Dev Notes (if any)
      </action>

      <check if="story file not found">
        <error>Story file not found: {{story_path}}</error>
        <action>Add to failed_stories with reason "file_not_found"</action>
        <action>Increment current_story_index</action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}},
              "failed_stories": {{updated_failed_stories}}
            },
            "output": "Story file not found: {{current_story}}. Skipping to next."
          }
        </return>
      </check>
    </step>

    <step n="3" name="check-status">
      <check if="status != 'ready-for-dev' AND status != 'in-progress'">
        <output>⏭️ Skipping {{current_story}} - status is "{{status}}"</output>
        <action>Increment current_story_index</action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}}
            },
            "output": "Skipped {{current_story}} (status: {{status}})"
          }
        </return>
      </check>
    </step>

    <step n="4" name="create-branch">
      <action>Set story_branch = {{current_story}}</action>

      <action>Ensure on epic branch:
        git checkout {{epic_branch}}
      </action>

      <action>Check if story branch exists:
        git branch --list {{story_branch}}
      </action>

      <check if="branch exists">
        <action>git checkout {{story_branch}}</action>
        <action>git merge {{epic_branch}} --no-edit</action>
        <output>Checked out existing branch {{story_branch}}, merged {{epic_branch}}</output>
      </check>

      <check if="branch does NOT exist">
        <action>git checkout -b {{story_branch}}</action>
        <output>Created branch {{story_branch}} from {{epic_branch}}</output>
      </check>
    </step>

    <step n="5" name="update-sprint-status">
      <action>Read docs/sprint-artifacts/sprint-status.yaml</action>
      <action>Update story status to "in-progress"</action>
      <action>Write sprint-status.yaml</action>

      <action>Git commit:
        git add docs/sprint-artifacts/sprint-status.yaml
        git commit -m "{{current_story}}: start implementation"
      </action>
    </step>

    <step n="6" name="init-story-metrics">
      <action>Add new story entry to metrics.stories:
        {
          "story_id": "{{current_story}}",
          "chunks_planned": 0,
          "chunks_completed": 0,
          "chunks_failed": 0,
          "chunks_skipped_dependency": 0,
          "planner_duration_ms": 0,
          "total_implementation_duration_ms": 0,
          "test_attempts": 0,
          "review_iterations": 0,
          "tests_passed": null,
          "integration_tests_passed": null,
          "final_status": "in_progress"
        }
      </action>
    </step>

  </execution>

  <output>
📖 **Story {{current_story_index + 1}}/{{story_queue.length}}: {{current_story}}**

Branch: {{story_branch}} (from {{epic_branch}})
Status: in-progress

Proceeding to planning phase...
  </output>

  <return>
    {
      "next_phase": "02-plan",
      "state_updates": {
        "current_story": "{{current_story}}",
        "story_branch": "{{story_branch}}",
        "story_path": "{{story_path}}",
        "chunk_plan": null,
        "chunk_queue": [],
        "current_chunk_index": 0,
        "completed_chunks": [],
        "failed_chunks": [],
        "chunk_retry_count": 0,
        "test_attempt": 0,
        "review_iteration": 0,
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
