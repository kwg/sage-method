# Phase 05: Code Review (REVIEWER Subagent)

```xml
<phase id="05-review" name="Code Review">

  <purpose>
    Spawn REVIEWER subagent for adversarial code review.
    Checks: correctness, patterns, security, maintainability.
    Retry up to 2 times for issues that must be fixed.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - story_branch: current git branch
    - review_iteration: current review iteration (0-based)
    - chunk_plan: for context on what was implemented
  </input>

  <preconditions>
    - All tests passing
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="gather-changes">
      <output>🔍 **Preparing Code Review (iteration {{review_iteration + 1}}/2)...**</output>

      <action>Get changed files:
        git diff {{epic_branch}}...{{story_branch}} --name-only
      </action>

      <action>Get diff for review:
        git diff {{epic_branch}}...{{story_branch}}
      </action>
    </step>

    <step n="2" name="spawn-reviewer">
      <action>
        metrics_collector:
          action: record_start
          operation: "reviewer"
          story_id: {{current_story}}
      </action>

      <action>
        subagent_spawner:
          action: spawn
          subagent_type: "REVIEWER"
          context:
            story_path: {{story_path}}
            diff: {{git_diff}}
            changed_files: {{changed_files}}
          output_schema:
            type: "review_result"
      </action>

      <subagent-prompt>
You are an ADVERSARIAL CODE REVIEWER. Your job is to find issues that would cause problems in production.

## Story Requirements
Read the story file: {{story_path}}

## Changes to Review
Files changed: {{changed_files | join(", ")}}

```diff
{{git_diff}}
```

## Review Criteria

### Critical (Must Fix)
- Security vulnerabilities (injection, XSS, CSRF, auth bypass)
- Data loss risks
- Race conditions or deadlocks
- Memory leaks
- Breaking changes to public APIs

### Important (Should Fix)
- Logic errors that could cause incorrect behavior
- Missing error handling for likely failure modes
- Performance issues (N+1 queries, unbounded loops)
- Missing input validation

### Suggestions (Nice to Have)
- Code clarity improvements
- Better naming
- Refactoring opportunities
- Documentation gaps

## Your Goal
1. Read each changed file completely
2. Understand the implementation intent from the story
3. Find issues systematically by category
4. Be specific: include file, line, and exact issue
5. Distinguish between must-fix and nice-to-have

## Output Format

Return JSON ONLY:
```json
{
  "approved": false,
  "issues": [
    {
      "severity": "critical",
      "file": "src/auth/login.ts",
      "line": 42,
      "issue": "SQL injection vulnerability - user input not sanitized",
      "suggestion": "Use parameterized query instead of string concatenation",
      "must_fix": true
    }
  ],
  "suggestions": [
    {
      "file": "src/auth/login.ts",
      "suggestion": "Consider extracting auth logic to separate function"
    }
  ],
  "approval_blockers": 1,
  "summary": "Found 1 critical security issue that must be fixed before merge"
}
```

Set approved=true ONLY if there are zero must_fix issues.
      </subagent-prompt>
    </step>

    <step n="3" name="process-review">
      <action>
        metrics_collector:
          action: record_end
          operation: "reviewer"
          story_id: {{current_story}}
      </action>

      <action>Parse REVIEWER response</action>

      <check if="approved == true">
        <output>✅ Code review passed!</output>
        <action>Update story metrics: review_iterations = {{review_iteration + 1}}</action>
        <return>
          {
            "next_phase": "06-story-complete",
            "state_updates": {
              "review_iteration": 0,
              "metrics": {{updated_metrics}}
            },
            "output": "Code review passed. Completing story..."
          }
        </return>
      </check>
    </step>

    <step n="4" name="check-iteration-limit">
      <check if="review_iteration >= 2">
        <output>❌ Code review failed after 2 iterations</output>

        <output>**Unresolved Issues:**
{{for issue in review.issues where issue.must_fix}}
- [{{issue.severity}}] {{issue.file}}:{{issue.line}}: {{issue.issue}}
{{endfor}}
        </output>

        <action>Ask user: force approve, continue fixing, or fail story?</action>

        <check if="user chooses fail">
          <action>Update story metrics: final_status = "failed"</action>
          <action>Add to failed_stories: { story_id: {{current_story}}, reason: "review_failed" }</action>
          <return>
            {
              "next_phase": "01-story-start",
              "state_updates": {
                "current_story_index": {{current_story_index + 1}},
                "failed_stories": {{updated_failed_stories}},
                "review_iteration": 0,
                "metrics": {{updated_metrics}}
              },
              "output": "Story {{current_story}} failed code review. Skipping."
            }
          </return>
        </check>

        <check if="user chooses force approve">
          <output>⚠️ Force approving with known issues</output>
          <return>
            {
              "next_phase": "06-story-complete",
              "state_updates": {
                "review_iteration": 0,
                "metrics": {{updated_metrics}}
              },
              "output": "Force approved. Completing story with known issues..."
            }
          </return>
        </check>
      </check>
    </step>

    <step n="5" name="output-issues">
      <output>
⚠️ **Review Issues Found ({{review.approval_blockers}} must fix)**

{{for issue in review.issues}}
### {{issue.severity | upper}}: {{issue.file}}:{{issue.line}}
{{issue.issue}}
**Suggestion:** {{issue.suggestion}}

{{endfor}}

{{if review.suggestions}}
### Suggestions (optional)
{{for s in review.suggestions}}
- {{s.file}}: {{s.suggestion}}
{{endfor}}
{{endif}}
      </output>
    </step>

    <step n="6" name="spawn-fixer-for-review">
      <output>🔧 **Fixing review issues...**</output>

      <action>
        subagent_spawner:
          action: spawn
          subagent_type: "FIXER"
          context:
            issues: {{review.issues | filter(i => i.must_fix)}}
            files: {{changed_files}}
          output_schema:
            type: "fix_result"
      </action>

      <subagent-prompt>
You are a CODE ISSUE FIXER. Fix the issues identified in code review.

## Issues to Fix
{{for issue in review.issues where issue.must_fix}}
### {{issue.severity}}: {{issue.file}}:{{issue.line}}
Issue: {{issue.issue}}
Suggestion: {{issue.suggestion}}

{{endfor}}

## Instructions
1. Read each file with issues
2. Apply the suggested fix or equivalent solution
3. Ensure fix doesn't break existing functionality
4. Be minimal - only fix what's needed

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "files": [
    {
      "path": "src/auth/login.ts",
      "action": "modify",
      "content": "FULL file content with fix"
    }
  ],
  "issues_fixed": ["SQL injection in login.ts:42"],
  "summary": "Fixed 1 security issue"
}
```
      </subagent-prompt>
    </step>

    <step n="7" name="apply-fixes">
      <action>For EACH file in fixer.files:
        - Write updated file content
      </action>

      <action>git add .</action>
      <action>git commit -m "{{current_story}}: address review feedback"</action>

      <output>📝 Review fixes applied: {{fixer.issues_fixed | join(", ")}}</output>
    </step>

  </execution>

  <output>
🔄 **Review Fixes Applied - Re-running Review**

Fixed: {{fixer.issues_fixed | join(", ")}}
Iteration: {{review_iteration + 1}}/2
  </output>

  <return>
    {
      "next_phase": "05-review",
      "state_updates": {
        "review_iteration": {{review_iteration + 1}},
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
