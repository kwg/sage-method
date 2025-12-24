#!/usr/bin/env bash
# init-phase.sh - Initialize workflow session and create checkpoint state
# Part of SAGE workflow lifecycle testing framework
# See: contracts/phases/init.contract.yaml

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed" >&2; exit 2; }

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ -d .sage/state ]; then
        # Rollback on failure
        emit_signal "ROLLBACK" '{"status":"started","reason":"init phase failed"}'
        rm -rf .sage/state/checkpoint.json .sage/state/session.json 2>/dev/null || true
        emit_signal "ROLLBACK" '{"status":"completed"}'
    fi
}
trap cleanup EXIT

# Helper: Emit signal to stderr
emit_signal() {
    local signal_name="$1"
    local payload="${2:-{}}"
    local timestamp
    timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)

    echo "{\"signal\":\"$signal_name\",\"payload\":$(echo "$payload" | jq -c ". + {phase:\"init\",timestamp:\"$timestamp\"}")}" >&2
}

# Helper: Emit error and exit
emit_error() {
    local error_type="$1"
    local message="$2"
    local code="${3:-2}"

    emit_signal "ERROR" "{\"error_type\":\"$error_type\",\"message\":\"$message\",\"error_code\":$code}"
    exit "$code"
}

# Read input state from stdin
STATE=$(cat)

# Validate input is valid JSON
if ! echo "$STATE" | jq -e . >/dev/null 2>&1; then
    emit_error "validation_error" "Input state is not valid JSON" 2
fi

# Precondition: checkpoint.json must not exist
if [ -f .sage/state/checkpoint.json ]; then
    emit_error "precondition_failed" "Precondition failed: .sage/state/checkpoint.json already exists" 1
fi

# Precondition: session.json must not exist
if [ -f .sage/state/session.json ]; then
    emit_error "precondition_failed" "Precondition failed: .sage/state/session.json already exists" 1
fi

# Precondition: git status should be clean (allow untracked files)
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    emit_error "precondition_failed" "Precondition failed: not in a git repository" 1
fi

if [ -n "$(git status --porcelain | grep -v '^??')" ]; then
    emit_error "precondition_failed" "Precondition failed: working tree has staged or unstaged changes" 1
fi

# Emit PHASE_START signal
emit_signal "PHASE_START" "{}"

# Create .sage/state directory
mkdir -p .sage/state || emit_error "directory_creation_failed" "Failed to create .sage/state directory" 2
emit_signal "CHECKPOINT" "{\"operation\":\"directory_created\"}"

# Generate session ID
SESSION_ID="session-$(date +%s)-$$"

# Create checkpoint.json
CHECKPOINT=$(echo "$STATE" | jq -c ". + {phase:\"init\",initialized:true,timestamp:\"$(date -Iseconds)\"}")
if ! echo "$CHECKPOINT" | jq . > .sage/state/checkpoint.json 2>&1; then
    emit_error "file_write_failed" "Failed to create checkpoint.json" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"checkpoint_created\",\"details\":{\"file\":\".sage/state/checkpoint.json\"}}"

# Create session.json
SESSION_DATA=$(jq -n --arg sid "$SESSION_ID" "{session_id:\$sid,started:\"$(date -Iseconds)\"}")
if ! echo "$SESSION_DATA" | jq . > .sage/state/session.json 2>&1; then
    emit_error "file_write_failed" "Failed to create session.json" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"session_created\",\"details\":{\"file\":\".sage/state/session.json\",\"session_id\":\"$SESSION_ID\"}}"

# Emit PHASE_COMPLETE signal
emit_signal "PHASE_COMPLETE" "{\"success\":true}"

# Return new state to stdout
echo "$STATE" | jq -c ". + {phase:\"init\",initialized:true,session_id:\"$SESSION_ID\"}"
