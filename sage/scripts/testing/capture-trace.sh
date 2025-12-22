#!/usr/bin/env bash
# capture-trace.sh - Capture workflow execution trace for validation
# Part of SAGE workflow lifecycle testing framework
#
# Usage: ./capture-trace.sh <workflow-name> [options]
#
# This script wraps workflow execution and captures a detailed trace of:
# - Phase transitions with timestamps
# - Signals emitted during execution
# - Duration of each phase
# - Final outcome and artifacts
#
# The trace file can be compared against contracts to validate behavior.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_EXECUTOR="$SCRIPT_DIR/../workflow-executor.sh"
CONTRACTS_DIR="$SCRIPT_DIR/../../../contracts/workflows"
TRACES_DIR="$SCRIPT_DIR/../../../docs/testing/traces"

# Trace state
TRACE_FILE=""
WORKFLOW_NAME=""
START_TIME=""
PHASES=()
CURRENT_PHASE=""
PHASE_START_TIME=""
PHASE_SIGNALS=()

#######################################
# Utility Functions
#######################################

log_info() {
    echo "[TRACE] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

get_timestamp() {
    date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z
}

get_epoch_ms() {
    # Get epoch time in milliseconds
    if command -v gdate >/dev/null 2>&1; then
        gdate +%s%3N
    elif date --version 2>&1 | grep -q GNU; then
        date +%s%3N
    else
        # Fallback: seconds * 1000
        echo $(($(date +%s) * 1000))
    fi
}

#######################################
# Trace Recording
#######################################

init_trace() {
    local workflow="$1"

    WORKFLOW_NAME="$workflow"
    START_TIME=$(get_timestamp)

    mkdir -p "$TRACES_DIR"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    TRACE_FILE="$TRACES_DIR/trace-${workflow}-${timestamp}.json"

    log_info "Initializing trace: $TRACE_FILE"
    log_info "Workflow: $WORKFLOW_NAME"
    log_info "Started: $START_TIME"
}

start_phase() {
    local phase="$1"

    CURRENT_PHASE="$phase"
    PHASE_START_TIME=$(get_epoch_ms)
    PHASE_SIGNALS=()

    log_info "Phase started: $phase"
}

record_signal() {
    local signal="$1"
    PHASE_SIGNALS+=("$signal")
    log_info "  Signal: $signal"
}

complete_phase() {
    local outcome="${1:-success}"

    local end_time
    end_time=$(get_epoch_ms)
    local duration=$((end_time - PHASE_START_TIME))

    local signals_json
    signals_json=$(printf '%s\n' "${PHASE_SIGNALS[@]}" | jq -R . | jq -s .)

    local phase_json
    phase_json=$(jq -n \
        --arg phase "$CURRENT_PHASE" \
        --arg started "$(date -Iseconds)" \
        --argjson duration "$duration" \
        --argjson signals "$signals_json" \
        --arg outcome "$outcome" \
        '{
            phase: $phase,
            started: $started,
            duration_ms: $duration,
            signals: $signals,
            outcome: $outcome
        }')

    PHASES+=("$phase_json")
    log_info "Phase completed: $CURRENT_PHASE (${duration}ms, $outcome)"
}

finalize_trace() {
    local outcome="${1:-success}"
    local artifacts="${2:-[]}"

    local end_time
    end_time=$(get_timestamp)

    local phases_json
    phases_json=$(printf '%s\n' "${PHASES[@]}" | jq -s .)

    jq -n \
        --arg workflow "$WORKFLOW_NAME" \
        --arg started "$START_TIME" \
        --arg completed "$end_time" \
        --argjson phases "$phases_json" \
        --arg outcome "$outcome" \
        --argjson artifacts "$artifacts" \
        '{
            workflow: $workflow,
            started_at: $started,
            completed_at: $completed,
            phases: $phases,
            outcome: $outcome,
            artifacts: $artifacts,
            trace_version: "1.0"
        }' > "$TRACE_FILE"

    log_info "Trace finalized: $TRACE_FILE"
    log_info "Outcome: $outcome"
}

#######################################
# Signal Parsing
#######################################

