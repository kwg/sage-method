# SOP Index

**Updated**: 2025-12-19
**Architecture**: Standalone SAGE Agents with Wrapper Pattern
**Submodule**: This directory (`sage/`) can be used as a git submodule in your projects

---

## Chain of Truth

SAGE follows a strict single-source architecture where each layer inherits from exactly one source:

```
config.yaml (sage/core/config.yaml - THE ONLY CONFIG)
    ↓
SOP-00001-activation.md (universal activation rules)
    ↓
Agent files (thin shells: persona + menu)
    ↓
Workflows (orchestrators pointing to steps)
    ↓
Step files (micro-worksteps with injected context)
    ↓
Outputs (artifacts with traced lineage)
```

### Core Principles

1. **Single Config Source**: All workflows load from `{project-root}/sage/core/config.yaml`
2. **Tell Don't Ask**: Agents receive injected context, never discover/search
3. **Micro-Worksteps**: Workflows decompose into small, focused step files
4. **Thin Shells**: Agents contain only persona + menu (target: <50 lines)
5. **Explicit Paths**: All references are explicit, no magic discovery

---

## Architecture Overview

SAGE is a **fully standalone agent framework** - no runtime dependency on `.sage/`.

### Directory Structure

```
sage/
├── agents/                    # STANDALONE Agent Definitions (SOURCE OF TRUTH)
│   ├── VERSION.yaml           # Agent version tracking (SAGE sync status)
│   ├── software/              # Software development agents
│   │   ├── analyst.md
│   │   ├── architect.md
│   │   ├── dev.md
│   │   ├── pm.md
│   │   ├── quick-flow-solo-dev.md
│   │   ├── sm.md
│   │   ├── tea.md
│   │   ├── tech-writer.md
│   │   └── ux-designer.md
│   ├── game/                  # Game development agents
│   │   ├── game-architect.md
│   │   ├── game-designer.md
│   │   ├── game-dev.md
│   │   ├── game-scrum-master.md
│   │   ├── game-solo-dev.md
│   │   ├── game-uiux.md
│   │   ├── game-qa-architect.md
│   │   └── qa-tester.md
│   ├── agentbuilder/          # Agent/workflow creation
│   │   └── sage-builder.md
│   ├── research/              # Creative & research innovation
│   │   ├── brainstorming-coach.md
│   │   ├── creative-problem-solver.md
│   │   ├── design-thinking-coach.md
│   │   ├── innovation-strategist.md
│   │   ├── presentation-master.md
│   │   └── storyteller.md
│   ├── core/                  # Universal agents
│   │   ├── sage-master.md
│   │   ├── devops.md
│   │   └── it.md
│   └── wrappers/              # IDE Wrapper Agents
│       ├── github/            # GitHub Copilot wrappers
│       └── claude/            # Claude Code wrappers
├── core/                      # Core infrastructure
│   ├── config.yaml            # Project config
│   ├── SOP-00001-activation.md # Universal activation rules
│   ├── components/            # Reusable orchestration components (EPIC-002)
│   │   ├── state-manager.md
│   │   ├── retry-handler.md
│   │   ├── metrics-collector.md
│   │   ├── learning-recorder.md
│   │   ├── subagent-spawner.md
│   │   └── orchestrator-base.md
│   ├── enforcement/           # Validation rules (EPIC-002)
│   │   ├── branch-rules.yaml
│   │   ├── file-location-rules.yaml
│   │   └── status-rules.yaml
│   ├── workflows/             # Core workflows
│   │   ├── party-mode/
│   │   ├── brainstorming/
│   │   └── epic-validation/   # Phase 4 validation (EPIC-002)
│   └── tasks/                 # Core tasks (workflow.xml)
├── data/                      # Data files
│   ├── documentation-standards.md
│   ├── agent-manifest.csv
│   ├── workflow-manifest.csv
│   └── task-manifest.csv
├── testarch/                  # TEA knowledge base
├── workflows/                 # Executable workflows
│   ├── software/              # Software methodology (Phase 1-4)
│   │   ├── 1-analysis/        # Phase 1: research, product-brief
│   │   ├── 2-plan-workflows/  # Phase 2: prd, ux-design
│   │   ├── 3-solutioning/     # Phase 2b: architecture, epics
│   │   └── implementation/    # Phase 3: sprint-planning, run-epic
│   │       └── run-epic/      # Orchestrated epic execution (EPIC-002)
│   ├── game/                  # Game development workflows
│   │   └── production/
│   │       └── run-epic-orchestrated/  # Game orchestrator (EPIC-002)
│   ├── agentbuilder/          # Agent/workflow creation
│   ├── it/                    # IT-specific workflows
│   └── protocols/             # Shared protocols
├── _shared/                   # Shared resources (EPIC-002)
│   └── personas/              # Modular persona fragments
│       ├── tdd-practitioner.md
│       ├── data-driven.md
│       ├── user-focused.md
│       ├── precision-communicator.md
│       ├── creative-storyteller.md
│       └── systematic-thinker.md
├── scripts/                   # Maintenance scripts
└── _templates/                # SOP templates
```

