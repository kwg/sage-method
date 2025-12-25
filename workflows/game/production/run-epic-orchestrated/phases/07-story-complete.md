# Phase 07: Story Complete

```xml
<phase id="07-story-complete" name="Complete Story">

  <purpose>
    Finalize story: update status, add dev record, merge to epic branch.
    Then advance to next story or finalization.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - story_branch: current branch
    - epic_branch: parent branch
    - completed_chunks, failed_chunks: chunk results
    - test_attempt, review_iteration: attempt counts
    - metrics: current metrics
  </input>

  <preconditions>
    - Review phase complete (passed or max iterations)
    - On story branch
  </preconditions>

  <execution>

    <step n="1a" name="prepare-dev-record">
      <action>Get agent model from state or environment:
        agent_model = state.agent_model || ENV["CLAUDE_MODEL"] || "claude-sonnet-4-5-20250929"
        <!-- Note: CLAUDE_MODEL is set by Claude Code CLI -->
      </action>

      <action>Get current date:
        current_date = Time.now.strftime("%Y-%m-%d")
      </action>

      <action>Get workflow version from state:
        workflow_version = state.metrics.workflow_version || "3.1-phased"
      </action>

      <action>Calculate chunk statistics:
        completed_count = completed_chunks.length
        total_count = chunk_queue.length
        failed_count = failed_chunks.length
        skipped_count = total_count - completed_count - failed_count
      </action>

      <action>Format test results:
        tests_passed_display = tests_passed ? "yes" : (tests_passed == false ? "no" : "skipped")
        integration_display = integration_tests_passed ? "yes" : (integration_tests_passed == false ? "no" : "skipped")
      </action>
    </step>

    <step n="1b" name="update-story-file">
      <action>Read story file</action>

      <action>Update frontmatter Status field to "done":
        Replace "Status: ready-for-dev" with "Status: done"
        OR Replace "Status: in-progress" with "Status: done"
      </action>

      <action>Add or update Dev Agent Record section with actual values (not placeholders):
```markdown
## Dev Agent Record

- **Agent Model**: {{agent_model}}
- **Workflow Version**: {{workflow_version}}
- **Completion Date**: {{current_date}}
- **Chunks**: {{completed_count}}/{{total_count}} completed
  - Failed: {{failed_count}}
  - Skipped (deps): {{skipped_count}}
- **Test Attempts**: {{test_attempt}}
- **Tests Passed**: {{tests_passed_display}}
- **Integration Tests**: {{integration_display}}
- **Review Iterations**: {{review_iteration}}
- **Issues Remaining**: {{remaining_issues_summary}}
- **Notes**: {{implementation_notes}}
```
      </action>

      <action>Write story file</action>
    </step>

    <step n="1c" name="verify-dev-record">
      <action>Read story file after write to verify changes</action>

      <check if="story file contains 'Not yet implemented' OR 'unknown' OR '{{model_info}}' in Dev Agent Record">
        <warning>Dev Agent Record not properly written - contains placeholder values</warning>
        <action>Log failed values for debugging</action>
        <action>Retry write with explicit hardcoded fallbacks:
          - agent_model = "claude-sonnet-4-5-20250929"
          - current_date = system date
          - workflow_version = "3.1-phased"
        </action>
      </check>

      <check if="story file frontmatter Status field != 'done' AND != 'review'">
        <warning>Story status not updated to done/review</warning>
        <action>Retry frontmatter update:
          Find first line matching "Status:" and replace with "Status: done"
        </action>
      </check>

      <output>✅ Dev Agent Record verified:
        - Agent Model: {{agent_model}}
        - Status: {{status_field_value}}
      </output>
    </step>

    <step n="2" name="update-sprint-status">
      <action>Read docs/sprint-artifacts/sprint-status.yaml</action>
      <action>Update story status to "review"</action>
      <action>Write sprint-status.yaml</action>
    </step>

    <step n="3" name="final-commit">
      <action>git add .</action>
      <action>git commit -m "{{current_story}}: story complete, ready for review"</action>
    </step>

    <step n="4" name="merge-to-epic">
      <action>git checkout {{epic_branch}}</action>
      <action>git merge {{story_branch}} --no-edit</action>

      <check if="merge conflict">
        <error>Merge conflict merging {{story_branch}} to {{epic_branch}}</error>
        <action>Output conflict details</action>
        <action>Ask user to resolve manually or skip</action>
      </check>

      <output>🔀 Merged {{story_branch}} → {{epic_branch}}</output>
    </step>

    <step n="5" name="update-metrics">
      <action>Update story metrics:
        - final_status = "completed"
        - total_implementation_duration_ms = sum of chunk durations
      </action>

      <action>Update summary metrics:
        - completed_stories++
      </action>

      <action>Add {{current_story}} to completed_stories list</action>
    </step>

    <step n="6" name="prepare-next">
      <action>Increment current_story_index</action>
      <action>Reset per-story state:
        - current_story = null
        - story_branch = null
        - story_path = null
        - chunk_plan = null
        - chunk_queue = []
        - current_chunk_index = 0
        - completed_chunks = []
        - failed_chunks = []
        - chunk_retry_count = 0
        - test_attempt = 0
        - review_iteration = 0
      </action>
    </step>

  </execution>

  <output>
✅ **Story Complete: {{current_story}}**

| Metric | Value |
|--------|-------|
| Chunks | {{completed_chunks.length}}/{{chunk_queue.length}} |
| Failed Chunks | {{failed_chunks.length}} |
| Tests | {{tests_passed_display}} |
| Integration | {{integration_display}} |
| Review Iterations | {{review_iteration}} |

Branch: {{story_branch}} → {{epic_branch}} ✓

Progress: {{completed_stories.length}}/{{story_queue.length}} stories complete
  </output>

  <return>
    {
      "next_phase": "01-story-start",
      "state_updates": {
        "current_story_index": {{current_story_index + 1}},
        "current_story": null,
        "story_branch": null,
        "story_path": null,
        "chunk_plan": null,
        "chunk_queue": [],
        "current_chunk_index": 0,
        "completed_chunks": [],
        "failed_chunks": [],
        "chunk_retry_count": 0,
        "test_attempt": 0,
        "review_iteration": 0,
        "completed_stories": {{updated_completed_stories}},
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
