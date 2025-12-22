#!/usr/bin/env bash
#
# SAGE Orchestrator v2 - Process Lifecycle Control
#
# This orchestrator manages Claude Code sessions using stream-json I/O
# instead of hooks. It controls the process lifecycle directly:
#
# 1. Spawns Claude with SAGE_ORCHESTRATOR=1
# 2. Monitors stdout for SAGE_SIGNAL patterns
# 3. On CHECKPOINT: kills process, restarts with fresh context
# 4. On HITL_REQUIRED: pauses, waits for human (via GitHub)
# 5. On EPIC_COMPLETE: exits cleanly
# 6. On FATAL_ERROR: exits with error
#
# Usage:
#   ./orchestrate-v2.sh                    # Resume from checkpoint (or error if none)
#   ./orchestrate-v2.sh --start epic.md    # Start new epic (interactive first)
#   ./orchestrate-v2.sh --test             # Run test simulation
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SAGE_ROOT/.." && pwd)"

# Directories
LOG_DIR="${PROJECT_ROOT}/.sage/logs"
STATE_DIR="${PROJECT_ROOT}/.sage/state"

# Files
LOG_FILE="${LOG_DIR}/orchestrator-v2.log"
SESSION_LOG="${LOG_DIR}/session-$(date +%Y%m%d-%H%M%S).jsonl"

# Configuration
MAX_CYCLES=50          # Safety limit on restart cycles
SIGNAL_TIMEOUT=600     # 10 minutes max per cycle before timeout
STRICT_MODE=false      # Require GitHub state verification to pass
VERIFY_STATE=true      # Run state verification after checkpoints
HITL_POLL_INTERVAL=30  # Seconds between resume signal checks
HITL_MAX_WAIT=86400    # Maximum wait time (24 hours)
RESUME_SIGNAL_FILE="${STATE_DIR}/.resume-signal"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR" 2>/dev/null || true

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp="$(date -Iseconds)"

    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"

    case "$level" in
        ERROR)   echo -e "${RED}[$level]${NC} $msg" ;;
        WARN)    echo -e "${YELLOW}[$level]${NC} $msg" ;;
        INFO)    echo -e "${BLUE}[$level]${NC} $msg" ;;
        SUCCESS) echo -e "${GREEN}[$level]${NC} $msg" ;;
        *)       echo "[$level] $msg" ;;
    esac
}

