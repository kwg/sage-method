# QA Testing Quick Commands

**Used by:** qa-tester agent
**Description:** Testing commands for game QA automation

---

## smoke-test

**Description:** Run quick smoke test to verify game launches

**Instructions:**
1. Launch game with: godot4 --path . -- --agent-mode 2>&1 &
2. Wait 4 seconds for startup
3. Send commands:
   - game scene
   - screenshot smoke_launch
   - game goto map
   - wait 1000
   - game scene
   - screenshot smoke_map
4. Verify no SCRIPT ERROR in output
5. Kill game process
6. Report results

---

## test-combat

**Description:** Test combat system functionality

**Instructions:**
1. Launch game in agent mode
2. Run combat_basic test suite from agent_config.json
3. Verify:
   - Cards can be played
   - Flash cards appear and accept answers
   - Turn counter increments
   - Damage is calculated correctly
4. Capture screenshots at each phase
5. Report results with state logs

---

## test-map

**Description:** Test map display and navigation

**Instructions:**
1. Launch game in agent mode
2. Navigate to map: game goto map
3. Query state: game map_state
4. Verify LAYER_COUNT and AVAILABLE_NODES in output
5. Try selecting a node: game select_node L1N0
6. Capture screenshots
7. Report results

---

## test-flow

**Description:** Test complete game flow from start to combat

**Instructions:**
1. Launch game in agent mode
2. Navigate to map
3. Select first available combat node
4. Play a full turn with flash cards
5. Verify state after turn (TURN: 2)
6. Capture screenshots at each step
7. Report full flow results

---

## verify-story

**Description:** Verify a specific story's agent_tests work

**Instructions:**
1. Read the story file specified by user
2. Parse the ## Agent Tests section
3. Execute each test's commands
4. Verify expected state per ## Verify section
5. Capture screenshots
6. Report pass/fail for each test
