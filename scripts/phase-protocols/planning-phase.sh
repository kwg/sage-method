#!/usr/bin/env bash
# planning-phase.sh - Create story files and update sprint tracking
# Part of SAGE workflow lifecycle testing framework
# See: contracts/phases/planning.contract.yaml

set -euo pipefail

# Dependency check
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed" >&2; exit 2; }

# Track created files for rollback
CREATED_FILES=()
CREATED_DIRS=()
BACKUP_FILE=""

# Cleanup handler
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        # Rollback on failure
        emit_signal "ROLLBACK" '{"status":"started","reason":"planning phase failed"}'

        # Restore sprint-status.yaml if backed up
        if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
            mv "$BACKUP_FILE" docs/sprint-artifacts/sprint-status.yaml 2>/dev/null || true
        fi

        # Remove created files (in reverse order)
        for ((i=${#CREATED_FILES[@]}-1; i>=0; i--)); do
            rm -f "${CREATED_FILES[$i]}" 2>/dev/null || true
        done

        # Remove created directories (in reverse order)
        for ((i=${#CREATED_DIRS[@]}-1; i>=0; i--)); do
            rmdir "${CREATED_DIRS[$i]}" 2>/dev/null || true
        done

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

    echo "{\"signal\":\"$signal_name\",\"payload\":$(echo "$payload" | jq -c ". + {phase:\"planning\",timestamp:\"$timestamp\"}")}" >&2
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

# Precondition: checkpoint phase must be 'init'
CHECKPOINT_PHASE=$(jq -r '.phase' .sage/state/checkpoint.json 2>/dev/null || echo "")
if [ "$CHECKPOINT_PHASE" != "init" ]; then
    emit_error "precondition_failed" "Precondition failed: checkpoint phase is '$CHECKPOINT_PHASE', expected 'init'" 1
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

# Extract story info from state (or use defaults for testing)
EPIC_NUM=$(echo "$STATE" | jq -r '.epic_num // "1"')
SPRINT_NUM=$(echo "$STATE" | jq -r '.sprint_num // "1"')
STORY_KEY=$(echo "$STATE" | jq -r '.story_key // "1-1-test-story"')

# Create epic and sprint directories
EPIC_DIR="docs/sprint-artifacts/epic-$EPIC_NUM"
SPRINT_DIR="$EPIC_DIR/sprint-$SPRINT_NUM"

mkdir -p "$SPRINT_DIR" || emit_error "directory_creation_failed" "Failed to create $SPRINT_DIR" 2
CREATED_DIRS+=("$EPIC_DIR" "$SPRINT_DIR")
emit_signal "CHECKPOINT" "{\"operation\":\"epic_directory_created\",\"details\":{\"directory\":\"$SPRINT_DIR\"}}"

# Create story file
STORY_FILE="$SPRINT_DIR/$STORY_KEY.md"
cat > "$STORY_FILE" <<EOF
# Story $STORY_KEY

Status: ready-for-dev

## Story

As a developer,
I want to test the planning phase,
so that I can validate workflow lifecycle behavior.

## Acceptance Criteria

1. Story file is created in correct directory structure
2. Sprint status is updated with story information

## Tasks / Subtasks

- [ ] Task 1: Implement feature
- [ ] Task 2: Write tests

## Dev Notes

This is a test story created by planning-phase.sh.
EOF

if [ ! -f "$STORY_FILE" ]; then
    emit_error "story_file_creation_failed" "Failed to create story file: $STORY_FILE" 2
fi
CREATED_FILES+=("$STORY_FILE")
emit_signal "CHECKPOINT" "{\"operation\":\"story_file_created\",\"details\":{\"file\":\"$STORY_FILE\"}}"

# Update or create sprint-status.yaml
mkdir -p docs/sprint-artifacts
SPRINT_STATUS_FILE="docs/sprint-artifacts/sprint-status.yaml"

# Backup existing sprint-status.yaml
if [ -f "$SPRINT_STATUS_FILE" ]; then
    BACKUP_FILE=$(mktemp)
    cp "$SPRINT_STATUS_FILE" "$BACKUP_FILE"
fi

# Create or append to sprint-status.yaml
if [ ! -f "$SPRINT_STATUS_FILE" ]; then
    cat > "$SPRINT_STATUS_FILE" <<EOF
sprint: $SPRINT_NUM
stories:
  - story_key: $STORY_KEY
    status: ready-for-dev
    epic: $EPIC_NUM
EOF
else
    # Simple append (in real implementation, would use YAML parser)
    echo "  - story_key: $STORY_KEY" >> "$SPRINT_STATUS_FILE"
    echo "    status: ready-for-dev" >> "$SPRINT_STATUS_FILE"
    echo "    epic: $EPIC_NUM" >> "$SPRINT_STATUS_FILE"
fi

if [ ! -f "$SPRINT_STATUS_FILE" ]; then
    emit_error "sprint_status_update_failed" "Failed to update sprint-status.yaml" 2
fi
emit_signal "CHECKPOINT" "{\"operation\":\"sprint_status_updated\",\"details\":{\"file\":\"$SPRINT_STATUS_FILE\"}}"

# Update checkpoint
CHECKPOINT=$(jq -c ". + {phase:\"planning\",story_created:true,story_file:\"$STORY_FILE\",timestamp:\"$(date -Iseconds)\"}" .sage/state/checkpoint.json)
echo "$CHECKPOINT" > .sage/state/checkpoint.json

# Emit PHASE_COMPLETE signal
emit_signal "PHASE_COMPLETE" "{\"success\":true}"

# Return new state to stdout
echo "$STATE" | jq -c ". + {phase:\"planning\",story_created:true,story_file:\"$STORY_FILE\"}"
