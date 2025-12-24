#!/usr/bin/env bash
#
# sprint-update.sh - Sprint Status YAML Updates for SAGE
#
# This script handles sprint status YAML file operations:
# - Read current status
# - Update story status (todo -> in_progress -> done)
# - Update task status within stories
# - Atomic writes with backup
#
# Uses yq for YAML manipulation to preserve formatting.
#
# Usage:
#   ./sprint-update.sh <command> [options]
#
# Commands:
#   read             Read current sprint status
#   story-status     Update story status
#   task-status      Update task status
#   add-story        Add a new story
#   summary          Get sprint summary
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - File not found
#   3 - YAML parse error
#   4 - Write error
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

DEFAULT_STATUS_FILE="docs/sprint-artifacts/sprint-status.yaml"
BACKUP_DIR=".sage/backups"

# Valid status values
VALID_STORY_STATUS="todo in_progress done blocked"
VALID_TASK_STATUS="pending in_progress done skipped"

#------------------------------------------------------------------------------
# Helpers
#------------------------------------------------------------------------------

# Find sprint status file
# Usage: find_status_file [path]
find_status_file() {
    local path="${1:-}"

    if [[ -n "$path" && -f "$path" ]]; then
        echo "$path"
        return 0
    fi

    # Check default location
    if [[ -f "$DEFAULT_STATUS_FILE" ]]; then
        echo "$DEFAULT_STATUS_FILE"
        return 0
    fi

    # Search in docs/sprint-artifacts
    local found
    found=$(find docs/sprint-artifacts -name "sprint-status*.yaml" -o -name "sprint-status*.yml" 2>/dev/null | head -1)

    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi

    log_error "Sprint status file not found"
    return 2
}

# Create backup of status file
# Usage: backup_status_file <file>
backup_status_file() {
    local file="$1"

    mkdir -p "$BACKUP_DIR"

    local backup_name
    backup_name="sprint-status-$(date +%Y%m%d-%H%M%S).yaml"

    cp "$file" "$BACKUP_DIR/$backup_name"
    log_verbose "Backup created: $BACKUP_DIR/$backup_name"
}

# Validate YAML file
# Usage: validate_yaml <file>
validate_yaml() {
    local file="$1"

    if ! yq e '.' "$file" &>/dev/null; then
        log_error "Invalid YAML in: $file"
        return 3
    fi

    return 0
}

#------------------------------------------------------------------------------
# Read Operations
#------------------------------------------------------------------------------

# Read sprint status
# Usage: read_status [--file FILE] [--json]
read_status() {
    local file=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    file=$(find_status_file "$file") || return $?

    if ! validate_yaml "$file"; then
        return 3
    fi

    if [[ "$json_output" == "true" ]]; then
        yq e -o=json '.' "$file"
    else
        cat "$file"
    fi

    return 0
}

# Get story status
# Usage: get_story_status <story_id> [--file FILE]
get_story_status() {
    local story_id=""
    local file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            *)
                if [[ -z "$story_id" ]]; then
                    story_id="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$story_id" ]]; then
        log_error "Missing story ID"
        return 1
    fi

    file=$(find_status_file "$file") || return $?

    local status
    status=$(yq e ".stories[] | select(.id == \"$story_id\") | .status" "$file" 2>/dev/null)

    if [[ -z "$status" || "$status" == "null" ]]; then
        log_warn "Story not found: $story_id"
        echo "unknown"
        return 0
    fi

    echo "$status"
    return 0
}

#------------------------------------------------------------------------------
# Update Operations
#------------------------------------------------------------------------------

