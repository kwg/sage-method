#!/usr/bin/env bash
#
# gh-poll-response.sh - Poll GitHub Issue for Human Response
#
# This script checks a GitHub issue for human comments and parses
# keywords to determine the response status. Used for HitL (Human in
# the Loop) approval workflows.
#
# Usage:
#   ./gh-poll-response.sh <issue_number> [options]
#
# Output (JSON):
#   {
#     "status": "APPROVED|REVISE|DISCUSS|HALT|DEFER|UNCLEAR|NO_RESPONSE",
#     "comment": "...",
#     "user": "username",
#     "created_at": "timestamp",
#     "conditional": true|false
#   }
#
# Exit codes:
#   0 - Response found and parsed
#   1 - Invalid arguments
#   2 - GitHub API error
#   3 - No human comments found
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

#------------------------------------------------------------------------------
# Keyword Patterns
#------------------------------------------------------------------------------

# Keywords by priority (higher priority checked first)
DISCUSS_KEYWORDS="let's discuss|questions|need to think|hmm|i wonder|can we talk|not sure"
HALT_KEYWORDS="blocked|stop|halt|pause|wait|hold"
DEFER_KEYWORDS="skip|defer|later|backlog|postpone"
APPROVED_KEYWORDS="approved|lgtm|ship it|looks good|go ahead|yes|proceed|🚀|👍|✅"
CONDITIONAL_KEYWORDS="but|however|although|except|with changes|if you|before we"
REVISE_KEYWORDS="needs work|changes requested|revise|not yet|no|fix|reject"

#------------------------------------------------------------------------------
# Response Parsing
#------------------------------------------------------------------------------

# Get latest human comment on issue
# Usage: get_latest_comment <issue_number>
get_latest_comment() {
    local issue_number="$1"

    # Get repo info
    if ! get_repo_info; then
        return 2
    fi

    log_verbose "Fetching comments for issue #$issue_number"

    # Query non-bot comments, get most recent
    local result
    result=$(gh api "repos/$OWNER/$REPO/issues/$issue_number/comments" \
        --jq '[.[] | select(.user.type != "Bot")] | last // empty' 2>/dev/null)

    if [[ -z "$result" || "$result" == "null" ]]; then
        log_verbose "No human comments found"
        return 3
    fi

    echo "$result"
    return 0
}

# Parse comment for approval keywords
# Usage: parse_approval_keywords <comment_body>
# Returns: status code word
parse_approval_keywords() {
    local body="$1"
    local body_lower
    body_lower=$(echo "$body" | tr '[:upper:]' '[:lower:]')

    # Check for discussion request (highest priority)
    if echo "$body_lower" | grep -qiE "$DISCUSS_KEYWORDS"; then
        echo "DISCUSS"
        return 0
    fi

    # Check for halt/block
    if echo "$body_lower" | grep -qiE "$HALT_KEYWORDS"; then
        echo "HALT"
        return 0
    fi

    # Check for defer
    if echo "$body_lower" | grep -qiE "$DEFER_KEYWORDS"; then
        echo "DEFER"
        return 0
    fi

    # Check for approval
    if echo "$body_lower" | grep -qiE "$APPROVED_KEYWORDS"; then
        # Check for conditional approval
        if echo "$body_lower" | grep -qiE "$CONDITIONAL_KEYWORDS"; then
            echo "CONDITIONAL"
            return 0
        fi
        echo "APPROVED"
        return 0
    fi

    # Check for revision request
    if echo "$body_lower" | grep -qiE "$REVISE_KEYWORDS"; then
        echo "REVISE"
        return 0
    fi

    # Unclear
    echo "UNCLEAR"
    return 0
}

# Check if approval is conditional
# Usage: is_conditional_approval <comment_body>
is_conditional_approval() {
    local body="$1"
    local body_lower
    body_lower=$(echo "$body" | tr '[:upper:]' '[:lower:]')

    if echo "$body_lower" | grep -qiE "$CONDITIONAL_KEYWORDS"; then
        return 0
    fi
    return 1
}

