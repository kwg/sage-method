#!/usr/bin/env bash
# workflow-executor.sh - Execute workflow contracts with phase chaining
# Part of SAGE workflow lifecycle testing framework

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_PROTOCOLS_DIR="$SCRIPT_DIR/phase-protocols"

# State file locations
CHECKPOINT_FILE=".sage/state/checkpoint.json"
SESSION_FILE=".sage/state/session.json"
SIGNALS_FILE=".sage/state/workflow-signals.log"

# Global state
CURRENT_STATE='{}'
WORKFLOW_NAME=""
WORKFLOW_FILE=""
PHASE_SEQUENCE=()
STOP_AT_PHASE=""
RESUME_MODE=false
DRY_RUN=false

#######################################
# Utility Functions
#######################################

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_signal() {
    local signal="$1"
    local payload="${2:-{}}"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)

    local signal_json="{\"signal\":\"$signal\",\"payload\":$payload,\"timestamp\":\"$timestamp\"}"
    echo "$signal_json" >> "$SIGNALS_FILE"
    echo "$signal_json" >&2
}

emit_workflow_signal() {
    local signal="$1"
    local details="${2:-{}}"
    log_signal "$signal" "{\"workflow\":\"$WORKFLOW_NAME\",$details}"
}

#######################################
# Workflow Contract Parsing
#######################################

