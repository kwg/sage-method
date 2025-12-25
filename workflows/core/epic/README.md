# Core Epic Workflows

## Overview

The `core/epic/` workflows provide shared, module-agnostic logic for epic management across all SAGE project types (game, software, brownfield).

## Workflows

### create-epic
**Location:** `sage/workflows/core/epic/create-epic/`
**Version:** 2.0
**Purpose:** Automated epic setup with retrospective learning integration

**Features:**
- Retrospective review and learning extraction
- **State file reading** - Extracts `learning_records` and `retro_notes` from `.sage/state/epic-*-state.json`
- Dependency analysis and batching
- Story draft creation with context injection
- Story context generation
- Epic kickoff summary

**EPIC-002 Integration:**
- `state-manager.md` - State persistence
- `metrics-collector.md` - Creation metrics
- `learning-recorder.md` - Pattern extraction

### run-epic
**Location:** `sage/workflows/core/epic/run-epic/`
**Status:** Planned (not yet implemented)
**Purpose:** Core epic execution orchestrator

### epic-complete
**Location:** `sage/workflows/core/epic/epic-complete/`
**Version:** 1.0
**Purpose:** Epic completion with structure validation

**Features:**
- State file validation
- Metrics aggregation
- **Structure alignment check** - Compares project structure with SAGE patterns
- **Brownfield conversion prompt** - Offers to upgrade structure (opt-in)

## Module Extension Pattern

Core workflows are designed to be extended by module-specific workflows.

### Extension Mechanism

**Game Module Example:**

```yaml
# game/production/create-epic/workflow.yaml
extends: "core/epic/create-epic"

# Override extension points
module_extensions:
  epic_definition_source: "GDD.md"
  story_workflow: "game/production/create-story/workflow.yaml"
  context_workflow: "game/production/story-context/workflow.yaml"
  pattern_matching:
    godot_patterns:
      - "signal", "async" → "P4, P5"
      - "scene", "node" → "Godot scene patterns"
  validation_hooks:
    post_story_creation:
      - "Validate Godot scene references"
```

**Software Module Example:**

```yaml
# software/implementation/create-epic/workflow.yaml
extends: "core/epic/create-epic"

# Override extension points
module_extensions:
  epic_definition_source: "epics.md"
  story_workflow: "software/implementation/create-story/workflow.yaml"
  pattern_matching:
    build_patterns:
      - "test", "ci" → "Test automation patterns"
      - "deploy" → "Deployment patterns"
  validation_hooks:
    post_story_creation:
      - "Validate build system integration"
```

### Extension Points

Core workflows define these extension points:

| Extension Point | Purpose | Example Override |
|----------------|---------|------------------|
| `epic_definition_source` | Where to find epic definitions | "GDD.md" (game) vs "epics.md" (software) |
| `story_workflow` | Which create-story workflow to use | Module-specific story creation |
| `context_workflow` | Which story-context workflow to use | Module-specific context generation |
| `pattern_matching` | Module-specific pattern detection | Godot patterns vs build patterns |
| `validation_hooks` | Post-creation validations | Scene validation vs test integration |

### Inheritance

Module workflows **inherit** from core:

**Inherited Features:**
- State file reading (`learning_records`, `retro_notes`)
- EPIC-002 core components
- Dependency analysis logic
- Batching algorithm
- Tell Don't Ask principles
- Error handling patterns

**Module-Specific Additions:**
- Epic source location (GDD vs PRD)
- Pattern matching rules
- Validation hooks
- Subagent selection

### Usage Pattern

1. **Direct core usage** (for brownfield or generic projects):
   ```
   Execute: sage/workflows/core/epic/create-epic/workflow.yaml
   ```

2. **Module extension** (for game/software projects):
   ```
   Execute: sage/workflows/game/production/create-epic/workflow.yaml
   (which extends core and adds game-specific features)
   ```

3. **Assistant delegation** (automatic):
   ```
   User: *create-epic
   Assistant: Detects project_type → Delegates to appropriate module
   ```

## State File Schema

All epic workflows use the same state file schema:

```json
{
  "workflow_name": "create-epic",
  "epic_id": "epic-8",
  "learning_records": [
    {
      "source": "epic-7-retro",
      "type": "pattern",
      "description": "Always use async null guards",
      "applied_to_stories": ["story-8-1", "story-8-3"]
    }
  ],
  "retro_notes": {
    "retrospectives_reviewed": ["epic-7-retro.md"],
    "state_files_reviewed": ["epic-7-state.json"],
    "applicable_patterns": ["P4", "P5", "P6"]
  }
}
```

## Assistant Integration

The assistant agent can delegate epic workflows:

**Menu Items (from `sage/agents/core/assistant.md`):**
- `*create-epic` → Detects project type, delegates to module
- `*run-epic` → Detects project type, delegates to module
- `*epic-status` → Reads `.sage/state/epic-*-state.json`
- `*epic-complete` → Runs core/epic/epic-complete

**Delegation Protocol:**
1. Check `project-sage/config.yaml` for `project_type`
2. If not set, detect from files (`project.godot`, `package.json`, etc.)
3. Delegate to appropriate module workflow
4. Fall back to core if module doesn't exist

## Directory Structure

```
sage/workflows/core/epic/
├── create-epic/
│   ├── workflow.yaml          # Core workflow definition (v2.0)
│   ├── instructions.md        # Shared instructions with state file reading
│   ├── state-schema.json      # State file schema
│   └── templates/
│       ├── briefing-template.md
│       └── story-template.md
├── run-epic/
│   ├── workflow.yaml          # (Planned)
│   └── orchestrator.md
├── epic-complete/
│   ├── workflow.yaml          # Completion workflow (v1.0)
│   └── instructions.md        # With brownfield conversion prompt
└── README.md                  # This file
```

## Version History

### v2.0 (2024-12-24) - Story 2-2

**Major Changes:**
- Created core/epic/ structure
- Extracted shared logic from game/create-epic
- Added state file reading (learning_records, retro_notes)
- Integrated EPIC-002 core components
- Defined module extension pattern
- Added assistant agent integration
- Created epic-complete with brownfield conversion

**Breaking Changes:**
- None (core is new, modules extend without breaking)

**Migration:**
- Game module updated to extend core (v1.0 → v2.0)
- Software module should extend core (TODO)

## Related Documentation

- **State Management:** `sage/core/components/state-manager.md`
- **Learning Records:** `sage/core/components/learning-recorder.md`
- **Metrics:** `sage/core/components/metrics-collector.md`
- **Assistant Protocols:** `sage/core/protocols/orchestration/`

## Future Enhancements

1. **run-epic core workflow** - Extract shared orchestration logic
2. **Software module extension** - Create software/implementation/create-epic extending core
3. **Brownfield conversion automation** - Automated structure migration scripts
4. **State file migration tool** - Convert v1.0 epics to v2.0 with state files
