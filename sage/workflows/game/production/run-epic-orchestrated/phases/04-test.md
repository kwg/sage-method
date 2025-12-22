# Phase 04: Run Tests (FIX Subagent if needed)

```xml
<phase id="04-test" name="Run Tests">

  <purpose>
    Run project test suite after all chunks implemented.
    If tests fail, spawn FIX subagent to diagnose and repair.
    Max 3 attempts before proceeding with failures noted.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
    - test_attempt: current attempt number (0-2)
    - completed_chunks: list of implemented chunks
  </input>

  <preconditions>
    - All chunks have been attempted
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="check-test-framework">
      <action>Detect test framework:
        - GUT for Godot: check for res://test/ or addons/gut
        - pytest for Python: check for tests/ or pytest.ini
        - jest for JS: check for jest.config or __tests__
      </action>

      <check if="no test framework detected">
        <output>ℹ️ No test framework configured - skipping test execution</output>
        <action>Update story metrics: tests_passed = null</action>
        <return>
          {
            "next_phase": "05-integration",
            "state_updates": {
              "metrics": {{updated_metrics}}
            },
            "output": "No test framework - skipping to integration tests"
          }
        </return>
      </check>
    </step>

    <step n="2" name="run-tests">
      <output>🧪 **Running Tests** (attempt {{test_attempt + 1}}/3)</output>

      <action>Determine test command:
        - Godot GUT: godot4 --headless --script addons/gut/gut_cmdln.gd
        - pytest: nix develop --command pytest
        - jest: npm test
      </action>

      <action>Execute test command</action>
      <action>Capture stdout, stderr, exit code</action>
    </step>

    <step n="3" name="evaluate-results">
      <check if="exit_code == 0 (tests pass)">
        <output>✅ All tests passing</output>
        <action>Update story metrics: tests_passed = true, test_attempts = {{test_attempt + 1}}</action>
        <return>
          {
            "next_phase": "05-integration",
            "state_updates": {
              "test_attempt": {{test_attempt + 1}},
              "metrics": {{updated_metrics}}
            },
            "output": "Tests passed on attempt {{test_attempt + 1}}"
          }
        </return>
      </check>

      <check if="exit_code != 0 AND test_attempt >= 2">
        <output>❌ Tests still failing after 3 fix attempts</output>
        <action>Update story metrics: tests_passed = false, test_attempts = 3</action>
        <return>
          {
            "next_phase": "05-integration",
            "state_updates": {
              "test_attempt": 3,
              "metrics": {{updated_metrics}}
            },
            "output": "Tests failed after 3 attempts. Proceeding with known failures."
          }
        </return>
      </check>
    </step>

    <step n="4" name="spawn-fixer">
      <output>⚠️ Tests failed - spawning FIX subagent (attempt {{test_attempt + 1}}/3)</output>

      <action>Use Task tool with subagent_type="general-purpose"</action>

      <subagent-prompt>
You are a TEST FIX SPECIALIST. Analyze failing tests and fix the implementation.

## Test Output
```
{{test_stdout}}
{{test_stderr}}
```

## Files Modified in This Story
{{for chunk in completed_chunks}}
{{chunk.files_to_create | join("\n")}}
{{chunk.files_to_modify | join("\n")}}
{{endfor}}

## Story Context
Read for acceptance criteria: {{story_path}}

## Instructions

1. Analyze the test failure output carefully
2. Identify the root cause - usually in implementation, not tests
3. Read the relevant implementation files
4. Apply minimal fixes to make tests pass
5. Do NOT refactor unrelated code
6. If tests themselves appear wrong, explain why

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "diagnosis": "Brief explanation of what went wrong and the fix",
  "files": [
    {
      "path": "relative/path/to/file.gd",
      "action": "modify",
      "content": "FULL file content with fix applied"
    }
  ],
  "tests_were_wrong": false,
  "tests_wrong_reason": null,
  "notes": "Any additional context"
}
```

If you cannot determine a fix, set success=false and explain in diagnosis.
      </subagent-prompt>
    </step>

    <step n="5" name="apply-fix">
      <action>Parse FIX subagent response</action>

      <check if="success == false">
        <output>❌ FIX subagent could not determine fix: {{response.diagnosis}}</output>
        <return>
          {
            "next_phase": "04-test",
            "state_updates": {
              "test_attempt": {{test_attempt + 1}}
            },
            "output": "Fix attempt {{test_attempt + 1}} failed: {{response.diagnosis}}"
          }
        </return>
      </check>

      <check if="tests_were_wrong == true">
        <output>⚠️ FIX subagent believes tests are incorrect: {{response.tests_wrong_reason}}</output>
        <action>Log this for review phase to evaluate</action>
      </check>

      <action>For EACH file in response.files:
        - Read existing file
        - Write new content
      </action>

      <action>git add .</action>
      <action>git commit -m "{{current_story}}: fix test failures (attempt {{test_attempt + 1}})"</action>

      <output>🔧 Applied fix: {{response.diagnosis}}</output>
    </step>

    <step n="6" name="re-run">
      <return>
        {
          "next_phase": "04-test",
          "state_updates": {
            "test_attempt": {{test_attempt + 1}}
          },
          "output": "Fix applied, re-running tests..."
        }
      </return>
    </step>

  </execution>

</phase>
```
