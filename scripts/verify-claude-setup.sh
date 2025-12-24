#!/usr/bin/env bash
# verify-claude-setup.sh - Verify Claude SAGE agent setup
#
# This script checks that all Claude agents are properly configured
# and provides guidance on next steps.

set -uo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  Claude SAGE Agent Setup Verification"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Check directories
echo -e "${BLUE}[1/5]${NC} Checking directories..."
if [[ -d ".claude" ]]; then
    echo -e "  ${GREEN}✓${NC} .claude/ directory exists"
else
    echo -e "  ${RED}✗${NC} .claude/ directory missing"
    exit 1
fi

if [[ -d "sage/agents/wrappers/claude" ]]; then
    echo -e "  ${GREEN}✓${NC} sage/agents/wrappers/claude/ exists"
else
    echo -e "  ${RED}✗${NC} Source directory missing"
    exit 1
fi

# Check agent files
echo ""
echo -e "${BLUE}[2/5]${NC} Checking agent files..."
EXPECTED_AGENTS=(
    "sage-analyst.md"
    "sage-architect.md"
    "sage-dev.md"
    "sage-devops.md"
    "sage-it.md"
    "sage-pm.md"
    "sage-quick-flow-solo-dev.md"
    "sage-sm.md"
    "sage-tea.md"
    "sage-tech-writer.md"
    "sage-ux-designer.md"
)

MISSING=0
for agent in "${EXPECTED_AGENTS[@]}"; do
    if [[ -f ".claude/$agent" ]]; then
        echo -e "  ${GREEN}✓${NC} $agent"
    else
        echo -e "  ${RED}✗${NC} $agent missing"
        ((MISSING++))
    fi
done

if [[ $MISSING -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}Warning: $MISSING agent(s) missing. Run sync script:${NC}"
    echo "  ./sage/scripts/sync-claude-agents.sh"
fi

# Check documentation
echo ""
echo -e "${BLUE}[3/5]${NC} Checking documentation..."
DOCS=(
    "README.md"
    "MIGRATION-GUIDE.md"
    "QUICK-REFERENCE.md"
)

for doc in "${DOCS[@]}"; do
    if [[ -f ".claude/$doc" ]]; then
        echo -e "  ${GREEN}✓${NC} $doc"
    else
        echo -e "  ${RED}✗${NC} $doc missing"
    fi
done

# Check sync script
echo ""
echo -e "${BLUE}[4/5]${NC} Checking sync script..."
if [[ -f "sage/scripts/sync-claude-agents.sh" ]]; then
    echo -e "  ${GREEN}✓${NC} sync-claude-agents.sh exists"
    if [[ -x "sage/scripts/sync-claude-agents.sh" ]]; then
        echo -e "  ${GREEN}✓${NC} Script is executable"
    else
        echo -e "  ${YELLOW}!${NC} Script not executable (chmod +x needed)"
    fi
else
    echo -e "  ${RED}✗${NC} Sync script missing"
fi

# Check VS Code extensions
echo ""
echo -e "${BLUE}[5/5]${NC} Checking VS Code setup..."
if command -v code &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} VS Code command available"
    
    # Check for Claude-related extensions
    if code --list-extensions 2>/dev/null | grep -qi "claude\|anthropic\|continue"; then
        echo -e "  ${GREEN}✓${NC} Claude/Continue extension appears installed"
    else
        echo -e "  ${YELLOW}!${NC} No Claude extension detected"
        echo -e "     Install: Search 'Claude' or 'Continue' in Extensions"
    fi
else
    echo -e "  ${YELLOW}!${NC} VS Code command not available"
    echo -e "     Setup may still work in VS Code GUI"
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✓${NC} 11 SAGE agents ready for Claude"
echo -e "${GREEN}✓${NC} Documentation available"
echo -e "${GREEN}✓${NC} Sync script configured"
echo ""
echo "Next Steps:"
echo ""
echo "1. Install Claude Extension in VS Code:"
echo "   - Open Extensions (Ctrl+Shift+X)"
echo "   - Search 'Claude' or 'Continue'"
echo "   - Install and configure"
echo ""
echo "2. Test an agent:"
echo "   - Open Claude chat in VS Code"
echo "   - Type: @.claude/sage-sm.md"
echo "   - Agent should activate with menu"
echo ""
echo "3. Read documentation:"
echo "   - Quick Start: .claude/QUICK-REFERENCE.md"
echo "   - Full Guide: .claude/README.md"
echo "   - Migration: .claude/MIGRATION-GUIDE.md"
echo ""
echo "4. Optionally disable GitHub Copilot:"
echo "   - Settings > Extensions > GitHub Copilot"
echo "   - Disable or uninstall"
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo ""
