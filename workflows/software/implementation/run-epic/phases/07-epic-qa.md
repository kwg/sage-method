# Phase 07: Epic QA (Mandatory Smoke Test)

```xml
<phase id="07-epic-qa" name="Epic QA">

  <purpose>
    Run mandatory smoke tests on the complete epic.
    Optionally run regression tests if configured.
    This phase is MANDATORY - cannot be skipped.
  </purpose>

  <input>
    {{state}} with:
    - epic_id: epic identifier
    - epic_branch: current git branch
    - completed_stories: list of completed story IDs
  </input>

  <preconditions>
    - All stories complete (or failed/skipped)
    - On epic branch
  </preconditions>

  <execution>

    <step n="1" name="prepare-qa">
      <output>🎯 **Epic QA (Mandatory)**

Epic: {{epic_id}}
Stories completed: {{completed_stories.length}}/{{story_queue.length}}
Branch: {{epic_branch}}

Running smoke tests...
      </output>

      <action>
        metrics_collector:
          action: record_start
          operation: "epic_qa"
          epic_id: {{epic_id}}
      </action>
    </step>

    <step n="2" name="run-smoke-tests">
      <action>Detect smoke test command:
        - If package.json has "test:smoke": npm run test:smoke
        - If pytest with markers: pytest -m smoke
        - If scripts/smoke-test.sh exists: run it
        - Fallback: npm test (or equivalent)
      </action>

      <action>Run smoke test command, capture output</action>
    </step>

    <step n="3" name="analyze-smoke-results">
      <action>Parse smoke test output for:
        - Total tests
        - Passed tests
        - Failed tests
        - Critical path coverage
      </action>

      <check if="smoke tests pass">
        <output>✅ Smoke tests passing!</output>
      </check>

      <check if="smoke tests fail">
        <output>❌ Smoke tests FAILED

{{smoke_test_output}}
        </output>

        <action>
          learning_recorder:
            action: record_failure
            failure:
              type: "test"
              context:
                phase: "07-epic-qa"
                epic_id: {{epic_id}}
                error: "Smoke tests failed"
              retry_count: 0
        </action>

        <action>Ask user: attempt fix, skip QA, or abort?</action>

        <check if="user chooses abort">
          <return>
            {
              "next_phase": "08-finalize",
              "state_updates": {
                "error": "smoke_tests_failed",
                "metrics": {{updated_metrics}}
              },
              "output": "Smoke tests failed. Proceeding to finalize with error state..."
            }
          </return>
        </check>
      </check>
    </step>

    <step n="4" name="run-regression-tests">
      <check if="regression tests configured">
        <output>🔄 Running regression tests...</output>

        <action>Detect regression test command:
          - If package.json has "test:regression": npm run test:regression
          - If pytest: pytest --ignore=tests/smoke
          - Fallback: full test suite
        </action>

        <action>Run regression tests, capture output</action>

        <check if="regression tests fail">
          <output>⚠️ Regression tests failed:

{{regression_output}}

Note: Smoke tests passed - core functionality works.
Regression failures are logged but don't block finalization.
          </output>

          <action>
            learning_recorder:
              action: record_failure
              failure:
                type: "test"
                context:
                  phase: "07-epic-qa"
                  epic_id: {{epic_id}}
                  error: "Regression tests failed"
          </action>
        </check>
      </check>
    </step>

    <step n="5" name="spawn-tester">
      <check if="integration_tests_defined">
        <output>🧪 Running integration tests via TESTER subagent...</output>

        <action>
          subagent_spawner:
            action: spawn
            subagent_type: "TESTER"
            context:
              epic_id: {{epic_id}}
              completed_stories: {{completed_stories}}
              test_type: "integration"
            output_schema:
              type: "test_result"
        </action>

        <subagent-prompt>
You are an INTEGRATION TEST SPECIALIST. Verify the epic works as a whole.

## Epic Context
Epic ID: {{epic_id}}
Stories completed: {{completed_stories | join(", ")}}

## Your Goal
1. Run integration tests that verify cross-story functionality
2. Check that components work together correctly
3. Verify API contracts are maintained
4. Check database migrations (if applicable)

## Instructions
1. Identify integration test files
2. Run integration test suite
3. Analyze results and identify any integration failures
4. Report on overall integration health

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "tests_passed": 15,
  "tests_failed": 0,
  "integration_health": "good",
  "notes": "All integrations working correctly"
}
```
        </subagent-prompt>
      </check>
    </step>

    <step n="6" name="record-qa-metrics">
      <action>
        metrics_collector:
          action: record_end
          operation: "epic_qa"
          epic_id: {{epic_id}}
      </action>

      <action>Update metrics.summary:
        - smoke_tests_passed: {{smoke_passed}}
        - regression_tests_passed: {{regression_passed}}
        - integration_tests_passed: {{integration_passed}}
      </action>
    </step>

  </execution>

  <output>
✅ **Epic QA Complete**

Smoke Tests: {{smoke_passed ? "PASSED ✓" : "FAILED ✗"}}
Regression Tests: {{regression_passed ? "PASSED ✓" : "SKIPPED/FAILED"}}
Integration Tests: {{integration_passed ? "PASSED ✓" : "SKIPPED/FAILED"}}

Proceeding to finalization...
  </output>

  <return>
    {
      "next_phase": "08-finalize",
      "state_updates": {
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
