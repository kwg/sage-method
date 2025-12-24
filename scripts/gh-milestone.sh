#!/usr/bin/env bash
#
# gh-milestone.sh - GitHub Milestone Operations for SAGE
#
# This script handles milestone operations for epic tracking:
# - Create milestones (idempotent)
# - Get milestone by epic ID
# - Update milestone progress
# - Close milestones
#
# Usage:
#   ./gh-milestone.sh <command> [options]
#
# Commands:
#   create          Create milestone for epic (idempotent)
#   get             Get milestone number by epic ID
#   update          Update milestone description with progress
#   close           Close a milestone
#   list            List open milestones
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - GitHub API error
#   3 - Milestone not found
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Milestone Operations
#------------------------------------------------------------------------------

# Create milestone for epic (idempotent - returns existing if found)
# Usage: create_milestone <epic_id> <epic_title> [--due-date DATE] [--description TEXT]
create_milestone() {
    local epic_id=""
    local epic_title=""
    local due_date=""
    local description=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --due-date)
                due_date="$2"
                shift 2
                ;;
            --description)
                description="$2"
                shift 2
                ;;
            *)
                if [[ -z "$epic_id" ]]; then
                    epic_id="$1"
                elif [[ -z "$epic_title" ]]; then
                    epic_title="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$epic_id" ]]; then
        log_error "Usage: create_milestone <epic_id> <epic_title> [options]"
        return 1
    fi

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_info "Creating milestone for epic: $epic_id"

    # Check if milestone already exists
    local existing
    existing=$(gh api "repos/$OWNER/$REPO/milestones" \
        --jq ".[] | select(.title | contains(\"$epic_id\")) | .number" 2>/dev/null | head -1)

    if [[ -n "$existing" ]]; then
        log_info "Milestone already exists: #$existing"
        echo "{\"milestone_number\": $existing, \"created\": false}"
        return 0
    fi

    # Build milestone title
    local title="$epic_id"
    if [[ -n "$epic_title" ]]; then
        title="$epic_id: $epic_title"
    fi

    # Build API request
    local api_args=()
    api_args+=("repos/$OWNER/$REPO/milestones")
    api_args+=(--method POST)
    api_args+=(-f "title=$title")

    if [[ -n "$description" ]]; then
        api_args+=(-f "description=$description")
    else
        api_args+=(-f "description=Epic $epic_id milestone for tracking stories")
    fi

    if [[ -n "$due_date" ]]; then
        api_args+=(-f "due_on=$due_date")
    fi

    api_args+=(-f "state=open")

    # Create milestone
    local result
    result=$(gh api "${api_args[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to create milestone: $result"
        return 2
    fi

    local milestone_number
    milestone_number=$(echo "$result" | jq -r '.number')

    log_success "Created milestone #$milestone_number: $title"
    echo "{\"milestone_number\": $milestone_number, \"created\": true}"
    return 0
}

# Get milestone number by epic ID
# Usage: get_milestone_number <epic_id> [--json]
get_milestone_number() {
    local epic_id="$1"
    local json_output="${2:-}"

    if [[ -z "$epic_id" ]]; then
        log_error "Usage: get_milestone_number <epic_id>"
        return 1
    fi

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_verbose "Looking up milestone for epic: $epic_id"

    local result
    result=$(gh api "repos/$OWNER/$REPO/milestones" \
        --jq ".[] | select(.title | contains(\"$epic_id\"))" 2>/dev/null | head -1)

    if [[ -z "$result" ]]; then
        log_warn "Milestone not found for epic: $epic_id"
        return 3
    fi

    if [[ "$json_output" == "--json" ]]; then
        echo "$result" | jq '{number: .number, title: .title, state: .state, open_issues: .open_issues, closed_issues: .closed_issues}'
    else
        echo "$result" | jq -r '.number'
    fi
    return 0
}

