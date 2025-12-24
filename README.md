# SAGE Method

**Stateless Agent Guidance Engine** - A framework for building LLM-powered development agents that follow instructions rather than improvising.

## What is SAGE?

SAGE is a stateless microagent architecture for building reliable, reproducible LLM workflows.

### Core Architecture

**Stateless Microagents** - Agents are thin shells (~50 lines) containing only persona and menu. No memory between sessions. All context is explicitly injected at runtime.

**Decomposed Workflows** - Complex tasks break into micro-worksteps: small, focused step files with clear inputs, outputs, and completion criteria. No monolithic prompts.

**Orchestrator Pattern** - A central orchestrator spawns specialized subagents, manages checkpoints for resume, handles retries with escalation, and coordinates multi-phase workflows.

**Single Source of Truth** - Strict inheritance chains where each layer has exactly one source. Context flows down explicitly - agents never "discover" information. This eliminates variance from LLMs making different decisions on different runs.

```
config.yaml
    ↓
SOP-00001-activation.md (universal rules)
    ↓
Agent file (thin shell: persona + menu)
    ↓
Workflow (orchestrator pointing to steps)
    ↓
Step files (micro-worksteps with injected context)
    ↓
Outputs (artifacts with traced lineage)
```

**Tell Don't Ask** - Agents receive instructions, not questions. The LLM executes predefined workflows rather than deciding what to do.

## Quick Start

### Prerequisites

- Claude Code, GitHub Copilot Chat, or compatible LLM-powered IDE
- Git

### Installation

```bash
# Add to your project as 'sage' folder
git clone https://github.com/kwg/sage-method.git sage

# Run setup
./sage/scripts/setup.sh --user "Your Name"
```

Or as a submodule:
```bash
git submodule add https://github.com/kwg/sage-method.git sage
./sage/scripts/setup.sh --user "Your Name"
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

- `core/config.yaml` - Framework defaults (in sage/)
- `project-sage/config.yaml` - Your project overrides (created by setup.sh)

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

- [Scripts Reference](scripts/README.md)
- [Framework Index](INDEX.md)

## License

MIT License - see [LICENSE](LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
