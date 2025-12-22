#!/usr/bin/env bash
#
# common.sh - Shared utilities for SAGE shell scripts
#
# This library provides common functions used across SAGE scripts.
# Source this file at the beginning of your script:
#
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"
#
# Functions:
#   - get_repo_info           Get GitHub owner/repo from git remote
#   - get_current_branch      Get current git branch name
#   - log_info/warn/error     Standardized logging with timestamps
#   - log_verbose             Debug logging (when VERBOSE=true)
#   - render_template         Substitute {{KEY}} patterns in templates
#   - require_command         Check if a command is available
#   - require_jq              Ensure jq is available for JSON processing
#   - json_escape             Escape a string for JSON embedding
#   - emit_signal             Output SAGE orchestrator signal
#
# Exit codes (standard across all SAGE scripts):
#   0 - Success
#   1 - Invalid arguments
#   2 - External command/API error
#   3 - Git error
#   4 - File/template not found
#   5 - JSON parsing error
#
set -uo pipefail

# Version for compatibility checks
SAGE_COMMON_VERSION="1.0.0"

# Global config (can be overridden by scripts)
VERBOSE="${VERBOSE:-false}"
LOG_TIMESTAMPS="${LOG_TIMESTAMPS:-true}"

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

_log_timestamp() {
    if [[ "$LOG_TIMESTAMPS" == "true" ]]; then
        echo -n "[$(date -Iseconds)] "
    fi
}

log_info() {
    echo "$(_log_timestamp)[INFO] $*" >&2
}

log_warn() {
    echo "$(_log_timestamp)[WARN] $*" >&2
}

log_error() {
    echo "$(_log_timestamp)[ERROR] $*" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "$(_log_timestamp)[DEBUG] $*" >&2
    fi
}

log_success() {
    echo "$(_log_timestamp)[SUCCESS] $*" >&2
}

#------------------------------------------------------------------------------
# Repository Detection
#------------------------------------------------------------------------------

# Get GitHub owner and repo from git remote
# Sets global OWNER and REPO variables
# Returns: 0 on success, 1 on failure
get_repo_info() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "")

    if [[ -z "$remote_url" ]]; then
        log_error "Cannot determine repository from git remote"
        return 1
    fi

    # Match both HTTPS and SSH GitHub URLs
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        log_verbose "Detected repository: $OWNER/$REPO"
        return 0
    fi

    log_error "Cannot parse GitHub URL from remote: $remote_url"
    return 1
}

# Get current git branch name
# Returns: branch name on stdout, empty on failure
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Check if we're in a git repository
# Returns: 0 if in repo, 1 if not
is_git_repo() {
    git rev-parse --git-dir &>/dev/null
}

# Get the repository root directory
# Returns: path on stdout
get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

#------------------------------------------------------------------------------
# Command Validation
#------------------------------------------------------------------------------

# Check if a command is available
# Usage: require_command <command> [purpose]
# Returns: 0 if available, exits with error if not
require_command() {
    local cmd="$1"
    local purpose="${2:-}"

    if ! command -v "$cmd" &>/dev/null; then
        if [[ -n "$purpose" ]]; then
            log_error "Required command '$cmd' not found (needed for: $purpose)"
        else
            log_error "Required command '$cmd' not found"
        fi
        log_error "Install with: nix-shell -p $cmd"
        exit 1
    fi
    log_verbose "Command '$cmd' is available"
}

# Ensure jq is available (commonly needed)
require_jq() {
    require_command jq "JSON processing"
}

# Ensure yq is available
require_yq() {
    require_command yq "YAML processing"
}

# Ensure gh CLI is available and authenticated
require_gh() {
    require_command gh "GitHub API operations"

    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI not authenticated"
        log_error "Run: gh auth login"
        exit 1
    fi
    log_verbose "GitHub CLI is authenticated"
}

#------------------------------------------------------------------------------
# Template Processing
#------------------------------------------------------------------------------

# Render a template file with variable substitution
# Usage: render_template <template_file> KEY1=value1 KEY2=value2 ...
# Replaces {{KEY}} patterns with values
# Returns: rendered content on stdout, exit 4 if template not found
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

