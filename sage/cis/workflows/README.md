# CIS Workflows

Creative Intelligence System workflows for interactive facilitation of creative and strategic processes.

## Overview

These workflows guide users through structured creative and strategic thinking using proven frameworks and methodologies. Each workflow is designed for interactive facilitation, helping users think systematically while maintaining creative momentum.

## Available Workflows

| Workflow | Purpose | Agent |
|----------|---------|-------|
| [design-thinking](./design-thinking/) | Human-centered design through five phases | Creative Director |
| [innovation-strategy](./innovation-strategy/) | Business model innovation and disruption analysis | Innovation Strategist |
| [problem-solving](./problem-solving/) | Systematic root cause analysis and solution design | Knowledge Curator |
| [storytelling](./storytelling/) | Compelling narrative development using story frameworks | Storytelling Coach |

## Workflow Structure

Each workflow contains:

```
workflow-name/
├── README.md         # Documentation and usage
├── instructions.md   # Step-by-step facilitation guide
└── template.md       # Output document template
```

## Usage

### Via Agent Menu

```bash
# Activate the relevant research agent
/creative-director
> *design-thinking

/innovation-strategist
> *innovate

/knowledge-curator
> *solve

/storytelling-coach
> *story
```

### Direct Reference

Workflows can be referenced directly in agent configurations:

```xml
<item cmd="*design" exec="{project-root}/sage/cis/workflows/design-thinking/instructions.md">
  Design Thinking Session
</item>
```

## Common Features

All CIS workflows share:

- **Interactive Facilitation** - AI guides through questions, not generation
- **Framework-Based** - Proven methodologies and techniques
- **Energy Checkpoints** - Monitor user engagement and pace
- **Checkpoint Protocol** - Save progress after each template output
- **Structured Output** - Comprehensive reports with insights and actions

## Configuration

Workflows use variables from project configuration:

| Variable | Purpose | Source |
|----------|---------|--------|
| `{project-root}` | Project root path | project-sage/config.yaml |
| `{output_folder}` | Where outputs are saved | project-sage/config.yaml |
| `{user_name}` | Session participant | project-sage/config.yaml |
| `{communication_language}` | Facilitation language | project-sage/config.yaml |

## Integration

CIS workflows integrate with the SAGE agent system:

- Research agents in `sage/agents/research/` reference these workflows
- Output documents saved to `{output_folder}/` with date stamps
- Workflows follow SAGE checkpoint protocol for resumability

## Adding New Workflows

To add a new CIS workflow:

1. Create directory under `sage/cis/workflows/`
2. Add `README.md`, `instructions.md`, and `template.md`
3. Update parent README (this file)
4. Add menu item to relevant research agent

---

_Part of the SAGE Creative Intelligence System_
