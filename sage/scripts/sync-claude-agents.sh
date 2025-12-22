#!/usr/bin/env bash
# sync-claude-agents.sh - Sync SAGE wrapper agents to .claude/commands/
#
# This script copies wrapper agents from the SAGE source-of-truth location
# (sage/agents/wrappers/claude/) to the Claude Code slash commands directory
# (.claude/commands/).
#
# Creates slash commands like /assistant, /software-dev, /game-architect
#
# Usage: ./sage/scripts/sync-claude-agents.sh [--dry-run] [--no-cleanup]
#
# Part of the SAGE standalone architecture.

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_DIR="$PROJECT_ROOT/sage/agents/wrappers/claude"
TARGET_DIR="$PROJECT_ROOT/.claude/commands"

# Parse arguments
DRY_RUN=false
VERBOSE=false
FORCE=false
NO_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Sync SAGE wrapper agents from sage/agents/wrappers/claude/ to .claude/commands/"
            echo ""
            echo "Options:"
            echo "  -n, --dry-run    Show what would be done without making changes"
            echo "  -v, --verbose    Show detailed output"
            echo "  -f, --force      Overwrite without confirmation"
            echo "  --no-cleanup     Skip removal of stale agents not in source"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "       $1"
    fi
}

# Validation
if [[ ! -d "$SOURCE_DIR" ]]; then
    log_error "Source directory not found: $SOURCE_DIR"
    exit 1
fi

# Count source files
SOURCE_FILES=("$SOURCE_DIR"/*.md)
if [[ ! -e "${SOURCE_FILES[0]}" ]]; then
    log_error "No .md files found in $SOURCE_DIR"
    exit 1
fi

NUM_SOURCE=${#SOURCE_FILES[@]}

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  SAGE Claude Agent Sync"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
log_info "Source: $SOURCE_DIR"
log_info "Target: $TARGET_DIR"
log_info "Files to sync: $NUM_SOURCE"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Create target directory if needed
if [[ ! -d "$TARGET_DIR" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create: $TARGET_DIR"
    else
        mkdir -p "$TARGET_DIR"
        log_success "Created target directory: $TARGET_DIR"
    fi
fi

# Track results
SYNCED=0
SKIPPED=0
UPDATED=0
REMOVED=0

# Build list of source filenames for cleanup comparison
declare -A SOURCE_FILENAMES
for SOURCE_FILE in "${SOURCE_FILES[@]}"; do
    FILENAME=$(basename "$SOURCE_FILE")
    SOURCE_FILENAMES["$FILENAME"]=1
done

# Step 1: Sync files from source to target
echo -e "${CYAN}▶ Syncing agents...${NC}"

for SOURCE_FILE in "${SOURCE_FILES[@]}"; do
    FILENAME=$(basename "$SOURCE_FILE")
    TARGET_FILE="$TARGET_DIR/$FILENAME"

    log_verbose "Processing: $FILENAME"

    # Check if target exists and compare
    if [[ -f "$TARGET_FILE" ]]; then
        if cmp -s "$SOURCE_FILE" "$TARGET_FILE"; then
            log_verbose "  Unchanged: $FILENAME"
            ((SKIPPED++))
            continue
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "Would update: $FILENAME"
            else
                cp "$SOURCE_FILE" "$TARGET_FILE"
                log_success "Updated: $FILENAME"
            fi
            ((UPDATED++))
        fi
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would create: $FILENAME"
        else
            cp "$SOURCE_FILE" "$TARGET_FILE"
            log_success "Created: $FILENAME"
        fi
        ((SYNCED++))
    fi
done

# Step 2: Clean up stale agents (files in target but not in source)
if [[ "$NO_CLEANUP" == "false" ]] && [[ -d "$TARGET_DIR" ]]; then
    echo ""
    echo -e "${CYAN}▶ Cleaning up stale agents...${NC}"

    for TARGET_FILE in "$TARGET_DIR"/*.md; do
        [[ -e "$TARGET_FILE" ]] || continue  # Skip if no files match

        FILENAME=$(basename "$TARGET_FILE")

        if [[ -z "${SOURCE_FILENAMES[$FILENAME]:-}" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_warn "Would remove stale: $FILENAME"
            else
                rm "$TARGET_FILE"
                log_warn "Removed stale: $FILENAME"
            fi
            ((REMOVED++))
        fi
    done

    if [[ $REMOVED -eq 0 ]]; then
        log_info "No stale agents found"
    fi
fi

echo ""
echo "───────────────────────────────────────────────────────────────────"
echo "  Summary"
echo "───────────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}Created:${NC}   $SYNCED"
echo -e "  ${BLUE}Updated:${NC}   $UPDATED"
echo -e "  ${YELLOW}Unchanged:${NC} $SKIPPED"
echo -e "  ${RED}Removed:${NC}   $REMOVED"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}Dry run complete. Run without --dry-run to apply changes.${NC}"
fi

echo ""
