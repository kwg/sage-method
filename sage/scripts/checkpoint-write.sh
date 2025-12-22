#!/usr/bin/env bash
#
# checkpoint-write.sh - Checkpoint JSON File Operations for SAGE
#
# This script handles checkpoint state file operations:
# - Create checkpoint JSON from current state
# - Atomic write to .sage/state/
# - Session log updates (JSONL format)
# - Checkpoint validation
#
# Used by the orchestrator for state persistence and recovery.
#
# Usage:
#   ./checkpoint-write.sh <command> [options]
#
# Commands:
#   create          Create checkpoint from current state
#   write           Write checkpoint to file
#   log             Append to session log
#   validate        Validate checkpoint JSON
#   read            Read current checkpoint
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Validation error
#   3 - Write error
#   4 - No checkpoint found
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

STATE_DIR=".sage/state"
CURRENT_CHECKPOINT="$STATE_DIR/current-checkpoint.json"
SESSION_LOG="$STATE_DIR/session.jsonl"

# Checkpoint schema fields
REQUIRED_FIELDS="epic_id story_id phase task_index status commit_hash"

#------------------------------------------------------------------------------
# Checkpoint Creation
#------------------------------------------------------------------------------

# Create checkpoint JSON from current state
# Usage: create_checkpoint <epic_id> <story_id> <phase> <task_index> [options]
create_checkpoint() {
    local epic_id=""
    local story_id=""
    local phase=""
    local task_index=0
    local status="in_progress"
    local notes=""
    local started_at=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)
                status="$2"
                shift 2
                ;;
            --notes)
                notes="$2"
                shift 2
                ;;
            --started-at)
                started_at="$2"
                shift 2
                ;;
            *)
                if [[ -z "$epic_id" ]]; then
                    epic_id="$1"
                elif [[ -z "$story_id" ]]; then
                    story_id="$1"
                elif [[ -z "$phase" ]]; then
                    phase="$1"
                elif [[ $task_index -eq 0 ]]; then
                    task_index="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$epic_id" || -z "$story_id" || -z "$phase" ]]; then
        log_error "Usage: create_checkpoint <epic_id> <story_id> <phase> [task_index]"
        return 1
    fi

    log_verbose "Creating checkpoint: $epic_id/$story_id phase:$phase task:$task_index"

    # Get git information
    local commit_hash branch
    commit_hash=$(git rev-parse HEAD 2>/dev/null || echo "")
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    # Get timestamps
    local timestamp
    timestamp=$(date -Iseconds)

    if [[ -z "$started_at" ]]; then
        # Try to get from existing checkpoint
        if [[ -f "$CURRENT_CHECKPOINT" ]]; then
            started_at=$(jq -r '.started_at // ""' "$CURRENT_CHECKPOINT" 2>/dev/null)
        fi
        # Default to now if still empty
        if [[ -z "$started_at" ]]; then
            started_at="$timestamp"
        fi
    fi

    # Get repo info
    local repo_url=""
    repo_url=$(git remote get-url origin 2>/dev/null || echo "")

    # Build checkpoint JSON
    cat << EOF
{
  "version": "1.0",
  "epic_id": "$epic_id",
  "story_id": "$story_id",
  "phase": "$phase",
  "task_index": $task_index,
  "status": "$status",
  "branch": "$branch",
  "commit_hash": "$commit_hash",
  "started_at": "$started_at",
  "updated_at": "$timestamp",
  "repository": "$repo_url",
  "notes": $(if [[ -n "$notes" ]]; then echo "\"$notes\""; else echo "null"; fi)
}
EOF

    return 0
}

#------------------------------------------------------------------------------
# Checkpoint Writing
#------------------------------------------------------------------------------

