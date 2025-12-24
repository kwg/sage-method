#!/usr/bin/env bash
#
# gh-wait-approval.sh - Orchestrator-Level Polling Loop for HitL Approval
#
# This script provides a polling loop for waiting on human approval via
# GitHub issues. It's designed for use by the orchestrator to pause
# execution until a human responds.
#
# Usage:
#   ./gh-wait-approval.sh <issue_number> [options]
#
# Options:
#   --timeout SECONDS     Maximum wait time (default: 86400 = 24h)
#   --interval SECONDS    Poll interval (default: 30)
#   --signal              Emit SAGE signals for orchestrator
#
# Output:
#   Emits SAGE_SIGNAL format when response received or timeout
#
# Exit codes:
#   0 - Approved
#   1 - Revise requested
#   2 - Discuss requested
#   3 - Halt requested
#   4 - Timeout
#   5 - Error
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

DEFAULT_TIMEOUT=86400    # 24 hours
DEFAULT_INTERVAL=30      # 30 seconds
EMIT_SIGNALS=false

#------------------------------------------------------------------------------
# Polling Loop
#------------------------------------------------------------------------------

# Wait for approval with polling
# Usage: wait_for_approval <issue_number> [--timeout N] [--interval N]
wait_for_approval() {
    local issue_number=""
    local timeout=$DEFAULT_TIMEOUT
    local interval=$DEFAULT_INTERVAL

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout)
                timeout="$2"
                shift 2
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            --signal)
                EMIT_SIGNALS=true
                shift
                ;;
            *)
                if [[ -z "$issue_number" ]]; then
                    issue_number="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$issue_number" ]]; then
        log_error "Missing issue number"
        return 5
    fi

    log_info "Waiting for approval on issue #$issue_number"
    log_info "Timeout: ${timeout}s, Poll interval: ${interval}s"

    local start_time
    start_time=$(date +%s)
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        # Poll for response
        local response
        response=$("$SCRIPT_DIR/gh-poll-response.sh" poll "$issue_number" 2>/dev/null)
        local poll_exit=$?

        if [[ $poll_exit -eq 0 ]]; then
            local status
            status=$(echo "$response" | jq -r '.status // "UNCLEAR"')

            case "$status" in
                APPROVED)
                    log_success "Approval received!"
                    emit_approval_signal "$issue_number" "$response"
                    return 0
                    ;;
                REVISE)
                    log_warn "Revision requested"
                    emit_revise_signal "$issue_number" "$response"
                    return 1
                    ;;
                DISCUSS)
                    log_warn "Discussion requested"
                    emit_discuss_signal "$issue_number" "$response"
                    return 2
                    ;;
                HALT)
                    log_error "Halt requested"
                    emit_halt_signal "$issue_number" "$response"
                    return 3
                    ;;
                DEFER)
                    log_info "Defer requested - treating as halt"
                    emit_halt_signal "$issue_number" "$response"
                    return 3
                    ;;
                NO_RESPONSE)
                    # Continue polling
                    ;;
                UNCLEAR)
                    # Log but continue polling - might get clearer response
                    log_verbose "Unclear response, continuing to poll..."
                    ;;
            esac
        fi

        # Calculate elapsed time
        local now
        now=$(date +%s)
        elapsed=$((now - start_time))

        # Show periodic status
        if [[ $((elapsed % 300)) -lt $interval ]]; then
            local remaining=$((timeout - elapsed))
            log_info "Waiting for approval... (${elapsed}s elapsed, ${remaining}s remaining)"
        fi

        # Sleep before next poll
        sleep "$interval"
    done

    # Timeout reached
    log_error "Timeout waiting for approval after ${timeout}s"
    emit_timeout_signal "$issue_number"
    return 4
}

#------------------------------------------------------------------------------
# Signal Emission
#------------------------------------------------------------------------------

emit_approval_signal() {
    local issue_number="$1"
    local response="$2"

    if [[ "$EMIT_SIGNALS" == "true" ]]; then
        local user
        user=$(echo "$response" | jq -r '.user // "unknown"')

        emit_signal "HITL_APPROVED" \
            "ISSUE_NUMBER=$issue_number" \
            "APPROVED_BY=$user" \
            "NEXT_ACTION=continue"
    fi
}

