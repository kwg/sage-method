# Phase 01: Start Story

```xml
<phase id="01-story-start" name="Start Story">

  <purpose>
    Load next story from queue, create feature branch, update story status.
    Validates branch naming convention: feature/{story_id}
  </purpose>

  <input>
    {{state}} with:
    - story_queue: ordered list of story IDs
    - current_story_index: which story we're on
    - epic_branch: parent branch
    - story_dir: where story files live
  </input>

  <preconditions>
    - On epic branch
    - story_queue is not empty (or we go to epic-qa)
  </preconditions>

  <execution>

    <step n="1" name="check-queue">
      <check if="current_story_index >= length(story_queue)">
        <output>All stories complete. Moving to epic QA.</output>
        <return>
          {
            "next_phase": "07-epic-qa",
            "state_updates": {},
            "output": "All {{completed_stories.length}} stories implemented. Running epic QA..."
          }
        </return>
      </check>
    </step>

    <step n="2" name="get-story">
      <action>Get current_story = story_queue[current_story_index]</action>
      <action>Construct story_path = {{story_dir}}/{{current_story}}.md</action>

      <check if="story file not found">
        <error>Story file not found: {{story_path}}</error>
        <action>Add to failed_stories: { story_id: {{current_story}}, reason: "file_not_found" }</action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}},
              "failed_stories": {{updated_failed_stories}}
            },
            "output": "Story file not found: {{current_story}}. Skipping."
          }
        </return>
      </check>
    </step>

    <step n="3" name="validate-story">
      <action>Read story file at {{story_path}}</action>
      <action>Extract:
        - story_title (from # heading)
        - status (from frontmatter or status line)
        - tasks list
        - acceptance criteria
      </action>

      <check if="status not in ['ready-for-dev', 'in-progress']">
        <output>⚠️ Story {{current_story}} status is "{{status}}" - skipping</output>
        <action>Add to skipped_stories</action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}},
              "skipped_stories": {{updated_skipped}}
            },
            "output": "Story {{current_story}} not ready ({{status}}). Skipping."
          }
        </return>
      </check>
    </step>

    <step n="4" name="create-feature-branch">
      <action>Set story_branch = "feature/{{current_story}}"</action>

      <action>Validate branch name:
        - Must match pattern: feature/{story_id}
        - No spaces, special characters
      </action>

      <action>Git operations:
        git checkout {{epic_branch}}
        git pull origin {{epic_branch}} (if remote exists)
      </action>

      <action>Check if story branch exists:
        git branch --list {{story_branch}}
      </action>

      <check if="branch exists">
        <action>git checkout {{story_branch}}</action>
        <action>git merge {{epic_branch}} --no-edit</action>
        <output>Resumed existing branch {{story_branch}}, merged latest epic</output>
      </check>

      <check if="branch does NOT exist">
        <action>git checkout -b {{story_branch}}</action>
        <output>Created new branch {{story_branch}} from {{epic_branch}}</output>
      </check>
    </step>

    <step n="5" name="update-story-status">
      <action>Update story file:
        - Set status: "in-progress"
        - Add started_at timestamp if not present
      </action>

      <action>git add {{story_path}}</action>
      <action>git commit -m "{{current_story}}: start implementation"</action>
    </step>

    <step n="6" name="initialize-story-metrics">
      <action>Create story metrics entry:
        {
          "story_id": "{{current_story}}",
          "story_title": "{{story_title}}",
          "started_at": "{{current_iso_timestamp}}",
          "chunks_planned": 0,
          "chunks_completed": 0,
          "chunks_failed": 0,
          "test_attempts": 0,
          "review_iterations": 0,
          "tdd_compliant": null,
          "final_status": "in_progress"
        }
      </action>
    </step>

    <step n="7" name="github-progress-update">
      <check if="state.issue_number exists">
        <action>Run: gh-issue-progress {{state.issue_number}} started --message "Beginning implementation of {{current_story}}: {{story_title}}"</action>
        <output>📢 GitHub issue updated: started</output>
      </check>
    </step>

  </execution>

  <output>
📖 **Starting Story {{current_story_index + 1}}/{{story_queue.length}}**

Story: {{current_story}} - {{story_title}}
Branch: {{story_branch}}
Tasks: {{task_count}}

Beginning planning phase...
  </output>

  <return>
    {
      "next_phase": "02-plan",
      "state_updates": {
        "current_story": "{{current_story}}",
        "story_path": "{{story_path}}",
        "story_branch": "{{story_branch}}",
        "story_title": "{{story_title}}",
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