# Substitute variables in a string (not file)
# Usage: substitute_vars <string> KEY1=value1 KEY2=value2 ...
substitute_vars() {
    local content="$1"
    shift

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        content="${content//\{\{$key\}\}/$value}"
        shift
    done

    echo "$content"
}

#------------------------------------------------------------------------------
# JSON Helpers
#------------------------------------------------------------------------------

# Escape a string for safe JSON embedding
# Usage: json_escape "string with \"quotes\" and newlines"
json_escape() {
    local str="$1"
    # Use jq for proper escaping if available
    if command -v jq &>/dev/null; then
        echo -n "$str" | jq -Rs '.'
    else
        # Fallback: basic escaping
        str="${str//\\/\\\\}"
        str="${str//\"/\\\"}"
        str="${str//$'\n'/\\n}"
        str="${str//$'\t'/\\t}"
        echo "\"$str\""
    fi
}

# Validate JSON string
# Usage: validate_json <json_string>
# Returns: 0 if valid, 5 if invalid
validate_json() {
    local json="$1"
    if ! echo "$json" | jq . &>/dev/null; then
        log_error "Invalid JSON"
        return 5
    fi
    return 0
}

# Read JSON file and validate
# Usage: read_json_file <file_path>
# Returns: JSON on stdout, exits 4 if not found, 5 if invalid
read_json_file() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        log_error "JSON file not found: $file_path"
        return 4
    fi

    local content
    content=$(cat "$file_path")

    if ! echo "$content" | jq . &>/dev/null; then
        log_error "Invalid JSON in file: $file_path"
        return 5
    fi

    echo "$content"
}

#------------------------------------------------------------------------------
# Orchestrator Signals
#------------------------------------------------------------------------------

# Emit a SAGE signal for orchestrator
# Usage: emit_signal <signal_type> [KEY=value ...]
# Example: emit_signal CHECKPOINT FILE="/path/to/file"
emit_signal() {
    local signal_type="$1"
    shift

    echo ""
    echo "============================================"
    echo "SAGE_SIGNAL:$signal_type"

    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        echo "$key: $value"
        shift
    done

    echo "============================================"
    echo ""
}

# Signal types for reference:
# - CHECKPOINT:      Save state and restart with fresh context
# - HITL_REQUIRED:   Human review needed (pauses orchestrator)
# - EPIC_COMPLETE:   Epic finished successfully
# - FATAL_ERROR:     Unrecoverable error

#------------------------------------------------------------------------------
# File Utilities
#------------------------------------------------------------------------------

# Atomic write to file (write to temp, then move)
# Usage: atomic_write <file_path> <content>
atomic_write() {
    local file_path="$1"
    local content="$2"
    local temp_file

    temp_file=$(mktemp)
    echo "$content" > "$temp_file"

    if ! mv "$temp_file" "$file_path"; then
        log_error "Failed to write file: $file_path"
        rm -f "$temp_file"
        return 2
    fi

    log_verbose "Wrote file: $file_path"
}

# Create backup of file before modification
# Usage: backup_file <file_path>
# Returns: backup path on stdout
backup_file() {
    local file_path="$1"
    local backup_path="${file_path}.bak.$(date +%Y%m%d-%H%M%S)"

    if [[ -f "$file_path" ]]; then
        cp "$file_path" "$backup_path"
        log_verbose "Created backup: $backup_path"
        echo "$backup_path"
    fi
}

#------------------------------------------------------------------------------
# Initialization
#------------------------------------------------------------------------------

# Initialize common library (call at start of script)
# Usage: sage_init [options]
#   --require-git     Fail if not in git repo
#   --require-gh      Fail if gh not authenticated
#   --verbose         Enable verbose logging
sage_init() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --require-git)
                if ! is_git_repo; then
                    log_error "Not in a git repository"
                    exit 3
                fi
                shift
                ;;
            --require-gh)
                require_gh
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            *)
                log_warn "Unknown init option: $1"
                shift
                ;;
        esac
    done

    log_verbose "SAGE common library v$SAGE_COMMON_VERSION initialized"
}
