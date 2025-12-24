#!/usr/bin/env bash
#
# git-checkpoint.sh - Git Commit and Checkpoint Operations for SAGE
#
# This script handles checkpoint-related git operations:
# - Stage changes with exclusions
# - Create checkpoint commits with standard naming
# - Micro-commits for chunk-level progress
# - Get commit hashes for checkpoint records
#
# Usage:
#   ./git-checkpoint.sh <command> [options]
#
# Commands:
#   stage              Stage all changes (with exclusions)
#   commit             Create a checkpoint commit
#   micro-commit       Create a micro-commit for a chunk
#   hash               Get current HEAD commit hash
#   verify-clean       Check for uncommitted changes
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - Git command failed
#   3 - Nothing to commit
#   4 - Pre-commit hook failed
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Files to exclude from staging (patterns)
EXCLUDE_PATTERNS=(
    "*.log"
    ".sage/logs/*"
    "*.tmp"
    "*.bak"
)

#------------------------------------------------------------------------------
# Checkpoint Operations
#------------------------------------------------------------------------------

# Stage all changes, excluding certain patterns
# Usage: stage_changes [--exclude <pattern>...]
stage_changes() {
    local extra_excludes=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --exclude)
                extra_excludes+=("$2")
                shift 2
                ;;
            *)
                log_warn "Unknown option: $1"
                shift
                ;;
        esac
    done

    log_info "Staging changes"

    # Stage everything first
    git add -A

    # Unstage excluded patterns
    for pattern in "${EXCLUDE_PATTERNS[@]}" "${extra_excludes[@]}"; do
        git reset -- "$pattern" 2>/dev/null || true
    done

    # Check if there's anything staged
    if git diff --cached --quiet; then
        log_warn "No changes to stage"
        return 3
    fi

    local staged_count
    staged_count=$(git diff --cached --name-only | wc -l)
    log_success "Staged $staged_count file(s)"
    return 0
}

# Create a checkpoint commit
# Usage: create_checkpoint_commit <epic_id> <story_id> <task_num> <step>
# Example: create_checkpoint_commit epic-3 3-1-protocol 2 implement
create_checkpoint_commit() {
    local epic_id="${1:-}"
    local story_id="${2:-}"
    local task_num="${3:-}"
    local step="${4:-checkpoint}"

    # Build commit message
    local message
    if [[ -n "$epic_id" && -n "$story_id" && -n "$task_num" ]]; then
        message="checkpoint: ${epic_id}-${story_id}-task-${task_num}-${step}"
    elif [[ -n "$story_id" ]]; then
        message="checkpoint: ${story_id}"
    else
        message="checkpoint: $(date +%Y%m%d-%H%M%S)"
    fi

    log_info "Creating checkpoint commit: $message"

    # Ensure there are staged changes
    if git diff --cached --quiet; then
        # Try to stage changes
        git add -A
        if git diff --cached --quiet; then
            log_warn "Nothing to commit"
            return 3
        fi
    fi

    # Attempt commit
    if ! git commit -m "$message" 2>&1; then
        local exit_code=$?

        # Check if pre-commit hook modified files
        if git diff --name-only | grep -q .; then
            log_info "Pre-commit hook modified files, re-staging and retrying"
            git add -A
            if ! git commit -m "$message" 2>&1; then
                log_error "Commit failed after pre-commit hook retry"
                return 4
            fi
        else
            log_error "Commit failed"
            return 2
        fi
    fi

    # Get and output the commit hash
    local commit_hash
    commit_hash=$(git rev-parse HEAD)
    log_success "Created checkpoint: $commit_hash"
    echo "$commit_hash"
    return 0
}

# Create a micro-commit for chunk completion
# Usage: create_micro_commit <story_id> <chunk_name>
create_micro_commit() {
    local story_id="$1"
    local chunk_name="$2"

    local message="${story_id}: ${chunk_name}"

    log_info "Creating micro-commit: $message"

    # Stage all changes
    git add -A

    # Check if there's anything to commit
    if git diff --cached --quiet; then
        log_warn "Nothing to commit for chunk: $chunk_name"
        return 3
    fi

    # Commit
    if ! git commit -m "$message" 2>&1; then
        local exit_code=$?

        # Handle pre-commit hook
        if git diff --name-only | grep -q .; then
            log_info "Pre-commit hook modified files, amending commit"
            git add -A
            if ! git commit --amend --no-edit 2>&1; then
                log_error "Commit failed after pre-commit amendment"
                return 4
            fi
        else
            log_error "Micro-commit failed"
            return 2
        fi
    fi

    local commit_hash
    commit_hash=$(git rev-parse HEAD)
    log_success "Micro-commit: $commit_hash"
    echo "$commit_hash"
    return 0
}

