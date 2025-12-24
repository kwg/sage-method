#!/usr/bin/env bash
#
# gh-create-review-issue.sh - Create GitHub Review Issue for HitL Approval
#
# This script creates a GitHub issue for document review during planning phase.
# It supports different document types (PRD, Architecture, UX, Epics) and
# emits HITL_REQUIRED signal for orchestrator integration.
#
# Usage:
#   ./gh-create-review-issue.sh <doc_type> <file_path> [options]
#
# Document Types:
#   prd           - Product Requirements Document
#   architecture  - Architecture Design Document
#   ux            - UX Design Document
#   epics         - Epic & Stories Document
#
# Options:
#   --branch        Branch name (default: current branch) - will be pushed if not on remote
#   --project-id    Project ID to link issue
#   --milestone     Milestone number to assign
#   --owner         GitHub owner (default: from git remote)
#   --repo          GitHub repository (default: from git remote)
#
# Output (JSON):
#   {
#     "issue_number": 123,
#     "issue_url": "https://github.com/owner/repo/issues/123"
#   }
#
# After creating the issue, outputs SAGE_SIGNAL:HITL_REQUIRED for orchestrator.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "$0")"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# Label mappings for document types
declare -A DOC_LABELS=(
    [prd]="prd-review,needs-approval,hitl/review"
    [architecture]="architecture-review,needs-approval,hitl/review"
    [ux]="ux-review,needs-approval,hitl/review"
    [epics]="epics-review,needs-approval,hitl/review"
)

# Template mappings
declare -A DOC_TEMPLATES=(
    [prd]="review-issue-prd.md"
    [architecture]="review-issue-architecture.md"
    [ux]="review-issue-ux.md"
    [epics]="review-issue-epics.md"
)

# Title prefixes
declare -A DOC_TITLES=(
    [prd]="Review: Product Requirements Document"
    [architecture]="Review: Architecture Design"
    [ux]="Review: UX Design"
    [epics]="Review: Epic & Stories"
)

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

get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

ensure_branch_pushed() {
    local branch="$1"

    # Check if branch exists on remote
    if git ls-remote --exit-code --heads origin "$branch" &>/dev/null; then
        log_info "Branch '$branch' exists on remote"
        # Push any new commits
        if ! git push origin "$branch" 2>&1; then
            log_warn "Failed to push latest commits, but branch exists on remote"
        fi
        return 0
    fi

    # Branch doesn't exist on remote, push it
    log_info "Pushing branch '$branch' to remote..."
    if ! git push -u origin "$branch" 2>&1; then
        log_error "Failed to push branch '$branch' to remote"
        return 1
    fi

    log_info "Branch '$branch' pushed to remote"
    return 0
}

build_document_url() {
    local owner="$1"
    local repo="$2"
    local branch="$3"
    local file_path="$4"

    # Build absolute GitHub URL for the document
    echo "https://github.com/${owner}/${repo}/blob/${branch}/${file_path}"
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

    echo "$content"
}

# Extract summary from document (first ~50 lines or to first major section)
extract_summary() {
    local file_path="$1"
    local max_lines=50

    if [[ ! -f "$file_path" ]]; then
        echo "(Document not found)"
        return
    fi

    head -n "$max_lines" "$file_path"
}

#------------------------------------------------------------------------------
# GitHub Functions
#------------------------------------------------------------------------------

create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    local milestone="${4:-}"
    local result

    local args=()
    args+=("repos/$OWNER/$REPO/issues")
    args+=(--method POST)
    args+=(-f "title=$title")
    args+=(-f "body=$body")

    if [[ -n "$labels" ]]; then
        # Convert comma-separated to JSON array
        local labels_json
        labels_json=$(echo "$labels" | tr ',' '\n' | jq -R . | jq -s .)
        args+=(--input -)
    fi

    if [[ -n "$milestone" ]]; then
        args+=(-F "milestone=$milestone")
    fi

    if [[ -n "$labels" ]]; then
        result=$(echo "{\"labels\": $labels_json}" | gh api "${args[@]}" 2>&1)
    else
        result=$(gh api "${args[@]}" 2>&1)
    fi

    if [[ $? -ne 0 ]]; then
        log_error "Failed to create issue: $result"
        return 2
    fi

    echo "$result" | jq -r '{issue_number: .number, issue_url: .html_url}'
}

