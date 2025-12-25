# Phase 08: Finalize Epic

```xml
<phase id="08-finalize" name="Finalize Epic">

  <purpose>
    All stories processed. Generate metrics report, save to file,
    push epic branch, create PR to dev.
  </purpose>

  <input>
    {{state}} with:
    - epic_id, epic_title, epic_branch
    - completed_stories, failed_stories, skipped_stories
    - metrics: full metrics object
  </input>

  <preconditions>
    - All stories in queue have been processed
    - On epic branch
  </preconditions>

  <execution>

    <step n="0" name="verify-branch-state">
      <action>Verify all story branches merged to epic branch:
        pending_merges = []
        for story in completed_stories:
          story_branch = story_id (branch naming convention)
          git log {{epic_branch}}..{{story_branch}} --oneline
          if output not empty:
            pending_merges.append({story: story, unmerged_count: line_count})
      </action>

      <check if="pending_merges not empty">
        <warning>{{pending_merges.length}} story branches have unmerged commits</warning>
        <output>
⚠️ **Unmerged Story Branches Detected**

The following story branches have commits not yet in {{epic_branch}}:

{{for item in pending_merges}}
- {{item.story}}: {{item.unmerged_count}} unmerged commits
{{endfor}}

This may indicate incomplete merges from Phase 07.
Please verify these branches before continuing.

Options:
1. Continue anyway (commits may be duplicates or intentional)
2. Abort and investigate
        </output>
        <action>Ask user: continue or abort?</action>
      </check>

      <action>Check epic branch vs dev branch:
        git log dev..{{epic_branch}} --oneline
        pending_commits = output
      </action>

      <output>
📊 **Branch State Summary**

Epic Branch: {{epic_branch}}
Target Branch: dev
Pending Commits: {{pending_commits.length}}

{{if pending_commits.length == 0}}
⚠️ WARNING: Epic branch has no new commits vs dev.
This may indicate the epic was already merged or branch is out of date.
{{else}}
✅ Epic branch contains {{pending_commits.length}} commits ready for PR.
{{endif}}
      </output>

      <check if="pending_commits.length == 0">
        <warning>Epic branch has no commits ahead of dev</warning>
        <action>Ask user: continue with empty PR or abort?</action>
      </check>
    </step>

    <step n="1" name="finalize-metrics">
      <action>Record end_time = current ISO timestamp</action>

      <action>Calculate summary metrics:
        - total_stories = story_queue.length
        - completed_stories = completed_stories.length
        - failed_stories = failed_stories.length
        - skipped_stories = skipped_stories.length
        - total_chunks = sum of chunks_planned across all stories
        - total_chunks_completed = sum of chunks_completed
        - total_chunks_failed = sum of chunks_failed
        - avg_chunk_duration_ms = average of successful chunk durations
        - total_test_attempts = sum of test_attempts
        - total_review_iterations = sum of review_iterations
      </action>

      <action>Update metrics.end_time</action>
      <action>Update metrics.summary with calculated values</action>
    </step>

    <step n="2" name="save-metrics">
      <action>Ensure on epic branch: git checkout {{epic_branch}}</action>

      <action>Write metrics to: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json</action>

      <action>git add docs/sprint-artifacts/epic-{{epic_id}}-metrics.json</action>
      <action>git commit -m "epic-{{epic_id}}: workflow metrics for retrospective"</action>
    </step>

    <step n="3" name="push-branch">
      <action>git push -u origin {{epic_branch}}</action>

      <check if="push fails">
        <error>Failed to push {{epic_branch}}</error>
        <action>Check remote configuration</action>
        <action>Ask user to push manually or retry</action>
      </check>
    </step>

    <step n="4" name="create-pr">
      <action>Build PR body:
```markdown
## Summary

Epic: {{epic_id}} - {{epic_title}}
Workflow: v3.0 Phased Execution
Completed: {{completed_stories.length}}/{{story_queue.length}} stories

## Stories Completed
{{for story in completed_stories}}
- [x] {{story}}
{{endfor}}

## Stories Failed
{{for story in failed_stories}}
- [ ] {{story.story_id}}: {{story.reason}}
{{endfor}}

## Stories Skipped (not ready-for-dev)
{{for story in skipped_stories}}
- [ ] {{story}}
{{endfor}}

## Metrics Summary

| Metric | Value |
|--------|-------|
| Total Chunks | {{total_chunks}} |
| Chunks Completed | {{total_chunks_completed}} |
| Chunks Failed | {{total_chunks_failed}} |
| Avg Chunk Duration | {{avg_chunk_duration_ms}}ms |
| Test Fix Attempts | {{total_test_attempts}} |
| Review Iterations | {{total_review_iterations}} |

Full metrics: `docs/sprint-artifacts/epic-{{epic_id}}-metrics.json`

## Next Steps

1. Review PR changes
2. Run CI checks
3. Manual QA if needed
4. Merge to dev when approved
```
      </action>

      <action>Create PR using gh CLI:
        gh pr create \
          --base dev \
          --head {{epic_branch}} \
          --title "Epic {{epic_id}}: {{epic_title}}" \
          --body "{{pr_body}}"
      </action>

      <action>Capture PR URL and PR number from gh output</action>

      <check if="PR creation fails">
        <warning>Failed to create PR automatically</warning>
        <output>You can create it manually:
          Base: dev
          Head: {{epic_branch}}
        </output>
        <action>Set pr_url and pr_number to null in state</action>
      </check>
    </step>

    <step n="5" name="cleanup-state">
      <action>Optionally archive state file:
        mv state/epic-{{epic_id}}-state.json state/archive/epic-{{epic_id}}-state.json
      </action>
    </step>

  </execution>

  <output>
🎉 **Epic Execution Complete (v3.0 Phased)**

## Summary

| | |
|---|---|
| Epic | {{epic_id}} - {{epic_title}} |
| Workflow | v3.0 Phased Execution |
| Duration | {{duration}} |
| Stories | {{completed_stories.length}}/{{story_queue.length}} completed |

## Metrics Highlights

| Metric | Value |
|--------|-------|
| Total Chunks | {{total_chunks}} |
| Chunks Completed | {{total_chunks_completed}} |
| Chunks Failed | {{total_chunks_failed}} |
| Avg Chunk Duration | {{avg_chunk_duration_ms}}ms |
| Test Attempts | {{total_test_attempts}} |
| Review Iterations | {{total_review_iterations}} |

## Artifacts

- Metrics: `docs/sprint-artifacts/epic-{{epic_id}}-metrics.json`
- PR: {{pr_url}}

## Retrospective Questions

1. Did phased execution improve context management?
2. Was state persistence useful for debugging/resuming?
3. What phase took longest on average?
4. Were subagent prompts effective?
5. Should any phases be split or combined?
  </output>

  <return>
    {
      "next_phase": {{#if auto_merge}}"09-merge-to-dev"{{else}}"done"{{/if}},
      "state_updates": {
        "metrics": {{final_metrics}},
        "pr_url": "{{pr_url}}",
        "pr_number": "{{pr_number}}"
      },
      "output": "{{output_text}}",
      "note": {{#unless auto_merge}}"Phase 09 skipped (auto_merge: false). Merge PR manually when ready."{{/unless}}
    }
  </return>

</phase>
```
