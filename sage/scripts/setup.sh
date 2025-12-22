#!/usr/bin/env bash
# setup.sh - Initialize SAGE in a new or existing project
#
# This script sets up the SAGE framework in a project by:
# 1. Creating necessary directory structure (project-sage/)
# 2. Creating project-specific config.yaml
# 3. Syncing GitHub wrapper agents
# 4. Setting up git hooks (optional)
#
# Usage:
#   ./sage/scripts/setup.sh [OPTIONS]
#   cd my-project && sage/scripts/setup.sh --user "Your Name"
#
# Options:
#   --user NAME          Set user name in config
#   --lang LANGUAGE      Set communication language (default: English)
#   --output-dir DIR     Set output folder (default: docs)
#   --no-git-hooks       Skip git hooks setup
#   --force              Overwrite existing config
#   --dry-run            Show what would be done
#   --github             Install GitHub Copilot agents only
#   --claude             Install Claude Code agents only
#   --all                Install agents for all platforms (default)
#
# Part of the SAGE standalone architecture.

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAGE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SAGE_ROOT/.." && pwd)"

# Detect if we're in the sage-framework repo itself
SAGE_BASENAME="$(basename "$SAGE_ROOT")"
if [[ "$SAGE_BASENAME" == "sage-framework" ]] && [[ ! -L "$SAGE_ROOT" ]]; then
    echo -e "${RED}[ERROR]${NC} Cannot run setup from within sage-framework repo itself"
    echo -e "${RED}[ERROR]${NC} This script should be run from a project that uses SAGE as a submodule"
    exit 1
fi

# Default values
USER_NAME=""
LANGUAGE="English"
OUTPUT_FOLDER="docs"
SETUP_GIT_HOOKS=true
FORCE=false
DRY_RUN=false
INTERACTIVE=false
INSTALL_GITHUB=false
INSTALL_CLAUDE=false
PLATFORM_SPECIFIED=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user)
            USER_NAME="$2"
            shift 2
            ;;
        --lang|--language)
            LANGUAGE="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_FOLDER="$2"
            shift 2
            ;;
        --no-git-hooks)
            SETUP_GIT_HOOKS=false
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --interactive|-i)
            INTERACTIVE=true
            shift
            ;;
        --github)
            INSTALL_GITHUB=true
            PLATFORM_SPECIFIED=true
            shift
            ;;
        --claude)
            INSTALL_CLAUDE=true
            PLATFORM_SPECIFIED=true
            shift
            ;;
        --all)
            INSTALL_GITHUB=true
            INSTALL_CLAUDE=true
            PLATFORM_SPECIFIED=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Initialize SAGE framework in a project"
            echo ""
            echo "Options:"
            echo "  --user NAME          Set user name in config"
            echo "  --lang LANGUAGE      Set communication language (default: English)"
            echo "  --output-dir DIR     Set output folder (default: docs)"
            echo "  --no-git-hooks       Skip git hooks setup"
            echo "  -f, --force          Overwrite existing config"
            echo "  -n, --dry-run        Show what would be done"
            echo "  -i, --interactive    Prompt for configuration values"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Platform Options:"
            echo "  --github             Install GitHub Copilot agents only"
            echo "  --claude             Install Claude Code agents only"
            echo "  --all                Install agents for all platforms (default)"
            echo ""
            echo "Examples:"
            echo "  $0 --user \"Jane Doe\" --output-dir artifacts"
            echo "  $0 --user \"Jane Doe\" --claude    # Claude only"
            echo "  $0 --user \"Jane Doe\" --github --claude  # Both platforms"
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
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}▶ $1${NC}"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [[ -n "$default" ]]; then
        read -p "$(echo -e "${CYAN}${prompt}${NC} [${default}]: ")" result
        echo "${result:-$default}"
    else
        read -p "$(echo -e "${CYAN}${prompt}${NC}: ")" result
        echo "$result"
    fi
}

# Header
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  SAGE Framework Setup"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
log_info "Project Root: $PROJECT_ROOT"
log_info "SAGE Location: $SAGE_ROOT"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Interactive prompts
if [[ "$INTERACTIVE" == "true" ]]; then
    log_step "Configuration"
    USER_NAME=$(prompt_input "Enter your name" "$USER_NAME")
    LANGUAGE=$(prompt_input "Communication language" "$LANGUAGE")
    OUTPUT_FOLDER=$(prompt_input "Output folder for docs/artifacts" "$OUTPUT_FOLDER")

    read -p "$(echo -e "${CYAN}Setup git hooks?${NC} [Y/n]: ")" response
    if [[ "$response" =~ ^[Nn] ]]; then
        SETUP_GIT_HOOKS=false
    fi

    # Platform selection (only ask if not already specified via CLI)
    if [[ "$PLATFORM_SPECIFIED" == "false" ]]; then
        echo ""
        echo -e "${CYAN}Which AI platforms do you want to set up agents for?${NC}"
        echo "  1) GitHub Copilot only"
        echo "  2) Claude Code only"
        echo "  3) Both (recommended)"
        read -p "$(echo -e "${CYAN}Select option${NC} [3]: ")" platform_choice
        case "${platform_choice:-3}" in
            1)
                INSTALL_GITHUB=true
                ;;
            2)
                INSTALL_CLAUDE=true
                ;;
            3|*)
                INSTALL_GITHUB=true
                INSTALL_CLAUDE=true
                ;;
        esac
        PLATFORM_SPECIFIED=true
    fi
