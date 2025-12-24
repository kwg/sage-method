# Step 05: Cleanup

```xml
<step id="05-cleanup" name="Branch Cleanup and Final Status">

  <purpose>
    Clean up feature branches and update final status.
    Preserves metrics and learning files.
  </purpose>

  <input>
    - epic_id: Epic identifier
    - epic_branch: Epic branch (already merged)
    - completed_stories: List of completed story IDs
    - skip_cleanup: If true, preserve all branches
  </input>

  <execution>

    <action n="1" name="check-skip">
      <check if="skip_cleanup == true">
        <output>⏭️ Branch cleanup skipped (--skip-cleanup flag)</output>
        <action>Jump to action n="5"</action>
      </check>
    </action>

    <action n="2" name="delete-feature-branches">
      <output>🧹 **Cleaning up feature branches...**</output>

      <check if="domain == 'software'">
        Branch pattern: feature/{story_id}
      </check>
      <check if="domain == 'game'">
        Branch pattern: {story_id}
      </check>

      <action>For each story in completed_stories:
        - Check if branch exists locally: git branch --list {{story_branch}}
        - Check if branch exists remotely: git ls-remote --heads origin {{story_branch}}
        - Delete local: git branch -d {{story_branch}}
        - Delete remote: git push origin --delete {{story_branch}}
      </action>

      <output>Deleted {{deleted_count}} feature branches</output>
    </action>

    <action n="3" name="delete-epic-branch">
      <output>Deleting epic branch {{epic_branch}}...</output>

      <action>
        git branch -d {{epic_branch}}
        git push origin --delete {{epic_branch}}
      </action>

      <check if="delete fails">
        <warning>Could not delete epic branch. May need manual cleanup.</warning>
      </check>

      <output>✅ Epic branch deleted</output>
    </action>

    <action n="4" name="cleanup-state-file">
      <output>Archiving state file...</output>

      <action>Move state file to archive:
        mv state/epic-{{epic_id}}-state.json state/archive/epic-{{epic_id}}-state.json
      </action>

      <check if="archive directory doesn't exist">
        <action>mkdir -p state/archive</action>
      </check>
    </action>

    <action n="5" name="update-sprint-status">
      <output>Updating sprint status...</output>

      <action>Update docs/sprint-artifacts/sprint-status.yaml:
        - Move epic from "in-progress" to "completed"
        - Add completion timestamp
        - Add metrics reference
      </action>
    </action>

    <action n="6" name="final-output">
      <output>
🎉 **EPIC VALIDATION COMPLETE**

**Epic:** {{epic_id}} - {{epic_title}}
**Status:** Merged to {{target_branch}}

## Summary
- Stories completed: {{completed_stories.length}}
- Stories failed: {{failed_stories.length}}
- Branches cleaned: {{deleted_count + 1}}

## Artifacts Preserved
- 📊 Metrics: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json
- 📚 Learnings: docs/sprint-artifacts/learning/epic-{{epic_id}}-learnings.md
- ✅ Validation: docs/sprint-artifacts/epic-{{epic_id}}-validation.md

## Next Steps
{{if failed_stories.length > 0}}
⚠️ **Failed stories need attention:**
{{for story in failed_stories}}
- {{story.story_id}}: {{story.reason}}
{{endfor}}

Consider creating follow-up stories or a new epic to address these.
{{else}}
All stories completed successfully! Ready for next epic.
{{endif}}

---
Phase 4 validation complete. Epic lifecycle finished.
      </output>
    </action>

  </execution>

  <workflow-complete>
    Epic {{epic_id}} has completed the full SAGE lifecycle:
    - Phase 1: Design ✅
    - Phase 2: Plan ✅
    - Phase 3: Build ✅
    - Phase 4: Validate ✅
  </workflow-complete>

</step>
```