# Update story status
# Usage: update_story_status <story_id> <new_status> [--file FILE]
update_story_status() {
    local story_id=""
    local new_status=""
    local file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            *)
                if [[ -z "$story_id" ]]; then
                    story_id="$1"
                elif [[ -z "$new_status" ]]; then
                    new_status="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$story_id" || -z "$new_status" ]]; then
        log_error "Usage: update_story_status <story_id> <new_status>"
        return 1
    fi

    # Validate status
    if ! echo "$VALID_STORY_STATUS" | grep -qw "$new_status"; then
        log_error "Invalid status: $new_status (valid: $VALID_STORY_STATUS)"
        return 1
    fi

    file=$(find_status_file "$file") || return $?

    if ! validate_yaml "$file"; then
        return 3
    fi

    # Check story exists
    local exists
    exists=$(yq e ".stories[] | select(.id == \"$story_id\") | .id" "$file" 2>/dev/null)

    if [[ -z "$exists" ]]; then
        log_error "Story not found: $story_id"
        return 1
    fi

    # Backup before modification
    backup_status_file "$file"

    log_info "Updating story $story_id status to: $new_status"

    # Update status and add timestamp
    local timestamp
    timestamp=$(date -Iseconds)

    yq e -i "(.stories[] | select(.id == \"$story_id\")).status = \"$new_status\"" "$file"
    yq e -i "(.stories[] | select(.id == \"$story_id\")).updated_at = \"$timestamp\"" "$file"

    # Add started_at if transitioning to in_progress
    if [[ "$new_status" == "in_progress" ]]; then
        local started
        started=$(yq e ".stories[] | select(.id == \"$story_id\") | .started_at" "$file" 2>/dev/null)
        if [[ -z "$started" || "$started" == "null" ]]; then
            yq e -i "(.stories[] | select(.id == \"$story_id\")).started_at = \"$timestamp\"" "$file"
        fi
    fi

    # Add completed_at if transitioning to done
    if [[ "$new_status" == "done" ]]; then
        yq e -i "(.stories[] | select(.id == \"$story_id\")).completed_at = \"$timestamp\"" "$file"
    fi

    log_success "Story $story_id updated to: $new_status"
    return 0
}

# Update task status within a story
# Usage: update_task_status <story_id> <task_id> <new_status> [--file FILE]
update_task_status() {
    local story_id=""
    local task_id=""
    local new_status=""
    local file=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            *)
                if [[ -z "$story_id" ]]; then
                    story_id="$1"
                elif [[ -z "$task_id" ]]; then
                    task_id="$1"
                elif [[ -z "$new_status" ]]; then
                    new_status="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$story_id" || -z "$task_id" || -z "$new_status" ]]; then
        log_error "Usage: update_task_status <story_id> <task_id> <new_status>"
        return 1
    fi

    # Validate status
    if ! echo "$VALID_TASK_STATUS" | grep -qw "$new_status"; then
        log_error "Invalid task status: $new_status (valid: $VALID_TASK_STATUS)"
        return 1
    fi

    file=$(find_status_file "$file") || return $?

    if ! validate_yaml "$file"; then
        return 3
    fi

    # Backup before modification
    backup_status_file "$file"

    log_info "Updating task $task_id in story $story_id to: $new_status"

    local timestamp
    timestamp=$(date -Iseconds)

    # Update task status
    yq e -i "(.stories[] | select(.id == \"$story_id\") | .tasks[] | select(.id == \"$task_id\")).status = \"$new_status\"" "$file"
    yq e -i "(.stories[] | select(.id == \"$story_id\") | .tasks[] | select(.id == \"$task_id\")).updated_at = \"$timestamp\"" "$file"

    log_success "Task $task_id updated to: $new_status"
    return 0
}

#------------------------------------------------------------------------------
# Add Operations
#------------------------------------------------------------------------------

