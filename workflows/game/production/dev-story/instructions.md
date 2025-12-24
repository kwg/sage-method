# Develop Story - Workflow Instructions

```xml
<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>Only modify the story file in these areas: Tasks/Subtasks checkboxes, Dev Agent Record (Debug Log, Completion Notes), File List, Change Log, and Status</critical>
<critical>Execute ALL steps in exact order; do NOT skip steps</critical>
<critical>Absolutely DO NOT stop because of "milestones", "significant progress", or "session boundaries". Continue in a single execution until the story is COMPLETE (all ACs satisfied and all tasks/subtasks checked) UNLESS a HALT condition is triggered or the USER gives other instruction.</critical>
<critical>Do NOT schedule a "next session" or request review pauses unless a HALT condition applies. Only Step 6 decides completion.</critical>

<critical>User skill level ({user_skill_level}) affects conversation style ONLY, not code updates.</critical>

<workflow>

  <step n="1" goal="Find next ready story and load it" tag="sprint-status">
    <check if="{{story_path}} is provided">
      <action>Use {{story_path}} directly</action>
      <action>Read COMPLETE story file</action>
      <action>Extract {{story_key}} from {{story_path}} filename pattern (e.g., "1-1-combat-state-machine.md" → "1-1-combat-state-machine")</action>
      <goto step="2">Proceed to branch setup</goto>
    </check>

    <critical>MUST read COMPLETE sprint-status.yaml file from start to end to preserve order</critical>
    <action>Load the FULL file: {{output_folder}}/sprint-status.yaml</action>
    <action>Read ALL lines from beginning to end - do not skip any content</action>
    <action>Parse the development_status section completely to understand story order</action>

    <action>Find the FIRST story (by reading in order from top to bottom) where:
      - Key matches pattern: number-number-name (e.g., "1-2-user-auth")
      - NOT an epic key (epic-X) or retrospective (epic-X-retrospective)
      - Status value equals "ready-for-dev"
    </action>

    <check if="no ready-for-dev or in-progress story found">
      <output>📋 No ready-for-dev stories found in sprint-status.yaml
**Options:**
1. Run `story-context` to generate context file and mark drafted stories as ready
2. Run `story-ready` to quickly mark drafted stories as ready without generating context
3. Run `create-story` if no incomplete stories are drafted yet
4. Check {output_folder}/sprint-status.yaml to see current sprint status
      </output>
      <action>HALT</action>
    </check>

    <action>Store the found story_key (e.g., "1-2-user-authentication") for later status updates</action>
    <action>Find matching story file in {{story_dir}} using story_key pattern: {{story_key}}.md</action>
    <action>Read COMPLETE story file from discovered path</action>
  </step>

  <step n="2" goal="Create or switch to feature branch" tag="git-branch">
    <critical>MUST ensure correct feature branch BEFORE starting any development work</critical>
    <critical>Uses git-branch-protocol.xml for branch management</critical>
    <critical>{{story_key}} is now known from Step 1</critical>

    <!-- Use shared protocol for branch verification/creation -->
    <invoke-protocol name="ensure_implementation_branch" />

    <check if="{{branch_ready}} != true">
      <action>HALT - Cannot proceed without correct branch</action>
    </check>

    <output>🌿 Feature branch ready: {{implementation_branch}}</output>
  </step>

  <step n="3" goal="Load story context and parse sections">
    <action>Parse sections: Story, Acceptance Criteria, Tasks/Subtasks, Dev Notes, Dev Agent Record, File List, Change Log, Status</action>

    <action>Check if context file exists at: {{story_dir}}/{{story_key}}.context.xml</action>
    <check if="context file exists">
      <action>Read COMPLETE context file</action>
      <action>Parse all sections: story details, artifacts (docs, code, dependencies), interfaces, constraints, tests</action>
      <action>Use this context to inform implementation decisions and approaches</action>
    </check>
    <check if="context file does NOT exist">
      <output>ℹ️ No context file found for {{story_key}}

Proceeding with story file only. For better context, consider running `story-context` workflow first.
      </output>
    </check>

    <action>Identify first incomplete task (unchecked [ ]) in Tasks/Subtasks</action>

    <action if="no incomplete tasks"><goto step="11">Completion sequence</goto></action>
    <action if="story file inaccessible">HALT: "Cannot develop story without access to story file"</action>
    <action if="incomplete task or subtask requirements ambiguous">ASK user to clarify or HALT</action>
  </step>

  <step n="4" goal="Discover and load project documents">
    <invoke-protocol name="discover_inputs" />
    <note>After discovery, these content variables are available: {architecture_content}, {tech_spec_content}, {ux_design_content}, {epics_content} (selective load), {document_project_content}</note>
  </step>

  <step n="5" goal="Detect review continuation and extract review context">
    <critical>Determine if this is a fresh start or continuation after code review</critical>

    <action>Check if "Senior Developer Review (AI)" section exists in the story file</action>
    <action>Check if "Review Follow-ups (AI)" subsection exists under Tasks/Subtasks</action>

    <check if="Senior Developer Review section exists">
      <action>Set review_continuation = true</action>
      <action>Extract from "Senior Developer Review (AI)" section:
        - Review outcome (Approve/Changes Requested/Blocked)
        - Review date
        - Total action items with checkboxes (count checked vs unchecked)
        - Severity breakdown (High/Med/Low counts)
      </action>
      <action>Count unchecked [ ] review follow-up tasks in "Review Follow-ups (AI)" subsection</action>
      <action>Store list of unchecked review items as {{pending_review_items}}</action>

      <output>⏯️ **Resuming Story After Code Review** ({{review_date}})

**Review Outcome:** {{review_outcome}}
**Action Items:** {{unchecked_review_count}} remaining to address
**Priorities:** {{high_count}} High, {{med_count}} Medium, {{low_count}} Low

**Strategy:** Will prioritize review follow-up tasks (marked [AI-Review]) before continuing with regular tasks.
      </output>
    </check>

    <check if="Senior Developer Review section does NOT exist">
      <action>Set review_continuation = false</action>
      <action>Set {{pending_review_items}} = empty</action>

      <output>🚀 **Starting Fresh Implementation**

Story: {{story_key}}
Context file: {{context_available}}
First incomplete task: {{first_task_description}}
      </output>
    </check>
  </step>

  <step n="6" goal="Mark story in-progress" tag="sprint-status">
    <action>Load the FULL file: {{output_folder}}/sprint-status.yaml</action>
    <action>Read all development_status entries to find {{story_key}}</action>
    <action>Get current status value for development_status[{{story_key}}]</action>

    <check if="current status == 'ready-for-dev'">
      <action>Update the story in the sprint status report to = "in-progress"</action>
      <output>🚀 Starting work on story {{story_key}}
Status updated: ready-for-dev → in-progress
      </output>
    </check>

    <check if="current status == 'in-progress'">
      <output>⏯️ Resuming work on story {{story_key}}
Story is already marked in-progress
      </output>
    </check>

    <check if="current status is neither ready-for-dev nor in-progress">
      <output>⚠️ Unexpected story status: {{current_status}}
Expected ready-for-dev or in-progress. Continuing anyway...
      </output>
    </check>
  </step>

  <step n="7" goal="Plan and implement task via subagent">
    <critical>MUST spawn a SUBAGENT for implementation to get fresh context</critical>
    <critical>Orchestrator prepares context, subagent implements, orchestrator applies changes</critical>

    <action>Review acceptance criteria and dev notes for the selected task</action>
    <action>Identify relevant existing files from context file or codebase exploration</action>
    <action>Prepare implementation context: task description, constraints, relevant file contents</action>

    <output>🔨 **Implementing Task:** {{task_description}}</output>

    <!-- SPAWN SUBAGENT FOR IMPLEMENTATION -->
    <action>Use Task tool with subagent_type="general-purpose" and the following prompt:</action>

    <subagent-prompt>
You are an IMPLEMENTATION SPECIALIST with fresh context. Implement the following task completely and correctly.

## Task to Implement
{{task_description}}

## Subtasks
{{subtasks_list}}

## Acceptance Criteria (relevant to this task)
{{relevant_acs}}

## Constraints
{{story_constraints}}
- Follow existing code patterns in this codebase
- Do NOT implement features for future stories
- Handle error conditions and edge cases appropriately

## Existing Code Context
{{relevant_file_contents}}

## Architecture/Patterns to Follow
{{architecture_patterns}}

## Instructions

1. Read and understand the existing code context
2. Plan your implementation approach
3. Implement ALL subtasks completely
4. Follow defensive programming practices:
   - Validate parameters
   - Check return values for null
   - Guard async operations after await
   - Add cleanup in _exit_tree() if needed
   - Prevent signal double-connection

## Output Format

Return a JSON object:
```json
{
  "success": true/false,
  "files": [
    {
      "path": "relative/path/to/file.gd",
      "action": "create|modify",
      "content": "full file content here"
    }
  ],
  "implementation_notes": "Brief description of what was implemented and key decisions",
  "blockers": ["any issues that prevented completion"]
}
```

If you encounter blockers, set success=false and describe the blockers.
    </subagent-prompt>

    <action>Parse subagent response</action>

    <check if="subagent reports success=false">
      <output>⚠️ Implementation blocked: {{blockers}}</output>
      <action if="blocker is clarification needed">ASK user for guidance</action>
      <action if="blocker is missing dependency">ASK user for approval before adding</action>
      <action if="3 consecutive implementation failures occur">HALT and request guidance</action>
    </check>

    <check if="subagent reports success=true">
      <action>For each file in response, apply the changes using Write/Edit tools</action>
      <action>Log implementation notes to Dev Agent Record → Debug Log</action>
      <output>✅ Task implementation complete</output>
    </check>

    <critical>Do not stop after partial progress; continue iterating tasks until all ACs are satisfied and tested or a HALT condition triggers</critical>
    <critical>Do NOT propose to pause for review, stand-ups, or validation until Step 11 gates are satisfied</critical>
  </step>

  <step n="8" goal="Author comprehensive tests via subagent">
    <critical>MUST spawn a SUBAGENT for test authoring - fresh context prevents testing "what I meant" vs "what I wrote"</critical>

    <action>Collect implementation files created/modified in Step 7</action>
    <action>Identify test requirements from story notes and test plan</action>
    <action>Find existing test patterns in codebase for consistency</action>

    <output>🧪 **Authoring Tests for:** {{task_description}}</output>

    <!-- SPAWN SUBAGENT FOR TEST AUTHORING -->
    <action>Use Task tool with subagent_type="general-purpose" and the following prompt:</action>

    <subagent-prompt>
You are a TEST ENGINEER with fresh context. Write comprehensive tests for the implementation provided.

IMPORTANT: You have NOT seen this code before. Test what the code ACTUALLY does, not what it's supposed to do.

## Implementation Files to Test
{{implementation_file_contents}}

## Test Requirements from Story
{{test_requirements}}

## Existing Test Patterns
{{existing_test_examples}}

## Test Framework
{{test_framework_info}}

## Instructions

1. Read the implementation files carefully
2. Identify all public methods and behaviors to test
3. Write tests covering:
   - Happy path / normal operation
   - Edge cases (null inputs, empty collections, boundary values)
   - Error conditions and exception handling
   - State transitions (if applicable)
   - Signal emissions (if applicable)

4. Follow the existing test patterns for consistency
5. Use descriptive test names that explain what is being tested

## Output Format

Return a JSON object:
```json
{
  "success": true/false,
  "test_files": [
    {
      "path": "tests/path/to/test_file.gd",
      "action": "create|modify",
      "content": "full test file content"
    }
  ],
  "coverage_notes": "Brief description of what is covered and any gaps",
  "untestable": ["any behaviors that couldn't be tested and why"]
}
```
    </subagent-prompt>

    <action>Parse subagent response</action>

    <check if="subagent reports success=true">
      <action>For each test file in response, apply using Write/Edit tools</action>
      <action>Log coverage notes to Dev Agent Record</action>
      <output>✅ Tests authored</output>
    </check>

    <check if="subagent reports untestable items">
      <action>Log untestable items to Dev Agent Record as known limitations</action>
    </check>
  </step>

  <step n="9" goal="Run validations and tests">
    <action>Determine how to run tests for this repo (infer or use {{run_tests_command}} if provided)</action>
    <action>Run all existing tests to ensure no regressions</action>
    <action>Run the new tests to verify implementation correctness</action>
    <action>Run linting and code quality checks if configured</action>
    <action>Validate implementation meets ALL story acceptance criteria; if ACs include quantitative thresholds (e.g., test pass rate), ensure they are met before marking complete</action>
    <action if="regression tests fail">STOP and fix before continuing, consider how current changes made broke regression</action>
    <action if="new tests fail">STOP and fix before continuing</action>
  </step>

  <step n="10" goal="Mark task complete, track review resolutions, and update story">
    <critical>If task is a review follow-up, must mark BOTH the task checkbox AND the corresponding action item in the review section</critical>

    <action>Check if completed task has [AI-Review] prefix (indicates review follow-up task)</action>

    <check if="task is review follow-up">
      <action>Extract review item details (severity, description, related AC/file)</action>
      <action>Add to resolution tracking list: {{resolved_review_items}}</action>

      <!-- Mark task in Review Follow-ups section -->
      <action>Mark task checkbox [x] in "Tasks/Subtasks → Review Follow-ups (AI)" section</action>

      <!-- CRITICAL: Also mark corresponding action item in review section -->
      <action>Find matching action item in "Senior Developer Review (AI) → Action Items" section by matching description</action>
      <action>Mark that action item checkbox [x] as resolved</action>

      <action>Add to Dev Agent Record → Completion Notes: "✅ Resolved review finding [{{severity}}]: {{description}}"</action>
    </check>

    <action>ONLY mark the task (and subtasks) checkbox with [x] if ALL tests pass and validation succeeds</action>
    <action>Update File List section with any new, modified, or deleted files (paths relative to repo root)</action>
    <action>Add completion notes to Dev Agent Record if significant changes were made (summarize intent, approach, and any follow-ups)</action>

    <!-- EMBEDDED DOCUMENTATION: Each agent documents their own domain -->
    <action>Update "Workflow Documentation" section in Dev Agent Record with:
      - Translation decisions made (e.g., how design spec mapped to implementation)
      - Patterns discovered or applied during this task
      - Why certain approaches were chosen over alternatives
      - Gotchas, edge cases, or workarounds encountered
      - Anything a future agent/developer would need to know
    </action>
    <note>This documentation becomes the spec for future tooling automation. The implementer has context that would be lost in handoff to a separate Tech Writer.</note>

    <check if="review_continuation == true and {{resolved_review_items}} is not empty">
      <action>Count total resolved review items in this session</action>
      <action>Add Change Log entry: "Addressed code review findings - {{resolved_count}} items resolved (Date: {{date}})"</action>
    </check>

    <action>Save the story file</action>
    <action>Determine if more incomplete tasks remain</action>
    <action if="more tasks remain"><goto step="7">Next task</goto></action>
    <action if="no tasks remain"><goto step="11">Completion</goto></action>
  </step>

  <step n="11" goal="Story completion and mark for review" tag="sprint-status">
    <action>Verify ALL tasks and subtasks are marked [x] (re-scan the story document now)</action>
    <action>Run the full regression suite (do not skip)</action>
    <action>Confirm File List includes every changed file</action>
    <action>Execute story definition-of-done checklist, if the story includes one</action>
    <action>Update the story Status to: review</action>

    <!-- Mark story ready for review -->
    <action>Load the FULL file: {{output_folder}}/sprint-status.yaml</action>
    <action>Find development_status key matching {{story_key}}</action>
    <action>Verify current status is "in-progress" (expected previous state)</action>
    <action>Update development_status[{{story_key}}] = "review"</action>
    <action>Save file, preserving ALL comments and structure including STATUS DEFINITIONS</action>

    <check if="story key not found in file">
      <output>⚠️ Story file updated, but sprint-status update failed: {{story_key}} not found

Story is marked Ready for Review in file, but sprint-status.yaml may be out of sync.
      </output>
    </check>

    <action if="any task is incomplete">Return to step 3 to complete remaining work (Do NOT finish with partial progress)</action>
    <action if="regression failures exist">STOP and resolve before completing</action>
    <action if="File List is incomplete">Update it before completing</action>
  </step>

  <step n="12" goal="Self-review loop via subagent" tag="self-review">
    <critical>MUST spawn a SUBAGENT for clean-context adversarial review</critical>
    <critical>Same-context review has familiarity blindness - subagent is required</critical>
    <critical>Maximum 3 review iterations to prevent infinite loops</critical>

    <!-- Initialize review counter on first pass -->
    <check if="{{review_iteration}} is NOT set">
      <action>Set {{review_iteration}} = 1</action>
    </check>

    <output>🔍 **Self-Review Iteration {{review_iteration}}/3** (via subagent)</output>

    <!-- SPAWN SUBAGENT FOR CLEAN-CONTEXT REVIEW -->
    <action>Use Task tool with subagent_type="general-purpose" and the following prompt:</action>

    <subagent-prompt>
You are an ADVERSARIAL Code Reviewer with FRESH CONTEXT. You have never seen this code before. Your job is to find problems.

## Story to Review
Story file: {{story_path}}

## Instructions

1. Read the COMPLETE story file
2. Extract: Acceptance Criteria, Tasks, File List, Important Constraints
3. Read EACH file in the File List

## Review Checklist

**Integration Check:** For each .tscn scene:
- Does the scene have a script that makes it functional?
- If the scene is loaded, does it actually DO something?
- Are all @onready references to valid nodes?
- Are signal connections wired up correctly?

**Scope Check:** Re-read "Important Constraints" section:
- Did implementation add code for out-of-scope features?
- Are there signals/methods for future stories that shouldn't exist yet?

**Edge Case Check:**
- What happens if null is returned from a method?
- What happens if the scene is freed mid-operation?
- Are there race conditions in async/await code?
- Is there cleanup in _exit_tree() if needed?
- Are signals checked for double-connection?

**Defensive Programming Check:**
- Are method parameters validated before use?
- Are return values checked for null/empty?
- Are async operations guarded after await?

**AC Verification:** For each Acceptance Criterion:
- Is it ACTUALLY implemented?
- Can you point to specific code (file:line) that satisfies it?

## Output Format

Return a JSON object:
```json
{
  "issues_found": true/false,
  "critical": [{"file": "path", "line": N, "issue": "description"}],
  "high": [{"file": "path", "line": N, "issue": "description"}],
  "medium": [{"file": "path", "line": N, "issue": "description"}],
  "low": [{"file": "path", "line": N, "issue": "description"}]
}
```

If you find ZERO issues, you are not looking hard enough. Check null handling, async guards, and signal lifecycle.
    </subagent-prompt>

    <action>Parse subagent response into {{self_review_issues}}</action>
    <action>Count issues by severity: {{critical_count}}, {{high_count}}, {{medium_count}}, {{low_count}}</action>

    <check if="{{critical_count}} == 0 AND {{high_count}} == 0">
      <output>✅ Self-review passed - no critical/high issues found
Medium: {{medium_count}}, Low: {{low_count}} (acceptable for commit)
      </output>
      <goto step="13">Proceed to commit</goto>
    </check>

    <check if="({{critical_count}} > 0 OR {{high_count}} > 0) AND {{review_iteration}} < 3">
      <output>⚠️ **Self-Review Found Issues:**

CRITICAL: {{critical_count}}
HIGH: {{high_count}}
MEDIUM: {{medium_count}}
LOW: {{low_count}}

{{self_review_issues}}

Fixing critical/high issues and re-reviewing...
      </output>

      <action>Fix each CRITICAL and HIGH issue</action>
      <action>Update story file's Completion Notes with fixes applied</action>
      <action>Increment {{review_iteration}} by 1</action>
      <goto step="12">Re-run self-review</goto>
    </check>

    <check if="({{critical_count}} > 0 OR {{high_count}} > 0) AND {{review_iteration}} >= 3">
      <output>⚠️ **Max Review Iterations Reached (3)**

Remaining issues after 3 fix attempts:
{{self_review_issues}}

Proceeding to commit. Critical issues should be addressed before merge.
      </output>
      <action>Add remaining issues to story's Dev Agent Record as "Known Issues"</action>
      <goto step="13">Proceed to commit despite issues</goto>
    </check>
  </step>

  <step n="13" goal="Commit changes to feature branch" tag="git-commit">
    <critical>Commit all implementation work to the feature branch before completion</critical>

    <action>Run: git status --porcelain</action>
    <action>Collect list of all changed files</action>

    <check if="no changes to commit">
      <output>ℹ️ No uncommitted changes - all work already committed</output>
      <goto step="14">Proceed to completion communication</goto>
    </check>

    <action>Run: git add .</action>
    <action>Prepare commit message summarizing story implementation</action>
    <action>Run: git commit -m "feat({{story_key}}): implement story

Story: {{story_key}}
Status: Ready for Review

Changes:
{{file_list_summary}}

🤖 Generated with SAGE dev-story workflow

Co-Authored-By: Claude <noreply@anthropic.com>"</action>

    <check if="commit succeeds">
      <output>✅ Changes committed to branch {{implementation_branch}}</output>
    </check>

    <check if="commit fails">
      <output>⚠️ Commit failed - check git status and resolve issues</output>
      <action>HALT - Resolve commit issues before proceeding</action>
    </check>

    <action>Optionally push to remote if configured: git push origin {{implementation_branch}}</action>
  </step>

  <step n="14" goal="Completion communication and user support">
    <action>Optionally run the workflow validation task against the story using {project-root}/sage/core/tasks/validate-workflow.xml</action>
    <action>Prepare a concise summary in Dev Agent Record → Completion Notes</action>

    <action>Communicate to {user_name} that story implementation is complete and ready for review</action>
    <action>Summarize key accomplishments: story ID, story key, title, key changes made, tests added, files modified</action>
    <action>Provide the story file path and current status (now "review", was "in-progress")</action>

    <action>Based on {user_skill_level}, ask if user needs any explanations about:
      - What was implemented and how it works
      - Why certain technical decisions were made
      - How to test or verify the changes
      - Any patterns, libraries, or approaches used
      - Anything else they'd like clarified
    </action>

    <check if="user asks for explanations">
      <action>Provide clear, contextual explanations tailored to {user_skill_level}</action>
      <action>Use examples and references to specific code when helpful</action>
    </check>

    <action>Once explanations are complete (or user indicates no questions), suggest logical next steps</action>
    <action>Common next steps to suggest (but allow user flexibility):
      - Review the implemented story yourself and test the changes
      - Verify all acceptance criteria are met
      - Ensure deployment readiness if applicable
      - Run `code-review` workflow for peer review
      - Check sprint-status.yaml to see project progress
    </action>
    <action>Remain flexible - allow user to choose their own path or ask for other assistance</action>
  </step>

  <step n="8" goal="Merge story branch into epic branch" tag="git-branch">
    <critical>Branch hierarchy: main → dev → epic-{x} → story branch</critical>
    <critical>Story branch must be merged into epic branch when complete</critical>

    <!-- Extract epic number from story key -->
    <action>Extract {{epic_num}} from {{story_key}} (first segment, e.g., "1-3-hp-system" → "1")</action>
    <action>Set {{epic_branch}} = "epic-{{epic_num}}"</action>
    <action>Set {{story_branch}} = "{{story_key}}"</action>

    <output>🔀 **Merge to Epic Branch**

Story {{story_key}} is complete. Ready to merge into {{epic_branch}}.
    </output>

    <!-- Update story status to done before merge -->
    <action>Update story file Status to: "done"</action>
    <action>Load {{output_folder}}/sprint-status.yaml</action>
    <action>Update development_status[{{story_key}}] = "done"</action>
    <action>Save file, preserving ALL comments and structure</action>

    <!-- Ensure all changes are committed -->
    <action>Check for uncommitted changes: git status --porcelain</action>
    <check if="uncommitted changes exist">
      <action>Run: git add .</action>
      <action>Run: git commit -m "feat({{story_key}}): Complete implementation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"</action>
      <output>✅ Changes committed</output>
    </check>

    <!-- Push story branch -->
    <action>Run: git push origin {{story_branch}}</action>
    <output>✅ Story branch pushed to origin</output>

    <!-- Switch to epic branch and merge -->
    <action>Run: git fetch origin</action>
    <action>Run: git checkout {{epic_branch}}</action>
    <action>Run: git pull origin {{epic_branch}} --rebase 2>/dev/null || true</action>

    <action>Run: git merge --no-ff {{story_branch}} -m "Merge story {{story_key}}

Story: {{story_key}}
Status: done

🤖 Generated with [Claude Code](https://claude.com/claude-code)"</action>

    <check if="merge conflict occurs">
      <output>❌ **MERGE CONFLICT**

Conflicts occurred merging {{story_branch}} into {{epic_branch}}.
Please resolve conflicts manually.
      </output>
      <action>HALT - Resolve merge conflicts</action>
    </check>

    <!-- Push epic branch -->
    <action>Run: git push origin {{epic_branch}}</action>
    <output>✅ Story merged and epic branch pushed</output>

    <!-- Optionally delete story branch -->
    <action>Ask user: Delete story branch {{story_branch}}? [y/n]</action>
    <check if="user confirms yes">
      <action>Run: git branch -d {{story_branch}}</action>
      <action>Run: git push origin --delete {{story_branch}} 2>/dev/null || true</action>
      <output>✅ Story branch deleted</output>
    </check>

    <output>🎉 **Story {{story_key}} Complete and Merged!**

Branch {{story_branch}} has been merged into {{epic_branch}}.

**Next steps:**
- Start next story: Run dev-story workflow
- When all stories done: Create PR from {{epic_branch}} to dev
    </output>
  </step>

</workflow>
```
