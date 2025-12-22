# Phase 06: Complete Story

```xml
<phase id="06-story-complete" name="Complete Story">

  <purpose>
    Finalize story: update status, merge to epic branch, record metrics.
    Prepare for next story or epic QA.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - story_branch: current git branch
    - epic_branch: parent branch
    - completed_chunks: list of completed chunk IDs
    - chunk_plan: for summary
  </input>

  <preconditions>
    - Tests passing
    - Code review approved (or force approved)
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="update-story-status">
      <action>Read story file at {{story_path}}</action>
      <action>Update:
        - status: "done"
        - completed_at: {{current_iso_timestamp}}
      </action>
      <action>Write story file</action>

      <action>git add {{story_path}}</action>
      <action>git commit -m "{{current_story}}: mark complete"</action>
    </step>

    <step n="2" name="finalize-story-metrics">
      <action>Calculate story metrics:
        - ended_at: {{current_iso_timestamp}}
        - total_duration_ms: ended_at - started_at
        - chunks_planned: {{chunk_plan.chunks.length}}
        - chunks_completed: {{completed_chunks.length}}
        - chunks_failed: {{failed_chunks.length}}
        - test_attempts: {{test_attempt}}
        - review_iterations: {{review_iteration}}
        - tests_passed: true
        - tdd_compliant: (tdd_metrics.tests_written_first > tdd_metrics.tests_written_after)
        - final_status: "completed"
      </action>

      <action>
        metrics_collector:
          action: record_completion
          story_id: {{current_story}}
          metrics: {{story_metrics}}
      </action>
    </step>

    <step n="3" name="merge-to-epic">
      <output>🔀 **Merging to epic branch...**</output>

      <action>git checkout {{epic_branch}}</action>
      <action>git merge {{story_branch}} --no-ff -m "Merge {{current_story}}: {{story_title}}"</action>

      <check if="merge conflict">
        <error>Merge conflict detected!</error>
        <action>Output conflicting files</action>
        <action>Ask user to resolve manually or skip</action>
      </check>

      <output>✅ Merged {{story_branch}} → {{epic_branch}}</output>
    </step>

    <step n="4" name="cleanup-branch">
      <action>Optionally delete story branch:
        git branch -d {{story_branch}}
      </action>

      <output>🧹 Cleaned up branch {{story_branch}}</output>
    </step>

    <step n="5" name="add-to-completed">
      <action>Add current_story to completed_stories</action>
      <action>Update metrics.summary.completed_stories++</action>
    </step>

    <step n="6" name="github-issue-complete">
      <check if="state.issue_number exists">
        <action>Run: gh-issue-complete {{state.issue_number}} --tasks-completed {{completed_chunks.length}} --tests-passed {{story_metrics.tests_passed}} --tests-failed 0 --coverage {{story_metrics.coverage}} --commit {{current_commit_sha}} --message "Story {{current_story}} completed successfully"</action>
        <output>📢 GitHub issue closed with completion summary</output>
      </check>
    </step>

    <step n="7" name="check-more-stories">
      <check if="current_story_index + 1 >= length(story_queue)">
        <output>📊 All stories complete! Moving to epic QA...</output>
        <return>
          {
            "next_phase": "07-epic-qa",
            "state_updates": {
              "current_story": null,
              "story_branch": null,
              "chunk_plan": null,
              "completed_stories": {{updated_completed_stories}},
              "metrics": {{updated_metrics}}
            },
            "output": "All stories complete. Running epic QA..."
          }
        </return>
      </check>
    </step>

  </execution>

  <output>
✅ **Story Complete: {{current_story}}**

Summary: {{chunk_plan.story_summary}}
Chunks: {{completed_chunks.length}}/{{chunk_plan.chunks.length}} completed
TDD Compliant: {{story_metrics.tdd_compliant ? "Yes ✓" : "No ⚠️"}}

Progress: {{completed_stories.length + 1}}/{{story_queue.length}} stories

Starting next story...
  </output>

  <return>
    {
      "next_phase": "01-story-start",
      "state_updates": {
        "current_story_index": {{current_story_index + 1}},
        "current_story": null,
        "story_branch": null,
        "chunk_plan": null,
        "completed_stories": {{updated_completed_stories}},
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