# Update milestone description with progress
# Usage: update_milestone_progress <milestone_number> <completed> <total> [--message TEXT]
update_milestone_progress() {
    local milestone_number=""
    local completed=0
    local total=0
    local message=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --message)
                message="$2"
                shift 2
                ;;
            *)
                if [[ -z "$milestone_number" ]]; then
                    milestone_number="$1"
                elif [[ "$completed" -eq 0 && "$1" =~ ^[0-9]+$ ]]; then
                    completed="$1"
                elif [[ "$total" -eq 0 && "$1" =~ ^[0-9]+$ ]]; then
                    total="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$milestone_number" ]]; then
        log_error "Usage: update_milestone_progress <milestone_number> <completed> <total>"
        return 1
    fi

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_info "Updating milestone #$milestone_number progress: $completed/$total"

    # Build progress description
    local progress_pct=0
    if [[ "$total" -gt 0 ]]; then
        progress_pct=$((completed * 100 / total))
    fi

    local description="**Progress:** $completed/$total stories ($progress_pct%)"
    if [[ -n "$message" ]]; then
        description="$description\n\n$message"
    fi

    # Update milestone
    local result
    result=$(gh api "repos/$OWNER/$REPO/milestones/$milestone_number" \
        --method PATCH \
        -f "description=$description" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to update milestone: $result"
        return 2
    fi

    log_success "Updated milestone #$milestone_number"
    return 0
}

# Close a milestone
# Usage: close_milestone <milestone_number>
close_milestone() {
    local milestone_number="$1"

    if [[ -z "$milestone_number" ]]; then
        log_error "Usage: close_milestone <milestone_number>"
        return 1
    fi

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_info "Closing milestone #$milestone_number"

    local result
    result=$(gh api "repos/$OWNER/$REPO/milestones/$milestone_number" \
        --method PATCH \
        -f "state=closed" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to close milestone: $result"
        return 2
    fi

    log_success "Closed milestone #$milestone_number"
    return 0
}

# List open milestones
# Usage: list_milestones [--json] [--all]
list_milestones() {
    local json_output=false
    local state="open"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                json_output=true
                shift
                ;;
            --all)
                state="all"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_info "Listing milestones (state: $state)"

    local result
    result=$(gh api "repos/$OWNER/$REPO/milestones?state=$state" 2>/dev/null)

    if [[ "$json_output" == "true" ]]; then
        echo "$result" | jq '[.[] | {number: .number, title: .title, state: .state, open_issues: .open_issues, closed_issues: .closed_issues}]'
    else
        echo "$result" | jq -r '.[] | "#\(.number) \(.title) [\(.state)] - \(.open_issues) open, \(.closed_issues) closed"'
    fi
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
gh-milestone.sh - GitHub Milestone Operations for SAGE

Usage:
  gh-milestone.sh <command> [options]

Commands:
  create <epic_id> [title]    Create milestone (idempotent)
  get <epic_id> [--json]      Get milestone number by epic ID
  update <num> <done> <total> Update progress description
  close <milestone_number>    Close a milestone
  list [--json] [--all]       List milestones

Options (create):
  --due-date DATE      Due date (ISO format)
  --description TEXT   Custom description

Options (update):
  --message TEXT       Additional message

Global Options:
  -v, --verbose        Enable verbose output
  -h, --help           Show this help message

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - GitHub API error
  3 - Milestone not found

Examples:
  # Create milestone for epic
  gh-milestone.sh create epic-3 "Architecture Optimization"

  # Get milestone number
  gh-milestone.sh get epic-3

  # Update progress
  gh-milestone.sh update 5 3 5 --message "3 of 5 stories complete"

  # Close milestone
  gh-milestone.sh close 5

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
    sage_init --require-git --require-gh

    # Dispatch command
    case "$command" in
        create)
            create_milestone "$@"
            ;;
        get)
            get_milestone_number "$@"
            ;;
        update)
            update_milestone_progress "$@"
            ;;
        close)
            close_milestone "$@"
            ;;
        list)
            list_milestones "$@"
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
