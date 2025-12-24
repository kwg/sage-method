#!/usr/bin/env bash
#
# git-recover.sh - Git Recovery Operations for SAGE
#
# This script handles recovery operations when checkpoint rollback is needed:
# - Stash uncommitted changes before recovery
# - Reset to checkpoint commit
# - Verify reset succeeded
# - List available recovery points (stashes, checkpoints)
#
# Usage:
#   ./git-recover.sh <command> [options]
#
# Commands:
#   reset <commit>      Hard reset to specific commit (with safety stash)
#   stash               Stash current changes with descriptive message
#   list-stashes        List available stash entries
#   list-checkpoints    List checkpoint commits
#   verify <commit>     Verify HEAD matches commit
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Git command failed
#   3 - Commit not found
#   4 - Verification failed (HEAD mismatch)
#   5 - Recovery aborted (user safety)
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Recovery Operations
#------------------------------------------------------------------------------

# Stash uncommitted changes with descriptive message
# Usage: stash_uncommitted [message]
stash_uncommitted() {
    local message="${1:-SAGE recovery stash $(date +%Y%m%d-%H%M%S)}"

    # Check if there's anything to stash
    if git diff --quiet && git diff --cached --quiet; then
        local untracked
        untracked=$(git ls-files --others --exclude-standard | wc -l)
        if [[ "$untracked" -eq 0 ]]; then
            log_info "Nothing to stash - working directory is clean"
            return 0
        fi
    fi

    log_info "Stashing uncommitted changes: $message"

    # Include untracked files in stash
    if ! git stash push -u -m "$message" 2>&1; then
        log_error "Failed to stash changes"
        return 2
    fi

    local stash_ref
    stash_ref=$(git stash list | head -1 | cut -d: -f1)
    log_success "Created stash: $stash_ref"
    echo "$stash_ref"
    return 0
}

# Verify a commit exists in the repository
# Usage: verify_commit_exists <commit>
verify_commit_exists() {
    local commit="$1"

    # Validate format (40 hex chars or short form)
    if ! [[ "$commit" =~ ^[0-9a-fA-F]{7,40}$ ]]; then
        log_error "Invalid commit format: $commit"
        return 1
    fi

    # Check if commit exists
    if ! git cat-file -t "$commit" &>/dev/null; then
        log_error "Commit not found in repository: $commit"
        return 3
    fi

    log_verbose "Commit exists: $commit"
    return 0
}

# Reset to checkpoint commit with safety stash
# Usage: reset_to_checkpoint <commit> [--force]
reset_to_checkpoint() {
    local commit="$1"
    local force="${2:-}"

    log_info "Resetting to checkpoint: $commit"

    # Verify commit exists
    if ! verify_commit_exists "$commit"; then
        return 3
    fi

    # Safety stash for uncommitted changes
    local had_changes=false
    if ! git diff --quiet || ! git diff --cached --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
        had_changes=true
        log_warn "Uncommitted changes detected - creating safety stash"
        if ! stash_uncommitted "pre-recovery-safety-$(date +%Y%m%d-%H%M%S)"; then
            if [[ "$force" != "--force" ]]; then
                log_error "Failed to stash changes. Use --force to skip stash."
                return 5
            fi
            log_warn "Proceeding without stash (--force)"
        fi
    fi

    # Execute hard reset
    log_info "Executing git reset --hard $commit"
    if ! git reset --hard "$commit" 2>&1; then
        log_error "Git reset failed"
        return 2
    fi

    # Verify reset succeeded
    local current_head
    current_head=$(git rev-parse HEAD)
    local target_full
    target_full=$(git rev-parse "$commit")

    if [[ "$current_head" != "$target_full" ]]; then
        log_error "HEAD ($current_head) does not match target ($target_full) after reset"
        return 4
    fi

    # Verify working tree is clean
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "Working tree not clean after reset - unexpected state"
    fi

    log_success "Reset to checkpoint: $commit"
    if [[ "$had_changes" == "true" ]]; then
        log_info "Previous changes saved in stash (use 'git stash pop' to restore)"
    fi

    # Output for orchestrator consumption
    echo "$current_head"
    return 0
}