parse_workflow_contract() {
    local contract_file="$1"

    if [ ! -f "$contract_file" ]; then
        log_error "Workflow contract not found: $contract_file"
        exit 1
    fi

    # Extract workflow name
    WORKFLOW_NAME=$(grep "^workflow:" "$contract_file" | head -1 | awk '{print $2}')

    # Extract phase sequence (simplified YAML parsing)
    PHASE_SEQUENCE=()
    local in_phases=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^phases: ]]; then
            in_phases=true
            continue
        fi

        if [ "$in_phases" = true ]; then
            if [[ "$line" =~ ^[a-z] ]]; then
                # New top-level key, stop
                break
            fi
            if [[ "$line" =~ "- phase:" ]]; then
                local phase
                phase=$(echo "$line" | sed 's/.*- phase: *//' | tr -d '"' | tr -d "'" | tr -d ' ')
                PHASE_SEQUENCE+=("$phase")
            fi
        fi
    done < "$contract_file"

    if [ ${#PHASE_SEQUENCE[@]} -eq 0 ]; then
        log_error "No phases found in workflow contract"
        exit 1
    fi

    log_info "Parsed workflow: $WORKFLOW_NAME with phases: ${PHASE_SEQUENCE[*]}"
}

#######################################
# State Management
#######################################

load_checkpoint() {
    if [ -f "$CHECKPOINT_FILE" ]; then
        local checkpoint_phase
        checkpoint_phase=$(jq -r '.phase // "none"' "$CHECKPOINT_FILE")
        CURRENT_STATE=$(cat "$CHECKPOINT_FILE")
        log_info "Loaded checkpoint at phase: $checkpoint_phase"
        echo "$checkpoint_phase"
    else
        echo "none"
    fi
}

save_checkpoint() {
    mkdir -p "$(dirname "$CHECKPOINT_FILE")"
    echo "$CURRENT_STATE" | jq . > "$CHECKPOINT_FILE"
}

validate_state_transition() {
    local from_phase="$1"
    local to_phase="$2"

    # Basic validation: check state has expected phase
    local state_phase
    state_phase=$(echo "$CURRENT_STATE" | jq -r '.phase // "none"')

    if [ "$state_phase" != "$from_phase" ]; then
        log_error "State transition validation failed: expected phase=$from_phase, got phase=$state_phase"
        return 1
    fi

    log_info "State transition validated: $from_phase -> $to_phase"
    return 0
}

#######################################
# Phase Execution
#######################################

get_phase_script() {
    local phase="$1"
    echo "$PHASE_PROTOCOLS_DIR/${phase}-phase.sh"
}

execute_phase() {
    local phase="$1"
    local script
    script=$(get_phase_script "$phase")

    if [ ! -x "$script" ]; then
        log_error "Phase script not found or not executable: $script"
        emit_workflow_signal "ERROR" "\"phase\":\"$phase\",\"error\":\"script_not_found\""
        return 1
    fi

    log_info "Executing phase: $phase"
    emit_workflow_signal "PHASE_START" "\"phase\":\"$phase\""

    # Create temp files for capturing output
    local stdout_file stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    # Execute phase script
    local exit_code=0
    echo "$CURRENT_STATE" | "$script" > "$stdout_file" 2> "$stderr_file" || exit_code=$?

    # Capture outputs
    local phase_stdout phase_stderr
    phase_stdout=$(cat "$stdout_file")
    phase_stderr=$(cat "$stderr_file")

    # Append signals to log
    echo "$phase_stderr" >> "$SIGNALS_FILE"

    # Output stderr for signal visibility
    echo "$phase_stderr" >&2

    rm -f "$stdout_file" "$stderr_file"

    if [ $exit_code -ne 0 ]; then
        log_error "Phase $phase failed with exit code $exit_code"
        emit_workflow_signal "ERROR" "\"phase\":\"$phase\",\"exit_code\":$exit_code"

        # Check for injected failure (for testing)
        if [ "${INJECT_FAILURE_AT:-}" = "$phase" ]; then
            log_info "Injected failure at phase $phase"
        fi

        # Trigger rollback
        emit_workflow_signal "ROLLBACK" "\"phase\":\"$phase\",\"reason\":\"phase_failed\""
        return $exit_code
    fi

    # Update state with phase output
    if [ -n "$phase_stdout" ]; then
        CURRENT_STATE="$phase_stdout"
        save_checkpoint
    fi

    emit_workflow_signal "PHASE_COMPLETE" "\"phase\":\"$phase\",\"success\":true"
    log_info "Phase $phase completed successfully"
    return 0
}

#######################################
# Workflow Execution
#######################################

find_resume_phase() {
    local checkpoint_phase
    checkpoint_phase=$(load_checkpoint)

    if [ "$checkpoint_phase" = "none" ]; then
        echo 0
        return
    fi

    # Find index of next phase after checkpoint
    for i in "${!PHASE_SEQUENCE[@]}"; do
        if [ "${PHASE_SEQUENCE[$i]}" = "$checkpoint_phase" ]; then
            echo $((i + 1))
            return
        fi
    done

    echo 0
}

execute_workflow() {
    local start_index=0

    # Initialize signals log
    mkdir -p "$(dirname "$SIGNALS_FILE")"
    : > "$SIGNALS_FILE"

    emit_workflow_signal "WORKFLOW_START" "\"phases\":${#PHASE_SEQUENCE[@]}"

    # Handle resume mode
    if [ "$RESUME_MODE" = true ]; then
        start_index=$(find_resume_phase)
        if [ "$start_index" -gt 0 ]; then
            log_info "Resuming from phase index $start_index"
        fi
    fi

    # Initialize state if starting fresh
    if [ "$start_index" -eq 0 ]; then
        CURRENT_STATE="{\"workflow\":\"$WORKFLOW_NAME\"}"
    fi

    local previous_phase="none"

    for ((i = start_index; i < ${#PHASE_SEQUENCE[@]}; i++)); do
        local phase="${PHASE_SEQUENCE[$i]}"

        # Check for stop-at
        if [ -n "$STOP_AT_PHASE" ] && [ "$phase" = "$STOP_AT_PHASE" ]; then
            log_info "Stopping at phase: $phase (as requested)"
            emit_workflow_signal "WORKFLOW_STOPPED" "\"at_phase\":\"$phase\""
            return 0
        fi

        # Validate transition (skip for first phase)
        if [ "$previous_phase" != "none" ]; then
            if ! validate_state_transition "$previous_phase" "$phase"; then
                log_error "State transition failed, triggering rollback"
                emit_workflow_signal "ROLLBACK" "\"from\":\"$previous_phase\",\"to\":\"$phase\""
                return 1
            fi
        fi

        # Check for injected failure (for testing)
        if [ "${INJECT_FAILURE_AT:-}" = "$phase" ]; then
            log_info "Injecting failure at phase: $phase"
            emit_workflow_signal "ERROR" "\"phase\":\"$phase\",\"error\":\"injected_failure\""
            emit_workflow_signal "ROLLBACK" "\"phase\":\"$phase\",\"reason\":\"injected_failure\""
            return 1
        fi

        # Execute phase
        if ! execute_phase "$phase"; then
            log_error "Workflow failed at phase: $phase"
            return 1
        fi

        previous_phase="$phase"
    done

    emit_workflow_signal "WORKFLOW_COMPLETE" "\"success\":true"
    log_info "Workflow completed successfully"

    # Output final state
    echo "$CURRENT_STATE"
    return 0
}

#######################################
# Main
#######################################

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] <workflow-contract.yaml>

Execute a workflow contract, running phases in sequence.

Options:
  --resume         Resume from last checkpoint
  --stop-at=PHASE  Stop execution at specified phase
  --dry-run        Parse contract but don't execute
  -h, --help       Show this help message

Environment Variables:
  INJECT_FAILURE_AT=PHASE  Inject failure at specified phase (for testing)

Examples:
  $(basename "$0") dev-story.workflow.yaml
  $(basename "$0") --resume dev-story.workflow.yaml
  $(basename "$0") --stop-at=planning dev-story.workflow.yaml
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --resume)
                RESUME_MODE=true
                shift
                ;;
            --stop-at=*)
                STOP_AT_PHASE="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
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
                WORKFLOW_FILE="$1"
                shift
                ;;
        esac
    done

    if [ -z "$WORKFLOW_FILE" ]; then
        log_error "Workflow contract file required"
        usage
        exit 1
    fi

    # Parse workflow contract
    parse_workflow_contract "$WORKFLOW_FILE"

    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run - workflow parsed successfully"
        exit 0
    fi

    # Execute workflow
    execute_workflow
}

main "$@"
