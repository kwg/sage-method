#!/usr/bin/env bash
#
# git-branch.sh - Git Branch Management for SAGE Workflows
#
# This script handles all branch operations for epic and story workflows:
# - Create epic branches from dev
# - Create story branches from epic branches
# - Switch branches with validation
# - Merge branches with conflict detection
# - Sync with upstream branches
#
# Usage:
#   ./git-branch.sh <command> [options]
#
# Commands:
#   create-epic    Create epic branch from dev
#   create-story   Create story branch from epic branch
#   switch         Switch to a branch with validation
#   merge          Merge source branch into current branch
#   sync           Sync current branch with upstream
#   exists         Check if a branch exists
#   current        Show current branch name
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Git command failed
#   3 - Branch already exists (for create operations)
#   4 - Branch not found
#   5 - Merge conflict
#   6 - Uncommitted changes blocking operation
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Branch Operations
#------------------------------------------------------------------------------

# Check if a branch exists (local or remote)
# Usage: branch_exists <branch_name> [--remote]
branch_exists() {
    local branch="$1"
    local check_remote="${2:-}"

    if [[ "$check_remote" == "--remote" ]]; then
        git ls-remote --exit-code --heads origin "$branch" &>/dev/null
    else
        git show-ref --verify --quiet "refs/heads/$branch"
    fi
}

# Get current branch name
current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Check for uncommitted changes
has_uncommitted_changes() {
    ! git diff-index --quiet HEAD -- 2>/dev/null
}

# Stash uncommitted changes with message
stash_changes() {
    local message="${1:-SAGE auto-stash}"
    if has_uncommitted_changes; then
        log_info "Stashing uncommitted changes: $message"
        git stash push -m "$message"
        return 0
    fi
    return 1
}

# Create epic branch from dev
# Usage: create_epic_branch <epic_id>
create_epic_branch() {
    local epic_id="$1"
    local branch_name="$epic_id"

    log_info "Creating epic branch: $branch_name"

    # Ensure we're on dev and up to date
    log_verbose "Switching to dev branch"
    if ! git checkout dev 2>/dev/null; then
        log_error "Failed to checkout dev branch"
        return 2
    fi

    log_verbose "Pulling latest from origin/dev"
    if ! git pull origin dev 2>/dev/null; then
        log_warn "Failed to pull from origin/dev, continuing with local state"
    fi

    # Check if branch already exists
    if branch_exists "$branch_name"; then
        log_info "Epic branch '$branch_name' already exists, checking out and merging dev"
        git checkout "$branch_name" || return 2
        git merge dev --no-edit || {
            log_error "Merge conflict while updating epic branch"
            return 5
        }
        echo "$branch_name"
        return 0
    fi

    # Create new branch
    log_verbose "Creating new branch: $branch_name"
    if ! git checkout -b "$branch_name"; then
        log_error "Failed to create branch: $branch_name"
        return 2
    fi

    log_success "Created epic branch: $branch_name"
    echo "$branch_name"
    return 0
}

# Create story branch from epic branch
# Usage: create_story_branch <story_id> <epic_branch>
create_story_branch() {
    local story_id="$1"
    local epic_branch="$2"
    local branch_name="$story_id"

    log_info "Creating story branch: $branch_name from $epic_branch"

    # Ensure epic branch exists
    if ! branch_exists "$epic_branch"; then
        log_error "Epic branch '$epic_branch' does not exist"
        return 4
    fi

    # Switch to epic branch first
    log_verbose "Switching to epic branch: $epic_branch"
    if ! git checkout "$epic_branch" 2>/dev/null; then
        log_error "Failed to checkout epic branch: $epic_branch"
        return 2
    fi

    # Check if story branch already exists
    if branch_exists "$branch_name"; then
        log_info "Story branch '$branch_name' already exists, checking out and merging epic"
        git checkout "$branch_name" || return 2
        git merge "$epic_branch" --no-edit || {
            log_error "Merge conflict while updating story branch"
            return 5
        }
        echo "$branch_name"
        return 0
    fi

    # Create new branch from epic
    log_verbose "Creating new branch: $branch_name"
    if ! git checkout -b "$branch_name"; then
        log_error "Failed to create branch: $branch_name"
        return 2
    fi

    log_success "Created story branch: $branch_name (from $epic_branch)"
    echo "$branch_name"
    return 0
}

# Switch to a branch with validation
# Usage: switch_branch <branch_name> [--stash]
switch_branch() {
    local branch_name="$1"
    local auto_stash="${2:-}"

    log_info "Switching to branch: $branch_name"

    # Check if branch exists
    if ! branch_exists "$branch_name"; then
        log_error "Branch '$branch_name' does not exist"
        return 4
    fi

    # Handle uncommitted changes
    if has_uncommitted_changes; then
        if [[ "$auto_stash" == "--stash" ]]; then
            stash_changes "Auto-stash before switching to $branch_name"
        else
            log_error "Uncommitted changes detected. Use --stash or commit first."
            return 6
        fi
    fi

    # Switch
    if ! git checkout "$branch_name" 2>/dev/null; then
        log_error "Failed to checkout branch: $branch_name"
        return 2
    fi

    log_success "Switched to branch: $branch_name"
    echo "$branch_name"
    return 0
}

