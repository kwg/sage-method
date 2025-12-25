# Phase 09: Merge to Dev

```xml
<phase id="09-merge-to-dev" name="Merge to Dev">

  <purpose>
    Merge the epic PR to dev branch after approval.
    Handles both auto-merge (if configured) and manual approval flow.
  </purpose>

  <input>
    {{state}} with:
    - pr_url: URL of created PR
    - pr_number: PR number
    - auto_merge: boolean from workflow config
    - delete_branch_after_merge: boolean (default: false)
    - epic_branch: epic branch name
    - epic_id: epic identifier
  </input>

  <preconditions>
    - Phase 08 completed successfully
    - PR exists and is open
    - gh CLI authenticated
  </preconditions>

  <execution>

    <step n="1" name="check-pr-status">
      <action>Get PR state using gh CLI:
        gh pr view {{pr_number}} --json state,mergeable,mergeStateStatus,reviewDecision
      </action>

      <check if="state == 'MERGED'">
        <output>✅ PR already merged</output>
        <action>Skip to step 4 (update-metrics)</action>
      </check>

      <check if="state == 'CLOSED'">
        <error>PR was closed without merging</error>
        <output>
❌ **PR Closed Without Merge**

PR {{pr_number}} was closed without merging.
This epic cannot be auto-completed.

Options:
1. Re-open PR and retry
2. Mark epic as failed
        </output>
        <action>Exit with error</action>
      </check>

      <output>PR Status: {{state}} ({{mergeStateStatus}})</output>
    </step>

    <step n="2" name="check-approval">
      <check if="reviewDecision != 'APPROVED'">
        <output>
⏳ **Awaiting PR Approval**

PR: {{pr_url}}
Status: {{reviewDecision || 'No reviews yet'}}
Mergeable: {{mergeable}}

The PR requires approval before merging.

{{if auto_merge == true}}
Waiting for approval (will poll every 60 seconds, max 10 attempts)...
{{else}}
Auto-merge is disabled. Options:
1. Approve the PR in GitHub, then resume: *resume-epic {{epic_id}}
2. Merge manually and mark epic as complete
{{endif}}
        </output>

        <check if="auto_merge == false">
          <action>Set resumable state marker</action>
          <action>Exit workflow (resumable from this phase)</action>
        </check>

        <action>Wait for approval with polling:
          max_attempts = 10
          wait_seconds = 60
          for attempt in 1..max_attempts:
            sleep(wait_seconds)
            gh pr view {{pr_number}} --json reviewDecision
            if reviewDecision == 'APPROVED':
              break
          if attempt == max_attempts:
            output "Approval timeout - manual intervention required"
            exit (resumable)
        </action>
      </check>

      <output>✅ PR approved by: {{reviewers}}</output>
    </step>

    <step n="3" name="execute-merge">
      <check if="mergeable != true">
        <error>PR is not mergeable: {{mergeStateStatus}}</error>
        <output>
❌ **PR Not Mergeable**

Status: {{mergeStateStatus}}
Mergeable: {{mergeable}}

Please resolve the following before merging:
- Merge conflicts (if any)
- Required status checks
- Branch protection rules

Then resume: *resume-epic {{epic_id}}
        </output>
        <action>Set resumable state marker</action>
        <action>Exit workflow (resumable from this phase)</action>
      </check>

      <action>Merge PR using gh CLI:
        gh pr merge {{pr_number}} --merge {{#if delete_branch_after_merge}}--delete-branch{{else}}--delete-branch=false{{/if}}
        <!-- delete_branch_after_merge defaults to false to preserve epic branches for reference -->
      </action>

      <check if="merge command fails">
        <error>Merge failed: {{error_message}}</error>
        <output>
❌ **Auto-Merge Failed**

Error: {{error_message}}

Manual merge instructions:
1. Visit: {{pr_url}}
2. Review any errors
3. Merge manually if appropriate
4. Resume epic: *resume-epic {{epic_id}}

Or retry auto-merge after fixing issues.
        </output>
        <action>Set resumable state marker</action>
        <action>Exit workflow (resumable from this phase)</action>
      </check>

      <output>✅ PR merged successfully!</output>
    </step>

    <step n="4" name="update-metrics">
      <action>Record merge completion timestamp:
        state.metrics.merged_at = current_iso_timestamp
        state.metrics.merged_to = "dev"
        state.pr_merged = true
      </action>

      <action>Update state file with merge status</action>
    </step>

    <step n="5" name="verify-merge">
      <action>Verify merge on dev branch:
        git fetch origin dev
        git log origin/dev --oneline -n 5
      </action>

      <check if="epic commits not in dev">
        <warning>Merge succeeded but commits not yet visible on origin/dev</warning>
        <output>This may be a timing issue. Verify manually if needed.</output>
      </check>

      <output>✅ Merge verified: {{epic_branch}} → dev</output>
    </step>

  </execution>

  <output>
🎉 **Epic Merged to Dev**

| | |
|---|---|
| Epic | {{epic_id}} |
| PR | {{pr_number}} |
| Merged To | dev |
| Merged At | {{merged_at}} |

The epic branch has been successfully merged to dev.

Next steps:
- Optionally run *merge-to-main to promote dev to main
- Run *epic-retro to conduct retrospective
- Archive epic state file
  </output>

  <return>
    {
      "next_phase": "done",
      "state_updates": {
        "pr_merged": true,
        "metrics": {
          "merged_at": "{{current_iso_timestamp}}",
          "merged_to": "dev"
        }
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