emit_revise_signal() {
    local issue_number="$1"
    local response="$2"

    if [[ "$EMIT_SIGNALS" == "true" ]]; then
        local comment
        comment=$(echo "$response" | jq -r '.comment // ""' | head -c 200)

        emit_signal "HITL_REVISE" \
            "ISSUE_NUMBER=$issue_number" \
            "REVISION_NOTES=$comment" \
            "NEXT_ACTION=revise"
    fi
}

emit_discuss_signal() {
    local issue_number="$1"
    local response="$2"

    if [[ "$EMIT_SIGNALS" == "true" ]]; then
        emit_signal "HITL_DISCUSS" \
            "ISSUE_NUMBER=$issue_number" \
            "NEXT_ACTION=pause"
    fi
}

emit_halt_signal() {
    local issue_number="$1"
    local response="$2"

    if [[ "$EMIT_SIGNALS" == "true" ]]; then
        emit_signal "HITL_HALT" \
            "ISSUE_NUMBER=$issue_number" \
            "NEXT_ACTION=halt"
    fi
}

emit_timeout_signal() {
    local issue_number="$1"

    if [[ "$EMIT_SIGNALS" == "true" ]]; then
        emit_signal "HITL_TIMEOUT" \
            "ISSUE_NUMBER=$issue_number" \
            "NEXT_ACTION=pause"
    fi
}

#------------------------------------------------------------------------------
# One-shot Check
#------------------------------------------------------------------------------

# Check once without looping (for scripts that manage their own loop)
check_once() {
    local issue_number="$1"

    if [[ -z "$issue_number" ]]; then
        log_error "Missing issue number"
        return 5
    fi

    # Poll for response
    local response
    response=$("$SCRIPT_DIR/gh-poll-response.sh" poll "$issue_number" 2>/dev/null)
    local poll_exit=$?

    if [[ $poll_exit -eq 3 ]]; then
        # No response yet
        echo '{"waiting": true, "status": "NO_RESPONSE"}'
        return 0
    fi

    if [[ $poll_exit -ne 0 ]]; then
        log_error "Poll failed"
        return 5
    fi

    local status
    status=$(echo "$response" | jq -r '.status // "UNCLEAR"')

    # Add waiting flag
    if [[ "$status" == "NO_RESPONSE" || "$status" == "UNCLEAR" ]]; then
        echo "$response" | jq '. + {waiting: true}'
    else
        echo "$response" | jq '. + {waiting: false}'
    fi

    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
gh-wait-approval.sh - Orchestrator-Level Polling Loop for HitL Approval

Usage:
  gh-wait-approval.sh <issue_number> [options]

Commands:
  wait <issue>     Wait for approval (with polling loop)
  check <issue>    Check once without looping

Options:
  --timeout SECS   Maximum wait time (default: 86400 = 24h)
  --interval SECS  Poll interval (default: 30)
  --signal         Emit SAGE signals for orchestrator

Exit Codes:
  0 - Approved
  1 - Revise requested
  2 - Discuss requested
  3 - Halt/Defer requested
  4 - Timeout
  5 - Error

Examples:
  # Wait for approval with signals
  gh-wait-approval.sh wait 123 --signal

  # Short timeout for testing
  gh-wait-approval.sh wait 123 --timeout 60 --interval 5

  # One-shot check (for custom polling)
  gh-wait-approval.sh check 123

EOF
}

main() {
    local command="wait"
    local issue_number=""
    local extra_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            wait|check)
                command="$1"
                shift
                ;;
            --timeout|--interval|--signal)
                extra_args+=("$1")
                if [[ "$1" != "--signal" && $# -gt 1 ]]; then
                    extra_args+=("$2")
                    shift
                fi
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$issue_number" ]]; then
                    issue_number="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$issue_number" ]]; then
        log_error "Missing issue number"
        usage
        exit 1
    fi

    # Initialize
    sage_init --require-git --require-gh

    # Dispatch command
    case "$command" in
        wait)
            wait_for_approval "$issue_number" "${extra_args[@]}"
            ;;
        check)
            check_once "$issue_number"
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
