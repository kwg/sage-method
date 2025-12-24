#!/usr/bin/env bash
#
# gh-project-init.sh - Initialize GitHub Project and Milestone for SAGE Epic
#
# This script creates or retrieves a GitHub Project board and Milestone
# for tracking epic progress. It's idempotent - safe to run multiple times.
#
# Usage:
#   ./gh-project-init.sh <epic_id> <epic_title> [--owner <owner>] [--repo <repo>]
#
# Output (JSON):
#   {
#     "project_id": "PVT_...",
#     "project_number": 1,
#     "project_url": "https://github.com/users/owner/projects/1",
#     "milestone_number": 1,
#     "milestone_url": "https://github.com/owner/repo/milestone/1"
#   }
#
# Exit codes:
#   0 - Success
#   1 - Missing dependencies or arguments
#   2 - GitHub API error
#   3 - Project creation failed
#   4 - Milestone creation failed
#
set -uo pipefail

SCRIPT_NAME="$(basename "$0")"

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

    # Parse GitHub URL (handles both HTTPS and SSH)
    # https://github.com/owner/repo.git
    # git@github.com:owner/repo.git
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
# GitHub Project Functions
#------------------------------------------------------------------------------

# Check if a project with the given title exists
# Returns project_id and project_number if found
find_existing_project() {
    local project_title="$1"
    local result

    # Query user's projects (V2 API)
    result=$(gh api graphql -f query='
        query($owner: String!) {
            user(login: $owner) {
                projectsV2(first: 50) {
                    nodes {
                        id
                        number
                        title
                        url
                    }
                }
            }
        }
    ' -f owner="$OWNER" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        # Try organization projects instead
        result=$(gh api graphql -f query='
            query($owner: String!) {
                organization(login: $owner) {
                    projectsV2(first: 50) {
                        nodes {
                            id
                            number
                            title
                            url
                        }
                    }
                }
            }
        ' -f owner="$OWNER" 2>/dev/null)
    fi

    if [[ -z "$result" ]]; then
        return 1
    fi

    # Find project matching our title
    echo "$result" | jq -r --arg title "$project_title" '
        (.data.user.projectsV2.nodes // .data.organization.projectsV2.nodes)
        | .[]
        | select(.title == $title)
        | {id: .id, number: .number, url: .url}
    ' 2>/dev/null | head -1
}

# Create a new GitHub Project V2
create_project() {
    local project_title="$1"
    local owner_id
    local result

    # Get owner node ID (needed for GraphQL)
    owner_id=$(gh api graphql -f query='
        query($login: String!) {
            user(login: $login) { id }
        }
    ' -f login="$OWNER" --jq '.data.user.id' 2>/dev/null)

    if [[ -z "$owner_id" || "$owner_id" == "null" ]]; then
        # Try organization
        owner_id=$(gh api graphql -f query='
            query($login: String!) {
                organization(login: $login) { id }
            }
        ' -f login="$OWNER" --jq '.data.organization.id' 2>/dev/null)
    fi

    if [[ -z "$owner_id" || "$owner_id" == "null" ]]; then
        log_error "Cannot find owner ID for: $OWNER"
        return 3
    fi

    log_info "Creating project: $project_title"

    result=$(gh api graphql -f query='
        mutation($ownerId: ID!, $title: String!) {
            createProjectV2(input: {
                ownerId: $ownerId
                title: $title
            }) {
                projectV2 {
                    id
                    number
                    url
                }
            }
        }
    ' -f ownerId="$owner_id" -f title="$project_title" 2>&1)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to create project: $result"
        return 3
    fi

    echo "$result" | jq -r '.data.createProjectV2.projectV2 | {id: .id, number: .number, url: .url}'
}

# Add default status field options to project
setup_project_fields() {
    local project_id="$1"

    log_info "Setting up project status field..."

    # Projects V2 have a default Status field
    # We could customize it here if needed, but the defaults usually work
    # This is a placeholder for future enhancements

    return 0
}

#------------------------------------------------------------------------------
# GitHub Milestone Functions
#------------------------------------------------------------------------------

# Find existing milestone by title
find_existing_milestone() {
    local milestone_title="$1"

    gh api "repos/$OWNER/$REPO/milestones" --jq --arg title "$milestone_title" '
        .[] | select(.title == $title) | {number: .number, url: .html_url}
    ' 2>/dev/null | head -1
}

# Create a new milestone
create_milestone() {
    local milestone_title="$1"
    local milestone_description="${2:-}"
    local result

    log_info "Creating milestone: $milestone_title"

    result=$(gh api "repos/$OWNER/$REPO/milestones" \
        --method POST \
        -f title="$milestone_title" \
        -f description="$milestone_description" \
        -f state="open" \
        2>&1)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to create milestone: $result"
        return 4
    fi

    echo "$result" | jq -r '{number: .number, url: .html_url}'
}

#------------------------------------------------------------------------------
# Main Function
#------------------------------------------------------------------------------

main() {
    local epic_id=""
    local epic_title=""
    local project_info=""
    local milestone_info=""

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
            --help|-h)
                echo "Usage: $SCRIPT_NAME <epic_id> <epic_title> [--owner <owner>] [--repo <repo>]"
                echo ""
                echo "Initialize GitHub Project and Milestone for a SAGE epic."
                echo ""
                echo "Arguments:"
                echo "  epic_id       The epic identifier (e.g., SAGE-GH-OBS)"
                echo "  epic_title    The epic title"
                echo ""
                echo "Options:"
                echo "  --owner       GitHub owner/organization (default: from git remote)"
                echo "  --repo        GitHub repository name (default: from git remote)"
                echo "  -h, --help    Show this help message"
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$epic_id" ]]; then
                    epic_id="$1"
                elif [[ -z "$epic_title" ]]; then
                    epic_title="$1"
                else
                    log_error "Too many arguments"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$epic_id" ]]; then
        log_error "Missing required argument: epic_id"
        echo "Usage: $SCRIPT_NAME <epic_id> <epic_title>" >&2
        exit 1
    fi

    if [[ -z "$epic_title" ]]; then
        epic_title="$epic_id"
    fi

    # Check gh CLI is available
    if ! command -v gh &>/dev/null; then
        log_error "GitHub CLI (gh) not found. Please install: https://cli.github.com/"
        exit 1
    fi

    # Check gh is authenticated
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

    # Project title format: "SAGE: {epic_title}"
    local project_title="SAGE: $epic_title"

    # Milestone title format: "{epic_id}: {epic_title}"
    local milestone_title="$epic_id: $epic_title"

    #--------------------------------------------------------------------------
    # Step 1: Find or create GitHub Project
    #--------------------------------------------------------------------------

    log_info "Checking for existing project: $project_title"
    project_info=$(find_existing_project "$project_title")

    if [[ -n "$project_info" ]] && [[ "$project_info" != "null" ]]; then
        log_info "Found existing project"
    else
        log_info "Creating new project..."
        project_info=$(create_project "$project_title")
        if [[ $? -ne 0 ]] || [[ -z "$project_info" ]]; then
            exit 3
        fi

        # Setup default fields
        local project_id
        project_id=$(echo "$project_info" | jq -r '.id')
        setup_project_fields "$project_id"
    fi

    #--------------------------------------------------------------------------
    # Step 2: Find or create Milestone
    #--------------------------------------------------------------------------

    log_info "Checking for existing milestone: $milestone_title"
    milestone_info=$(find_existing_milestone "$milestone_title")

    if [[ -n "$milestone_info" ]] && [[ "$milestone_info" != "null" ]]; then
        log_info "Found existing milestone"
    else
        log_info "Creating new milestone..."
        local milestone_desc="Epic: $epic_title - Automated by SAGE Orchestrator"
        milestone_info=$(create_milestone "$milestone_title" "$milestone_desc")
        if [[ $? -ne 0 ]] || [[ -z "$milestone_info" ]]; then
            exit 4
        fi
    fi

    #--------------------------------------------------------------------------
    # Step 3: Output combined result
    #--------------------------------------------------------------------------

    # Combine project and milestone info
    local project_id project_number project_url
    local milestone_number milestone_url

    project_id=$(echo "$project_info" | jq -r '.id')
    project_number=$(echo "$project_info" | jq -r '.number')
    project_url=$(echo "$project_info" | jq -r '.url')

    milestone_number=$(echo "$milestone_info" | jq -r '.number')
    milestone_url=$(echo "$milestone_info" | jq -r '.url')

    # Output final JSON
    jq -n \
        --arg project_id "$project_id" \
        --argjson project_number "$project_number" \
        --arg project_url "$project_url" \
        --argjson milestone_number "$milestone_number" \
        --arg milestone_url "$milestone_url" \
        '{
            project_id: $project_id,
            project_number: $project_number,
            project_url: $project_url,
            milestone_number: $milestone_number,
            milestone_url: $milestone_url
        }'

    log_info "GitHub Project and Milestone initialized successfully"
}

# Run if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