# Get current HEAD commit hash
# Usage: get_commit_hash [--short]
get_commit_hash() {
    local short="${1:-}"

    if [[ "$short" == "--short" ]]; then
        git rev-parse --short HEAD 2>/dev/null
    else
        git rev-parse HEAD 2>/dev/null
    fi
}

# Verify working directory is clean
# Usage: verify_clean_state [--json]
verify_clean_state() {
    local json_output="${1:-}"

    local has_staged=false
    local has_unstaged=false
    local has_untracked=false

    # Check staged changes
    if ! git diff --cached --quiet 2>/dev/null; then
        has_staged=true
    fi

    # Check unstaged changes
    if ! git diff --quiet 2>/dev/null; then
        has_unstaged=true
    fi

    # Check untracked files
    if [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
        has_untracked=true
    fi

    if [[ "$json_output" == "--json" ]]; then
        cat << EOF
{
  "clean": $(if [[ "$has_staged" == "false" && "$has_unstaged" == "false" && "$has_untracked" == "false" ]]; then echo "true"; else echo "false"; fi),
  "staged_changes": $has_staged,
  "unstaged_changes": $has_unstaged,
  "untracked_files": $has_untracked
}
EOF
        if [[ "$has_staged" == "true" || "$has_unstaged" == "true" || "$has_untracked" == "true" ]]; then
            return 1
        fi
        return 0
    fi

    # Text output
    if [[ "$has_staged" == "true" || "$has_unstaged" == "true" || "$has_untracked" == "true" ]]; then
        log_warn "Working directory is not clean:"
        [[ "$has_staged" == "true" ]] && log_warn "  - Staged changes present"
        [[ "$has_unstaged" == "true" ]] && log_warn "  - Unstaged changes present"
        [[ "$has_untracked" == "true" ]] && log_warn "  - Untracked files present"
        return 1
    fi

    log_info "Working directory is clean"
    return 0
}

# Mark task complete in story file and commit
# Usage: mark_tasks_complete <story_file> <task_ids...>
mark_tasks_complete() {
    local story_file="$1"
    shift
    local task_ids=("$@")

    if [[ ! -f "$story_file" ]]; then
        log_error "Story file not found: $story_file"
        return 4
    fi

    log_info "Marking tasks complete in $story_file: ${task_ids[*]}"

    # Read file
    local content
    content=$(cat "$story_file")

    # Replace task checkboxes
    for task_id in "${task_ids[@]}"; do
        # Match patterns like "- [ ] **Task 1.1:" or "- [ ] 1.1:"
        content=$(echo "$content" | sed -E "s/^(- )\[ \]( \*\*Task ${task_id}:|- \[ \] ${task_id}:)/\1[x]\2/")
    done

    # Write back
    echo "$content" > "$story_file"

    # Stage and commit
    git add "$story_file"
    local story_name
    story_name=$(basename "$story_file" .md)
    git commit -m "${story_name}: mark tasks ${task_ids[*]} complete" 2>/dev/null || {
        log_warn "No changes to commit (tasks may already be marked)"
        return 0
    }

    log_success "Marked tasks complete and committed"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
git-checkpoint.sh - Git Commit and Checkpoint Operations for SAGE

Usage:
  git-checkpoint.sh <command> [options]

Commands:
  stage [--exclude pattern]           Stage changes (with exclusions)
  commit <epic> <story> <task> <step> Create checkpoint commit
  micro-commit <story> <chunk>        Create micro-commit for chunk
  hash [--short]                      Get current HEAD commit hash
  verify-clean [--json]               Check for uncommitted changes
  mark-complete <file> <task_ids...>  Mark tasks complete in story file

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help message

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - Git command failed
  3 - Nothing to commit
  4 - Pre-commit hook failed / File not found

Examples:
  # Stage all changes
  git-checkpoint.sh stage

  # Create checkpoint commit
  git-checkpoint.sh commit epic-3 3-1-protocol 2 implement

  # Create micro-commit
  git-checkpoint.sh micro-commit 3-1-protocol "implement core functions"

  # Check if clean
  git-checkpoint.sh verify-clean --json

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
        stage)
            stage_changes "$@"
            ;;
        commit)
            create_checkpoint_commit "$@"
            ;;
        micro-commit)
            [[ $# -lt 2 ]] && { log_error "Missing story_id or chunk_name"; exit 1; }
            create_micro_commit "$1" "$2"
            ;;
        hash)
            get_commit_hash "$@"
            ;;
        verify-clean)
            verify_clean_state "$@"
            ;;
        mark-complete)
            [[ $# -lt 2 ]] && { log_error "Missing story_file or task_ids"; exit 1; }
            mark_tasks_complete "$@"
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
