# SAGE Scripts Reference

**Location**: `sage/scripts/`

These scripts manage SAGE framework lifecycle in projects.

---

## Prerequisites

SAGE shell scripts require the following tools. All are available via NixOS/nix-shell.

| Tool | Version | Purpose | Required For |
|------|---------|---------|--------------|
| `bash` | ≥4.0 | Shell execution (associative arrays) | All scripts |
| `jq` | ≥1.6 | JSON processing | Checkpoint, metrics, orchestration |
| `yq` | ≥3.0 | YAML processing | Sprint status, compile-sage-agent |
| `gh` | ≥2.0 | GitHub CLI | PR creation, issues, milestones |
| `bats` | ≥1.0 | Bash testing framework | Running tests (Phase 6) |
| `git` | ≥2.0 | Version control | All git operations |

### Verification

```bash
# Check all tools are available
bash --version | head -1
jq --version
yq --version
gh --version | head -1
bats --version
git --version
```

### Expected Output

```
GNU bash, version 5.x.x
jq-1.7+
yq 3.x.x (or 4.x.x)
gh version 2.x.x
Bats 1.x.x
git version 2.x.x
```

---

## setup.sh - Initialize SAGE in a Project

**Purpose**: Set up SAGE framework in a new or existing project.

### What It Does

1. ✅ Creates `project-sage/` directory structure
2. ✅ Creates project-specific `config.yaml` with user settings
3. ✅ Syncs GitHub Copilot wrapper agents to `.github/agents/`
4. ✅ Creates output directories
5. ✅ Sets up git hooks (optional)
6. ✅ Creates README in `project-sage/`

### Usage

```bash
# Basic setup (interactive prompts)
./sage/scripts/setup.sh --interactive

# Quick setup with args
./sage/scripts/setup.sh --user "Your Name" --output-dir docs

# Preview changes
./sage/scripts/setup.sh --dry-run --user "Test User"

# Full example
./sage/scripts/setup.sh \
  --user "Jane Doe" \
  --lang English \
  --output-dir artifacts \
  --force
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--user NAME` | Set user name in config | (required) |
| `--lang LANGUAGE` | Communication language | English |
| `--output-dir DIR` | Output folder for artifacts | docs |
| `--no-git-hooks` | Skip git hooks setup | (setup hooks) |
| `-f, --force` | Overwrite existing config | (no overwrite) |
| `-n, --dry-run` | Preview changes | (apply changes) |
| `-i, --interactive` | Prompt for all values | (use args only) |
| `-h, --help` | Show help | |

### Expected Output Structure

```
my-project/
├── project-sage/           # ← Created by setup
│   ├── config.yaml         # ← Your project settings
│   ├── agents/             # ← Custom agents
│   ├── workflows/          # ← Custom workflows
│   ├── knowledge/          # ← TEA knowledge
│   └── README.md
├── docs/                   # ← Output folder (configurable)
├── .github/
│   └── agents/             # ← Synced wrapper agents
└── sage/                   # ← Submodule (unchanged)
```

---

## sync-github-agents.sh - Sync GitHub Copilot Wrapper Agents

**Purpose**: Copy wrapper agents from SAGE to `.github/agents/` for GitHub Copilot.

This script is called automatically by `setup.sh`, but can be run standalone.

### Usage

```bash
# Sync agents
./sage/scripts/sync-github-agents.sh

# Preview sync
./sage/scripts/sync-github-agents.sh --dry-run

# Verbose output
./sage/scripts/sync-github-agents.sh --verbose

# Force overwrite
./sage/scripts/sync-github-agents.sh --force
```

### What It Syncs

Copies all `*.agent.md` files from:
- **Source**: `sage/agents/wrappers/github/`
- **Target**: `.github/agents/`

Only updates files that have changed (checksums compared).

---

## sync-claude-agents.sh - Sync Claude Code Wrapper Agents

**Purpose**: Copy wrapper agents from SAGE to `.claude/commands/` for Claude Code slash commands.

This script is called automatically by `setup.sh`, but can be run standalone.

### Usage

```bash
# Sync agents
./sage/scripts/sync-claude-agents.sh

# Preview sync
./sage/scripts/sync-claude-agents.sh --dry-run

# Verbose output
./sage/scripts/sync-claude-agents.sh --verbose

# Skip removal of stale agents
./sage/scripts/sync-claude-agents.sh --no-cleanup
```

