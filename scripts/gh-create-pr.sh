#!/usr/bin/env bash
#
# gh-create-pr.sh - Create GitHub Pull Requests for SAGE Workflows
#
# This script handles PR creation for story and epic completion:
# - Create story PRs (story branch -> epic branch)
# - Create epic PRs (epic branch -> dev)
# - Generate PR body from templates
# - Add labels, milestones, and project board links
#
# Usage:
#   ./gh-create-pr.sh <command> [options]
#
# Commands:
#   story           Create story PR (into epic branch)
#   epic            Create epic PR (into dev branch)
#
# Exit codes:
#   0 - Success
#   1 - Invalid arguments
#   2 - GitHub API error
#   3 - Branch not found
#   4 - PR already exists
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Default labels for different PR types
STORY_LABELS="story,ready-for-review"
EPIC_LABELS="epic,ready-for-review"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

# Ensure branch is pushed to remote
ensure_branch_pushed() {
    local branch="$1"

    # Check if branch exists on remote
    if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
        log_verbose "Branch '$branch' exists on remote"
        # Push any new commits
        git push origin "$branch" 2>/dev/null || log_warn "Push failed, continuing"
        return 0
    fi

    # Branch doesn't exist on remote, push it
    log_info "Pushing branch '$branch' to remote..."
    if ! git push -u origin "$branch" 2>&1; then
        log_error "Failed to push branch '$branch' to remote"
        return 2
    fi

    log_info "Branch '$branch' pushed to remote"
    return 0
}

# Get diff stats for PR body
get_diff_stats() {
    local base="$1"
    local head="$2"

    local stats
    stats=$(git diff --shortstat "$base..$head" 2>/dev/null || echo "")

    if [[ -z "$stats" ]]; then
        echo "No changes"
        return
    fi

    echo "$stats"
}

# Get list of changed files
get_changed_files() {
    local base="$1"
    local head="$2"
    local limit="${3:-10}"

    git diff --name-only "$base..$head" 2>/dev/null | head -n "$limit"
}

# Check if PR already exists
pr_exists() {
    local base="$1"
    local head="$2"

    local existing
    existing=$(gh pr list --base "$base" --head "$head" --json number --jq '.[0].number' 2>/dev/null || echo "")

    if [[ -n "$existing" ]]; then
        log_warn "PR already exists: #$existing"
        echo "$existing"
        return 0
    fi
    return 1
}

#------------------------------------------------------------------------------
# PR Creation Functions
#------------------------------------------------------------------------------

