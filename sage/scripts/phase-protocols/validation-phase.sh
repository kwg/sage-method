#!/usr/bin/env bash
# validation-phase.sh - Run test suite and validate implementation meets acceptance criteria
# Part of SAGE workflow lifecycle testing framework
# See: contracts/phases/validation.contract.yaml

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed" >&2; exit 2; }

# Track created artifacts for rollback
COVERAGE_DIR_CREATED=false

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        # Rollback on failure
        emit_signal "ROLLBACK" '{"status":"started","reason":"validation phase failed"}'

        # Remove coverage directory if we created it
        if [ "$COVERAGE_DIR_CREATED" = true ] && [ -d coverage ]; then
            rm -rf coverage 2>/dev/null || true
        fi

        # Remove test results if created
        rm -f .sage/state/test-results.json 2>/dev/null || true

        emit_signal "ROLLBACK" '{"status":"completed"}'
    fi
}
trap cleanup EXIT

# Helper: Emit signal to stderr
emit_signal() {
    local signal_name="$1"
    local payload="${2:-{}}"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)

    echo "{\"signal\":\"$signal_name\",\"payload\":$(echo "$payload" | jq -c ". + {phase:\"validation\",timestamp:\"$timestamp\"}")}" >&2
}

# Helper: Emit error and exit
emit_error() {
    local error_type="$1"
    local message="$2"
    local code="${3:-2}"

    emit_signal "ERROR" "{\"error_type\":\"$error_type\",\"message\":\"$message\",\"error_code\":$code}"
    exit "$code"
}

# Read input state from stdin
STATE=$(cat)

# Validate input is valid JSON
if ! echo "$STATE" | jq -e . >/dev/null 2>&1; then
    emit_error "validation_error" "Input state is not valid JSON" 2
fi

# Precondition: checkpoint.json must exist
if [ ! -f .sage/state/checkpoint.json ]; then
    emit_error "precondition_failed" "Precondition failed: .sage/state/checkpoint.json does not exist" 1
fi

# Precondition: checkpoint phase must be 'implementation'
CHECKPOINT_PHASE=$(jq -r '.phase' .sage/state/checkpoint.json 2>/dev/null || echo "")
if [ "$CHECKPOINT_PHASE" != "implementation" ]; then
    emit_error "precondition_failed" "Precondition failed: checkpoint phase is '$CHECKPOINT_PHASE', expected 'implementation'" 1
fi

# Precondition: code_committed must be true
CODE_COMMITTED=$(jq -r '.code_committed' .sage/state/checkpoint.json 2>/dev/null || echo "false")
if [ "$CODE_COMMITTED" != "true" ]; then
    emit_error "precondition_failed" "Precondition failed: code not committed (code_committed != true)" 1
fi

# Precondition: git status should be clean (allow untracked files)
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    emit_error "precondition_failed" "Precondition failed: not in a git repository" 1
fi

if [ -n "$(git status --porcelain | grep -v '^??')" ]; then
    emit_error "precondition_failed" "Precondition failed: working tree has staged or unstaged changes" 1
fi

# Emit PHASE_START signal
emit_signal "PHASE_START" "{}"

# Emit tests started checkpoint
emit_signal "CHECKPOINT" "{\"operation\":\"tests_started\"}"

# Simulate running unit tests
UNIT_TESTS_RUN=10
UNIT_TESTS_PASSED=10
sleep 0.1  # Simulate test execution time

if [ $UNIT_TESTS_PASSED -ne $UNIT_TESTS_RUN ]; then
    emit_error "tests_failed" "Unit tests failed: $UNIT_TESTS_PASSED/$UNIT_TESTS_RUN passed" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"unit_tests_passed\",\"details\":{\"tests_run\":$UNIT_TESTS_RUN,\"tests_passed\":$UNIT_TESTS_PASSED}}"

# Simulate running integration tests
INTEGRATION_TESTS_RUN=5
INTEGRATION_TESTS_PASSED=5
sleep 0.1  # Simulate test execution time

if [ $INTEGRATION_TESTS_PASSED -ne $INTEGRATION_TESTS_RUN ]; then
    emit_error "tests_failed" "Integration tests failed: $INTEGRATION_TESTS_PASSED/$INTEGRATION_TESTS_RUN passed" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"integration_tests_passed\",\"details\":{\"tests_run\":$INTEGRATION_TESTS_RUN,\"tests_passed\":$INTEGRATION_TESTS_PASSED}}"

# Simulate coverage calculation
COVERAGE_PERCENT=85
COVERAGE_THRESHOLD=80

if [ $COVERAGE_PERCENT -lt $COVERAGE_THRESHOLD ]; then
    emit_error "coverage_below_threshold" "Coverage $COVERAGE_PERCENT% is below threshold $COVERAGE_THRESHOLD%" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"coverage_calculated\",\"details\":{\"coverage_percent\":$COVERAGE_PERCENT,\"threshold\":$COVERAGE_THRESHOLD}}"

# Create coverage directory (simulate)
mkdir -p coverage
COVERAGE_DIR_CREATED=true

# Create coverage report (simulate)
cat > coverage/coverage.json <<EOF
{
  "coverage_percent": $COVERAGE_PERCENT,
  "threshold": $COVERAGE_THRESHOLD,
  "lines_covered": 850,
  "lines_total": 1000,
  "timestamp": "$(date -Iseconds)"
}
EOF

# Create test results
TOTAL_TESTS=$((UNIT_TESTS_RUN + INTEGRATION_TESTS_RUN))
TOTAL_PASSED=$((UNIT_TESTS_PASSED + INTEGRATION_TESTS_PASSED))

TEST_RESULTS=$(jq -n \
    --arg timestamp "$(date -Iseconds)" \
    --argjson unit_run "$UNIT_TESTS_RUN" \
    --argjson unit_passed "$UNIT_TESTS_PASSED" \
    --argjson integration_run "$INTEGRATION_TESTS_RUN" \
    --argjson integration_passed "$INTEGRATION_TESTS_PASSED" \
    --argjson total_run "$TOTAL_TESTS" \
    --argjson total_passed "$TOTAL_PASSED" \
    --argjson coverage "$COVERAGE_PERCENT" \
    '{
        timestamp: $timestamp,
        unit_tests: {run: $unit_run, passed: $unit_passed},
        integration_tests: {run: $integration_run, passed: $integration_passed},
        total_tests: {run: $total_run, passed: $total_passed},
        coverage_percent: $coverage,
        all_passed: ($total_run == $total_passed)
    }')

echo "$TEST_RESULTS" > .sage/state/test-results.json
emit_signal "CHECKPOINT" "{\"operation\":\"test_results_saved\",\"details\":{\"file\":\".sage/state/test-results.json\"}}"

# Update checkpoint
CHECKPOINT=$(jq -c ". + {phase:\"validation\",tests_passed:true,coverage_met:true,total_tests:$TOTAL_TESTS,coverage_percent:$COVERAGE_PERCENT,timestamp:\"$(date -Iseconds)\"}" .sage/state/checkpoint.json)
echo "$CHECKPOINT" > .sage/state/checkpoint.json

# Emit PHASE_COMPLETE signal
emit_signal "PHASE_COMPLETE" "{\"success\":true}"

# Return new state to stdout
echo "$STATE" | jq -c ". + {phase:\"validation\",tests_passed:true,coverage_met:true,total_tests:$TOTAL_TESTS,coverage_percent:$COVERAGE_PERCENT}"