log_info()    { log "INFO" "$@"; }
log_warn()    { log "WARN" "$@"; }
log_error()   { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

#------------------------------------------------------------------------------
# Signal Detection
#------------------------------------------------------------------------------

# Extract signal type from a line of output
# Returns: CHECKPOINT, HITL_REQUIRED, EPIC_COMPLETE, FATAL_ERROR, or empty
extract_signal() {
    local line="$1"

    if echo "$line" | grep -q "SAGE_SIGNAL:CHECKPOINT"; then
        echo "CHECKPOINT"
    elif echo "$line" | grep -q "SAGE_SIGNAL:HITL_REQUIRED"; then
        echo "HITL_REQUIRED"
    elif echo "$line" | grep -q "SAGE_SIGNAL:EPIC_COMPLETE"; then
        echo "EPIC_COMPLETE"
    elif echo "$line" | grep -q "SAGE_SIGNAL:FATAL_ERROR"; then
        echo "FATAL_ERROR"
    else
        echo ""
    fi
}

# Parse checkpoint file path from signal block
extract_checkpoint_file() {
    local output="$1"
    echo "$output" | grep -o 'CHECKPOINT_FILE: [^ ]*' | cut -d' ' -f2 | head -1
}

#------------------------------------------------------------------------------
# GitHub State Verification
#------------------------------------------------------------------------------

# Verify GitHub state matches checkpoint state
# Returns: 0 = pass, 1 = fail
verify_github_state() {
    local checkpoint_file="$1"

    if [[ "$VERIFY_STATE" != "true" ]]; then
        log_info "State verification disabled"
        return 0
    fi

    if [[ -z "$checkpoint_file" ]] || [[ ! -f "$checkpoint_file" ]]; then
        log_warn "No checkpoint file for verification: $checkpoint_file"
        return 0
    fi

    log_info "Verifying GitHub state against checkpoint..."

    local verify_script="${SAGE_ROOT}/scripts/gh-verify-state.sh"
    if [[ ! -x "$verify_script" ]]; then
        log_warn "Verification script not found: $verify_script"
        return 0
    fi

    local result
    if result=$(nix-shell -p jq --run "$verify_script '$checkpoint_file'" 2>&1); then
        log_success "GitHub state verification passed"
        echo "$result" >> "$LOG_FILE"
        return 0
    else
        log_warn "GitHub state verification found discrepancies:"
        echo "$result" | tee -a "$LOG_FILE"

        if [[ "$STRICT_MODE" == "true" ]]; then
            log_error "Strict mode enabled - halting on verification failure"
            return 1
        else
            log_warn "Continuing despite discrepancies (use --strict to enforce)"
            return 0
        fi
    fi
}

#------------------------------------------------------------------------------
# HITL Wait Loop
#------------------------------------------------------------------------------

# Wait for resume signal from webhook
# Returns: 0 = approved, 1 = revise, 2 = discuss, 3 = halt, 4 = timeout
wait_for_resume_signal() {
    local wait_start
    wait_start=$(date +%s)
    local elapsed=0

    log_info "Entering HITL wait loop..."
    log_info "Resume signal file: $RESUME_SIGNAL_FILE"
    log_info "Polling every ${HITL_POLL_INTERVAL}s (max wait: ${HITL_MAX_WAIT}s)"

    while [[ $elapsed -lt $HITL_MAX_WAIT ]]; do
        if [[ -f "$RESUME_SIGNAL_FILE" ]]; then
            log_info "Resume signal detected!"

            local signal_content
            signal_content=$(cat "$RESUME_SIGNAL_FILE")

            # Extract status from signal file
            local status
            status=$(echo "$signal_content" | grep -oP 'STATUS:\s*\K\w+' | head -1)

            if [[ -z "$status" ]]; then
                status=$(echo "$signal_content" | tr '[:lower:]' '[:upper:]' | head -1)
            fi

            log_info "Resume status: $status"

            # Clean up signal file
            rm -f "$RESUME_SIGNAL_FILE"

            case "$status" in
                APPROVED)
                    log_success "HitL approved - resuming"
                    return 0
                    ;;
                REVISE)
                    log_warn "Revision requested"
                    return 1
                    ;;
                DISCUSS)
                    log_warn "Discussion requested"
                    return 2
                    ;;
                HALT)
                    log_error "Halt requested"
                    return 3
                    ;;
                *)
                    log_warn "Unknown status: $status - treating as approved"
                    return 0
                    ;;
            esac
        fi

        # Calculate elapsed time
        local now
        now=$(date +%s)
        elapsed=$((now - wait_start))

        # Show periodic status
        if [[ $((elapsed % 300)) -lt $HITL_POLL_INTERVAL ]]; then
            local remaining=$((HITL_MAX_WAIT - elapsed))
            log_info "Waiting for approval... (${elapsed}s elapsed, ${remaining}s remaining)"
        fi

        sleep "$HITL_POLL_INTERVAL"
    done

    log_error "HITL wait timeout after ${HITL_MAX_WAIT}s"
    return 4
}

#------------------------------------------------------------------------------
# Claude Process Management
#------------------------------------------------------------------------------

