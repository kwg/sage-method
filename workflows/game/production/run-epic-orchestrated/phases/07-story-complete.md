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

    <step n="1" name="update-story-file">
      <action>Read story file</action>

      <action>Update frontmatter:
        - status: "review" (ready for human review)
      </action>

      <action>Add or update Dev Agent Record section:
```markdown
## Dev Agent Record

- **Agent Model**: {{model_info}}
- **Workflow Version**: 3.0-phased
- **Completion Date**: {{current_date}}
- **Chunks**: {{completed_chunks.length}}/{{chunk_queue.length}} completed
  - Failed: {{failed_chunks.length}}
  - Skipped (deps): {{chunks_skipped_dependency}}
- **Test Attempts**: {{test_attempt}}
- **Tests Passed**: {{tests_passed | "yes" or "no" or "skipped"}}
- **Integration Tests**: {{integration_tests_passed | "yes" or "no" or "skipped"}}
- **Review Iterations**: {{review_iteration}}
- **Issues Remaining**: {{remaining_issues_summary}}
- **Notes**: {{implementation_notes}}
```
      </action>

      <action>Write story file</action>
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