# Verify HEAD matches expected commit
# Usage: verify_reset <commit>
verify_reset() {
    local expected_commit="$1"

    local current_head
    current_head=$(git rev-parse HEAD)
    local expected_full
    expected_full=$(git rev-parse "$expected_commit" 2>/dev/null)

    if [[ -z "$expected_full" ]]; then
        log_error "Cannot resolve commit: $expected_commit"
        return 3
    fi

    if [[ "$current_head" == "$expected_full" ]]; then
        log_success "HEAD matches expected commit"
        echo "true"
        return 0
    else
        log_error "HEAD mismatch: expected $expected_commit, got $current_head"
        echo "false"
        return 4
    fi
}

# List stash entries
# Usage: list_stashes [--json]
list_stashes() {
    local json_output="${1:-}"

    if [[ "$json_output" == "--json" ]]; then
        local stashes
        stashes=$(git stash list --format='{"ref":"%gd","message":"%s","date":"%ai"}' 2>/dev/null | \
            jq -s '.' 2>/dev/null || echo "[]")
        echo "$stashes"
    else
        if ! git stash list 2>/dev/null | head -20; then
            log_info "No stash entries found"
        fi
    fi
    return 0
}

# List checkpoint commits (commits matching checkpoint pattern)
# Usage: list_checkpoints [--limit N] [--json]
list_checkpoints() {
    local limit=10
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit)
                limit="$2"
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

    log_info "Searching for checkpoint commits (limit: $limit)"

    if [[ "$json_output" == "true" ]]; then
        git log --oneline --grep="^checkpoint:" -n "$limit" \
            --format='{"hash":"%H","short":"%h","message":"%s","date":"%ai"}' 2>/dev/null | \
            jq -s '.' 2>/dev/null || echo "[]"
    else
        git log --oneline --grep="^checkpoint:" -n "$limit" 2>/dev/null || {
            log_info "No checkpoint commits found"
        }
    fi
    return 0
}

# Pop the most recent stash
# Usage: pop_stash [stash_ref]
pop_stash() {
    local stash_ref="${1:-stash@{0}}"

    log_info "Popping stash: $stash_ref"

    if ! git stash pop "$stash_ref" 2>&1; then
        log_error "Failed to pop stash (may have conflicts)"
        return 2
    fi

    log_success "Restored stash: $stash_ref"
    return 0
}

# Drop a stash entry
# Usage: drop_stash [stash_ref]
drop_stash() {
    local stash_ref="${1:-stash@{0}}"

    log_info "Dropping stash: $stash_ref"

    if ! git stash drop "$stash_ref" 2>&1; then
        log_error "Failed to drop stash"
        return 2
    fi

    log_success "Dropped stash: $stash_ref"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
git-recover.sh - Git Recovery Operations for SAGE

Usage:
  git-recover.sh <command> [options]

Commands:
  reset <commit> [--force]        Hard reset to commit (with safety stash)
  stash [message]                 Stash current changes
  pop [stash_ref]                 Pop stash (default: stash@{0})
  drop [stash_ref]                Drop stash entry
  verify <commit>                 Verify HEAD matches commit
  list-stashes [--json]           List stash entries
  list-checkpoints [--limit N]    List checkpoint commits

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help message

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - Git command failed
  3 - Commit not found
  4 - Verification failed
  5 - Recovery aborted

Examples:
  # Reset to checkpoint commit (auto-stashes uncommitted changes)
  git-recover.sh reset abc123f

  # Force reset without stashing
  git-recover.sh reset abc123f --force

  # List available checkpoints
  git-recover.sh list-checkpoints --limit 5

  # Stash current work before manual intervention
  git-recover.sh stash "WIP: debugging test failures"

  # Restore stashed work
  git-recover.sh pop

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
        reset)
            [[ $# -lt 1 ]] && { log_error "Missing commit"; exit 1; }
            reset_to_checkpoint "$@"
            ;;
        stash)
            stash_uncommitted "$@"
            ;;
        pop)
            pop_stash "$@"
            ;;
        drop)
            drop_stash "$@"
            ;;
        verify)
            [[ $# -lt 1 ]] && { log_error "Missing commit"; exit 1; }
            verify_reset "$1"
            ;;
        list-stashes)
            list_stashes "$@"
            ;;
        list-checkpoints)
            list_checkpoints "$@"
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
