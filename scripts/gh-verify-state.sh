#!/usr/bin/env bash
#
# gh-verify-state.sh - Verify GitHub State Matches Checkpoint State
#
# This script compares the expected state from a checkpoint JSON file
# against the actual state of issues and milestones on GitHub.
#
# Usage:
#   ./gh-verify-state.sh <checkpoint_file> [options]
#
# Options:
#   --owner           GitHub owner (default: from git remote)
#   --repo            GitHub repository (default: from git remote)
#   --verbose, -v     Show detailed comparison output
#
# Exit codes:
#   0 - Verification passed (states match)
#   1 - Verification failed (discrepancies found)
#   2 - Error (missing file, API error, etc.)
#
set -uo pipefail

SCRIPT_NAME="$(basename "$0")"
VERBOSE=false

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

get_repo_info() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -z "$remote_url" ]]; then
        echo "ERROR: Cannot determine repository from git remote" >&2
        return 1
    fi

    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        return 0
    fi

    echo "ERROR: Cannot parse GitHub URL from remote: $remote_url" >&2
    return 1
}

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

#------------------------------------------------------------------------------
# Verification Functions
#------------------------------------------------------------------------------

# Get issue state from GitHub
get_issue_state() {
    local issue_number="$1"

    gh api "repos/$OWNER/$REPO/issues/$issue_number" \
        --jq '{number: .number, state: .state, title: .title, labels: [.labels[].name]}' \
        2>/dev/null
}

# Get milestone state from GitHub
get_milestone_state() {
    local milestone_number="$1"

    gh api "repos/$OWNER/$REPO/milestones/$milestone_number" \
        --jq '{number: .number, state: .state, title: .title, open_issues: .open_issues, closed_issues: .closed_issues}' \
        2>/dev/null
}

# Compare expected vs actual state for a story
verify_story() {
    local story_id="$1"
    local expected_status="$2"
    local issue_number="${3:-}"
    local discrepancies=()

    if [[ -z "$issue_number" ]]; then
        log_verbose "Story $story_id: No issue number in checkpoint, skipping"
        echo "skip"
        return 0
    fi

    log_verbose "Verifying story $story_id (issue #$issue_number)..."

    local actual_state
    actual_state=$(get_issue_state "$issue_number")

    if [[ -z "$actual_state" ]]; then
        echo "error:Issue #$issue_number not found on GitHub"
        return 1
    fi

    local actual_issue_state
    actual_issue_state=$(echo "$actual_state" | jq -r '.state')

    # Map expected status to GitHub issue state
    local expected_issue_state
    case "$expected_status" in
        completed)
            expected_issue_state="closed"
            ;;
        in-progress|pending|blocked)
            expected_issue_state="open"
            ;;
        *)
            expected_issue_state="open"
            ;;
    esac

    if [[ "$actual_issue_state" != "$expected_issue_state" ]]; then
        echo "mismatch:Story $story_id - expected issue state '$expected_issue_state' but found '$actual_issue_state'"
        return 1
    fi

    echo "pass"
    return 0
}

