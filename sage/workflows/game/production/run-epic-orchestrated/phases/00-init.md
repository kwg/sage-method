# Phase 00: Initialize Epic

```xml
<phase id="00-init" name="Initialize Epic">

  <purpose>
    Parse epic file, build story queue, create epic branch, initialize metrics.
    This phase runs ONCE at the start of an epic run.
  </purpose>

  <input>
    {{state}} with:
    - phase: "00-init"
    - epic_path: path to epic file (or null to find from sprint-status)
    - metrics.start_time: already set by orchestrator
  </input>

  <preconditions>
    - Git working directory is clean (or user has confirmed to proceed)
    - Currently on dev branch (or will checkout)
  </preconditions>

  <execution>

    <step n="1" name="find-epic">
      <check if="epic_path is provided">
        <action>Use provided epic_path</action>
      </check>
      <check if="epic_path is null">
        <action>Read docs/sprint-artifacts/sprint-status.yaml</action>
        <action>Find current epic from sprint status</action>
        <action>Construct epic_path: docs/sprint-artifacts/epics/{{epic_id}}/epic.md</action>
      </check>
    </step>

    <step n="2" name="parse-epic">
      <action>Read epic file at {{epic_path}}</action>
      <action>Extract:
        - epic_id (from filename or frontmatter)
        - epic_title (from # heading or frontmatter)
        - story_dir (directory containing story files)
        - stories list (from ## Stories section)
      </action>

      <check if="epic file not found or unparseable">
        <error>Cannot parse epic file: {{epic_path}}</error>
        <action>Return with error, stay on phase 00-init</action>
      </check>
    </step>

    <step n="3" name="build-story-queue">
      <action>For each story in epic:
        - Read story file to check status
        - If status == "ready-for-dev" OR status == "in-progress": add to story_queue
        - Else: add to skipped_stories
      </action>

      <action>Order story_queue by:
        - Explicit dependencies (story X depends on Y → Y first)
        - Numeric order as fallback
      </action>

      <check if="story_queue is empty">
        <warning>No stories ready for development!</warning>
        <action>List skipped stories with their statuses</action>
        <action>Ask user: proceed anyway or abort?</action>
      </check>
    </step>

    <step n="4" name="warn-skipped">
      <check if="skipped_stories is not empty">
        <output>
⚠️ **WARNING: The following stories will be SKIPPED** (not ready-for-dev):
{{for story in skipped_stories}}
- {{story.id}}: {{story.status}}
{{endfor}}

These stories will NOT be implemented during this run.
        </output>
      </check>
    </step>

    <step n="5" name="create-epic-branch">
      <action>Set epic_branch = "epic-{{epic_id}}"</action>

      <action>Git operations:
        git checkout dev
        git pull origin dev
      </action>

      <action>Check if epic branch exists:
        git branch --list {{epic_branch}}
      </action>

      <check if="branch exists">
        <action>git checkout {{epic_branch}}</action>
        <action>git merge dev --no-edit</action>
        <output>Checked out existing branch {{epic_branch}}, merged latest dev</output>
      </check>

      <check if="branch does NOT exist">
        <action>git checkout -b {{epic_branch}}</action>
        <output>Created new branch {{epic_branch}} from dev</output>
      </check>
    </step>

    <step n="6" name="initialize-metrics">
      <action>Set metrics:
        - metrics.epic_id = {{epic_id}}
        - metrics.epic_title = {{epic_title}}
        - metrics.summary.total_stories = length(story_queue)
        - metrics.summary.skipped_stories = length(skipped_stories)
      </action>
    </step>

    <step n="7" name="rename-state-file">
      <action>If state file was "epic-new-state.json":
        Rename to "epic-{{epic_id}}-state.json"
      </action>
    </step>

  </execution>

  <output>
🎯 **Epic Initialized (v3.0 Phased)**

Epic: {{epic_id}} - {{epic_title}}
Branch: {{epic_branch}}
Stories to execute: {{story_queue.length}}
Stories skipped: {{skipped_stories.length}}
Order: {{story_queue | join(", ")}}

Beginning orchestrated execution...
  </output>

  <return>
    {
      "next_phase": "01-story-start",
      "state_updates": {
        "epic_id": "{{epic_id}}",
        "epic_title": "{{epic_title}}",
        "epic_branch": "{{epic_branch}}",
        "epic_path": "{{epic_path}}",
        "story_dir": "{{story_dir}}",
        "story_queue": {{story_queue}},
        "skipped_stories": {{skipped_stories}},
        "current_story_index": 0,
        "completed_stories": [],
        "failed_stories": [],
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
