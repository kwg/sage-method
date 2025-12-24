#!/usr/bin/env bash
# complete-phase.sh - Merge feature branch, update story status, and cleanup
# Part of SAGE workflow lifecycle testing framework
# See: contracts/phases/complete.contract.yaml

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed" >&2; exit 2; }

# Track state for rollback
MERGE_IN_PROGRESS=false
SPRINT_STATUS_BACKUP=""

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        # Rollback on failure
        emit_signal "ROLLBACK" '{"status":"started","reason":"complete phase failed"}'

        # Abort merge if in progress
        if [ "$MERGE_IN_PROGRESS" = true ]; then
            git merge --abort 2>/dev/null || true
        fi

        # Restore sprint-status.yaml if backed up
        if [ -n "$SPRINT_STATUS_BACKUP" ] && [ -f "$SPRINT_STATUS_BACKUP" ]; then
            mv "$SPRINT_STATUS_BACKUP" docs/sprint-artifacts/sprint-status.yaml 2>/dev/null || true
        fi

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

    echo "{\"signal\":\"$signal_name\",\"payload\":$(echo "$payload" | jq -c ". + {phase:\"complete\",timestamp:\"$timestamp\"}")}" >&2
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

# Precondition: checkpoint.json must exist
if [ ! -f .sage/state/checkpoint.json ]; then
    emit_error "precondition_failed" "Precondition failed: .sage/state/checkpoint.json does not exist" 1
fi

# Precondition: checkpoint phase must be 'validation'
CHECKPOINT_PHASE=$(jq -r '.phase' .sage/state/checkpoint.json 2>/dev/null || echo "")
if [ "$CHECKPOINT_PHASE" != "validation" ]; then
    emit_error "precondition_failed" "Precondition failed: checkpoint phase is '$CHECKPOINT_PHASE', expected 'validation'" 1
fi

# Precondition: tests_passed must be true
TESTS_PASSED=$(jq -r '.tests_passed' .sage/state/checkpoint.json 2>/dev/null || echo "false")
if [ "$TESTS_PASSED" != "true" ]; then
    emit_error "precondition_failed" "Precondition failed: tests not passed (tests_passed != true)" 1
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

# Get branch info from state
FEATURE_BRANCH=$(echo "$STATE" | jq -r '.branch // "feature-1-1-test-story"')
TARGET_BRANCH="main"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# If we're on feature branch, merge to target
if [ "$CURRENT_BRANCH" = "$FEATURE_BRANCH" ]; then
    # Switch to target branch
    if ! git checkout "$TARGET_BRANCH" 2>/dev/null; then
        emit_error "merge_failed" "Failed to checkout $TARGET_BRANCH" 2
    fi
fi

# Perform merge
MERGE_IN_PROGRESS=true
if ! git merge --no-ff "$FEATURE_BRANCH" -m "Merge $FEATURE_BRANCH into $TARGET_BRANCH" 2>/dev/null; then
    # Check if it's a conflict
    if git status | grep -q "Unmerged paths"; then
        emit_error "merge_conflict" "Merge conflict detected between $FEATURE_BRANCH and $TARGET_BRANCH" 3
    else
        emit_error "merge_failed" "Failed to merge $FEATURE_BRANCH into $TARGET_BRANCH" 2
    fi
fi
MERGE_IN_PROGRESS=false

emit_signal "CHECKPOINT" "{\"operation\":\"branch_merged\",\"details\":{\"source_branch\":\"$FEATURE_BRANCH\",\"target_branch\":\"$TARGET_BRANCH\"}}"

# Update sprint-status.yaml
SPRINT_STATUS_FILE="docs/sprint-artifacts/sprint-status.yaml"
if [ -f "$SPRINT_STATUS_FILE" ]; then
    # Backup sprint-status.yaml
    SPRINT_STATUS_BACKUP=$(mktemp)
    cp "$SPRINT_STATUS_FILE" "$SPRINT_STATUS_BACKUP"

    # Update story status to 'done'
    STORY_KEY=$(echo "$STATE" | jq -r '.story_key // "1-1-test-story"')

    # Simple sed replacement (in real implementation, would use YAML parser)
    if grep -q "story_key: $STORY_KEY" "$SPRINT_STATUS_FILE"; then
        # Find the status line after story_key and replace it
        sed -i "/story_key: $STORY_KEY/,/status:/ s/status: .*/status: done/" "$SPRINT_STATUS_FILE"
    fi

    emit_signal "CHECKPOINT" "{\"operation\":\"story_status_updated\",\"details\":{\"story_key\":\"$STORY_KEY\",\"new_status\":\"done\"}}"
fi

# Cleanup temporary files
rm -f .sage/state/session.json 2>/dev/null || true
rm -f .sage/state/test-results.json 2>/dev/null || true
emit_signal "CHECKPOINT" "{\"operation\":\"cleanup_completed\"}"

# Update checkpoint
CHECKPOINT=$(jq -c ". + {phase:\"complete\",branch_merged:true,story_status:\"done\",timestamp:\"$(date -Iseconds)\"}" .sage/state/checkpoint.json)
echo "$CHECKPOINT" > .sage/state/checkpoint.json

# Emit PHASE_COMPLETE signal
emit_signal "PHASE_COMPLETE" "{\"success\":true}"

# Return new state to stdout
echo "$STATE" | jq -c ". + {phase:\"complete\",branch_merged:true,story_status:\"done\"}"
