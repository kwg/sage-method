#!/usr/bin/env bash
# implementation-phase.sh - Create feature branch, implement code, and commit changes
# Part of SAGE workflow lifecycle testing framework
# See: contracts/phases/implementation.contract.yaml

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed" >&2; exit 2; }

# Track state for rollback
ORIGINAL_BRANCH=""
FEATURE_BRANCH=""
BRANCH_CREATED=false

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ "$BRANCH_CREATED" = true ]; then
        # Rollback on failure
        emit_signal "ROLLBACK" '{"status":"started","reason":"implementation phase failed"}'

        # Reset git state
        git reset --hard HEAD 2>/dev/null || true
        git clean -fd 2>/dev/null || true

        # Switch back to original branch
        if [ -n "$ORIGINAL_BRANCH" ]; then
            git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
        fi

        # Delete feature branch
        if [ -n "$FEATURE_BRANCH" ]; then
            git branch -D "$FEATURE_BRANCH" 2>/dev/null || true
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

    echo "{\"signal\":\"$signal_name\",\"payload\":$(echo "$payload" | jq -c ". + {phase:\"implementation\",timestamp:\"$timestamp\"}")}" >&2
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

# Precondition: checkpoint phase must be 'planning'
CHECKPOINT_PHASE=$(jq -r '.phase' .sage/state/checkpoint.json 2>/dev/null || echo "")
if [ "$CHECKPOINT_PHASE" != "planning" ]; then
    emit_error "precondition_failed" "Precondition failed: checkpoint phase is '$CHECKPOINT_PHASE', expected 'planning'" 1
fi

# Precondition: story_created must be true
STORY_CREATED=$(jq -r '.story_created' .sage/state/checkpoint.json 2>/dev/null || echo "false")
if [ "$STORY_CREATED" != "true" ]; then
    emit_error "precondition_failed" "Precondition failed: story not created (story_created != true)" 1
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

# Get current branch
ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Extract story key from state
STORY_KEY=$(echo "$STATE" | jq -r '.story_key // "1-1-test-story"')
FEATURE_BRANCH="feature-$STORY_KEY"

# Create and switch to feature branch
if git rev-parse --verify "$FEATURE_BRANCH" >/dev/null 2>&1; then
    emit_error "branch_creation_failed" "Branch $FEATURE_BRANCH already exists" 2
fi

if ! git checkout -b "$FEATURE_BRANCH" 2>/dev/null; then
    emit_error "branch_creation_failed" "Failed to create branch $FEATURE_BRANCH" 2
fi
BRANCH_CREATED=true
emit_signal "CHECKPOINT" "{\"operation\":\"branch_created\",\"details\":{\"branch\":\"$FEATURE_BRANCH\"}}"

# Create or modify a test file (simulates code implementation)
TEST_FILE="test-implementation-$STORY_KEY.txt"
cat > "$TEST_FILE" <<EOF
# Test Implementation for $STORY_KEY

This file simulates code changes made during the implementation phase.
Created at: $(date -Iseconds)
Story: $STORY_KEY
Branch: $FEATURE_BRANCH
EOF

FILES_MODIFIED=1
emit_signal "CHECKPOINT" "{\"operation\":\"code_written\",\"details\":{\"files_modified\":$FILES_MODIFIED}}"

# Stage changes
git add "$TEST_FILE" || emit_error "git_operation_failed" "Failed to stage changes" 2
emit_signal "CHECKPOINT" "{\"operation\":\"changes_staged\"}"

# Commit changes
COMMIT_MSG="feat($STORY_KEY): implement story

This commit implements the changes for story $STORY_KEY.
Created by implementation-phase.sh for testing."

if ! git commit -m "$COMMIT_MSG" >/dev/null 2>&1; then
    emit_error "git_commit_failed" "Failed to commit changes" 2
fi

COMMIT_SHA=$(git rev-parse HEAD)
emit_signal "CHECKPOINT" "{\"operation\":\"changes_committed\",\"details\":{\"commit_sha\":\"$COMMIT_SHA\"}}"

# Update checkpoint
CHECKPOINT=$(jq -c ". + {phase:\"implementation\",branch_created:true,code_committed:true,branch:\"$FEATURE_BRANCH\",commit_sha:\"$COMMIT_SHA\",timestamp:\"$(date -Iseconds)\"}" .sage/state/checkpoint.json)
echo "$CHECKPOINT" > .sage/state/checkpoint.json

# Emit PHASE_COMPLETE signal
emit_signal "PHASE_COMPLETE" "{\"success\":true}"

# Return new state to stdout
echo "$STATE" | jq -c ". + {phase:\"implementation\",branch_created:true,code_committed:true,branch:\"$FEATURE_BRANCH\",commit_sha:\"$COMMIT_SHA\"}"