### What It Syncs

Copies all `*.md` files from:
- **Source**: `sage/agents/wrappers/claude/`
- **Target**: `.claude/commands/`

Creates slash commands like `/assistant`, `/software-dev`, `/game-architect`.

### Naming Convention

Agent files use `{category}-{role}.md` pattern:
- `assistant.md` → `/assistant`
- `software-dev.md` → `/software-dev`
- `game-architect.md` → `/game-architect`

Only updates files that have changed (checksums compared). Removes stale agents not in source.

---

## Common Workflows

### New Project Setup

```bash
# 1. Clone SAGE
git clone https://github.com/YOUR-USERNAME/sage-method.git
cd sage-method

# 2. Initialize SAGE
./sage/scripts/setup.sh --interactive

# 3. Try it out
# Open in your IDE, trigger the assistant agent
```

### Updating SAGE

```bash
# Pull latest changes
git pull origin main

# Re-sync agents if needed
./sage/scripts/sync-github-agents.sh
./sage/scripts/sync-claude-agents.sh
```

### Re-sync Agents Only

```bash
# If .github/agents/ or .claude/commands/ get out of sync
./sage/scripts/sync-github-agents.sh
./sage/scripts/sync-claude-agents.sh
```

---

## Troubleshooting

### "User name is required"

Setup needs your name for agent configuration. Use interactive mode:

```bash
./sage/scripts/setup.sh --interactive
```

### Config Already Exists

If `project-sage/config.yaml` exists and you want to recreate it:

```bash
./sage/scripts/setup.sh --force
```

---

## Architecture Notes

### Why These Scripts?

- **Consistency**: Standardized setup across all projects
- **Safety**: Dry-run mode, checks, automatic backups
- **Automation**: Reduces manual steps and errors

### Design Principles

1. **Idempotent**: Can run multiple times safely
2. **Transparent**: Shows what will happen before doing it
3. **Reversible**: Changes can be undone
4. **Informative**: Clear output and error messages
5. **Composable**: Scripts work together and standalone

### File Ownership

| Location | Owned By | Modified By |
|----------|----------|-------------|
| `sage/` | SAGE repo | git pull |
| `project-sage/` | Your project | You |
| `.github/agents/` | Generated | sync script |
| `.claude/commands/` | Generated | sync script |

---

## md2pdf.py - Convert Markdown to PDF

**Purpose**: Generate PDF reports from Markdown files. Useful for creating shareable documentation from analysis reports, test results, and other Markdown outputs.

### What It Does

1. 📄 Converts Markdown to formatted PDF
2. 📊 Renders tables, code blocks, headers (h1-h4), lists
3. 📝 Adds header with document title and page numbers
4. 🔤 Handles unicode characters gracefully
5. 🔧 Works in NixOS environments via `uvx`

### Usage

```bash
# Basic usage (outputs to same directory as input)
nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py report.md

# Specify output path
nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py report.md -o /path/to/output.pdf

# Custom title in header
nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py report.md -t "My Report"

# From within a project using SAGE
cd /path/to/project
nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py docs/analysis.md
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `input` | Input Markdown file (required) | - |
| `-o, --output` | Output PDF path | Same name with .pdf extension |
| `-t, --title` | Document title for header | Extracted from first h1 |

### Supported Markdown Features

| Feature | Syntax | Notes |
|---------|--------|-------|
| Headers | `# ## ### ####` | h1-h4 supported |
| Tables | `\| col \| col \|` | Auto-sized columns |
| Code blocks | ` ``` ` | Monospace font, gray background |
| Bullet lists | `- item` | Rendered with asterisk |
| Numbered lists | `1. item` | Preserved as-is |
| Horizontal rules | `---` | Gray line separator |
| Bold/Italic | `**bold** *italic*` | Converted to plain text |
| Inline code | `` `code` `` | Converted to plain text |

### Example

```bash
# Generate PDF from test analysis report
cd /path/to/your-project
nix develop --command uvx --with fpdf2 python sage/scripts/md2pdf.py \
  docs/reports/analysis-report.md \
  -o docs/reports/analysis-report.pdf