# Write checkpoint to file (atomic)
# Usage: write_checkpoint <checkpoint_json> [--file FILE]
write_checkpoint() {
    local checkpoint=""
    local output_file="$CURRENT_CHECKPOINT"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                output_file="$2"
                shift 2
                ;;
            *)
                if [[ -z "$checkpoint" ]]; then
                    checkpoint="$1"
                fi
                shift
                ;;
        esac
    done

    # Read from stdin if no checkpoint provided
    if [[ -z "$checkpoint" ]]; then
        checkpoint=$(cat)
    fi

    # Validate JSON
    if ! echo "$checkpoint" | jq -e '.' &>/dev/null; then
        log_error "Invalid JSON checkpoint"
        return 2
    fi

    # Validate required fields
    for field in $REQUIRED_FIELDS; do
        local value
        value=$(echo "$checkpoint" | jq -r ".$field // empty")
        if [[ -z "$value" ]]; then
            log_error "Missing required field: $field"
            return 2
        fi
    done

    # Ensure directory exists
    mkdir -p "$(dirname "$output_file")"

    # Atomic write
    if ! atomic_write "$output_file" "$checkpoint"; then
        log_error "Failed to write checkpoint"
        return 3
    fi

    log_success "Checkpoint written: $output_file"

    # Also log to session log
    append_to_session_log "$checkpoint"

    return 0
}

#------------------------------------------------------------------------------
# Session Log
#------------------------------------------------------------------------------

# Append checkpoint to session log (JSONL format)
# Usage: append_to_session_log <checkpoint_json>
append_to_session_log() {
    local checkpoint="$1"

    mkdir -p "$(dirname "$SESSION_LOG")"

    # Add log entry with action type
    local log_entry
    log_entry=$(echo "$checkpoint" | jq -c '. + {action: "checkpoint", logged_at: (now | todate)}' 2>/dev/null)

    if [[ -z "$log_entry" ]]; then
        log_warn "Failed to create log entry"
        return 0
    fi

    echo "$log_entry" >> "$SESSION_LOG"
    log_verbose "Appended to session log"

    return 0
}

# Log a custom event to session log
# Usage: log_event <event_type> [--data JSON]
log_event() {
    local event_type="$1"
    shift

    local data="{}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --data)
                data="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    mkdir -p "$(dirname "$SESSION_LOG")"

    local timestamp
    timestamp=$(date -Iseconds)

    local log_entry
    log_entry=$(jq -nc --arg type "$event_type" --arg ts "$timestamp" --argjson data "$data" \
        '{action: $type, timestamp: $ts} + $data')

    echo "$log_entry" >> "$SESSION_LOG"
    log_verbose "Logged event: $event_type"

    return 0
}

#------------------------------------------------------------------------------
# Checkpoint Reading
#------------------------------------------------------------------------------

# Read current checkpoint
# Usage: read_checkpoint [--file FILE] [--field FIELD]
read_checkpoint() {
    local input_file="$CURRENT_CHECKPOINT"
    local field=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                input_file="$2"
                shift 2
                ;;
            --field)
                field="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -f "$input_file" ]]; then
        log_warn "No checkpoint found: $input_file"
        return 4
    fi

    if [[ -n "$field" ]]; then
        jq -r ".$field // empty" "$input_file"
    else
        cat "$input_file"
    fi

    return 0
}

#------------------------------------------------------------------------------
# Validation
#------------------------------------------------------------------------------

# Validate checkpoint JSON
# Usage: validate_checkpoint <checkpoint_json>
validate_checkpoint() {
    local checkpoint="$1"

    # Read from stdin if not provided
    if [[ -z "$checkpoint" ]]; then
        checkpoint=$(cat)
    fi

    # Check JSON validity
    if ! echo "$checkpoint" | jq -e '.' &>/dev/null; then
        log_error "Invalid JSON"
        echo "invalid_json"
        return 2
    fi

    # Check required fields
    local missing=()
    for field in $REQUIRED_FIELDS; do
        local value
        value=$(echo "$checkpoint" | jq -r ".$field // empty")
        if [[ -z "$value" ]]; then
            missing+=("$field")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing fields: ${missing[*]}"
        echo "missing_fields:${missing[*]}"
        return 2
    fi

    # Validate status
    local status
    status=$(echo "$checkpoint" | jq -r '.status // ""')
    case "$status" in
        in_progress|completed|paused|error|hitl_pending)
            ;;
        *)
            log_error "Invalid status: $status"
            echo "invalid_status:$status"
            return 2
            ;;
    esac

    log_info "Checkpoint valid"
    echo "valid"
    return 0
}

#------------------------------------------------------------------------------
# Clear/Archive Operations
#------------------------------------------------------------------------------