# Add issue to project board
add_to_project() {
    local issue_number="$1"
    local project_id="$2"

    if [[ -z "$project_id" ]]; then
        log_info "No project ID provided, skipping project link"
        return 0
    fi

    # Get issue node ID
    local issue_node_id
    issue_node_id=$(gh api "repos/$OWNER/$REPO/issues/$issue_number" --jq '.node_id' 2>/dev/null)

    if [[ -z "$issue_node_id" ]]; then
        log_warn "Could not get issue node ID"
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
    ' -f projectId="$project_id" -f contentId="$issue_node_id" 2>/dev/null

    log_info "Added issue to project board"
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local doc_type=""
    local file_path=""
    local branch=""
    local project_id=""
    local milestone=""
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
            --branch)
                branch="$2"
                shift 2
                ;;
            --project-id)
                project_id="$2"
                shift 2
                ;;
            --milestone)
                milestone="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $SCRIPT_NAME <doc_type> <file_path> [options]"
                echo ""
                echo "Create GitHub review issue for HitL approval."
                echo ""
                echo "Document Types:"
                echo "  prd           Product Requirements Document"
                echo "  architecture  Architecture Design Document"
                echo "  ux            UX Design Document"
                echo "  epics         Epic & Stories Document"
                echo ""
                echo "Options:"
                echo "  --branch       Branch name (default: current branch)"
                echo "  --project-id   Project ID to link issue"
                echo "  --milestone    Milestone number to assign"
                echo "  --owner        GitHub owner"
                echo "  --repo         GitHub repository"
                echo "  -h, --help     Show this help message"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$doc_type" ]]; then
                    doc_type="$1"
                elif [[ -z "$file_path" ]]; then
                    file_path="$1"
                else
                    log_error "Too many positional arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$doc_type" ]]; then
        log_error "Missing required argument: doc_type"
        echo "Usage: $SCRIPT_NAME <doc_type> <file_path> [options]" >&2
        exit 1
    fi

    if [[ -z "$file_path" ]]; then
        log_error "Missing required argument: file_path"
        exit 1
    fi

    # Validate doc type
    if [[ -z "${DOC_LABELS[$doc_type]:-}" ]]; then
        log_error "Unknown document type: $doc_type"
        log_error "Valid types: prd, architecture, ux, epics"
        exit 1
    fi

    # Check gh CLI
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found"
        exit 1
    fi

    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI not authenticated"
        exit 1
    fi

    # Get repo info
    if [[ -z "${OWNER:-}" ]] || [[ -z "${REPO:-}" ]]; then
        if ! get_repo_info; then
            exit 1
        fi
    fi

    log_info "Repository: $OWNER/$REPO"
    log_info "Document type: $doc_type"
    log_info "File: $file_path"

    #--------------------------------------------------------------------------
    # Step 0: Get branch and ensure it's pushed
    #--------------------------------------------------------------------------

    # Use provided branch or detect current
    if [[ -z "$branch" ]]; then
        branch=$(get_current_branch)
        if [[ -z "$branch" ]]; then
            log_error "Could not determine current branch"
            exit 1
        fi
    fi

    log_info "Branch: $branch"

    # Ensure branch is pushed to remote before creating issue
    if ! ensure_branch_pushed "$branch"; then
        log_error "Cannot create review issue: branch must be pushed to remote"
        exit 1
    fi

    #--------------------------------------------------------------------------
    # Step 1: Prepare issue content
    #--------------------------------------------------------------------------

    local title="${DOC_TITLES[$doc_type]}"
    local labels="${DOC_LABELS[$doc_type]}"
    local template_file="$TEMPLATES_DIR/${DOC_TEMPLATES[$doc_type]}"

    # Build absolute GitHub URL for the document
    local doc_url
    doc_url=$(build_document_url "$OWNER" "$REPO" "$branch" "$file_path")

    # Extract document summary
    local doc_summary
    doc_summary=$(extract_summary "$file_path")

    # Get document filename for title
    local doc_name
    doc_name=$(basename "$file_path")
    title="$title - $doc_name"

    # Render template
    local body
    body=$(render_template "$template_file" \
        "TIMESTAMP=$timestamp" \
        "DOC_PATH=$file_path" \
        "DOC_URL=$doc_url" \
        "DOC_NAME=$doc_name" \
        "DOC_SUMMARY=$doc_summary")

    if [[ $? -ne 0 ]]; then
        exit 4
    fi

    #--------------------------------------------------------------------------
    # Step 2: Create issue
    #--------------------------------------------------------------------------

    log_info "Creating review issue..."
    local result
    result=$(create_issue "$title" "$body" "$labels" "$milestone")

    if [[ $? -ne 0 ]]; then
        exit 2
    fi

    local issue_number
    local issue_url
    issue_number=$(echo "$result" | jq -r '.issue_number')
    issue_url=$(echo "$result" | jq -r '.issue_url')

    log_info "Created issue #$issue_number: $issue_url"

    #--------------------------------------------------------------------------
    # Step 3: Add to project (if provided)
    #--------------------------------------------------------------------------

    if [[ -n "$project_id" ]]; then
        add_to_project "$issue_number" "$project_id"
    fi

    #--------------------------------------------------------------------------
    # Step 4: Output result
    #--------------------------------------------------------------------------

    echo "$result"

    #--------------------------------------------------------------------------
    # Step 5: Emit HITL_REQUIRED signal for orchestrator
    #--------------------------------------------------------------------------

    echo ""
    echo "============================================"
    echo "SAGE_SIGNAL:HITL_REQUIRED"
    echo "REVIEW_TYPE: $doc_type"
    echo "ISSUE_NUMBER: $issue_number"
    echo "ISSUE_URL: $issue_url"
    echo "============================================"
    echo ""

    log_info "Review issue created. Awaiting human approval on GitHub."
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