parse_signals_from_output() {
    local output="$1"

    # Extract signal lines (JSON with "signal" key)
    echo "$output" | grep '"signal"' | while read -r line; do
        local signal
        signal=$(echo "$line" | jq -r '.signal // empty' 2>/dev/null)
        if [ -n "$signal" ]; then
            echo "$signal"
        fi
    done
}

#######################################
# Workflow Execution with Tracing
#######################################

execute_with_trace() {
    local workflow_file="$1"

    # Parse workflow to get phase list
    local phases_list
    phases_list=$(grep "- phase:" "$workflow_file" | sed 's/.*- phase: *//' | tr -d '"' | tr -d "'")

    init_trace "$WORKFLOW_NAME"

    local state='{}'
    local overall_outcome="success"
    local artifacts=()

    for phase in $phases_list; do
        start_phase "$phase"

        # Execute phase and capture output
        local script="$SCRIPT_DIR/../phase-protocols/${phase}-phase.sh"

        if [ ! -x "$script" ]; then
            log_error "Phase script not found: $script"
            complete_phase "error"
            overall_outcome="failure"
            break
        fi

        local stdout_file stderr_file
        stdout_file=$(mktemp)
        stderr_file=$(mktemp)

        local exit_code=0
        echo "$state" | "$script" > "$stdout_file" 2> "$stderr_file" || exit_code=$?

        # Parse signals from stderr
        local signals
        signals=$(parse_signals_from_output "$(cat "$stderr_file")")
        for sig in $signals; do
            record_signal "$sig"
        done

        if [ $exit_code -ne 0 ]; then
            log_error "Phase $phase failed with exit code $exit_code"
            complete_phase "failure"
            overall_outcome="failure"
            rm -f "$stdout_file" "$stderr_file"
            break
        fi

        state=$(cat "$stdout_file")
        rm -f "$stdout_file" "$stderr_file"

        complete_phase "success"
    done

    # Collect artifacts (files created)
    if [ -d ".sage/state" ]; then
        for f in .sage/state/*; do
            [ -f "$f" ] && artifacts+=("$(basename "$f")")
        done
    fi

    local artifacts_json
    artifacts_json=$(printf '%s\n' "${artifacts[@]}" 2>/dev/null | jq -R . | jq -s . 2>/dev/null || echo '[]')

    finalize_trace "$overall_outcome" "$artifacts_json"

    # Output trace file path
    echo "$TRACE_FILE"

    [ "$overall_outcome" = "success" ]
}

#######################################
# Main
#######################################

usage() {
    cat <<EOF
Usage: $(basename "$0") <workflow-name> [options]

Capture a workflow execution trace for validation.

Arguments:
  workflow-name    Name of workflow to trace (e.g., 'dev-story', 'retrospective')

Options:
  -o, --output DIR  Output directory for trace files (default: docs/testing/traces)
  -h, --help        Show this help message

Examples:
  $(basename "$0") dev-story
  $(basename "$0") retrospective -o /tmp/traces

Output:
  Creates a JSON trace file with execution details including:
  - Phase transitions with timestamps
  - Signals emitted during execution
  - Duration of each phase
  - Final outcome and artifacts

The trace file can be compared against previous traces to detect
behavioral changes in workflow execution.
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -o|--output)
                TRACES_DIR="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                WORKFLOW_NAME="$1"
                shift
                ;;
        esac
    done

    if [ -z "$WORKFLOW_NAME" ]; then
        log_error "Workflow name required"
        usage
        exit 1
    fi

    # Find workflow contract
    local workflow_file="$CONTRACTS_DIR/${WORKFLOW_NAME}.workflow.yaml"
    if [ ! -f "$workflow_file" ]; then
        log_error "Workflow contract not found: $workflow_file"
        exit 1
    fi

    log_info "Starting trace capture for workflow: $WORKFLOW_NAME"

    # Execute with tracing
    if execute_with_trace "$workflow_file"; then
        log_info "Trace capture completed successfully"
        exit 0
    else
        log_info "Trace capture completed with failures"
        exit 1
    fi
}

main "$@"
