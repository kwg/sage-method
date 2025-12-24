# Phase Protocol Scripts

## Overview

Phase protocol scripts are reference implementations of the SAGE workflow lifecycle phases. They serve as executable specifications that can be validated against contracts without requiring live AI execution.

## Purpose

These scripts:
- **Define expected behavior** for each workflow phase
- **Accept JSON state via stdin** and return modified state via stdout
- **Emit signals to stderr** for observation and orchestration
- **Validate preconditions** before execution
- **Implement rollback** on failure
- **Work in isolation** without SAGE installation dependencies

## Scripts

### 1. init-phase.sh

**Purpose:** Initialize workflow session and create checkpoint state

**Contract:** `contracts/phases/init.contract.yaml`

**Preconditions:**
- No existing checkpoint.json or session.json
- Git repository with clean working tree (allows untracked files)

**Postconditions:**
- `.sage/state/` directory created
- `.sage/state/checkpoint.json` created with phase="init"
- `.sage/state/session.json` created with unique session ID

**Signals Emitted:**
- `PHASE_START`
- `CHECKPOINT` (directory_created)
- `CHECKPOINT` (checkpoint_created)
- `CHECKPOINT` (session_created)
- `PHASE_COMPLETE`

**Usage:**
```bash
echo '{}' | ./init-phase.sh > state.json 2> signals.log
```

**Example Output:**
```json
{
  "phase": "init",
  "initialized": true,
  "session_id": "session-1703174400-12345"
}
```

---

### 2. planning-phase.sh

**Purpose:** Create story files and update sprint tracking

**Contract:** `contracts/phases/planning.contract.yaml`

**Preconditions:**
- Checkpoint exists with phase="init"
- Git repository with clean working tree (allows untracked files)

**Postconditions:**
- Epic and sprint directories created
- Story markdown file created
- `sprint-status.yaml` updated with story information
- Checkpoint updated to phase="planning"

**Signals Emitted:**
- `PHASE_START`
- `CHECKPOINT` (epic_directory_created)
- `CHECKPOINT` (story_file_created)
- `CHECKPOINT` (sprint_status_updated)
- `PHASE_COMPLETE`

**Usage:**
```bash
echo '{"epic_num":"6","sprint_num":"1","story_key":"6-1-test"}' | ./planning-phase.sh > state.json 2> signals.log
```

**Example Output:**
```json
{
  "epic_num": "6",
  "sprint_num": "1",
  "story_key": "6-1-test",
  "phase": "planning",
  "story_created": true,
  "story_file": "docs/sprint-artifacts/epic-6/sprint-1/6-1-test.md"
}
```

---

### 3. implementation-phase.sh

**Purpose:** Create feature branch, implement code, and commit changes

**Contract:** `contracts/phases/implementation.contract.yaml`

**Preconditions:**
- Checkpoint exists with phase="planning" and story_created=true
- Git repository with clean working tree (allows untracked files)

**Postconditions:**
- Feature branch created and checked out
- Code changes committed
- Checkpoint updated to phase="implementation"

**Signals Emitted:**
- `PHASE_START`
- `CHECKPOINT` (branch_created)
- `CHECKPOINT` (code_written)
- `CHECKPOINT` (changes_staged)
- `CHECKPOINT` (changes_committed)
- `PHASE_COMPLETE`

**Usage:**
```bash
echo '{"story_key":"6-1-test"}' | ./implementation-phase.sh > state.json 2> signals.log
```

**Example Output:**
```json
{
  "story_key": "6-1-test",
  "phase": "implementation",
  "branch_created": true,
  "code_committed": true,
  "branch": "feature-6-1-test",
  "commit_sha": "abc123def456..."
}
```

---

### 4. validation-phase.sh

**Purpose:** Run test suite and validate implementation meets acceptance criteria

**Contract:** `contracts/phases/validation.contract.yaml`

**Preconditions:**
- Checkpoint exists with phase="implementation" and code_committed=true
- Git repository with clean working tree (allows untracked files)

