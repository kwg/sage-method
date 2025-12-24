#!/usr/bin/env bash
#
# gh-issue-complete.sh - Mark GitHub Issue as Complete with Summary
#
# This script posts a completion summary to a GitHub issue, updates labels,
# closes the issue, and optionally updates the project board status.
#
# Usage:
#   ./gh-issue-complete.sh <issue_number> [options]
#
# Options:
#   --tasks-completed   Number of tasks completed
#   --tests-passed      Number of tests passed
#   --tests-failed      Number of tests failed
#   --coverage          Coverage percentage
#   --commit            Commit SHA or reference
#   --pr                Pull request number
#   --message, -m       Additional message/notes
#   --project-id        Project ID for board update
#   --owner             GitHub owner (default: from git remote)
#   --repo              GitHub repository (default: from git remote)
#
# Output (JSON):
#   {
#     "issue_url": "https://github.com/owner/repo/issues/1",
#     "comment_url": "https://github.com/owner/repo/issues/1#issuecomment-...",
#     "closed": true
#   }
#
# Exit codes:
#   0 - Success
#   1 - Missing dependencies or arguments
#   2 - GitHub API error
#   3 - Issue not found
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Get owner/repo from git remote if not specified
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

#------------------------------------------------------------------------------
# Template Functions
#------------------------------------------------------------------------------

render_template() {
    local template_file="$1"
    shift
    local content

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 4
    fi

    content=$(cat "$template_file")

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        content="${content//\{\{$key\}\}/$value}"
        shift
    done

    content=$(echo "$content" | sed 's/{{[A-Z_]*}}//g')

    echo "$content"
}

#------------------------------------------------------------------------------
# GitHub Functions
#------------------------------------------------------------------------------

# Post a comment to an issue
post_comment() {
    local issue_number="$1"
    local body="$2"
    local result

    result=$(gh api "repos/$OWNER/$REPO/issues/$issue_number/comments" \
        --method POST \
        -f body="$body" \
        2>&1)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to post comment: $result"
        return 2
    fi

    echo "$result" | jq -r '.html_url'
}

# Update issue labels
update_labels() {
    local issue_number="$1"
    local add_labels="$2"
    local remove_labels="$3"

    # Remove labels first
    if [[ -n "$remove_labels" ]]; then
        local IFS=','
        for label in $remove_labels; do
            label=$(echo "$label" | xargs)
            if [[ -n "$label" ]]; then
                gh api "repos/$OWNER/$REPO/issues/$issue_number/labels/$label" \
                    --method DELETE 2>/dev/null || true
            fi
        done
    fi

    # Add new labels
    if [[ -n "$add_labels" ]]; then
        local IFS=','
        local labels_json="["
        local first=true
        for label in $add_labels; do
            label=$(echo "$label" | xargs)
            if [[ -n "$label" ]]; then
                if [[ "$first" == "true" ]]; then
                    labels_json+="\"$label\""
                    first=false
                else
                    labels_json+=",\"$label\""
                fi
            fi
        done
        labels_json+="]"

        if [[ "$labels_json" != "[]" ]]; then
            gh api "repos/$OWNER/$REPO/issues/$issue_number/labels" \
                --method POST \
                --input - <<< "{\"labels\": $labels_json}" 2>/dev/null || true
        fi
    fi
}

# Close an issue
close_issue() {
    local issue_number="$1"
    local result

    result=$(gh api "repos/$OWNER/$REPO/issues/$issue_number" \
        --method PATCH \
        -f state="closed" \
        -f state_reason="completed" \
        2>&1)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to close issue: $result"
        return 2
    fi

    echo "$result" | jq -r '.html_url'
}

