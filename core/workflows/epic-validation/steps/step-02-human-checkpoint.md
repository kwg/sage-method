# Step 02: Human Checkpoint

```xml
<step id="02-human-checkpoint" name="Require Human Approval">

  <critical>
    THIS STEP BLOCKS UNTIL HUMAN APPROVAL.
    The workflow CANNOT proceed automatically past this point.
  </critical>

  <purpose>
    Require explicit human approval before merging the epic.
    This is the quality gate that ensures human oversight.
  </purpose>

  <input>
    - epic_summary: Generated in step 01
    - pr_url: PR URL if exists
    - failed_stories: List of failed stories
  </input>

  <execution>

    <action n="1" name="present-decision">
      <output>
⏸️ **HUMAN CHECKPOINT REQUIRED**

Please review the epic summary above and make a decision:

{{if failed_stories.length > 0}}
⚠️ **WARNING:** This epic has {{failed_stories.length}} failed stories.
{{endif}}

{{if pr_url}}
📝 **Pull Request:** {{pr_url}}
   Please review the PR diff before approving.
{{endif}}

**Options:**
1. **approve** - Proceed with merge to {{target_branch}}
2. **reject** - Abort merge, keep branch for fixes
3. **defer** - Pause workflow, resume later with *validate-epic {{epic_id}} --resume

What would you like to do?
      </output>
    </action>

    <action n="2" name="wait-for-input">
      <wait>User must respond with: approve, reject, or defer</wait>

      <check if="response == 'approve'">
        <action>Set approval_status = "approved"</action>
        <action>Set approved_by = "human"</action>
        <action>Set approved_at = current_timestamp</action>
        <output>✅ Approved. Proceeding with merge...</output>
      </check>

      <check if="response == 'reject'">
        <action>Set approval_status = "rejected"</action>
        <output>
❌ **Merge Rejected**

The epic branch {{epic_branch}} will be preserved.
You can:
- Fix issues and re-run validation: *validate-epic {{epic_id}}
- Delete the branch manually if abandoning

Workflow terminated.
        </output>
        <action>Exit workflow</action>
      </check>

      <check if="response == 'defer'">
        <action>Set approval_status = "deferred"</action>
        <action>Save workflow state for resume</action>
        <output>
⏸️ **Workflow Paused**

Resume later with: *validate-epic {{epic_id}} --resume

The epic branch and PR are preserved.
        </output>
        <action>Exit workflow (resumable)</action>
      </check>

      <check if="response not recognized">
        <output>Please respond with: approve, reject, or defer</output>
        <action>Return to action n="2"</action>
      </check>
    </action>

    <action n="3" name="record-approval">
      <check if="approval_status == 'approved'">
        Write validation record to: docs/sprint-artifacts/epic-{{epic_id}}-validation.md

        ---
        epic_id: {{epic_id}}
        approved_by: human
        approved_at: {{approved_at}}
        stories_completed: {{completed_stories.length}}
        stories_failed: {{failed_stories.length}}
        pr_url: {{pr_url}}
        ---
      </check>
    </action>

  </execution>

  <next-step>
    <check if="approval_status == 'approved'">
      Load: steps/step-03-merge-automation.md
    </check>
  </next-step>

</step>
```