# Run Claude with stream-json output, monitor for signals
# Returns exit code based on signal detected:
#   0 = EPIC_COMPLETE (success)
#   1 = FATAL_ERROR
#   2 = CHECKPOINT (restart needed)
#   3 = HITL_REQUIRED (pause needed)
#   4 = timeout or unexpected exit
run_claude_cycle() {
    local prompt="$1"
    local detected_signal=""
    local output_buffer=""
    local line

    log_info "Starting Claude cycle with prompt: $prompt"
    log_info "Session log: $SESSION_LOG"

    # Export orchestrator mode
    export SAGE_ORCHESTRATOR=1

    # Run Claude with stream-json output
    # We pipe the prompt and capture output line by line
    cd "$PROJECT_ROOT" || return 4

    # Use timeout to prevent hanging
    # The --verbose flag is required for stream-json in print mode
    echo "$prompt" | timeout "$SIGNAL_TIMEOUT" claude -p \
        --output-format stream-json \
        --verbose \
        --dangerously-skip-permissions \
        2>&1 | while IFS= read -r line; do

        # Log to session file
        echo "$line" >> "$SESSION_LOG"

        # Check for signals in output
        detected_signal=$(extract_signal "$line")

        if [[ -n "$detected_signal" ]]; then
            log_info "Detected signal: $detected_signal"

            # Accumulate lines for context extraction
            output_buffer+="$line"$'\n'

            # Read a few more lines to capture full signal block
            for _ in {1..5}; do
                if IFS= read -r extra_line; then
                    echo "$extra_line" >> "$SESSION_LOG"
                    output_buffer+="$extra_line"$'\n'
                fi
            done

            # Write signal info for parent process
            echo "$detected_signal" > "${STATE_DIR}/.last_signal"
            echo "$output_buffer" > "${STATE_DIR}/.last_signal_context"

            # Exit the subshell with signal-specific code
            case "$detected_signal" in
                EPIC_COMPLETE)   exit 0 ;;
                FATAL_ERROR)     exit 1 ;;
                CHECKPOINT)      exit 2 ;;
                HITL_REQUIRED)   exit 3 ;;
            esac
        fi
    done

    local exit_code=$?

    # If we got here without a signal, check timeout
    if [[ $exit_code -eq 124 ]]; then
        log_error "Claude process timed out after ${SIGNAL_TIMEOUT}s"
        return 4
    fi

    return $exit_code
}

#------------------------------------------------------------------------------
# Main Orchestration Loop
#------------------------------------------------------------------------------

orchestrate() {
    local initial_prompt="$1"
    local cycle=0
    local exit_code
    local checkpoint_file

    log_info "=== SAGE Orchestrator v2 Starting ==="
    log_info "Project root: $PROJECT_ROOT"
    log_info "Max cycles: $MAX_CYCLES"

    local current_prompt="$initial_prompt"

    while [[ $cycle -lt $MAX_CYCLES ]]; do
        ((cycle++))
        log_info "--- Cycle $cycle / $MAX_CYCLES ---"

        run_claude_cycle "$current_prompt"
        exit_code=$?

        case $exit_code in
            0)
                # EPIC_COMPLETE
                log_success "Epic completed successfully!"
                log_info "Total cycles: $cycle"
                return 0
                ;;

            1)
                # FATAL_ERROR
                log_error "Fatal error detected"
                if [[ -f "${STATE_DIR}/.last_signal_context" ]]; then
                    log_error "Context:"
                    cat "${STATE_DIR}/.last_signal_context" | head -20
                fi
                return 1
                ;;

            2)
                # CHECKPOINT - restart with fresh context
                log_info "Checkpoint signal received"

                # Extract checkpoint file from signal context
                if [[ -f "${STATE_DIR}/.last_signal_context" ]]; then
                    checkpoint_file=$(extract_checkpoint_file "$(cat "${STATE_DIR}/.last_signal_context")")
                    log_info "Checkpoint file: $checkpoint_file"
                fi

                # Verify GitHub state matches checkpoint
                if ! verify_github_state "$checkpoint_file"; then
                    log_error "State verification failed in strict mode"
                    return 1
                fi

                # Clean up signal files
                rm -f "${STATE_DIR}/.last_signal" "${STATE_DIR}/.last_signal_context" 2>/dev/null

                # Set next prompt to resume (explicit resume command)
                current_prompt="/assistant *resume"

                # Brief pause to ensure clean process separation
                log_info "Restarting with fresh context in 2s..."
                sleep 2
                ;;

            3)
                # HITL_REQUIRED - pause and wait for human
                log_warn "Human-in-the-loop required"
                log_info "Check GitHub for the review request"

                # Enter wait loop for resume signal
                local wait_result
                wait_for_resume_signal
                wait_result=$?

                case $wait_result in
                    0)
                        # Approved - continue with next phase
                        log_success "Approval received - resuming orchestration"
                        current_prompt="/assistant *resume"
                        sleep 2
                        ;;
                    1)
                        # Revise - need to restart with revision context
                        log_warn "Revision requested - restarting for revisions"
                        current_prompt="/assistant *resume"
                        sleep 2
                        ;;
                    2)
                        # Discuss - pause for discussion
                        log_warn "Discussion requested - pausing for discussion"
                        log_info "Run this script again after discussion to continue"
                        return 0
                        ;;
                    3)
                        # Halt - stop orchestration
                        log_error "Halt requested - stopping orchestration"
                        return 1
                        ;;
                    4)
                        # Timeout
                        log_error "HITL wait timeout - stopping orchestration"
                        log_info "Run this script again to continue"
                        return 0
                        ;;
                esac
                ;;

            4)
                # Timeout or unexpected
                log_error "Timeout or unexpected exit"
                return 1
                ;;

            *)
                log_error "Unknown exit code: $exit_code"
                return 1
                ;;
        esac
    done

    log_error "Max cycles ($MAX_CYCLES) reached - possible infinite loop"
    return 1
}

