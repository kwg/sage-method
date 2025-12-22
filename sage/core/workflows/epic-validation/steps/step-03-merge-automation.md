# Step 03: Merge Automation

```xml
<step id="03-merge-automation" name="Execute Merge">

  <purpose>
    Merge the approved epic branch to target branch (default: dev).
    Handle PR merge or direct merge depending on setup.
  </purpose>

  <input>
    - epic_branch: Branch to merge
    - target_branch: Destination branch (default: dev)
    - pr_url: Existing PR if any
    - approval_status: Must be "approved"
  </input>

  <preconditions>
    - approval_status == "approved"
    - epic_branch exists
    - No merge conflicts (or user has resolved them)
  </preconditions>

  <execution>

    <action n="1" name="verify-approval">
      <check if="approval_status != 'approved'">
        <error>Cannot merge without approval. Run step 02 first.</error>
        <action>Exit workflow</action>
      </check>
    </action>

    <action n="2" name="check-pr-status">
      <check if="pr_url exists">
        <action>Check PR status:
          gh pr view {{pr_number}} --json state,mergeable,mergeStateStatus
        </action>

        <check if="PR is not mergeable">
          <output>
⚠️ **PR Not Mergeable**

Status: {{merge_state_status}}

Please resolve the following before continuing:
- Merge conflicts
- Required reviews
- CI checks

Then run: *validate-epic {{epic_id}} --resume
          </output>
          <action>Exit workflow (resumable)</action>
        </check>
      </check>
    </action>

    <action n="3" name="execute-merge">
      <output>🔀 **Merging {{epic_branch}} → {{target_branch}}...**</output>

      <check if="pr_url exists">
        <action>Merge via PR:
          gh pr merge {{pr_number}} --merge --delete-branch=false
        </action>
      </check>

      <check if="no pr_url">
        <action>Direct merge:
          git checkout {{target_branch}}
          git pull origin {{target_branch}}
          git merge {{epic_branch}} --no-ff -m "Merge epic {{epic_id}}: {{epic_title}}"
          git push origin {{target_branch}}
        </action>
      </check>

      <check if="merge fails">
        <error>Merge failed: {{error_message}}</error>
        <output>
❌ **Merge Failed**

Error: {{error_message}}

Please resolve manually:
1. git checkout {{target_branch}}
2. git merge {{epic_branch}}
3. Resolve conflicts
4. git push origin {{target_branch}}

Then run: *validate-epic {{epic_id}} --resume
        </output>
        <action>Exit workflow (resumable)</action>
      </check>

      <output>✅ Merged successfully!</output>
    </action>

    <action n="4" name="update-metrics">
      <action>
        metrics_collector:
          action: record_completion
          epic_id: {{epic_id}}
          merged_at: {{current_timestamp}}
          merged_to: {{target_branch}}
      </action>
    </action>

  </execution>

  <next-step>
    Load: steps/step-04-learning-summary.md
  </next-step>

</step>
```
