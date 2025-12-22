# SAGE Method

**Stateless Agent Guidance Engine** - A framework for building LLM-powered development agents that follow instructions rather than improvising.

## What is SAGE?

SAGE Method is an agent framework built on a simple principle: **Tell Don't Ask**.

Traditional AI agents ask the LLM to figure out what to do. SAGE agents are told exactly what to do through structured instructions, workflows, and protocols. The LLM executes rather than decides.

This produces:
- **Predictable behavior** - Same input, same process, reliable output
- **Stateless operation** - No memory between sessions; all context is explicit
- **Composable agents** - Combine specialized microagents for complex workflows
- **IDE integration** - Works with Claude Code, GitHub Copilot, and compatible tools

### Single Source of Truth

SAGE enforces strict truth chains. Each layer inherits from exactly one source. Nothing is inferred twice. Context flows down explicitly - agents never "discover" or "search" for information. This eliminates the variance that comes from LLMs making different decisions on different runs.

## Quick Start

### Prerequisites

- Claude Code, GitHub Copilot Chat, or compatible LLM-powered IDE
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/sage-method.git
cd sage-method

# Run setup (interactive prompts for config)
./sage/scripts/setup.sh --interactive
```

### First Use

In Claude Code:
```
/assistant
```

In GitHub Copilot:
```
@sage-assistant *menu
```

The agent will greet you and show a numbered menu. Pick an option by number or keyword.

## Core Concepts

### Agents

Agents are personas with menus. Each menu item triggers a workflow, protocol, or action. Agents don't make decisions - they execute what their menu items define.

```
*status     → Show current project status
*develop    → Execute the dev-story workflow
*code-review → Run code review checklist
```

### Workflows

Workflows are step-by-step instructions the agent follows. Each step has clear inputs, outputs, and completion criteria.

### Two-Tier Configuration

- `sage/core/config.yaml` - Framework defaults
- `project-sage/config.yaml` - Your project overrides

## Project Structure

```
your-project/
├── sage/                    # Framework (submodule)
│   ├── agents/              # Agent definitions
│   ├── workflows/           # Workflow definitions
│   ├── scripts/             # Automation scripts
│   └── core/                # Core framework
├── project-sage/            # Your customizations
│   ├── config.yaml          # Project settings
│   ├── agents/              # Custom agents
│   └── workflows/           # Custom workflows
└── .claude/commands/        # Claude Code integration
```

## Attribution

SAGE Method is built on [BMAD Method](https://github.com/bmad-code-org/BMAD-METHOD) by BMad Code, LLC.

### From BMAD:
- Step-file workflow architecture
- Agent persona format and base personas
- XML workflow execution engine
- Party Mode concept
- Document sharding approach

### SAGE adds:
- Strict single-source truth chains (no inference variance)
- Stateless microagent architecture with "Tell Don't Ask" pattern
- Orchestration layer with checkpoint/resume
- Signal-based IPC for external integration
- Shell scripts for git/GitHub automation
- Multi-IDE wrapper generation
- Two-tier configuration system

## Documentation

- [Scripts Reference](sage/scripts/README.md)
- [Framework Index](sage/INDEX.md)

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
