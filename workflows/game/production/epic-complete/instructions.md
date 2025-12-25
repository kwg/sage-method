# Epic Completion Workflow Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/game/production/epic-complete/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>

<critical>
EPIC COMPLETION REQUIREMENTS:
1. All stories in the epic must have status "done"
2. Integration must be verified (all systems work together)
3. Human playtest must be completed with sign-off
4. All Severity A/B bugs must be resolved
5. Only after ALL requirements are met can an epic be marked "complete"

Code Complete ≠ Epic Complete
- Code complete means all stories are individually done
- Epic complete means the integrated whole is verified and playable
</critical>

<workflow>

<step n="1" goal="Identify Epic to Complete">

<output>
**Epic Completion Check**

{user_name}, this workflow verifies that an epic is ready to be marked complete.

Requirements for epic completion:
1. All stories have status "done"
2. Integration is verified
3. Human playtest is completed
4. No blocking bugs remain

Let me identify which epic to check.
</output>

<action>Load {sprint_status_file}</action>
<action>Find all epics in development_status</action>
<action>Identify epics where all stories are "done" but epic is not "complete"</action>

<check if="epic candidates found">
  <output>
Found epic(s) with all stories done:
{{list epic candidates}}

Which epic would you like to verify for completion, {user_name}?
  </output>
  <action>WAIT for {user_name} to select epic</action>
</check>

<check if="no epic candidates">
  <output>
No epics found with all stories done.

**Current Epic Status:**
{{list epics with incomplete story counts}}

**Next Steps:**
1. Complete remaining stories using `dev-story` workflow
2. Run `code-review` for stories awaiting review
3. Check back when all stories in an epic are done
  </output>
  <action>HALT</action>
</check>

<action>Set {{epic_num}} based on user selection or single candidate</action>

</step>

<step n="2" goal="Verify All Stories Complete">

<output>
**Checking Story Completion for Epic {{epic_num}}**
</output>

<action>Load {sprint_status_file}</action>
<action>Find all story keys matching pattern "{{epic_num}}-*"</action>
<action>Count total stories and stories with status "done"</action>

<output>
**Story Status:**
- Total Stories: {{total_stories}}
- Completed (Done): {{done_stories}}
- Incomplete: {{incomplete_stories}}

