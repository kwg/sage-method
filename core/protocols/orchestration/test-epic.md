# Protocol: Test Epic

**Purpose**: Run a test/demo epic to validate SAGE functionality.

## Overview

This protocol runs a minimal test epic to verify:
1. Configuration loading works
2. Agent spawning works
3. Checkpoint save/resume works
4. GitHub integration works (optional)

## Test Epic Specification

```yaml
name: "SAGE Test Epic"
stories:
  - key: "test-1"
    title: "Verify config loading"
    tasks:
      - Load project-sage/config.yaml
      - Verify user_name resolves
      - Verify project_root resolves

  - key: "test-2"
    title: "Verify checkpoint"
    tasks:
      - Write checkpoint
      - Clear context
      - Resume from checkpoint
      - Verify state restored

  - key: "test-3"
    title: "Verify subagent spawn"
    tasks:
      - Spawn Dev agent with test task
      - Verify agent responds
      - Parse agent output
```

## Execution Steps

### Step 1: Create Test Directory

```bash
mkdir -p .sage/test-runs/{date}/
```

### Step 2: Run Test Stories

Execute each test story, capturing results.

### Step 3: Generate Report

```
SAGE Test Results
═══════════════════════════════════════
Config Loading:     [PASS/FAIL]
Checkpoint:         [PASS/FAIL]
Subagent Spawn:     [PASS/FAIL]
GitHub (optional):  [PASS/FAIL/SKIP]
═══════════════════════════════════════
Overall: {PASS/FAIL}
```

### Step 4: Cleanup

Remove test artifacts (or keep with --keep-artifacts flag).

## TODO

- [ ] Implement actual test execution
- [ ] Add GitHub integration tests
- [ ] Add performance benchmarks
- [ ] Support custom test suites