# Verify milestone state
verify_milestone() {
    local milestone_number="$1"
    local expected_state="${2:-open}"

    if [[ -z "$milestone_number" ]]; then
        log_verbose "No milestone number in checkpoint, skipping"
        echo "skip"
        return 0
    fi

    log_verbose "Verifying milestone #$milestone_number..."

    local actual_state
    actual_state=$(get_milestone_state "$milestone_number")

    if [[ -z "$actual_state" ]]; then
        echo "error:Milestone #$milestone_number not found on GitHub"
        return 1
    fi

    local actual_milestone_state
    actual_milestone_state=$(echo "$actual_state" | jq -r '.state')

    if [[ "$actual_milestone_state" != "$expected_state" ]]; then
        echo "mismatch:Milestone - expected state '$expected_state' but found '$actual_milestone_state'"
        return 1
    fi

    echo "pass"
    return 0
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local checkpoint_file=""
    local discrepancies=()
    local passed=0
    local failed=0
    local skipped=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --owner)
                OWNER="$2"
                shift 2
                ;;
            --repo)
                REPO="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME <checkpoint_file> [options]"
                echo ""
                echo "Verify GitHub state matches checkpoint state."
                echo ""
                echo "Options:"
                echo "  -v, --verbose  Show detailed comparison output"
                echo "  --owner        GitHub owner"
                echo "  --repo         GitHub repository"
                echo "  -h, --help     Show this help message"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 2
                ;;
            *)
                if [[ -z "$checkpoint_file" ]]; then
                    checkpoint_file="$1"
                else
                    log_error "Too many positional arguments"
                    exit 2
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$checkpoint_file" ]]; then
        log_error "Missing required argument: checkpoint_file"
        echo "Usage: $SCRIPT_NAME <checkpoint_file> [options]" >&2
        exit 2
    fi

    if [[ ! -f "$checkpoint_file" ]]; then
        log_error "Checkpoint file not found: $checkpoint_file"
        exit 2
    fi

    # Check gh CLI is available and authenticated
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found. Please install: https://cli.github.com/"
        exit 2
    fi

    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI not authenticated. Run: gh auth login"
        exit 2
    fi

    # Get repo info if not specified
    if [[ -z "${OWNER:-}" ]] || [[ -z "${REPO:-}" ]]; then
        if ! get_repo_info; then
            exit 2
        fi
    fi

    log_info "Repository: $OWNER/$REPO"
    log_info "Checkpoint: $checkpoint_file"

    #--------------------------------------------------------------------------
    # Load checkpoint data
    #--------------------------------------------------------------------------

    local checkpoint_data
    checkpoint_data=$(cat "$checkpoint_file")

    if ! echo "$checkpoint_data" | jq empty 2>/dev/null; then
        log_error "Invalid JSON in checkpoint file"
        exit 2
    fi

    #--------------------------------------------------------------------------
    # Verify milestone (if present)
    #--------------------------------------------------------------------------

    local milestone_number
    milestone_number=$(echo "$checkpoint_data" | jq -r '.milestone_number // empty')

    if [[ -n "$milestone_number" ]]; then
        local result
        result=$(verify_milestone "$milestone_number")

        case "${result%%:*}" in
            pass)
                ((passed++))
                log_verbose "Milestone verification: PASS"
                ;;
            skip)
                ((skipped++))
                ;;
            mismatch|error)
                ((failed++))
                discrepancies+=("${result#*:}")
                log_warn "Milestone verification: FAIL - ${result#*:}"
                ;;
        esac
    fi

    #--------------------------------------------------------------------------
    # Verify completed stories
    #--------------------------------------------------------------------------

    local completed_stories
    completed_stories=$(echo "$checkpoint_data" | jq -r '.completed_stories // [] | .[]')

    while IFS= read -r story_id; do
        [[ -z "$story_id" ]] && continue

        # Try to find issue number in metrics
        local issue_number
        issue_number=$(echo "$checkpoint_data" | jq -r --arg sid "$story_id" \
            '.metrics.stories[] | select(.story_id == $sid) | .issue_number // empty')

        local result
        result=$(verify_story "$story_id" "completed" "$issue_number")

        case "${result%%:*}" in
            pass)
                ((passed++))
                log_verbose "Story $story_id: PASS"
                ;;
            skip)
                ((skipped++))
                ;;
            mismatch|error)
                ((failed++))
                discrepancies+=("${result#*:}")
                log_warn "Story $story_id: FAIL - ${result#*:}"
                ;;
        esac
    done <<< "$completed_stories"

    #--------------------------------------------------------------------------
    # Verify current story (if present)
    #--------------------------------------------------------------------------

    local current_story
    current_story=$(echo "$checkpoint_data" | jq -r '.current_story // empty')

    if [[ -n "$current_story" ]]; then
        local issue_number
        issue_number=$(echo "$checkpoint_data" | jq -r --arg sid "$current_story" \
            '.metrics.stories[] | select(.story_id == $sid) | .issue_number // empty')

        local result
        result=$(verify_story "$current_story" "in-progress" "$issue_number")

        case "${result%%:*}" in
            pass)
                ((passed++))
                log_verbose "Current story $current_story: PASS"
                ;;
            skip)
                ((skipped++))
                ;;
            mismatch|error)
                ((failed++))
                discrepancies+=("${result#*:}")
                log_warn "Current story $current_story: FAIL - ${result#*:}"
                ;;
        esac
    fi

    #--------------------------------------------------------------------------
    # Output results
    #--------------------------------------------------------------------------

    echo ""
    log_info "Verification Summary:"
    log_info "  Passed:  $passed"
    log_info "  Failed:  $failed"
    log_info "  Skipped: $skipped"

    if [[ ${#discrepancies[@]} -gt 0 ]]; then
        echo ""
        log_warn "Discrepancies found:"
        for disc in "${discrepancies[@]}"; do
            echo "  - $disc" >&2
        done
    fi

    # Output JSON result
    jq -n \
        --argjson passed "$passed" \
        --argjson failed "$failed" \
        --argjson skipped "$skipped" \
        --argjson discrepancies "$(printf '%s\n' "${discrepancies[@]:-}" | jq -R . | jq -s .)" \
        '{
            verified: ($failed == 0),
            passed: $passed,
            failed: $failed,
            skipped: $skipped,
            discrepancies: $discrepancies
        }'

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi

    exit 0
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
