#!/usr/bin/env bash
#
# git-state-check.sh - Git State Validation for SAGE
#
# This script validates git repository state before operations:
# - Check for uncommitted changes
# - Validate branch existence
# - Check upstream sync status
# - Get divergence from remote
#
# Used as prerequisite checks by other git scripts and the orchestrator.
#
# Usage:
#   ./git-state-check.sh <command> [options]
#
# Commands:
#   clean             Check for uncommitted changes
#   branch-exists     Check if branch exists
#   upstream-sync     Check if in sync with remote
#   divergence        Get commits ahead/behind remote
#   full              Complete state check (JSON output)
#
# Exit codes:
#   0 - Check passed / State is good
#   1 - Invalid arguments
#   2 - Git command failed
#   3 - Check failed (not clean, not synced, etc.)
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# State Check Operations
#------------------------------------------------------------------------------

# Check if working directory is clean
# Usage: check_clean_state [--allow-untracked]
check_clean_state() {
    local allow_untracked="${1:-}"
    local is_clean=true
    local issues=()

    # Check staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
        is_clean=false
        issues+=("staged changes present")
    fi

    # Check unstaged changes
    if ! git diff --quiet 2>/dev/null; then
        is_clean=false
        issues+=("unstaged changes present")
    fi

    # Check untracked files (unless allowed)
    if [[ "$allow_untracked" != "--allow-untracked" ]]; then
        local untracked
        untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)
        if [[ "$untracked" -gt 0 ]]; then
            is_clean=false
            issues+=("$untracked untracked file(s)")
        fi
    fi

    if [[ "$is_clean" == "true" ]]; then
        log_info "Working directory is clean"
        echo "clean"
        return 0
    else
        log_warn "Working directory is not clean: ${issues[*]}"
        echo "dirty"
        return 3
    fi
}

# Check if a branch exists locally or on remote
# Usage: check_branch_exists <branch> [--local|--remote|--any]
check_branch_exists() {
    local branch="$1"
    local scope="${2:---any}"

    local exists_local=false
    local exists_remote=false

    # Check local
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        exists_local=true
    fi

    # Check remote
    if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
        exists_remote=true
    fi

    case "$scope" in
        --local)
            if [[ "$exists_local" == "true" ]]; then
                log_info "Branch exists locally: $branch"
                echo "local"
                return 0
            fi
            ;;
        --remote)
            if [[ "$exists_remote" == "true" ]]; then
                log_info "Branch exists on remote: $branch"
                echo "remote"
                return 0
            fi
            ;;
        --any|*)
            if [[ "$exists_local" == "true" || "$exists_remote" == "true" ]]; then
                if [[ "$exists_local" == "true" && "$exists_remote" == "true" ]]; then
                    log_info "Branch exists locally and on remote: $branch"
                    echo "both"
                elif [[ "$exists_local" == "true" ]]; then
                    log_info "Branch exists locally only: $branch"
                    echo "local"
                else
                    log_info "Branch exists on remote only: $branch"
                    echo "remote"
                fi
                return 0
            fi
            ;;
    esac

    log_warn "Branch not found: $branch"
    echo "none"
    return 3
}

# Check if current branch is in sync with upstream
# Usage: check_upstream_sync [--fetch]
check_upstream_sync() {
    local do_fetch="${1:-}"
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [[ -z "$current_branch" ]]; then
        log_error "Cannot determine current branch"
        return 2
    fi

    # Optionally fetch first
    if [[ "$do_fetch" == "--fetch" ]]; then
        log_verbose "Fetching from origin..."
        git fetch origin 2>/dev/null || log_warn "Fetch failed"
    fi

    # Check if tracking upstream exists
    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")

    if [[ -z "$upstream" ]]; then
        log_info "No upstream configured for $current_branch"
        echo "no-upstream"
        return 0
    fi

    # Get divergence
    local local_commit remote_commit
    local_commit=$(git rev-parse HEAD 2>/dev/null)
    remote_commit=$(git rev-parse "$upstream" 2>/dev/null)

    if [[ "$local_commit" == "$remote_commit" ]]; then
        log_info "Branch is in sync with $upstream"
        echo "synced"
        return 0
    fi

    # Determine direction
    local ahead behind
    ahead=$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo "0")
    behind=$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo "0")

    if [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
        log_warn "Branch has diverged: $ahead ahead, $behind behind"
        echo "diverged"
        return 3
    elif [[ "$ahead" -gt 0 ]]; then
        log_info "Branch is $ahead commit(s) ahead of $upstream"
        echo "ahead"
        return 0
    else
        log_warn "Branch is $behind commit(s) behind $upstream"
        echo "behind"
        return 3
    fi
}

