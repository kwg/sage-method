#!/usr/bin/env bash
#
# gh-issue-progress.sh - Post progress updates to GitHub Issues
#
# This script posts formatted progress comments to GitHub issues and
# manages issue labels to reflect current status.
#
# Usage:
#   ./gh-issue-progress.sh <issue_number> <update_type> [options]
#
# Update Types:
#   started       - Story execution has begun
#   task_complete - A task/subtask has been completed
#   blocker       - A blocker has been encountered
#   decision      - A decision has been made
#   test_results  - Test results are available
#
# Options:
#   --message, -m     Custom message to include
#   --task, -t        Task name/description (for task_complete)
#   --tests-passed    Number of tests passed (for test_results)
#   --tests-failed    Number of tests failed (for test_results)
#   --tests-skipped   Number of tests skipped (for test_results)
#   --coverage        Coverage percentage (for test_results)
#   --owner           GitHub owner (default: from git remote)
#   --repo            GitHub repository (default: from git remote)
#
# Output (JSON):
#   {
#     "comment_url": "https://github.com/owner/repo/issues/1#issuecomment-...",
#     "comment_id": 123456789
#   }
#
# Exit codes:
#   0 - Success
#   1 - Missing dependencies or arguments
#   2 - GitHub API error
#   3 - Invalid update type
#   4 - Template not found
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Label mappings for different update types
declare -A LABEL_ADD=(
    [started]="in-progress"
    [blocker]="blocked"
)

declare -A LABEL_REMOVE=(
    [started]="planned,ready"
    [blocker]=""
    [task_complete]="blocked"
)

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

# Load and render a template with variable substitution
render_template() {
    local template_file="$1"
    shift
    local content

    if [[ ! -f "$template_file" ]]; then
        log_error "Template not found: $template_file"
        return 4
    fi

    content=$(cat "$template_file")

    # Substitute variables passed as key=value pairs
    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        content="${content//\{\{$key\}\}/$value}"
        shift
    done

    # Replace any remaining unset variables with empty string
    content=$(echo "$content" | sed 's/{{[A-Z_]*}}//g')

    echo "$content"
}

# Get template path for update type
get_template_path() {
    local update_type="$1"
    local template_file

    case "$update_type" in
        started)
            template_file="progress-started.md"
            ;;
        task_complete)
            template_file="progress-task.md"
            ;;
        blocker)
            template_file="progress-blocker.md"
            ;;
        decision)
            template_file="progress-decision.md"
            ;;
        test_results)
            template_file="progress-test-results.md"
            ;;
        *)
            log_error "Unknown update type: $update_type"
            return 3
            ;;
    esac

    echo "$TEMPLATES_DIR/$template_file"
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

    echo "$result" | jq -r '{comment_url: .html_url, comment_id: .id}'
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
            label=$(echo "$label" | xargs)  # trim whitespace
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

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local issue_number=""
    local update_type=""
    local message=""
    local task_name=""
    local tests_passed=""
    local tests_failed=""
    local tests_skipped=""
    local coverage=""
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
            --message|-m)
                message="$2"
                shift 2
                ;;
            --task|-t)
                task_name="$2"
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
            --tests-skipped)
                tests_skipped="$2"
                shift 2
                ;;
            --coverage)
                coverage="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME <issue_number> <update_type> [options]"
                echo ""
                echo "Post progress updates to GitHub issues."
                echo ""
                echo "Update Types:"
                echo "  started       Story execution has begun"
                echo "  task_complete A task/subtask has been completed"
                echo "  blocker       A blocker has been encountered"
                echo "  decision      A decision has been made"
                echo "  test_results  Test results are available"
                echo ""
                echo "Options:"
                echo "  -m, --message      Custom message to include"
                echo "  -t, --task         Task name (for task_complete)"
                echo "  --tests-passed     Number of tests passed"
                echo "  --tests-failed     Number of tests failed"
                echo "  --tests-skipped    Number of tests skipped"
                echo "  --coverage         Coverage percentage"
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
                elif [[ -z "$update_type" ]]; then
                    update_type="$1"
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
        echo "Usage: $SCRIPT_NAME <issue_number> <update_type> [options]" >&2
        exit 1
    fi

    if [[ -z "$update_type" ]]; then
        log_error "Missing required argument: update_type"
        echo "Usage: $SCRIPT_NAME <issue_number> <update_type> [options]" >&2
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
    log_info "Update type: $update_type"

    #--------------------------------------------------------------------------
    # Step 1: Get template and render content
    #--------------------------------------------------------------------------

    local template_path
    template_path=$(get_template_path "$update_type")
    if [[ $? -ne 0 ]]; then
        exit 3
    fi

    local comment_body
    comment_body=$(render_template "$template_path" \
        "TIMESTAMP=$timestamp" \
        "MESSAGE=$message" \
        "TASK_NAME=$task_name" \
        "TESTS_PASSED=$tests_passed" \
        "TESTS_FAILED=$tests_failed" \
        "TESTS_SKIPPED=$tests_skipped" \
        "COVERAGE=$coverage")

    if [[ $? -ne 0 ]]; then
        exit 4
    fi

    #--------------------------------------------------------------------------
    # Step 2: Post comment
    #--------------------------------------------------------------------------

    log_info "Posting progress update..."
    local result
    result=$(post_comment "$issue_number" "$comment_body")

    if [[ $? -ne 0 ]]; then
        exit 2
    fi

    #--------------------------------------------------------------------------
    # Step 3: Update labels
    #--------------------------------------------------------------------------

    local add_label="${LABEL_ADD[$update_type]:-}"
    local remove_label="${LABEL_REMOVE[$update_type]:-}"

    if [[ -n "$add_label" ]] || [[ -n "$remove_label" ]]; then
        log_info "Updating labels..."
        update_labels "$issue_number" "$add_label" "$remove_label"
    fi

    #--------------------------------------------------------------------------
    # Step 4: Output result
    #--------------------------------------------------------------------------

    echo "$result"
    log_info "Progress update posted successfully"
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