# Poll issue and return structured response
# Usage: poll_response <issue_number> [--raw]
poll_response() {
    local issue_number="$1"
    local raw_output="${2:-}"

    if [[ -z "$issue_number" ]]; then
        log_error "Usage: poll_response <issue_number>"
        return 1
    fi

    log_info "Polling issue #$issue_number for response"

    # Get latest comment
    local comment_json
    comment_json=$(get_latest_comment "$issue_number")
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        if [[ $exit_code -eq 3 ]]; then
            # No comments found
            echo '{"status": "NO_RESPONSE", "comment": null, "user": null, "created_at": null, "conditional": false}'
            return 3
        fi
        return $exit_code
    fi

    # Extract fields
    local body user created_at
    body=$(echo "$comment_json" | jq -r '.body // ""')
    user=$(echo "$comment_json" | jq -r '.user.login // ""')
    created_at=$(echo "$comment_json" | jq -r '.created_at // ""')

    # Parse status
    local status
    status=$(parse_approval_keywords "$body")

    # Check for conditional
    local conditional=false
    if [[ "$status" == "CONDITIONAL" ]]; then
        status="DISCUSS"
        conditional=true
    elif [[ "$status" == "APPROVED" ]] && is_conditional_approval "$body"; then
        conditional=true
    fi

    # Handle raw output
    if [[ "$raw_output" == "--raw" ]]; then
        echo "$status"
        return 0
    fi

    # Build response JSON
    local body_escaped
    body_escaped=$(echo "$body" | jq -Rs '.')

    cat << EOF
{
  "status": "$status",
  "comment": $body_escaped,
  "user": "$user",
  "created_at": "$created_at",
  "conditional": $conditional
}
EOF
    return 0
}

# Check for specific response type
# Usage: check_response_type <issue_number> <type>
check_response_type() {
    local issue_number="$1"
    local expected_type="$2"

    local response
    response=$(poll_response "$issue_number" --raw)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        return $exit_code
    fi

    if [[ "$response" == "$expected_type" ]]; then
        echo "true"
        return 0
    else
        echo "false"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

usage() {
    cat << 'EOF'
gh-poll-response.sh - Poll GitHub Issue for Human Response

Usage:
  gh-poll-response.sh <issue_number> [options]

Commands:
  poll <issue>               Poll for response (default, JSON output)
  check <issue> <type>       Check if response matches type

Options:
  --raw                      Output status only (no JSON)
  -v, --verbose              Enable verbose output
  -h, --help                 Show this help message

Response Types:
  APPROVED      - Approval keywords detected
  REVISE        - Revision/changes requested
  DISCUSS       - Discussion requested
  HALT          - Halt/block requested
  DEFER         - Defer/postpone requested
  UNCLEAR       - Comment found but unclear intent
  NO_RESPONSE   - No human comments found

Exit Codes:
  0 - Response found and parsed
  1 - Invalid arguments
  2 - GitHub API error
  3 - No human comments found

Examples:
  # Poll for any response (JSON output)
  gh-poll-response.sh poll 123

  # Check if approved
  gh-poll-response.sh check 123 APPROVED

  # Get just the status
  gh-poll-response.sh poll 123 --raw

EOF
}

main() {
    local command="poll"
    local issue_number=""

    # Parse arguments
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
            poll|check)
                command="$1"
                shift
                ;;
            --raw)
                shift
                # Pass through
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "$issue_number" ]]; then
                    issue_number="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$issue_number" ]]; then
        log_error "Missing issue number"
        usage
        exit 1
    fi

    # Initialize
    sage_init --require-git --require-gh

    # Dispatch command
    case "$command" in
        poll)
            poll_response "$issue_number" "$@"
            ;;
        check)
            if [[ $# -lt 1 ]]; then
                log_error "Missing expected type for check"
                exit 1
            fi
            check_response_type "$issue_number" "$1"
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