# Update project board status (if project is linked)
update_project_status() {
    local issue_number="$1"
    local project_id="$2"
    local status="Done"

    if [[ -z "$project_id" ]]; then
        log_info "No project ID provided, skipping board update"
        return 0
    fi

    # Get the issue's project item ID
    local item_id
    item_id=$(gh api graphql -f query='
        query($owner: String!, $repo: String!, $issue: Int!) {
            repository(owner: $owner, name: $repo) {
                issue(number: $issue) {
                    projectItems(first: 10) {
                        nodes {
                            id
                            project { id }
                        }
                    }
                }
            }
        }
    ' -f owner="$OWNER" -f repo="$REPO" -F issue="$issue_number" \
        --jq ".data.repository.issue.projectItems.nodes[] | select(.project.id == \"$project_id\") | .id" 2>/dev/null)

    if [[ -z "$item_id" ]]; then
        log_warn "Issue not found in project, skipping board update"
        return 0
    fi

    # Get the Status field ID and "Done" option ID
    local status_field_id
    local done_option_id

    local field_info
    field_info=$(gh api graphql -f query='
        query($projectId: ID!) {
            node(id: $projectId) {
                ... on ProjectV2 {
                    fields(first: 20) {
                        nodes {
                            ... on ProjectV2SingleSelectField {
                                id
                                name
                                options {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
    ' -f projectId="$project_id" 2>/dev/null)

    status_field_id=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id' 2>/dev/null)
    done_option_id=$(echo "$field_info" | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Done") | .id' 2>/dev/null)

    if [[ -z "$status_field_id" ]] || [[ -z "$done_option_id" ]]; then
        log_warn "Could not find Status field or Done option in project"
        return 0
    fi

    # Update the item status
    gh api graphql -f query='
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
            updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: { singleSelectOptionId: $optionId }
            }) {
                projectV2Item { id }
            }
        }
    ' -f projectId="$project_id" -f itemId="$item_id" -f fieldId="$status_field_id" -f optionId="$done_option_id" 2>/dev/null

    log_info "Updated project board status to Done"
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local issue_number=""
    local tasks_completed=""
    local tests_passed=""
    local tests_failed=""
    local coverage=""
    local commit_sha=""
    local pr_number=""
    local message=""
    local project_id=""
    local timestamp
    timestamp=$(date -u +"%Y-%m-%d %H:%M UTC")

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
            --tasks-completed)
                tasks_completed="$2"
                shift 2
                ;;
            --tests-passed)
                tests_passed="$2"
                shift 2
                ;;
            --tests-failed)
                tests_failed="$2"
                shift 2
                ;;
            --coverage)
                coverage="$2"
                shift 2
                ;;
            --commit)
                commit_sha="$2"
                shift 2
                ;;
            --pr)
                pr_number="$2"
                shift 2
                ;;
            --message|-m)
                message="$2"
                shift 2
                ;;
            --project-id)
                project_id="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME <issue_number> [options]"
                echo ""
                echo "Mark GitHub issue as complete with summary."
                echo ""
                echo "Options:"
                echo "  --tasks-completed  Number of tasks completed"
                echo "  --tests-passed     Number of tests passed"
                echo "  --tests-failed     Number of tests failed"
                echo "  --coverage         Coverage percentage"
                echo "  --commit           Commit SHA or reference"
                echo "  --pr               Pull request number"
                echo "  -m, --message      Additional message/notes"
                echo "  --project-id       Project ID for board update"
                echo "  --owner            GitHub owner"
                echo "  --repo             GitHub repository"
                echo "  -h, --help         Show this help message"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$issue_number" ]]; then
                    issue_number="$1"
                else
                    log_error "Too many positional arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$issue_number" ]]; then
        log_error "Missing required argument: issue_number"
        echo "Usage: $SCRIPT_NAME <issue_number> [options]" >&2
        exit 1
    fi

    # Check gh CLI is available and authenticated
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found. Please install: https://cli.github.com/"
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI not authenticated. Run: gh auth login"
        exit 1
    fi

    # Get repo info if not specified
    if [[ -z "${OWNER:-}" ]] || [[ -z "${REPO:-}" ]]; then
        if ! get_repo_info; then
            exit 1
        fi
    fi

    log_info "Repository: $OWNER/$REPO"
    log_info "Issue: #$issue_number"

    #--------------------------------------------------------------------------
    # Step 1: Render completion comment
    #--------------------------------------------------------------------------

    local template_path="$TEMPLATES_DIR/completion.md"
    local comment_body
    comment_body=$(render_template "$template_path" \
        "TIMESTAMP=$timestamp" \
        "TASKS_COMPLETED=$tasks_completed" \
        "TESTS_PASSED=$tests_passed" \
        "TESTS_FAILED=$tests_failed" \
        "COVERAGE=$coverage" \
        "COMMIT_SHA=$commit_sha" \
        "PR_NUMBER=$pr_number" \
        "MESSAGE=$message")

    if [[ $? -ne 0 ]]; then
        exit 4
    fi

    #--------------------------------------------------------------------------
    # Step 2: Post completion comment
    #--------------------------------------------------------------------------

    log_info "Posting completion summary..."
    local comment_url
    comment_url=$(post_comment "$issue_number" "$comment_body")

    if [[ $? -ne 0 ]]; then
        exit 2
    fi

    #--------------------------------------------------------------------------
    # Step 3: Update labels
    #--------------------------------------------------------------------------

    log_info "Updating labels..."
    update_labels "$issue_number" "completed" "in-progress,blocked"

    #--------------------------------------------------------------------------
    # Step 4: Close issue
    #--------------------------------------------------------------------------

    log_info "Closing issue..."
    local issue_url
    issue_url=$(close_issue "$issue_number")

    if [[ $? -ne 0 ]]; then
        exit 2
    fi

    #--------------------------------------------------------------------------
    # Step 5: Update project board (if project ID provided)
    #--------------------------------------------------------------------------

    if [[ -n "$project_id" ]]; then
        update_project_status "$issue_number" "$project_id"
    fi

    #--------------------------------------------------------------------------
    # Step 6: Output result
    #--------------------------------------------------------------------------

    jq -n \
        --arg issue_url "$issue_url" \
        --arg comment_url "$comment_url" \
        --argjson closed true \
        '{
            issue_url: $issue_url,
            comment_url: $comment_url,
            closed: $closed
        }'

    log_info "Issue completed and closed successfully"
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
