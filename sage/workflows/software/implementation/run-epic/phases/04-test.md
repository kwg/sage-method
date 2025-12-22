# Phase 04: Test Story (FIXER Subagent on Failure)

```xml
<phase id="04-test" name="Run Tests">

  <purpose>
    Run all tests for the story implementation.
    On failure: spawn FIXER subagent to diagnose and fix.
    Retry up to 3 times before failing story.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_branch: current git branch
    - test_attempt: current attempt number (0-based)
    - completed_chunks: list of completed chunk IDs
  </input>

  <preconditions>
    - All chunks implemented (or failed/skipped)
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="run-tests">
      <output>🧪 **Running tests (attempt {{test_attempt + 1}}/3)...**</output>

      <action>
        metrics_collector:
          action: record_start
          operation: "test"
          story_id: {{current_story}}
      </action>

      <action>Detect test runner:
        - If package.json exists with test script: npm test
        - If pytest.ini or conftest.py: pytest
        - If Cargo.toml: cargo test
        - If go.mod: go test ./...
        - Fallback: Ask user for test command
      </action>

      <action>Run test command, capture output</action>
    </step>

    <step n="2" name="analyze-results">
      <action>
        metrics_collector:
          action: record_end
          operation: "test"
          story_id: {{current_story}}
      </action>

      <action>Parse test output for:
        - Total tests
        - Passed tests
        - Failed tests
        - Skipped tests
        - Coverage (if available)
      </action>

      <check if="all tests pass">
        <output>✅ All tests passing!</output>
        <action>Update story metrics: tests_passed = true</action>

        <check if="state.issue_number exists">
          <action>Run: gh-issue-progress {{state.issue_number}} test_results --tests-passed {{tests_passed}} --tests-failed 0 --tests-skipped {{tests_skipped}} --coverage {{coverage_percent}} --message "All tests passing"</action>
          <output>📢 GitHub issue updated: test results</output>
        </check>

        <return>
          {
            "next_phase": "05-review",
            "state_updates": {
              "test_attempt": 0,
              "metrics": {{updated_metrics}}
            },
            "output": "All tests passing. Proceeding to code review..."
          }
        </return>
      </check>
    </step>

    <step n="3" name="check-retry-limit">
      <check if="test_attempt >= 3">
        <output>❌ Tests failed after 3 fix attempts</output>
        <action>Update story metrics: tests_passed = false, final_status = "failed"</action>
        <action>Add to failed_stories: { story_id: {{current_story}}, reason: "tests_failed" }</action>
        <action>
          learning_recorder:
            action: record_failure
            failure:
              type: "test"
              context:
                phase: "04-test"
                story_id: {{current_story}}
                error: {{test_output}}
              retry_count: 3
        </action>
        <action>
          learning_recorder:
            action: classify
            classification:
              category: "{{inferred_category}}"
              pattern: "{{identified_pattern}}"
              preventable: {{is_preventable}}
        </action>
        <return>
          {
            "next_phase": "01-story-start",
            "state_updates": {
              "current_story_index": {{current_story_index + 1}},
              "failed_stories": {{updated_failed_stories}},
              "test_attempt": 0,
              "metrics": {{updated_metrics}},
              "learning_records": {{updated_learning_records}}
            },
            "output": "Story {{current_story}} failed: tests could not be fixed. Skipping."
          }
        </return>
      </check>
    </step>

    <step n="4" name="spawn-fixer">
      <output>🔧 **Spawning FIXER subagent...**

Failed tests:
{{test_output_summary}}
      </output>

      <action>
        subagent_spawner:
          action: spawn
          subagent_type: "FIXER"
          context:
            test_output: {{test_output}}
            failing_files: {{identified_failing_files}}
            previous_attempts: {{test_attempt}}
          output_schema:
            type: "fix_result"
      </action>

      <subagent-prompt>
You are a TEST FAILURE SPECIALIST. Diagnose and fix the failing tests.

## Test Output
```
{{test_output}}
```

## Previous Attempts
This is attempt {{test_attempt + 1}} of 3.
{{if test_attempt > 0}}
Previous fixes did not resolve all issues. Look for:
- Root cause vs symptoms
- Related failures that share a common cause
- Side effects from previous fixes
{{endif}}

## Your Goal
1. Diagnose the root cause of each failure
2. Identify if it's a test issue or implementation issue
3. Fix the code to make tests pass
4. Do NOT modify tests to make them pass (unless test is genuinely wrong)

## Instructions

1. Read the failing test files
2. Read the implementation files under test
3. Identify the root cause (not just the symptom)
4. Make minimal, targeted fixes
5. Consider if the same pattern causes multiple failures

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "diagnosis": "Clear explanation of root cause",
  "files": [
    {
      "path": "relative/path/to/file.ts",
      "action": "modify",
      "content": "FULL file content with fix"
    }
  ],
  "root_cause": "syntax|logic|architecture|integration|environment",
  "preventable": true,
  "prevention_hint": "How to avoid this in future"
}
```

If you cannot fix the issue, set success=false and explain why.
      </subagent-prompt>
    </step>

    <step n="5" name="apply-fix">
      <check if="fixer.success == false">
        <output>❌ FIXER could not resolve: {{fixer.diagnosis}}</output>
        <action>Increment test_attempt</action>
        <return>
          {
            "next_phase": "04-test",
            "state_updates": {
              "test_attempt": {{test_attempt + 1}},
              "metrics": {{updated_metrics}}
            },
            "output": "Fix unsuccessful. Retrying..."
          }
        </return>
      </check>

      <action>For EACH file in fixer.files:
        - Write updated file content
      </action>

      <action>git add .</action>
      <action>git commit -m "{{current_story}}: fix - {{fixer.diagnosis | truncate(50)}}"</action>

      <output>📝 Fix applied: {{fixer.diagnosis}}</output>
    </step>

    <step n="6" name="record-learning">
      <action>
        learning_recorder:
          action: record_failure
          failure:
            type: "test"
            context:
              phase: "04-test"
              story_id: {{current_story}}
              error: {{test_output_summary}}
            retry_count: {{test_attempt}}
      </action>

      <action>
        learning_recorder:
          action: record_resolution
          resolution:
            action: {{fixer.diagnosis}}
            success: {{fixer.success}}
            files_changed: {{fixer.files | map(f => f.path)}}
      </action>

      <action>
        learning_recorder:
          action: classify
          classification:
            category: {{fixer.root_cause}}
            preventable: {{fixer.preventable}}
            prevention_rule: {{fixer.prevention_hint}}
      </action>
    </step>

    <step n="7" name="cascade-check">
      <action>Update cascade_detection:
        - Add current failure to last_failures
        - Increment failures_in_window
        - Check if >= threshold (3 in 5)
      </action>

      <check if="cascade detected">
        <action>Set cascade_detection.cascade_detected = true</action>
        <output>⚠️ CASCADE DETECTED: Multiple similar failures</output>
      </check>
    </step>

  </execution>

  <output>
🔄 **Fix Applied - Retrying Tests**

Diagnosis: {{fixer.diagnosis}}
Root cause: {{fixer.root_cause}}
Preventable: {{fixer.preventable ? "Yes" : "No"}}

Attempt: {{test_attempt + 1}}/3
  </output>

  <return>
    {
      "next_phase": "04-test",
      "state_updates": {
        "test_attempt": {{test_attempt + 1}},
        "metrics": {{updated_metrics}},
        "learning_records": {{updated_learning_records}},
        "cascade_detection": {{updated_cascade}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