# Create story PR (story branch -> epic branch)
# Usage: create_story_pr <story_id> <story_branch> <epic_branch> [options]
create_story_pr() {
    local story_id=""
    local story_branch=""
    local epic_branch=""
    local story_title=""
    local milestone=""
    local project_id=""
    local labels="$STORY_LABELS"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                story_title="$2"
                shift 2
                ;;
            --milestone)
                milestone="$2"
                shift 2
                ;;
            --project-id)
                project_id="$2"
                shift 2
                ;;
            --labels)
                labels="$2"
                shift 2
                ;;
            *)
                if [[ -z "$story_id" ]]; then
                    story_id="$1"
                elif [[ -z "$story_branch" ]]; then
                    story_branch="$1"
                elif [[ -z "$epic_branch" ]]; then
                    epic_branch="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate required args
    if [[ -z "$story_id" || -z "$story_branch" || -z "$epic_branch" ]]; then
        log_error "Usage: create_story_pr <story_id> <story_branch> <epic_branch> [options]"
        return 1
    fi

    log_info "Creating story PR: $story_branch -> $epic_branch"

    # Ensure branch is pushed
    if ! ensure_branch_pushed "$story_branch"; then
        return 2
    fi

    # Check for existing PR
    local existing_pr
    if existing_pr=$(pr_exists "$epic_branch" "$story_branch"); then
        log_info "Using existing PR: #$existing_pr"
        echo "{\"pr_number\": $existing_pr, \"pr_url\": \"$(gh pr view "$existing_pr" --json url --jq '.url')\"}"
        return 4
    fi

    # Build PR title
    local title="${story_title:-Story $story_id: Implementation Complete}"

    # Get diff stats
    local diff_stats
    diff_stats=$(get_diff_stats "$epic_branch" "$story_branch")

    local changed_files
    changed_files=$(get_changed_files "$epic_branch" "$story_branch" 10)

    # Build PR body
    local body
    body=$(cat << EOF
## Summary

Story **$story_id** implementation complete.

---

## Changes

$diff_stats

**Key Files:**
\`\`\`
$changed_files
\`\`\`

---

## Checklist

- [x] All tasks completed
- [x] Tests passing
- [x] Code reviewed
- [x] Ready for merge to epic branch

---

**Story Branch:** \`$story_branch\`
**Target:** \`$epic_branch\`
EOF
)

    # Build gh pr create command
    local pr_args=()
    pr_args+=(--base "$epic_branch")
    pr_args+=(--head "$story_branch")
    pr_args+=(--title "$title")
    pr_args+=(--body "$body")

    if [[ -n "$labels" ]]; then
        pr_args+=(--label "$labels")
    fi

    if [[ -n "$milestone" ]]; then
        pr_args+=(--milestone "$milestone")
    fi

    # Create PR
    local result
    result=$(gh pr create "${pr_args[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to create PR: $result"
        return 2
    fi

    # Extract PR number and URL
    local pr_url="$result"
    local pr_number
    pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$' || echo "")

    log_success "Created PR #$pr_number: $pr_url"

    # Add to project if specified
    if [[ -n "$project_id" && -n "$pr_number" ]]; then
        add_pr_to_project "$pr_number" "$project_id"
    fi

    # Output JSON
    echo "{\"pr_number\": $pr_number, \"pr_url\": \"$pr_url\"}"
    return 0
}

# Create epic PR (epic branch -> dev)
# Usage: create_epic_pr <epic_id> <epic_branch> [options]
create_epic_pr() {
    local epic_id=""
    local epic_branch=""
    local base_branch="dev"
    local epic_title=""
    local completed_count=0
    local story_count=0
    local milestone=""
    local labels="$EPIC_LABELS"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --base)
                base_branch="$2"
                shift 2
                ;;
            --title)
                epic_title="$2"
                shift 2
                ;;
            --completed)
                completed_count="$2"
                shift 2
                ;;
            --total)
                story_count="$2"
                shift 2
                ;;
            --milestone)
                milestone="$2"
                shift 2
                ;;
            --labels)
                labels="$2"
                shift 2
                ;;
            *)
                if [[ -z "$epic_id" ]]; then
                    epic_id="$1"
                elif [[ -z "$epic_branch" ]]; then
                    epic_branch="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate required args
    if [[ -z "$epic_id" || -z "$epic_branch" ]]; then
        log_error "Usage: create_epic_pr <epic_id> <epic_branch> [options]"
        return 1
    fi

    log_info "Creating epic PR: $epic_branch -> $base_branch"

    # Ensure branch is pushed
    if ! ensure_branch_pushed "$epic_branch"; then
        return 2
    fi

    # Check for existing PR
    local existing_pr
    if existing_pr=$(pr_exists "$base_branch" "$epic_branch"); then
        log_info "Using existing PR: #$existing_pr"
        echo "{\"pr_number\": $existing_pr, \"pr_url\": \"$(gh pr view "$existing_pr" --json url --jq '.url')\"}"
        return 4
    fi

    # Build PR title
    local title="Epic $epic_id: ${epic_title:-Implementation Complete}"

    # Get diff stats
    local diff_stats
    diff_stats=$(get_diff_stats "$base_branch" "$epic_branch")

    # Build PR body
    local body
    body=$(cat << EOF
## Summary

Epic **$epic_id**: ${epic_title:-Implementation Complete}

**Stories:** $completed_count/$story_count completed

---

## Changes

$diff_stats

---

## Metrics

See: \`docs/sprint-artifacts/epic-${epic_id}-metrics.json\`

---

## Checklist

- [x] All stories completed
- [x] Tests passing
- [x] Code reviewed
- [x] Ready for merge to $base_branch

---

## Next Steps

1. Review PR
2. Run CI checks
3. Merge to $base_branch when approved
EOF
)

    # Build gh pr create command
    local pr_args=()
    pr_args+=(--base "$base_branch")
    pr_args+=(--head "$epic_branch")
    pr_args+=(--title "$title")
    pr_args+=(--body "$body")

    if [[ -n "$labels" ]]; then
        pr_args+=(--label "$labels")
    fi

    if [[ -n "$milestone" ]]; then
        pr_args+=(--milestone "$milestone")
    fi

    # Create PR
    local result
    result=$(gh pr create "${pr_args[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "Failed to create PR: $result"
        return 2
    fi

    # Extract PR number and URL
    local pr_url="$result"
    local pr_number
    pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$' || echo "")

    log_success "Created PR #$pr_number: $pr_url"

    # Output JSON
    echo "{\"pr_number\": $pr_number, \"pr_url\": \"$pr_url\"}"
    return 0
}

# Add PR to project board
add_pr_to_project() {
    local pr_number="$1"
    local project_id="$2"

    log_info "Adding PR #$pr_number to project..."

    # Get PR node ID
    local pr_node_id
    pr_node_id=$(gh pr view "$pr_number" --json id --jq '.id' 2>/dev/null)

    if [[ -z "$pr_node_id" ]]; then
        log_warn "Could not get PR node ID"
        return 0
    fi

    # Add to project
    gh api graphql -f query='
        mutation($projectId: ID!, $contentId: ID!) {
            addProjectV2ItemById(input: {
                projectId: $projectId
                contentId: $contentId
            }) {
                item { id }
            }
        }
    ' -f projectId="$project_id" -f contentId="$pr_node_id" 2>/dev/null || {
        log_warn "Failed to add to project board"
        return 0
    }

    log_info "Added PR to project board"
    return 0
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
gh-create-pr.sh - Create GitHub Pull Requests for SAGE Workflows

Usage:
  gh-create-pr.sh <command> [options]

Commands:
  story <id> <branch> <epic-branch>   Create story PR
  epic <id> <branch>                  Create epic PR

Options (story):
  --title TEXT       PR title
  --milestone NAME   Milestone to assign
  --project-id ID    Project board ID
  --labels LABELS    Comma-separated labels

Options (epic):
  --base BRANCH      Base branch (default: dev)
  --title TEXT       PR title
  --completed N      Number of completed stories
  --total N          Total number of stories
  --milestone NAME   Milestone to assign

Global Options:
  -v, --verbose      Enable verbose output
  -h, --help         Show this help message

Exit Codes:
  0 - Success
  1 - Invalid arguments
  2 - GitHub API error
  3 - Branch not found
  4 - PR already exists

Examples:
  # Create story PR
  gh-create-pr.sh story 3-1-protocol 3-1-protocol-extraction epic-3-architecture

  # Create epic PR with details
  gh-create-pr.sh epic epic-3 epic-3-architecture \
    --title "Architecture Optimization" \
    --completed 5 --total 5

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
        story)
            create_story_pr "$@"
            ;;
        epic)
            create_epic_pr "$@"
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
