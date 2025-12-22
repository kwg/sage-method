# Phase 06: Code Review (REVIEWER Subagent)

```xml
<phase id="06-review" name="Adversarial Code Review">

  <purpose>
    Spawn REVIEWER subagent with fresh context to adversarially review
    all code changes. Find issues, verify acceptance criteria.
    Max 3 iterations to fix critical/high issues.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - completed_chunks: list of implemented chunks
    - review_iteration: current iteration (0-2)
  </input>

  <preconditions>
    - Implementation complete (all chunks attempted)
    - Tests have been run (pass or fail)
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="gather-files">
      <action>Build list of all files modified in this story:
        - From completed_chunks: files_to_create, files_to_modify
        - From git diff against epic branch
      </action>
    </step>

    <step n="2" name="spawn-reviewer">
      <output>🔍 **Spawning REVIEWER** (iteration {{review_iteration + 1}}/3)</output>

      <action>Use Task tool with subagent_type="general-purpose"</action>

      <subagent-prompt>
You are an ADVERSARIAL Code Reviewer. You have NEVER seen this code before. Your job is to find problems.

## Story File
Read for acceptance criteria: {{story_path}}

## Files to Review
{{for file in modified_files}}
- {{file}}
{{endfor}}

Read each file completely before reviewing.

## Review Checklist

### Integration Issues
- [ ] Do scenes have functional scripts attached?
- [ ] Are @onready references to valid node paths?
- [ ] Are signals connected correctly (check both connect calls and handler existence)?
- [ ] Are autoloads/singletons used correctly?

### Scope Creep
- [ ] Is there code for features NOT in this story's acceptance criteria?
- [ ] Are there signals/methods declared "for future use"?
- [ ] Are there TODO comments for out-of-scope work?

### Edge Cases & Defensive Programming
- [ ] Null handling - what happens if a method returns null?
- [ ] Scene freed mid-operation - checked with is_instance_valid()?
- [ ] Race conditions in async/await - node could be freed after await?
- [ ] _exit_tree() cleanup - are signals disconnected, timers stopped?
- [ ] Signal double-connection prevention - using is_connected() checks?
- [ ] Parameter validation - are inputs validated where needed?
- [ ] Return value checks - are nullable returns handled?

### Acceptance Criteria Verification
For EACH acceptance criterion in the story:
- [ ] Is it implemented?
- [ ] Point to specific code (file:line) as evidence

## Output Format

Return JSON ONLY:
```json
{
  "issues_found": true,
  "critical": [
    {
      "file": "path/to/file.gd",
      "line": 42,
      "issue": "Signal connected but handler doesn't exist",
      "fix": "Add func _on_button_pressed(): pass"
    }
  ],
  "high": [],
  "medium": [],
  "low": [],
  "ac_verification": [
    {
      "ac": "User can click Start button to begin game",
      "status": "pass",
      "evidence": "ui/main_menu.gd:25 - _on_start_pressed() calls SceneManager.goto_scene()"
    },
    {
      "ac": "Score displays in top-right corner",
      "status": "fail",
      "evidence": "HUD scene exists but score_label not connected to ScoreManager"
    }
  ],
  "summary": "Found 2 critical issues. AC 1/3 passing."
}
```

Issue severity:
- critical: Will cause crash or major malfunction
- high: Will cause incorrect behavior
- medium: Code smell or minor bug
- low: Style issue or optimization opportunity
      </subagent-prompt>
    </step>

    <step n="3" name="process-review">
      <action>Parse REVIEWER response</action>
      <action>Count issues by severity</action>
      <action>Update story metrics: issues_found = {critical, high, medium, low}</action>

      <check if="critical_count == 0 AND high_count == 0">
        <output>✅ Review passed - no critical or high issues</output>
        <action>Update story metrics: review_iterations = {{review_iteration + 1}}</action>
        <return>
          {
            "next_phase": "07-story-complete",
            "state_updates": {
              "review_iteration": {{review_iteration + 1}},
              "metrics": {{updated_metrics}}
            },
            "output": "Review clean. {{medium_count}} medium, {{low_count}} low issues noted."
          }
        </return>
      </check>

      <check if="review_iteration >= 2">
        <output>⚠️ Max review iterations (3) reached
Still have: {{critical_count}} critical, {{high_count}} high issues

Proceeding to completion with known issues.
        </output>
        <action>Update story metrics: review_iterations = 3</action>
        <return>
          {
            "next_phase": "07-story-complete",
            "state_updates": {
              "review_iteration": 3,
              "metrics": {{updated_metrics}}
            },
            "output": "Review incomplete - {{critical_count}} critical, {{high_count}} high issues remain"
          }
        </return>
      </check>
    </step>

    <step n="4" name="apply-fixes">
      <output>⚠️ Found {{critical_count}} critical, {{high_count}} high issues

Applying fixes from reviewer suggestions...
      </output>

      <action>For EACH critical issue:
        - Read the file at issue.file
        - Apply the suggested fix from issue.fix
        - If fix is code, insert/replace at the specified location
        - If fix is unclear, make minimal change to address issue.issue
      </action>

      <action>For EACH high issue:
        - Same process as critical
      </action>

      <action>git add .</action>
      <action>git commit -m "{{current_story}}: fix review issues (iteration {{review_iteration + 1}})"</action>

      <output>🔧 Applied {{critical_count + high_count}} fixes</output>
    </step>

    <step n="5" name="re-review">
      <return>
        {
          "next_phase": "06-review",
          "state_updates": {
            "review_iteration": {{review_iteration + 1}},
            "metrics": {{updated_metrics}}
          },
          "output": "Fixes applied. Re-running review..."
        }
      </return>
    </step>

  </execution>

</phase>
```