# Clear current checkpoint (archive it first)
# Usage: clear_checkpoint [--archive]
clear_checkpoint() {
    local archive=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --archive)
                archive=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -f "$CURRENT_CHECKPOINT" ]]; then
        log_info "No checkpoint to clear"
        return 0
    fi

    if [[ "$archive" == "true" ]]; then
        # Archive to timestamped file
        local archive_file
        archive_file="$STATE_DIR/checkpoint-$(date +%Y%m%d-%H%M%S).json"
        mv "$CURRENT_CHECKPOINT" "$archive_file"
        log_info "Checkpoint archived: $archive_file"
    else
        rm "$CURRENT_CHECKPOINT"
        log_info "Checkpoint cleared"
    fi

    return 0
}

# Update checkpoint with new values
# Usage: update_checkpoint [--phase PHASE] [--task TASK] [--status STATUS] [--notes NOTES]
update_checkpoint() {
    if [[ ! -f "$CURRENT_CHECKPOINT" ]]; then
        log_error "No current checkpoint to update"
        return 4
    fi

    local updates=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --phase)
                updates+=(".phase = \"$2\"")
                shift 2
                ;;
            --task)
                updates+=(".task_index = $2")
                shift 2
                ;;
            --status)
                updates+=(".status = \"$2\"")
                shift 2
                ;;
            --notes)
                updates+=(".notes = \"$2\"")
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ${#updates[@]} -eq 0 ]]; then
        log_warn "No updates specified"
        return 0
    fi

    # Always update timestamp
    updates+=(".updated_at = \"$(date -Iseconds)\"")

    # Build jq expression
    local jq_expr
    jq_expr=$(IFS="|"; echo "${updates[*]}")

    # Read, update, and write
    local current updated
    current=$(cat "$CURRENT_CHECKPOINT")
    updated=$(echo "$current" | jq "$jq_expr")

    if ! atomic_write "$CURRENT_CHECKPOINT" "$updated"; then
        log_error "Failed to update checkpoint"
        return 3
    fi

    # Log the update
    append_to_session_log "$updated"

    log_success "Checkpoint updated"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
checkpoint-write.sh - Checkpoint JSON File Operations for SAGE

Usage:
  checkpoint-write.sh <command> [options]

Commands:
  create <epic> <story> <phase> [task]  Create checkpoint JSON
  write                    Write checkpoint to file (reads stdin)
  update                   Update existing checkpoint
  read                     Read current checkpoint
  validate                 Validate checkpoint JSON
  log <event>              Log event to session log
  clear                    Clear current checkpoint

Options (create):
  --status STATUS    Checkpoint status (default: in_progress)
  --notes TEXT       Optional notes
  --started-at TIME  Override start time

Options (write):
  --file FILE        Custom output file

Options (read):
  --file FILE        Custom input file
  --field FIELD      Extract specific field

Options (update):
  --phase PHASE      Update phase
  --task INDEX       Update task index
  --status STATUS    Update status
  --notes TEXT       Update notes

Options (log):
  --data JSON        Additional data for log entry

Options (clear):
  --archive          Archive instead of delete

Global Options:
  -v, --verbose      Enable verbose output
  -h, --help         Show this help

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - Validation error
  3 - Write error
  4 - No checkpoint found

Examples:
  # Create and write checkpoint
  checkpoint-write.sh create epic-3 3-1-protocol "Phase 1" 2 | checkpoint-write.sh write

  # Update current checkpoint
  checkpoint-write.sh update --phase "Phase 2" --task 0 --status in_progress

  # Read specific field
  checkpoint-write.sh read --field commit_hash

  # Log custom event
  checkpoint-write.sh log story_complete --data '{"story_id": "3-1"}'

  # Clear with archive
  checkpoint-write.sh clear --archive

EOF
}

main() {
    local command=""

    # Parse global options
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
            -*)
                break
                ;;
            *)
                command="$1"
                shift
                break
                ;;
        esac
    done

    # Initialize
    sage_init --require-git

    # Dispatch command
    case "$command" in
        create)
            create_checkpoint "$@"
            ;;
        write)
            write_checkpoint "$@"
            ;;
        update)
            update_checkpoint "$@"
            ;;
        read)
            read_checkpoint "$@"
            ;;
        validate)
            validate_checkpoint "$@"
            ;;
        log)
            if [[ $# -lt 1 ]]; then
                log_error "Missing event type"
                exit 1
            fi
            log_event "$@"
            ;;
        clear)
            clear_checkpoint "$@"
            ;;
        "")
            log_error "No command specified"
            usage
            exit 1
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