---

## SAGE Module Naming

SAGE uses descriptive module names distinct from upstream SAGE:

| SAGE Module | SAGE Source | Description |
|-------------|-------------|-------------|
| `software` | upstream-software | Software development methodology |
| `game` | bmgd | Game development |
| `agentbuilder` | bmb | Agent/workflow/module creation |
| `research` | cis | Creative & research innovation |
| `core` | - | Universal agents and infrastructure |

---

## Agent Architecture

### Standalone Agents (`sage/agents/`)

Full agent definitions with all rules and behaviors. Agents are organized by module.

#### Software Module (`sage/agents/software/`)

| Agent | File | Description |
|-------|------|-------------|
| Analyst | `software/analyst.md` | Business analysis, research, product briefs |
| Architect | `software/architect.md` | System design and architecture |
| Developer | `software/dev.md` | Story implementation with NixOS/git rules |
| PM | `software/pm.md` | Product management and planning |
| Quick Flow Solo Dev | `software/quick-flow-solo-dev.md` | Rapid development mode |
| Scrum Master | `software/sm.md` | Sprint management and validation |
| TEA | `software/tea.md` | Technical excellence advisor |
| Tech Writer | `software/tech-writer.md` | Documentation maintenance |
| UX Designer | `software/ux-designer.md` | User experience design |

#### Game Module (`sage/agents/game/`)

| Agent | File | Description |
|-------|------|-------------|
| Game Architect | `game/game-architect.md` | Game system architecture |
| Game Designer | `game/game-designer.md` | Game design and mechanics |
| Game Dev | `game/game-dev.md` | Game implementation |
| Game Scrum Master | `game/game-scrum-master.md` | Game sprint management |
| Game Solo Dev | `game/game-solo-dev.md` | Indie game development |
| Game UI/UX | `game/game-uiux.md` | Game interface design |
| Game QA Architect | `game/game-qa-architect.md` | Game testing architecture |
| QA Tester | `game/qa-tester.md` | Game testing execution |

#### AgentBuilder Module (`sage/agents/agentbuilder/`)

| Agent | File | Description |
|-------|------|-------------|
| Builder | `agentbuilder/sage-builder.md` | Agent/workflow/module creation |

#### Research Module (`sage/agents/research/`)

| Agent | File | Description |
|-------|------|-------------|
| Brainstorming Coach | `research/brainstorming-coach.md` | Facilitated ideation |
| Creative Problem Solver | `research/creative-problem-solver.md` | Creative solutions |
| Design Thinking Coach | `research/design-thinking-coach.md` | Design thinking methodology |
| Innovation Strategist | `research/innovation-strategist.md` | Innovation strategy |
| Presentation Master | `research/presentation-master.md` | Presentation design |
| Storyteller | `research/storyteller.md` | Narrative development |

#### Core Module (`sage/agents/core/`)

Universal agents available across all contexts:

| Agent | File | Description |
|-------|------|-------------|
| SAGE Master | `core/sage-master.md` | Framework orchestration |
| DevOps | `core/devops.md` | Infrastructure and deployment |
| IT Support | `core/it.md` | NixOS configuration management |

### Wrapper Agents

Lightweight wrappers that load standalone agents at runtime.

#### Naming Convention

| Category | Description | Examples |
|----------|-------------|----------|
| `software-*` | Software development agents | `software-dev`, `software-architect` |
| `game-*` | Game development agents | `game-dev`, `game-designer` |
| `cis-*` | Research/creative agents | `cis-storyteller`, `cis-brainstorming-coach` |
| `agentdev-*` | Agent development tools | `agentdev-sage-builder` |

---

## Workflow Reference

### Software Module (`sage/workflows/software/`)

#### Phase 1: Analysis

| Workflow | Path | Description | Agent |
|----------|------|-------------|-------|
| Research | `software/1-analysis/research/` | Market, domain, competitive research | Analyst |
| Product Brief | `software/1-analysis/product-brief/` | Create product brief | Analyst |

#### Phase 2: Planning

| Workflow | Path | Description | Agent |
|----------|------|-------------|-------|
| PRD | `software/2-plan-workflows/prd/` | Product Requirements Document | PM |
| UX Design | `software/2-plan-workflows/create-ux-design/` | UX Design and UI Plan | UX Designer |

#### Phase 3: Solutioning

| Workflow | Path | Description | Agent |
|----------|------|-------------|-------|
| Architecture | `software/3-solutioning/architecture/` | Architecture document | Architect |
| Epics & Stories | `software/3-solutioning/create-epics-and-stories/` | Epics and user stories | PM |
| Implementation Readiness | `software/3-solutioning/implementation-readiness/` | Alignment validation | Architect, PM |

#### Phase 4: Implementation

| Workflow | Path | Description | Agent |
|----------|------|-------------|-------|
| Sprint Planning | `software/implementation/sprint-planning/` | Generate sprint-status.yaml | SM |
| Create Story | `software/implementation/create-story/` | Create draft story | SM |
| Develop Story | `software/implementation/dev-story/` | Execute dev story workflow | Dev |
| Code Review | `software/implementation/code-review/` | Code review | Dev |
| Correct Course | `software/implementation/correct-course/` | Course correction | PM, SM |
| Retrospective | `software/implementation/retrospective/` | Sprint retrospective | SM |