#------------------------------------------------------------------------------
# Usage and CLI
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
SAGE Orchestrator v2 - Process Lifecycle Control

Usage:
  orchestrate-v2.sh [options]

Options:
  -h, --help      Show this help message
  -r, --resume    Resume from existing checkpoint (default)
  -t, --test      Run test epic simulation
  -s, --start     Start interactively (for initial epic setup)
  --status        Show current orchestrator status
  --strict        Require GitHub state verification to pass
  --no-verify     Skip GitHub state verification

Description:
  This orchestrator manages Claude Code sessions using stream-json I/O.
  It monitors for SAGE signals and controls process lifecycle:

  - CHECKPOINT:     Kill process, restart with fresh context
  - HITL_REQUIRED:  Pause, wait for GitHub approval
  - EPIC_COMPLETE:  Exit successfully
  - FATAL_ERROR:    Exit with error

Environment:
  SAGE_ORCHESTRATOR=1 is set automatically for Claude

Examples:
  ./orchestrate-v2.sh                 # Resume from checkpoint
  ./orchestrate-v2.sh --test          # Run test epic
  ./orchestrate-v2.sh --status        # Check status

EOF
}

show_status() {
    echo "=== SAGE Orchestrator v2 Status ==="
    echo

    echo "Checkpoint files:"
    if ls "${STATE_DIR}"/*.json 2>/dev/null; then
        ls -la "${STATE_DIR}"/*.json
    else
        echo "  (none)"
    fi
    echo

    echo "Last signal:"
    if [[ -f "${STATE_DIR}/.last_signal" ]]; then
        cat "${STATE_DIR}/.last_signal"
    else
        echo "  (none)"
    fi
    echo

    echo "Recent log entries:"
    if [[ -f "$LOG_FILE" ]]; then
        tail -10 "$LOG_FILE"
    else
        echo "  (no log file)"
    fi
}

#------------------------------------------------------------------------------
# Main Entry Point
#------------------------------------------------------------------------------

main() {
    local mode="resume"
    local prompt=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -r|--resume)
                mode="resume"
                shift
                ;;
            -t|--test)
                mode="test"
                shift
                ;;
            -s|--start)
                mode="start"
                shift
                ;;
            --status)
                show_status
                exit 0
                ;;
            --strict)
                STRICT_MODE=true
                log_info "Strict mode enabled"
                shift
                ;;
            --no-verify)
                VERIFY_STATE=false
                log_info "State verification disabled"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Set prompt based on mode
    case "$mode" in
        resume)
            # Check if checkpoint exists
            if ! ls "${STATE_DIR}"/*.json >/dev/null 2>&1; then
                log_error "No checkpoint found. Use --start to begin interactively."
                exit 1
            fi
            # Explicit resume command since on-load is now JIT loaded
            prompt="/assistant *resume"
            ;;
        test)
            prompt="/assistant"
            log_info "Test mode: Agent will detect test epic setup"
            # Note: Need to trigger *test-epic somehow
            # For now, just load assistant - user can run *test-epic
            ;;
        start)
            log_info "Starting interactive session for epic setup..."
            log_info "Run *start-epic or *run-epic to create a checkpoint"
            log_info "Then run this script with --resume to continue autonomously"

            # Just run Claude normally (not in orchestrator mode)
            cd "$PROJECT_ROOT" || exit 1
            exec claude --dangerously-skip-permissions "/assistant"
            ;;
    esac

    # Run orchestration
    orchestrate "$prompt"
}

main "$@"