fi

# Default to all platforms if none specified
if [[ "$PLATFORM_SPECIFIED" == "false" ]]; then
    INSTALL_GITHUB=true
    INSTALL_CLAUDE=true
fi

# Validate required inputs
if [[ -z "$USER_NAME" ]]; then
    log_error "User name is required. Use --user or --interactive"
    exit 1
fi

# Step 1: Create project-sage directory structure
log_step "Step 1: Creating project-sage directory structure"

PROJECT_SAGE_DIR="$PROJECT_ROOT/project-sage"
DIRECTORIES=(
    "$PROJECT_SAGE_DIR"
    "$PROJECT_SAGE_DIR/agents"
    "$PROJECT_SAGE_DIR/workflows"
    "$PROJECT_SAGE_DIR/knowledge"
)

for DIR in "${DIRECTORIES[@]}"; do
    if [[ -d "$DIR" ]]; then
        log_info "Already exists: ${DIR#$PROJECT_ROOT/}"
    else
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would create: ${DIR#$PROJECT_ROOT/}"
        else
            mkdir -p "$DIR"
            log_success "Created: ${DIR#$PROJECT_ROOT/}"
        fi
    fi
done

# Step 2: Create project-specific config.yaml
log_step "Step 2: Creating project configuration"

CONFIG_FILE="$PROJECT_SAGE_DIR/config.yaml"
PROJECT_NAME=$(basename "$PROJECT_ROOT")

if [[ -f "$CONFIG_FILE" ]] && [[ "$FORCE" == "false" ]]; then
    log_warn "Config already exists: ${CONFIG_FILE#$PROJECT_ROOT/}"
    log_info "Use --force to overwrite"
else
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create: ${CONFIG_FILE#$PROJECT_ROOT/}"
        echo ""
        echo "───────────────────────────────────────────────────────────────────"
        cat <<EOF
# Project SAGE Configuration
# This file contains project-specific settings that extend sage/core/config.yaml

# User Configuration (REQUIRED)
user_name: "$USER_NAME"
communication_language: "$LANGUAGE"

# Project Configuration
project_name: "$PROJECT_NAME"
project_root: "$PROJECT_ROOT"
output_folder: "$OUTPUT_FOLDER"
sprint_artifacts: "$OUTPUT_FOLDER/sprint-artifacts"

# Development Configuration (customize as needed)
default_branch: "main"
feature_branch_pattern: "feature/{story-key}"

# Add project-specific settings below
# ...
EOF
        echo "───────────────────────────────────────────────────────────────────"
        echo ""
    else
        cat > "$CONFIG_FILE" <<EOF
# Project SAGE Configuration
# This file contains project-specific settings that extend sage/core/config.yaml

# User Configuration (REQUIRED)
user_name: "$USER_NAME"
communication_language: "$LANGUAGE"

# Project Configuration
project_name: "$PROJECT_NAME"
project_root: "$PROJECT_ROOT"
output_folder: "$OUTPUT_FOLDER"
sprint_artifacts: "$OUTPUT_FOLDER/sprint-artifacts"

# Development Configuration (customize as needed)
default_branch: "main"
feature_branch_pattern: "feature/{story-key}"

# Add project-specific settings below
# ...
EOF
        log_success "Created: ${CONFIG_FILE#$PROJECT_ROOT/}"
    fi
fi

# Step 3: Create README in project-sage
log_step "Step 3: Creating project-sage README"

README_FILE="$PROJECT_SAGE_DIR/README.md"

if [[ ! -f "$README_FILE" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create: ${README_FILE#$PROJECT_ROOT/}"
    else
        cat > "$README_FILE" <<EOF
# Project-Specific SAGE Extensions

This directory contains project-specific extensions to the core SAGE framework.

## Structure

- \`agents/\` - Custom agents specific to this project
- \`workflows/\` - Custom workflows specific to this project  
- \`knowledge/\` - Project-specific TEA knowledge base entries
- \`config.yaml\` - Project configuration (overrides sage/core/config.yaml)

## Usage

Core SAGE agents automatically discover and load extensions from this directory.

### Adding Custom Agents

Create agent files in \`agents/\` following the same format as core agents in \`sage/agents/\`.

### Adding Custom Workflows

Create workflow files in \`workflows/\` following the SAGE workflow format.

## Important

- Do NOT modify core SAGE files in \`sage/\` directory
- Use this directory for project-specific additions only
- Changes to SAGE behavior should go upstream to sage-framework repo

EOF
        log_success "Created: ${README_FILE#$PROJECT_ROOT/}"
    fi
else
    log_info "Already exists: ${README_FILE#$PROJECT_ROOT/}"
fi

# Step 4: Sync wrapper agents to AI platforms
log_step "Step 4: Syncing wrapper agents to AI platforms"

# Sync GitHub Copilot agents
if [[ "$INSTALL_GITHUB" == "true" ]]; then
    log_info "Setting up GitHub Copilot agents..."
    GITHUB_SYNC_SCRIPT="$SCRIPT_DIR/sync-github-agents.sh"
    if [[ -f "$GITHUB_SYNC_SCRIPT" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would run: sync-github-agents.sh --dry-run"
            bash "$GITHUB_SYNC_SCRIPT" --dry-run 2>&1 | sed 's/^/  /'
        else
            bash "$GITHUB_SYNC_SCRIPT" 2>&1 | sed 's/^/  /'
        fi
    else
        log_warn "sync-github-agents.sh not found, skipping GitHub setup"
    fi
else
    log_info "Skipping GitHub Copilot agents (not selected)"
fi

# Sync Claude Code agents
if [[ "$INSTALL_CLAUDE" == "true" ]]; then
    log_info "Setting up Claude Code agents..."
    CLAUDE_SYNC_SCRIPT="$SCRIPT_DIR/sync-claude-agents.sh"
    if [[ -f "$CLAUDE_SYNC_SCRIPT" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would run: sync-claude-agents.sh --dry-run"
            bash "$CLAUDE_SYNC_SCRIPT" --dry-run 2>&1 | sed 's/^/  /'
        else
            bash "$CLAUDE_SYNC_SCRIPT" 2>&1 | sed 's/^/  /'
        fi
    else
        log_warn "sync-claude-agents.sh not found, skipping Claude setup"
    fi
else
    log_info "Skipping Claude Code agents (not selected)"
fi

# Step 5: Create output directory
log_step "Step 5: Creating output directories"

OUTPUT_DIR="$PROJECT_ROOT/$OUTPUT_FOLDER"
if [[ ! -d "$OUTPUT_DIR" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Would create: $OUTPUT_FOLDER/"
    else
        mkdir -p "$OUTPUT_DIR"
        log_success "Created: $OUTPUT_FOLDER/"
    fi
else
    log_info "Already exists: $OUTPUT_FOLDER/"
fi

# Step 6: Git hooks (optional)
if [[ "$SETUP_GIT_HOOKS" == "true" ]]; then
    log_step "Step 6: Setting up git hooks"
    
    GIT_DIR="$PROJECT_ROOT/.git"
    if [[ ! -d "$GIT_DIR" ]]; then
        log_warn "Not a git repository, skipping git hooks"
    else
        HOOKS_DIR="$GIT_DIR/hooks"
        POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "Would create git hook: .git/hooks/post-commit"
        else
            cat > "$POST_COMMIT_HOOK" <<'EOF'
#!/usr/bin/env bash
# Auto-sync wrapper agents after commits to sage/agents/wrappers/

# Check if GitHub wrappers changed
if git diff HEAD~1 HEAD --name-only | grep -q "^sage/agents/wrappers/github/"; then
    echo "SAGE GitHub wrapper agents changed, syncing to .github/agents/..."
    ./sage/scripts/sync-github-agents.sh
fi

# Check if Claude wrappers changed
if git diff HEAD~1 HEAD --name-only | grep -q "^sage/agents/wrappers/claude/"; then
    echo "SAGE Claude wrapper agents changed, syncing to .claude/commands/..."
    ./sage/scripts/sync-claude-agents.sh
fi
EOF
            chmod +x "$POST_COMMIT_HOOK"
            log_success "Created git hook: .git/hooks/post-commit"
        fi
    fi
else
    log_step "Step 6: Skipping git hooks setup"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

if [[ "$DRY_RUN" == "false" ]]; then
    echo -e "${GREEN}✓${NC} SAGE framework is ready to use!"
    echo ""

    # Show which platforms were installed
    echo "Installed platforms:"
    if [[ "$INSTALL_GITHUB" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} GitHub Copilot (.github/agents/)"
    fi
    if [[ "$INSTALL_CLAUDE" == "true" ]]; then
        echo -e "  ${GREEN}✓${NC} Claude Code (.claude/commands/)"
    fi
    echo ""

    echo "Next steps:"
    echo "  1. Review configuration: project-sage/config.yaml"
    if [[ "$INSTALL_GITHUB" == "true" ]]; then
        echo "  2. Try GitHub agent: @sage-analyst *menu"
    fi
    if [[ "$INSTALL_CLAUDE" == "true" ]]; then
        echo "  2. Try Claude agent: Use /assistant command"
    fi
    echo "  3. Add custom agents to: project-sage/agents/"
    echo ""
    echo "To update SAGE framework:"
    echo "  ./sage/scripts/update.sh"
    echo ""
else
    echo -e "${YELLOW}Dry run complete.${NC} Run without --dry-run to apply changes."
    echo ""
fi
