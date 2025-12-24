# Full QA Test Suite Workflow

```xml
<critical>VERSION 1.0: Comprehensive automated QA testing via agent framework</critical>
<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {installed_path}/workflow.yaml</critical>
<critical>This workflow launches the game and exercises ALL features autonomously</critical>

<workflow>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 1: INITIALIZATION                                                     -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="0" goal="Initialize QA session and load test configuration" tag="init">
    <critical>Load test suites from agent_config.json</critical>
    <critical>Check for epic-specific QA manifest</critical>

    <action>Load agent config from: {{agent_config}}</action>
    <action>Parse qa_test_suites section</action>

    <action>Check for QA manifest:
      - Look in {{sprint_artifacts}}/epic-*/qa-manifest.yaml
      - If found, parse custom tests and suite selections
      - If not found, use default suites from agent_config.json
    </action>

    <action>Initialize QA state:
      - {{qa_start_time}} = current timestamp
      - {{suites_to_run}} = selected test suites
      - {{total_tests}} = 0
      - {{tests_passed}} = 0
      - {{tests_failed}} = 0
      - {{screenshots}} = []
      - {{errors}} = []
    </action>

    <action>Create output directories:
      - mkdir -p {{qa_output_dir}}
      - mkdir -p {{screenshots_dir}}
    </action>

    <output>🧪 **Full QA Test Suite Initialized**

Suites to run: {{suites_to_run}}
Output: {{qa_output_dir}}
Screenshots: {{screenshots_dir}}

Beginning test execution...
    </output>

    <goto step="1">Launch game</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 2: GAME LAUNCH                                                        -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="1" goal="Launch game in agent mode" tag="launch">
    <critical>Game must be running before any tests can execute</critical>

    <action>Clean up any previous command file:
      ```bash
      CMDFILE="$HOME/.local/share/godot/app_userdata/Critical Calculations/agent_commands.txt"
      rm -f "$CMDFILE"
      ```
    </action>

    <action>Launch game in background with agent mode:
      ```bash
      godot4 --path {{project_path}} -- --agent-mode 2>&1 &
      GAME_PID=$!
      echo "Game PID: $GAME_PID"
      sleep 4
      ```
    </action>

    <action>Store {{game_pid}} for cleanup</action>

    <action>Verify game launched successfully:
      - Check for "AgentInput enabled" in logs
      - Check for SCRIPT ERROR (immediate failure)
    </action>

    <check if="SCRIPT ERROR in startup">
      <output>❌ Game failed to launch - critical error in startup</output>
      <action>Record error in {{errors}}</action>
      <goto step="99">Cleanup and report</goto>
    </check>

    <output>🎮 Game launched (PID: {{game_pid}})</output>

    <goto step="2">Run test suites</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 3: TEST SUITE EXECUTION                                               -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="2" goal="Execute test suites in order" tag="run-suites">
    <critical>Run each suite's tests sequentially</critical>
    <critical>Capture state and screenshots for verification</critical>

    <action>Set {{current_suite_index}} = 0</action>

    <loop while="{{current_suite_index}} < length({{suites_to_run}})">
      <action>Get {{current_suite}} = {{suites_to_run}}[{{current_suite_index}}]</action>
      <action>Get {{suite_tests}} from agent_config.json qa_test_suites[{{current_suite}}].tests</action>

      <output>📋 **Running Suite: {{current_suite}}**
Tests: {{length(suite_tests)}}
      </output>

      <action>Set {{current_test_index}} = 0</action>

      <loop while="{{current_test_index}} < length({{suite_tests}})">
        <action>Get {{current_test}} = {{suite_tests}}[{{current_test_index}}]</action>
        <action>Increment {{total_tests}}</action>

        <output>  🔹 Test: {{current_test.name}}</output>

        <!-- Execute test commands -->
        <action>For EACH command in {{current_test.commands}}:
          ```bash
          echo "{{command}}" >> "$CMDFILE"
          ```
          - Add appropriate sleep between commands (500-2000ms depending on command)
        </action>

        <!-- Wait for command execution -->
        <action>sleep 3 (allow commands to process)</action>

        <!-- Capture state for verification -->
        <action>Parse game output for:
          - AGENT_STATE_* blocks
          - AGENT_SCENE_* blocks
          - AGENT_MAP_STATE_* blocks
          - SCRIPT ERROR
        </action>

        <!-- Verify expected conditions -->
        <action>For EACH verification in {{current_test.verify}}:
          - Search for expected pattern in captured output
          - Record pass/fail
        </action>

        <check if="all verifications pass AND no SCRIPT ERROR">
          <action>Increment {{tests_passed}}</action>
          <output>    ✅ PASS</output>
        </check>

        <check if="any verification fails OR SCRIPT ERROR">
          <action>Increment {{tests_failed}}</action>
          <action>Add failure details to {{errors}}</action>
          <output>    ❌ FAIL: {{failure_reason}}</output>
        </check>

        <!-- Capture screenshot evidence -->
        <action>Copy screenshot from user://screenshots/ to {{screenshots_dir}}</action>
        <action>Add screenshot path to {{screenshots}}</action>

        <action>Increment {{current_test_index}}</action>
      </loop>

      <action>Increment {{current_suite_index}}</action>
    </loop>

    <goto step="3">Run full flow test</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 4: FULL FLOW TEST                                                     -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="3" goal="Run complete game flow test" tag="full-flow">
    <critical>Tests the full gameplay loop end-to-end</critical>

    <output>🔄 **Running Full Flow Test**
Start run → Navigate map → Enter combat → Complete turn → Victory/Defeat
    </output>

    <action>Clear command file</action>

    <action>Execute full flow sequence:
      ```bash
      # Navigate to map
      echo "game goto map" >> "$CMDFILE"
      sleep 2
      echo "game map_state" >> "$CMDFILE"
      echo "screenshot flow_1_map" >> "$CMDFILE"
      sleep 1

      # Select first available node
      echo "game select_node L1N0" >> "$CMDFILE"
      sleep 3
      echo "game scene" >> "$CMDFILE"
      echo "screenshot flow_2_node_selected" >> "$CMDFILE"
      sleep 1

      # If in combat, play a turn
      echo "game state" >> "$CMDFILE"
      sleep 1
      echo "game play_card 0 0" >> "$CMDFILE"
      echo "game play_card 0 0" >> "$CMDFILE"
      echo "game play_card 0 0" >> "$CMDFILE"
      echo "game end_turn" >> "$CMDFILE"
      sleep 1
      echo "game answer_correct" >> "$CMDFILE"
      sleep 1
      echo "game answer_correct" >> "$CMDFILE"
      sleep 1
      echo "game answer_correct" >> "$CMDFILE"
      sleep 4
      echo "game state" >> "$CMDFILE"
      echo "screenshot flow_3_turn_complete" >> "$CMDFILE"
      sleep 2
      ```
    </action>

    <action>Parse output and verify:
      - Map displayed correctly (LAYER_COUNT, AVAILABLE_NODES)
      - Combat entered (SCENE_TYPE: combat)
      - Turn completed (TURN: 2)
      - No SCRIPT ERROR throughout
    </action>

    <action>Record full flow result</action>

    <goto step="99">Generate report</goto>
  </step>

  <!-- ═══════════════════════════════════════════════════════════════════════════ -->
  <!-- PHASE 5: CLEANUP AND REPORTING                                              -->
  <!-- ═══════════════════════════════════════════════════════════════════════════ -->

  <step n="99" goal="Kill game, generate report, save results" tag="cleanup">
    <critical>Always kill game process</critical>
    <critical>Generate comprehensive report</critical>

    <action>Kill game process:
      ```bash
      kill {{game_pid}} 2>/dev/null || true
      pkill -f "godot4.*agent-mode" 2>/dev/null || true
      ```
    </action>

    <action>Record {{qa_end_time}} = current timestamp</action>
    <action>Calculate {{duration}} = {{qa_end_time}} - {{qa_start_time}}</action>

    <action>Generate QA report JSON:
      ```json
      {
        "success": {{tests_failed}} == 0,
        "timestamp": "{{qa_start_time}}",
        "duration_ms": {{duration}},
        "suites_run": {{suites_to_run}},
        "summary": {
          "total_tests": {{total_tests}},
          "tests_passed": {{tests_passed}},
          "tests_failed": {{tests_failed}},
          "pass_rate": {{tests_passed / total_tests * 100}}%
        },
        "failures": {{errors}},
        "screenshots": {{screenshots}}
      }
      ```
    </action>

    <action>Save report to: {{qa_output_dir}}/qa-report-{{timestamp}}.json</action>

    <check if="{{tests_failed}} > 0">
      <output>❌ **QA SUITE FAILED**

## Summary
- Total Tests: {{total_tests}}
- Passed: {{tests_passed}}
- Failed: {{tests_failed}}
- Pass Rate: {{pass_rate}}%
- Duration: {{duration}}ms

## Failures
{{failures_formatted}}

## Screenshots
Saved to: {{screenshots_dir}}

## Recommendations
{{recommendations_based_on_failures}}
      </output>
    </check>

    <check if="{{tests_failed}} == 0">
      <output>✅ **QA SUITE PASSED**

## Summary
- Total Tests: {{total_tests}}
- Passed: {{tests_passed}}
- Failed: {{tests_failed}}
- Pass Rate: 100%
- Duration: {{duration}}ms

## Screenshots
Saved to: {{screenshots_dir}}

All features verified working correctly.
      </output>
    </check>
  </step>

</workflow>
```

## Test Suites Reference

### Default Suites (from agent_config.json)

| Suite | Description | Tests |
|-------|-------------|-------|
| smoke | Quick launch and navigation check | game_launch, map_navigation |
| combat_basic | Basic combat functionality | play_cards_and_execute |
| map_full | Full map testing | map_display |

### Custom Tests via QA Manifest

Create `docs/sprint-artifacts/epic-{n}/qa-manifest.yaml`:

```yaml
epic_id: 4
epic_title: "Run Structure"

suites:
  - smoke
  - combat_basic
  - map_full

custom_tests:
  - name: "shop_flow"
    description: "Test shop purchase flow"
    commands:
      - "game goto shop"
      - "wait 1000"
      - "game click_button BuyButton"
      - "screenshot shop_purchase"
    verify:
      - "SCENE_TYPE: shop"

regression:
  - suite: combat_basic

full_flow:
  name: "complete_run"
  description: "Full run from start to boss"
  commands:
    - "game goto map"
    - "..."
```

## Running the Workflow

Invoke from the QA Tester agent:
```
*full-qa
```

Or specify an epic:
```
*full-qa epic-4
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-15 | Initial version extracted from run-epic workflow |