# Add a new story to sprint status
# Usage: add_story <story_id> <title> [--file FILE] [--priority PRIORITY]
add_story() {
    local story_id=""
    local title=""
    local file=""
    local priority="medium"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            --priority)
                priority="$2"
                shift 2
                ;;
            *)
                if [[ -z "$story_id" ]]; then
                    story_id="$1"
                elif [[ -z "$title" ]]; then
                    title="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$story_id" || -z "$title" ]]; then
        log_error "Usage: add_story <story_id> <title>"
        return 1
    fi

    file=$(find_status_file "$file") || return $?

    # Check if story already exists
    local exists
    exists=$(yq e ".stories[] | select(.id == \"$story_id\") | .id" "$file" 2>/dev/null)

    if [[ -n "$exists" ]]; then
        log_warn "Story already exists: $story_id"
        return 0
    fi

    # Backup before modification
    backup_status_file "$file"

    log_info "Adding story: $story_id - $title"

    local timestamp
    timestamp=$(date -Iseconds)

    # Add new story
    yq e -i ".stories += [{
        \"id\": \"$story_id\",
        \"title\": \"$title\",
        \"status\": \"todo\",
        \"priority\": \"$priority\",
        \"created_at\": \"$timestamp\",
        \"tasks\": []
    }]" "$file"

    log_success "Story added: $story_id"
    return 0
}

#------------------------------------------------------------------------------
# Summary Operations
#------------------------------------------------------------------------------

# Get sprint summary
# Usage: get_summary [--file FILE] [--json]
get_summary() {
    local file=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file)
                file="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    file=$(find_status_file "$file") || return $?

    local total todo in_progress done blocked
    total=$(yq e '.stories | length' "$file" 2>/dev/null || echo "0")
    todo=$(yq e '[.stories[] | select(.status == "todo")] | length' "$file" 2>/dev/null || echo "0")
    in_progress=$(yq e '[.stories[] | select(.status == "in_progress")] | length' "$file" 2>/dev/null || echo "0")
    done=$(yq e '[.stories[] | select(.status == "done")] | length' "$file" 2>/dev/null || echo "0")
    blocked=$(yq e '[.stories[] | select(.status == "blocked")] | length' "$file" 2>/dev/null || echo "0")

    local progress=0
    if [[ $total -gt 0 ]]; then
        progress=$((done * 100 / total))
    fi

    if [[ "$json_output" == "true" ]]; then
        cat << EOF
{
  "total_stories": $total,
  "todo": $todo,
  "in_progress": $in_progress,
  "done": $done,
  "blocked": $blocked,
  "progress_percent": $progress
}
EOF
    else
        echo "Sprint Summary"
        echo "=============="
        echo "Total:       $total stories"
        echo "Todo:        $todo"
        echo "In Progress: $in_progress"
        echo "Done:        $done"
        echo "Blocked:     $blocked"
        echo "Progress:    $progress%"
    fi

    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
sprint-update.sh - Sprint Status YAML Updates for SAGE

Usage:
  sprint-update.sh <command> [options]

Commands:
  read                       Read current sprint status
  story-status <id> <status> Update story status
  task-status <story> <task> <status>  Update task status
  add-story <id> <title>     Add a new story
  summary                    Get sprint summary

Options:
  --file FILE      Sprint status file path
  --json           Output as JSON
  --priority PRI   Story priority (add-story)
  -v, --verbose    Enable verbose output
  -h, --help       Show this help

Valid Story Status:
  todo, in_progress, done, blocked

Valid Task Status:
  pending, in_progress, done, skipped

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - File not found
  3 - YAML parse error
  4 - Write error

Examples:
  # Read current status
  sprint-update.sh read

  # Update story to in_progress
  sprint-update.sh story-status 3-1-protocol in_progress

  # Update task within story
  sprint-update.sh task-status 3-1-protocol task-1-1 done

  # Add new story
  sprint-update.sh add-story 3-2-testing "Add test coverage" --priority high

  # Get summary as JSON
  sprint-update.sh summary --json

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

    # Check for yq
    if ! command -v yq &>/dev/null; then
        log_error "yq is required but not installed"
        log_info "Install with: nix-env -i yq  or  brew install yq"
        exit 1
    fi

    # Initialize
    sage_init --require-git

    # Dispatch command
    case "$command" in
        read)
            read_status "$@"
            ;;
        story-status)
            update_story_status "$@"
            ;;
        task-status)
            update_task_status "$@"
            ;;
        add-story)
            add_story "$@"
            ;;
        summary)
            get_summary "$@"
            ;;
        get-story)
            get_story_status "$@"
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