### Game Module (`sage/workflows/game/`)

| Workflow | Path | Description |
|----------|------|-------------|
| Brainstorm Game | `game/preproduction/brainstorm-game/` | Game concept ideation |
| Game Brief | `game/preproduction/game-brief/` | Game concept document |
| GDD | `game/design/gdd/` | Game Design Document |
| Narrative | `game/design/narrative/` | Story and narrative design |
| Game Architecture | `game/technical/game-architecture/` | Technical architecture |
| Create Epic | `game/production/create-epic/` | Epic creation |
| Sprint Planning | `game/production/sprint-planning/` | Sprint planning |
| Dev Story | `game/production/dev-story/` | Story development |
| Code Review | `game/production/code-review/` | Code review |
| Retrospective | `game/production/retrospective/` | Sprint retrospective |

### AgentBuilder Module (`sage/workflows/agentbuilder/`)

| Workflow | Path | Description |
|----------|------|-------------|
| Create Agent | `agentbuilder/create-agent/` | Create new agent |
| Edit Agent | `agentbuilder/edit-agent/` | Modify existing agent |
| Create Workflow | `agentbuilder/create-workflow/` | Create new workflow |
| Edit Workflow | `agentbuilder/edit-workflow/` | Modify existing workflow |
| Create Module | `agentbuilder/create-module/` | Create new module |
| Compliance Check | `agentbuilder/workflow-compliance-check/` | Validate workflow compliance |

### Core Workflows (`sage/core/workflows/`)

| Workflow | Path | Description |
|----------|------|-------------|
| Party Mode | `core/workflows/party-mode/` | Multi-agent collaboration |
| Brainstorming | `core/workflows/brainstorming/` | Guided brainstorming |
| Epic Validation | `core/workflows/epic-validation/` | Phase 4 human approval gate |

### Orchestrated Workflows (EPIC-002)

| Workflow | Path | Description |
|----------|------|-------------|
| Run Epic (Software) | `software/implementation/run-epic/` | 9-phase epic orchestrator with TDD |
| Run Epic (Game) | `game/production/run-epic-orchestrated/` | 8-phase game epic orchestrator |

---

## Core Components (EPIC-002)

Reusable components for building orchestrated workflows. See `sage/core/components/README.md`.

| Component | Purpose |
|-----------|---------|
| state-manager | Persistent JSON state with read/write/merge |
| retry-handler | Retry with escalation and cascade detection |
| metrics-collector | Timing, tokens, and counts per story/epic |
| learning-recorder | Failure patterns for self-improvement |
| subagent-spawner | Bounded subagents (PLANNER, IMPLEMENTER, etc.) |
| orchestrator-base | Base pattern for domain orchestrators |

---

## Enforcement Rules (EPIC-002)

Validation rules enforced at artifact creation time. See `sage/core/enforcement/README.md`.

| Rule Set | Purpose |
|----------|---------|
| branch-rules.yaml | Epic: `epic-{id}`, Software: `feature/{id}`, Game: `{id}` |
| file-location-rules.yaml | Required paths for epics, stories, state, learning |
| status-rules.yaml | Valid statuses and transitions for stories/epics |

---

## Modular Personas (EPIC-002)

Reusable persona fragments for agent composition. See `sage/_shared/personas/README.md`.

| Fragment | Applicable Roles |
|----------|------------------|
| tdd-practitioner | dev, game-dev, qa-tester |
| data-driven | analyst, architect, pm |
| user-focused | ux-designer, pm, game-uiux |
| precision-communicator | architect, tech-writer, devops |
| creative-storyteller | game-designer, storyteller, brainstorming-coach |
| systematic-thinker | sm, architect, qa-tester |

---

## Maintenance

### Editing Agent Behavior

Agents are standalone - edit directly:

```bash
vim sage/agents/software/dev.md
# Changes take effect immediately
```

### SAGE Agent Sync

Compare SAGE agents against upstream SAGE:

```bash
# Compile SAGE agents to /tmp for comparison
nix develop --command ./sage/scripts/compile-sage-agent.sh --all

# Compare a specific agent (SAGE uses bmm, SAGE uses software)
diff sage/agents/software/dev.md /tmp/sage-compiled/bmm/dev.md

# Check VERSION.yaml for sync status
cat sage/agents/VERSION.yaml
```

### Syncing Wrappers

```bash
# Sync to GitHub Copilot
./sage/scripts/sync-github-agents.sh

# Sync to Claude Code
./sage/scripts/sync-claude-agents.sh
```

---

## Submodule Workflow

**Commits require two steps**:
```bash
# 1. Commit in sage submodule
cd sage && git add -A && git commit -m "message" && git push origin sage-framework-dev

# 2. Update parent repo's submodule pointer
cd .. && git add sage && git commit -m "chore: update sage submodule" && git push
```