```

### Dependencies

- **fpdf2**: Pure Python PDF library (installed automatically via uvx)
- No system dependencies required

---

## Git Operations Scripts (Story 3-1)

Scripts for git operations extracted from workflows. All scripts source `lib/common.sh` for shared utilities.

### git-branch.sh

Branch management operations.

```bash
git-branch.sh create epic <epic_id>        # Create epic branch from dev
git-branch.sh create story <story_id> <epic>  # Create story branch from epic
git-branch.sh switch <branch>              # Checkout with validation
git-branch.sh merge <branch>               # Merge with conflict detection
git-branch.sh sync <branch>                # Pull and merge from parent
git-branch.sh push <branch>                # Push to remote
```

### git-checkpoint.sh

Commit and checkpoint operations.

```bash
git-checkpoint.sh stage                    # Stage all changes
git-checkpoint.sh commit --message "..."   # Create checkpoint commit
git-checkpoint.sh micro --message "..."    # Create micro-commit
git-checkpoint.sh mark-tasks <story>       # Mark tasks complete
```

### git-recover.sh

Recovery and revert operations.

```bash
git-recover.sh stash                       # Safety stash before recovery
git-recover.sh reset <commit>              # Hard reset to commit
git-recover.sh pop                         # Restore from stash
git-recover.sh list                        # Show recovery points
```

### git-state-check.sh

Git state validation for orchestrator.

```bash
git-state-check.sh clean                   # Check uncommitted changes
git-state-check.sh branch-exists <branch>  # Validate branch
git-state-check.sh upstream-sync           # Check remote sync
git-state-check.sh full                    # Complete state (JSON)
```

---

## GitHub Operations Scripts (Story 3-1)

Scripts for GitHub API operations.

### gh-create-pr.sh

Pull request creation.

```bash
gh-create-pr.sh story <id> <story_branch> <epic_branch>
gh-create-pr.sh epic <id> <epic_branch> --title "..."
```

### gh-milestone.sh

Milestone operations.

```bash
gh-milestone.sh create <epic_id> "Title"   # Create (idempotent)
gh-milestone.sh get <epic_id>              # Get milestone number
gh-milestone.sh update <num> <done> <total>  # Update progress
gh-milestone.sh close <num>                # Close milestone
```

### gh-poll-response.sh

HitL polling (single check).

```bash
gh-poll-response.sh poll <issue>           # Get response JSON
gh-poll-response.sh poll <issue> --raw     # Status only
gh-poll-response.sh check <issue> APPROVED # Check specific type
```

### gh-wait-approval.sh

Orchestrator polling loop.

```bash
gh-wait-approval.sh wait <issue> --signal  # Wait with signals
gh-wait-approval.sh check <issue>          # One-shot check
```

### gh-create-review-issue.sh

Create GitHub issue for HitL document review.

```bash
gh-create-review-issue.sh prd docs/prd.md           # PRD review
gh-create-review-issue.sh architecture docs/arch.md # Architecture review
gh-create-review-issue.sh epics docs/epics.md       # Epic review
gh-create-review-issue.sh ux docs/ux.md --milestone 1
```

Supports document types: `prd`, `architecture`, `ux`, `epics`. Emits `HITL_REQUIRED` signal.

### gh-issue-complete.sh

Mark GitHub issue as complete with summary.

```bash
gh-issue-complete.sh 123 --tasks-completed 5 --tests-passed 10
gh-issue-complete.sh 123 --pr 45 --commit abc123 -m "All done"
gh-issue-complete.sh 123 --coverage 85 --project-id PVT_xxx
```

Posts completion summary, updates labels, closes issue.

### gh-issue-progress.sh

Post progress updates to GitHub issues.

```bash
gh-issue-progress.sh 123 started -m "Beginning implementation"
gh-issue-progress.sh 123 task_complete -t "Add validation"
gh-issue-progress.sh 123 blocker -m "Waiting on API access"
gh-issue-progress.sh 123 test_results --tests-passed 10 --coverage 80
```

Update types: `started`, `task_complete`, `blocker`, `decision`, `test_results`.

### gh-project-init.sh

Initialize GitHub Project and Milestone for epic.

```bash
gh-project-init.sh epic-7 "SAGE Method v1.0 Release"
gh-project-init.sh epic-8 "DevOps Workflows" --owner YOUR-USERNAME --repo sage-method
```

Creates or retrieves project board and milestone. Idempotent - safe to run multiple times.

### gh-verify-state.sh

Verify GitHub state matches checkpoint.

```bash
gh-verify-state.sh .sage/state/checkpoint.json           # Basic check
gh-verify-state.sh .sage/state/checkpoint.json --verbose # Detailed output
```

Compares expected state from checkpoint against actual GitHub issues/milestones.

---

## Verification Scripts

### verify-claude-setup.sh

Verify Claude Code SAGE agent setup.

```bash
./sage/scripts/verify-claude-setup.sh
```

Checks that all Claude agents are properly configured:
- Verifies `.claude/` directory structure
- Validates agent wrapper files
- Checks slash command availability
- Provides next-step guidance

---

## Orchestration Scripts

### webhook-receiver.sh

Lightweight HTTP server for GitHub webhook reception.

```bash
./sage/scripts/webhook-receiver.sh        # Default port 9876
./sage/scripts/webhook-receiver.sh 8080   # Custom port
```

Receives GitHub webhooks and triggers Claude Code resume when HitL responses detected. Requires tunnel (ngrok/cloudflare) for external access.

### workflow-executor.sh

Execute workflow contracts with phase chaining.

```bash
workflow-executor.sh run workflow.yaml              # Run full workflow
workflow-executor.sh run workflow.yaml --dry-run    # Preview execution
workflow-executor.sh run workflow.yaml --stop-at implementation
workflow-executor.sh resume                         # Resume from checkpoint
```

Part of SAGE workflow lifecycle testing framework. Manages phase transitions and checkpoint state.

### testing/capture-trace.sh

Capture workflow execution trace for validation.

```bash
./sage/scripts/testing/capture-trace.sh dev-story    # Capture trace for workflow
./sage/scripts/testing/capture-trace.sh dev-story --compare contracts/dev-story.yaml
```

Wraps workflow execution and captures detailed trace of phase transitions, signals emitted, duration of each phase, and final outcome. Trace files can be compared against contracts to validate behavior.

---

## Test & Metrics Scripts (Story 3-1)

Scripts for test execution and metrics collection.

### test-run.sh

Test execution wrapper.

```bash
test-run.sh run                            # Auto-detect and run
test-run.sh run --framework pytest         # Force framework
test-run.sh run --coverage --nix           # With coverage in Nix
test-run.sh detect                         # Framework detection only
test-run.sh report --format summary        # Last run summary
```

### metrics-collect.sh

Metrics collection.

```bash
metrics-collect.sh git --base main --json  # Git metrics
metrics-collect.sh time --start TIME       # Duration
metrics-collect.sh test                    # Test metrics
metrics-collect.sh full --epic 3           # All metrics
metrics-collect.sh write --append          # Write to file
```

### sprint-update.sh

Sprint status YAML updates.

```bash
sprint-update.sh read                      # Current status
sprint-update.sh story-status <id> done    # Update story
sprint-update.sh task-status <s> <t> done  # Update task
sprint-update.sh summary --json            # Sprint summary
```

### checkpoint-write.sh

Checkpoint JSON operations.

```bash
checkpoint-write.sh create <epic> <story> <phase> <task>
checkpoint-write.sh write                  # Write from stdin
checkpoint-write.sh update --status done   # Update existing
checkpoint-write.sh read --field status    # Read field
checkpoint-write.sh clear --archive        # Clear with archive
```

---

## Shared Library

### lib/common.sh

Common utilities sourced by all scripts:

- `log_info/warn/error()` - Standardized logging
- `get_repo_info()` - Repository detection
- `get_current_branch()` - Branch detection
- `require_command()` - Dependency checking
- `emit_signal()` - SAGE signal emission
- `atomic_write()` - Safe file writes
- `sage_init()` - Script initialization

---

## See Also

- [INDEX.md](../INDEX.md) - SAGE architecture overview
- [agents/](../agents/) - Core agent definitions
- [workflows/](../workflows/) - Core workflow library
- [docs/git-command-migration.md](../../docs/git-command-migration.md) - Git command migration guide
- [docs/workflow-audit.md](../../docs/workflow-audit.md) - Workflow optimization audit