{{#if incomplete_stories > 0}}
**Incomplete Stories:**
{{list incomplete story keys with status}}

**BLOCKED**: Cannot complete epic until all stories are done.
{{else}}
All {{total_stories}} stories are complete.
{{/if}}
</output>

<check if="incomplete stories exist">
  <action>HALT with message: Complete remaining stories before epic completion</action>
</check>

</step>

<step n="3" goal="Verify Integration">

<output>
**Checking Integration Status**

Integration verification ensures all epic components work together as a cohesive whole.
</output>

<action>Check if integration test scene exists for this epic</action>
<action>Check for integration-related story (typically the last story in an epic)</action>

<output>
{user_name}, have you verified that all Epic {{epic_num}} systems are integrated and working together?

Integration checks:
- [ ] All components are wired in the main scenes
- [ ] Signal connections are functional
- [ ] No errors or warnings on startup
- [ ] Basic functionality works end-to-end

Have you completed integration verification? (yes/no)
</output>

<action>WAIT for {user_name} to confirm integration</action>

<check if="user says no">
  <output>
**BLOCKED**: Integration verification required.

**Next Steps:**
1. Run the integration test scene
2. Verify all systems connect properly
3. Fix any integration issues
4. Return to complete epic when verified
  </output>
  <action>HALT</action>
</check>

</step>

<step n="4" goal="Verify Human Playtest Complete">

<output>
**Checking Playtest Status**

Human playtesting is mandatory before marking an epic complete.
</output>

<action>Search {playtest_folder} for epic-{{epic_num}}-playtest-*.md</action>

<check if="playtest report found">
  <action>Load playtest report</action>
  <action>Check for sign-off criteria completion</action>
  <output>
**Playtest Report Found:** {{playtest_file}}
- Structured Tests: {{structured_result}}
- Exploratory Tests: {{exploratory_result}}
- Gameplay Sessions: {{gameplay_result}}
- Sign-Off: {{signoff_status}}
  </output>
</check>

<check if="no playtest report found">
  <output>
**WARNING**: No playtest report found for Epic {{epic_num}}.

Human playtesting is mandatory. Please run the `epic-playtest` workflow first.

{user_name}, has human playtesting been completed for Epic {{epic_num}}? (yes/no)

If yes, please provide the playtest report location.
  </output>
  <action>WAIT for {user_name} response</action>
</check>

<check if="playtest not complete">
  <output>
**BLOCKED**: Human playtest required.

**Next Steps:**
1. Run `epic-playtest` workflow
2. Complete structured, free, and gameplay testing
3. Sign off on playtest checklist
4. Return to complete epic when done
  </output>
  <action>HALT</action>
</check>

</step>

<step n="5" goal="Verify No Blocking Bugs">

<output>
**Checking Bug Status**
</output>

<action>Search {bugs_folder} for epic-{{epic_num}}-bug-*.md</action>
<action>Count bugs by severity (A/B/C)</action>
<action>Check for unresolved A/B bugs</action>

<check if="bugs found">
  <output>
**Bug Report for Epic {{epic_num}}:**
- Severity A (Critical): {{severity_a_count}}
- Severity B (Major): {{severity_b_count}}
- Severity C (Minor): {{severity_c_count}}

{{#if blocking_bugs}}
**BLOCKING BUGS:**
{{list unresolved A/B bugs}}

These must be resolved before epic completion.
{{else}}
No blocking bugs (A/B severity) remain unresolved.
{{/if}}
  </output>
</check>

<check if="no bugs found">
  <output>
No bug reports found for Epic {{epic_num}}.

{user_name}, were any bugs discovered during playtest? (yes/no)
  </output>
  <action>WAIT for {user_name} response</action>
</check>

<check if="blocking bugs exist">
  <output>
**BLOCKED**: Resolve Severity A/B bugs before completing epic.

**Next Steps:**
1. Fix blocking bugs
2. Re-run affected tests
3. Update bug status to resolved
4. Return to complete epic
  </output>
  <action>HALT</action>
</check>

</step>

<step n="6" goal="Verify Branch Merge Status">

<output>
**Checking Branch Merge Status**

Verifying that epic branch has been merged to dev/main.
</output>

<action>Determine epic branch name: epic-{{epic_num}}</action>
<action>Check if epic branch exists:
  git branch --list epic-{{epic_num}}
</action>

<check if="epic branch exists">
  <action>Check if epic branch is merged to dev:
    git log dev..epic-{{epic_num}} --oneline
    unmerged_commits = output
  </action>

  <check if="unmerged_commits exist">
    <output>
⚠️ **WARNING: Epic Branch Not Merged**

Epic branch: epic-{{epic_num}}
Unmerged commits: {{unmerged_commits.length}}

The epic branch has commits that are not in dev. This may indicate:
1. PR was not merged after Phase 09
2. PR was merged but branch not updated
3. Work was done outside the workflow

**Action Required:**
- Review PR status for epic-{{epic_num}}
- Verify branch merge status
- Merge manually if needed

{user_name}, has the epic-{{epic_num}} branch been merged to dev? (yes/no)
    </output>
    <action>WAIT for {user_name} response</action>

    <check if="user says no">
      <output>
**BLOCKED**: Epic branch must be merged before completion.

**Next Steps:**
1. Check PR status: gh pr list --head epic-{{epic_num}}
2. Merge PR if approved
3. Or run Phase 09 to complete merge
4. Return when branch is merged
      </output>
      <action>HALT</action>
    </check>

    <check if="user confirms merged">
      <output>
⚠️ User confirmed merge, but git shows unmerged commits.
This may be a branch sync issue. Proceeding with caution.
      </output>
    </check>
  </check>

  <check if="no unmerged commits">
    <output>
✅ Epic branch merged to dev
    </output>
  </check>
</check>

<check if="epic branch does not exist">
  <output>
ℹ️  Epic branch epic-{{epic_num}} not found locally.
This may indicate:
1. Epic was developed without branch workflow
2. Branch was deleted after merge
3. Working in different repository

Proceeding without branch verification.
  </output>
</check>

</step>

<step n="7" goal="Epic Completion Checklist">

<output>
**Epic {{epic_num}} Completion Checklist**

Please verify each item:

- [{{stories_complete}}] All stories have status "done" ({{done_stories}}/{{total_stories}})
- [{{integration_verified}}] Integration verified
- [{{playtest_complete}}] Human playtest completed with sign-off
- [{{no_blocking_bugs}}] No unresolved Severity A/B bugs
- [{{branch_merged}}] Epic branch merged to dev

{{#if all_checks_pass}}
All requirements met! Ready to mark Epic {{epic_num}} as complete.
{{else}}
**Cannot complete epic** - some requirements not met.
{{/if}}

{user_name}, do you want to mark Epic {{epic_num}} as complete? (yes/no)
</output>

<action>WAIT for {user_name} confirmation</action>

<check if="user says no">
  <output>
Epic {{epic_num}} will remain in current status.

Return when ready to complete the epic.
  </output>
  <action>HALT</action>
</check>

</step>

<step n="8" goal="Mark Epic Complete">

<action>Load {sprint_status_file}</action>
<action>Find epic key "epic-{{epic_num}}"</action>
<action>Update development_status["epic-{{epic_num}}"] = "complete"</action>
<action>Save file, preserving ALL comments and structure</action>

<check if="update successful">
  <output>
**Epic {{epic_num}} Marked Complete!**

Sprint status updated: epic-{{epic_num}} = "complete"
  </output>
</check>

<check if="epic key not found">
  <output>
**Warning**: Could not update sprint-status.yaml - epic key not found.

Epic completion verified, but manual update may be needed.
  </output>
</check>

</step>

<step n="9" goal="Recommend Next Steps">

<output>
**Epic {{epic_num}} Complete, {user_name}!**

**Summary:**
- Stories Completed: {{done_stories}}/{{total_stories}}
- Integration: Verified
- Playtest: Completed
- Blocking Bugs: None

**Recommended Next Steps:**

1. **Run Retrospective**
   - Use `retrospective` workflow to review Epic {{epic_num}}
   - Capture lessons learned
   - Prepare for next epic

2. **Start Next Epic**
   - Review Epic {{next_epic_num}} stories
   - Run `epic-tech-context` for technical context
   - Begin development with `dev-story`

3. **Archive Artifacts**
   - Playtest reports in {playtest_folder}
   - Bug reports in {bugs_folder}
   - Story files in {story_directory}

**Congratulations on completing Epic {{epic_num}}!**
</output>

</step>

</workflow>

<facilitation-guidelines>
<guideline>Verify ALL completion requirements before marking epic done</guideline>
<guideline>Human playtest is mandatory - code complete is not enough</guideline>
<guideline>Severity A/B bugs must be resolved - no exceptions</guideline>
<guideline>Integration verification ensures systems work together</guideline>
<guideline>Document completion status for future reference</guideline>
<guideline>Recommend retrospective for continuous improvement</guideline>
</facilitation-guidelines>