**Postconditions:**
- Test suite executed (unit + integration tests)
- Coverage calculated and meets threshold
- Test results saved to `.sage/state/test-results.json`
- Checkpoint updated to phase="validation"

**Signals Emitted:**
- `PHASE_START`
- `CHECKPOINT` (tests_started)
- `CHECKPOINT` (unit_tests_passed)
- `CHECKPOINT` (integration_tests_passed)
- `CHECKPOINT` (coverage_calculated)
- `CHECKPOINT` (test_results_saved)
- `PHASE_COMPLETE`

**Usage:**
```bash
cat state.json | ./validation-phase.sh > state.json 2> signals.log
```

**Example Output:**
```json
{
  "phase": "validation",
  "tests_passed": true,
  "coverage_met": true,
  "total_tests": 15,
  "coverage_percent": 85
}
```

---

### 5. complete-phase.sh

**Purpose:** Merge feature branch, update story status, and cleanup

**Contract:** `contracts/phases/complete.contract.yaml`

**Preconditions:**
- Checkpoint exists with phase="validation" and tests_passed=true
- Git repository with clean working tree (allows untracked files)

**Postconditions:**
- Feature branch merged to main
- Story status updated to "done" in sprint-status.yaml
- Temporary files cleaned up
- Checkpoint updated to phase="complete"

**Signals Emitted:**
- `PHASE_START`
- `CHECKPOINT` (branch_merged)
- `CHECKPOINT` (story_status_updated)
- `CHECKPOINT` (cleanup_completed)
- `PHASE_COMPLETE`

**Usage:**
```bash
cat state.json | ./complete-phase.sh > state.json 2> signals.log
```

**Example Output:**
```json
{
  "phase": "complete",
  "branch_merged": true,
  "story_status": "done"
}
```

---

## Running Scripts in Isolation

### Prerequisites

All scripts require:
- `bash` (version 4.0+)
- `jq` (JSON processor)
- `git` (version 2.0+)
- Standard Unix utilities (`date`, `mkdir`, `rm`, etc.)

### Isolated Test Environment

Scripts are designed to run in any directory with git initialized:

```bash
# Create test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Initialize git repository
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Run phase scripts
echo '{}' | /path/to/init-phase.sh > state.json 2> signals.log

# Cleanup
cd /
rm -rf "$TEST_DIR"
```

### Environment Variables

**SAGE_TEST_MODE** (optional):
- Set to `1` to enable test mode
- Scripts may skip certain validations in test mode
- Not currently used but reserved for future enhancements

Example:
```bash
export SAGE_TEST_MODE=1
echo '{}' | ./init-phase.sh
```

## State Flow

State is passed between phases via JSON:

```
{}  →  init-phase.sh  →  {phase:"init",...}
                          ↓
                    planning-phase.sh  →  {phase:"planning",...}
                          ↓
                 implementation-phase.sh  →  {phase:"implementation",...}
                          ↓
                   validation-phase.sh  →  {phase:"validation",...}
                          ↓
                    complete-phase.sh  →  {phase:"complete",...}
```

Each phase:
1. Reads state from stdin
2. Validates preconditions
3. Performs operations
4. Emits signals to stderr
5. Returns updated state to stdout

## Signal Flow

Signals are emitted to stderr as JSON lines:

```bash
# Run script and capture both state and signals
STATE=$(echo '{}' | ./init-phase.sh 2>signals.json)

# Parse signals
jq -s '.' signals.json
```

**Signal Format:**
```json
{
  "signal": "CHECKPOINT",
  "payload": {
    "phase": "init",
    "operation": "directory_created",
    "timestamp": "2025-12-21T10:30:00Z"
  }
}
```

See `contracts/SIGNAL_REGISTRY.md` for complete signal documentation.

## Error Handling

### Exit Codes

- **0**: Success
- **1**: Precondition failure (expected error)
- **2**: Mid-execution failure (unexpected error)
- **3**: Merge conflict or other recoverable error

### Error Signals

Before exiting with non-zero code, scripts emit an ERROR signal:

```json
{
  "signal": "ERROR",
  "payload": {
    "phase": "init",
    "error_type": "precondition_failed",
    "message": "Precondition failed: checkpoint already exists",
    "error_code": 1,
    "timestamp": "2025-12-21T10:30:00Z"
  }
}
```

### Rollback on Failure

Scripts implement automatic rollback using `trap`:

```bash
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        emit_signal "ROLLBACK" '{"status":"started"}'
        # Perform rollback operations...
        emit_signal "ROLLBACK" '{"status":"completed"}'
    fi
}
trap cleanup EXIT
```

## Contract Validation

Scripts are designed to satisfy their corresponding contracts in `contracts/phases/`. To validate:

1. Run script in test environment
2. Capture state (stdout) and signals (stderr)
3. Verify postconditions against state and filesystem
4. Verify signals match expected emissions
5. Test failure conditions by violating preconditions

See Story 6.2 for contract validation test implementation.

## Complete Workflow Example

```bash
#!/usr/bin/env bash
# Run complete workflow lifecycle

set -euo pipefail

# Create test environment
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
git config user.email "test@example.com"
git config user.name "Test User"
git commit --allow-empty -m "Initial commit"

# Set script directory
SCRIPTS="/path/to/sage/scripts/phase-protocols"

# Phase 1: Init
echo "=== INIT PHASE ==="
STATE=$(echo '{}' | "$SCRIPTS/init-phase.sh" 2>init-signals.json)
echo "$STATE" | jq .

# Phase 2: Planning
echo "=== PLANNING PHASE ==="
STATE=$(echo "$STATE" | jq '. + {epic_num:"1",sprint_num:"1",story_key:"1-1-test"}' | "$SCRIPTS/planning-phase.sh" 2>planning-signals.json)
echo "$STATE" | jq .

# Phase 3: Implementation
echo "=== IMPLEMENTATION PHASE ==="
STATE=$(echo "$STATE" | "$SCRIPTS/implementation-phase.sh" 2>implementation-signals.json)
echo "$STATE" | jq .

# Phase 4: Validation
echo "=== VALIDATION PHASE ==="
STATE=$(echo "$STATE" | "$SCRIPTS/validation-phase.sh" 2>validation-signals.json)
echo "$STATE" | jq .

# Phase 5: Complete
echo "=== COMPLETE PHASE ==="
STATE=$(echo "$STATE" | "$SCRIPTS/complete-phase.sh" 2>complete-signals.json)
echo "$STATE" | jq .

echo "=== WORKFLOW COMPLETE ==="

# Cleanup
cd /
rm -rf "$TEST_DIR"
```

## ShellCheck Compliance

All scripts are designed to pass ShellCheck static analysis:

```bash
shellcheck -x *.sh
```

Common patterns followed:
- Quote all variable expansions: `"$VAR"`
- Use `[[ ]]` for conditionals
- Explicit error handling with `set -euo pipefail`
- Trap cleanup handlers
- Validate external commands before use

## Testing

Phase protocol scripts will be tested in Story 6.2 using BATS (Bash Automated Testing System).

Test structure:
```bash
@test "init-phase: creates checkpoint.json" {
    setup_test_repo
    echo '{}' | ./init-phase.sh > output.json
    [ -f .sage/state/checkpoint.json ]
    jq -e '.phase == "init"' .sage/state/checkpoint.json
}
```

See `sage/scripts/tests/` for existing BATS test examples.

## Dependencies

**Required:**
- bash (4.0+)
- jq (1.5+)
- git (2.0+)
- coreutils (date, mkdir, rm, etc.)

**Optional:**
- shellcheck (for static analysis)
- bats (for testing)

## License

Part of SAGE (Stateless Agent Guidance Engine)
See project LICENSE file.

## Version History

- **v1.0** (2025-12-21): Initial phase protocol implementation
  - 5 phase scripts: init, planning, implementation, validation, complete
  - Signal emission protocol
  - Rollback handling
  - Isolated execution support
