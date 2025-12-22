# Phase 05: Integration Tests (TESTER Subagent)

```xml
<phase id="05-integration" name="Visual Integration Tests">

  <purpose>
    Spawn TESTER subagent to launch the game and verify story implementation
    works visually. Uses agent_tests section from story file if present.
  </purpose>

  <input>
    {{state}} with:
    - current_story: story ID
    - story_path: path to story file
  </input>

  <preconditions>
    - Unit tests have been attempted (or skipped)
    - On story branch
  </preconditions>

  <execution>

    <step n="1" name="check-agent-tests">
      <action>Read story file at {{story_path}}</action>
      <action>Look for ## Agent Tests or agent_tests: section</action>

      <check if="no agent_tests section found">
        <output>ℹ️ No agent_tests defined for this story - skipping visual verification</output>
        <action>Update story metrics: integration_tests_passed = null</action>
        <return>
          {
            "next_phase": "06-review",
            "state_updates": {
              "metrics": {{updated_metrics}}
            },
            "output": "No integration tests defined. Skipping to review."
          }
        </return>
      </check>

      <action>Parse agent_tests section:
        - List of test scenarios
        - Commands to execute
        - Expected state to verify
      </action>
    </step>

    <step n="2" name="spawn-tester">
      <output>🎮 **Spawning TESTER Subagent for Visual Verification...**</output>

      <action>Use Task tool with subagent_type="general-purpose"</action>

      <subagent-prompt>
You are a VISUAL INTEGRATION TESTER. Your job is to verify the story implementation works by running the game.

## Story File
Read this file: {{story_path}}

## Agent Tests Section
{{agent_tests_content}}

## Testing Framework Reference
Read: docs/workflows/agent-testing-workflow.md (if exists)

## Your Task

1. Launch the game in agent mode:
   ```bash
   CMDFILE="$HOME/.local/share/godot/app_userdata/Critical Calculations/agent_commands.txt"
   rm -f "$CMDFILE"
   godot4 --path . -- --agent-mode 2>&1 &
   GAME_PID=$!
   sleep 4
   ```

2. Execute the test commands from agent_tests section:
   - Send each command: `echo "command" >> "$CMDFILE"`
   - Wait appropriate time between commands (sleep 1-2)
   - Capture screenshots at verification points if needed

3. Parse game output for:
   - AGENT_STATE_* blocks for state verification
   - SCRIPT ERROR for failures
   - Expected state values per the verify section

4. Cleanup:
   ```bash
   kill $GAME_PID 2>/dev/null || true
   ```

5. If screenshots were captured, read them to verify visual state

## Output Format

Return JSON ONLY:
```json
{
  "success": true,
  "tests_run": 3,
  "tests_passed": 3,
  "tests_failed": 0,
  "results": [
    {
      "name": "test_name_from_agent_tests",
      "passed": true,
      "commands_executed": 5,
      "verifications": [
        {"check": "SCENE_TYPE: map", "expected": "map", "found": "map", "passed": true}
      ],
      "screenshots": [],
      "notes": "optional notes"
    }
  ],
  "errors": [],
  "game_output": "relevant portions of game output",
  "summary": "All visual tests passed. Feature works as expected."
}
```

If game fails to launch or tests cannot run, set success=false and describe in errors array.
      </subagent-prompt>
    </step>

    <step n="3" name="process-results">
      <action>Parse TESTER response</action>

      <check if="success == false OR tests_failed > 0">
        <output>⚠️ Integration tests had issues:
{{for result in response.results where not result.passed}}
- {{result.name}}: {{result.notes}}
{{endfor}}

Errors: {{response.errors | join(", ")}}
        </output>
        <action>Update story metrics: integration_tests_passed = false</action>
      </check>

      <check if="success == true AND tests_failed == 0">
        <output>✅ Visual integration tests passed: {{response.tests_passed}}/{{response.tests_run}}</output>
        <action>Update story metrics: integration_tests_passed = true</action>
      </check>
    </step>

  </execution>

  <output>
🎮 **Integration Test Results**

Tests: {{response.tests_passed}}/{{response.tests_run}} passed
Summary: {{response.summary}}

Proceeding to code review...
  </output>

  <return>
    {
      "next_phase": "06-review",
      "state_updates": {
        "metrics": {{updated_metrics}}
      },
      "output": "{{output_text}}"
    }
  </return>

</phase>
```