# Get detailed divergence information
# Usage: get_divergence [--json]
get_divergence() {
    local json_output="${1:-}"
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")

    local ahead=0
    local behind=0
    local status="unknown"

    if [[ -n "$upstream" ]]; then
        ahead=$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo "0")
        behind=$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo "0")

        if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
            status="synced"
        elif [[ "$ahead" -gt 0 && "$behind" -gt 0 ]]; then
            status="diverged"
        elif [[ "$ahead" -gt 0 ]]; then
            status="ahead"
        else
            status="behind"
        fi
    else
        status="no-upstream"
    fi

    if [[ "$json_output" == "--json" ]]; then
        cat << EOF
{
  "branch": "$current_branch",
  "upstream": "$upstream",
  "ahead": $ahead,
  "behind": $behind,
  "status": "$status"
}
EOF
    else
        log_info "Branch: $current_branch"
        log_info "Upstream: ${upstream:-none}"
        log_info "Ahead: $ahead, Behind: $behind"
        log_info "Status: $status"
        echo "$status"
    fi
    return 0
}

# Full state check - comprehensive JSON output for orchestrator
# Usage: full_state_check
full_state_check() {
    log_info "Running full state check..."

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

    local head_commit
    head_commit=$(git rev-parse HEAD 2>/dev/null || echo "")

    local head_short
    head_short=$(git rev-parse --short HEAD 2>/dev/null || echo "")

    # Clean state
    local is_clean=true
    local staged_count=0
    local unstaged_count=0
    local untracked_count=0

    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l)
    unstaged_count=$(git diff --name-only 2>/dev/null | wc -l)
    untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l)

    if [[ "$staged_count" -gt 0 || "$unstaged_count" -gt 0 || "$untracked_count" -gt 0 ]]; then
        is_clean=false
    fi

    # Upstream info
    local upstream
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")

    local ahead=0
    local behind=0
    if [[ -n "$upstream" ]]; then
        ahead=$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo "0")
        behind=$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo "0")
    fi

    # Last commit info
    local last_commit_msg
    last_commit_msg=$(git log -1 --format='%s' 2>/dev/null || echo "")

    local last_commit_time
    last_commit_time=$(git log -1 --format='%ai' 2>/dev/null || echo "")

    # Stash count
    local stash_count
    stash_count=$(git stash list 2>/dev/null | wc -l)

    # Output JSON
    cat << EOF
{
  "branch": "$current_branch",
  "head": {
    "commit": "$head_commit",
    "short": "$head_short",
    "message": $(echo "$last_commit_msg" | jq -Rs '.' 2>/dev/null || echo "\"$last_commit_msg\""),
    "time": "$last_commit_time"
  },
  "working_tree": {
    "clean": $is_clean,
    "staged": $staged_count,
    "unstaged": $unstaged_count,
    "untracked": $untracked_count
  },
  "upstream": {
    "ref": $(if [[ -n "$upstream" ]]; then echo "\"$upstream\""; else echo "null"; fi),
    "ahead": $ahead,
    "behind": $behind
  },
  "stashes": $stash_count
}
EOF
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
git-state-check.sh - Git State Validation for SAGE

Usage:
  git-state-check.sh <command> [options]

Commands:
  clean [--allow-untracked]       Check for uncommitted changes
  branch-exists <branch> [scope]  Check if branch exists (--local|--remote|--any)
  upstream-sync [--fetch]         Check sync with remote
  divergence [--json]             Get commits ahead/behind
  full                            Complete state check (JSON)

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help message

Exit Codes:
  0 - Check passed
  1 - Invalid arguments
  2 - Git command failed
  3 - Check failed

Examples:
  # Check if working directory is clean
  git-state-check.sh clean

  # Check if feature branch exists
  git-state-check.sh branch-exists feature/my-branch

  # Get full state as JSON (for orchestrator)
  git-state-check.sh full

  # Check divergence and fetch first
  git-state-check.sh upstream-sync --fetch

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
        clean)
            check_clean_state "$@"
            ;;
        branch-exists)
            [[ $# -lt 1 ]] && { log_error "Missing branch name"; exit 1; }
            check_branch_exists "$@"
            ;;
        upstream-sync)
            check_upstream_sync "$@"
            ;;
        divergence)
            get_divergence "$@"
            ;;
        full)
            full_state_check
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