# Merge source branch into current branch
# Usage: merge_branch <source_branch> [--no-commit]
merge_branch() {
    local source_branch="$1"
    local no_commit="${2:-}"
    local current
    current=$(current_branch)

    log_info "Merging $source_branch into $current"

    # Check if source branch exists
    if ! branch_exists "$source_branch"; then
        log_error "Source branch '$source_branch' does not exist"
        return 4
    fi

    # Perform merge
    local merge_args="--no-edit"
    if [[ "$no_commit" == "--no-commit" ]]; then
        merge_args="$merge_args --no-commit"
    fi

    if ! git merge $source_branch $merge_args 2>/dev/null; then
        # Check if it's a conflict
        if git diff --name-only --diff-filter=U | grep -q .; then
            log_error "Merge conflict detected"
            log_error "Conflicting files:"
            git diff --name-only --diff-filter=U >&2
            return 5
        fi
        log_error "Merge failed"
        return 2
    fi

    log_success "Merged $source_branch into $current"
    return 0
}

# Sync current branch with its upstream (pull and merge)
# Usage: sync_with_upstream [upstream_branch]
sync_with_upstream() {
    local upstream="${1:-}"
    local current
    current=$(current_branch)

    # If no upstream specified, try to detect tracking branch
    if [[ -z "$upstream" ]]; then
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || echo "")
        if [[ -z "$upstream" ]]; then
            log_error "No upstream branch configured for $current"
            return 4
        fi
    fi

    log_info "Syncing $current with $upstream"

    # Fetch latest
    log_verbose "Fetching from origin"
    git fetch origin 2>/dev/null || log_warn "Fetch failed, continuing with local state"

    # Pull/merge
    if ! git pull origin "$current" --no-edit 2>/dev/null; then
        if git diff --name-only --diff-filter=U | grep -q .; then
            log_error "Merge conflict during sync"
            return 5
        fi
        log_warn "Pull failed, branch may not exist on remote yet"
    fi

    log_success "Synced $current"
    return 0
}

# Push current branch to remote
# Usage: push_branch [--force] [--set-upstream]
push_branch() {
    local force=""
    local set_upstream=""
    local current
    current=$(current_branch)

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f) force="--force" ;;
            --set-upstream|-u) set_upstream="-u" ;;
            *) log_warn "Unknown option: $1" ;;
        esac
        shift
    done

    log_info "Pushing branch: $current"

    if ! git push $set_upstream $force origin "$current" 2>&1; then
        log_error "Failed to push branch: $current"
        return 2
    fi

    log_success "Pushed branch: $current"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
git-branch.sh - Git Branch Management for SAGE Workflows

Usage:
  git-branch.sh <command> [options]

Commands:
  create-epic <epic_id>                Create epic branch from dev
  create-story <story_id> <epic>       Create story branch from epic
  switch <branch> [--stash]            Switch to branch (optionally stash changes)
  merge <source> [--no-commit]         Merge source into current branch
  sync [upstream]                      Sync current branch with upstream
  push [--force] [--set-upstream]      Push current branch to remote
  exists <branch> [--remote]           Check if branch exists (exit 0 if yes)
  current                              Print current branch name

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help message

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - Git command failed
  3 - Branch already exists
  4 - Branch not found
  5 - Merge conflict
  6 - Uncommitted changes blocking operation

Examples:
  # Create epic branch
  git-branch.sh create-epic epic-3-architecture

  # Create story branch from epic
  git-branch.sh create-story 3-1-protocol-extraction epic-3-architecture

  # Switch with auto-stash
  git-branch.sh switch main --stash

  # Merge story into epic
  git checkout epic-3-architecture
  git-branch.sh merge 3-1-protocol-extraction

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
                # Unknown option, might be command-specific
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
        create-epic)
            [[ $# -lt 1 ]] && { log_error "Missing epic_id"; exit 1; }
            create_epic_branch "$1"
            ;;
        create-story)
            [[ $# -lt 2 ]] && { log_error "Missing story_id or epic_branch"; exit 1; }
            create_story_branch "$1" "$2"
            ;;
        switch)
            [[ $# -lt 1 ]] && { log_error "Missing branch name"; exit 1; }
            switch_branch "$@"
            ;;
        merge)
            [[ $# -lt 1 ]] && { log_error "Missing source branch"; exit 1; }
            merge_branch "$@"
            ;;
        sync)
            sync_with_upstream "$@"
            ;;
        push)
            push_branch "$@"
            ;;
        exists)
            [[ $# -lt 1 ]] && { log_error "Missing branch name"; exit 1; }
            if branch_exists "$@"; then
                echo "true"
                exit 0
            else
                echo "false"
                exit 4
            fi
            ;;
        current)
            current_branch
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
