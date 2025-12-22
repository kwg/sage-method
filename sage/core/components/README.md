# SAGE Core Components

**Version:** 1.0
**Purpose:** Reusable components for building orchestrated workflows

---

## Overview

Core components provide standardized interfaces for common workflow operations. They are designed to be:

- **Injection-friendly**: Accept configuration, return structured output
- **Domain-agnostic**: Work across software, game, research modules
- **Testable**: Each component can be validated independently
- **Composable**: Components work together seamlessly

---

## Available Components

| Component | Purpose | Key Features |
|-----------|---------|--------------|
| [state-manager.md](./state-manager.md) | Persistent JSON state | Read, write, merge, resume |
| [retry-handler.md](./retry-handler.md) | Retry with escalation | Configurable limits, cascade detection |
| [metrics-collector.md](./metrics-collector.md) | Timing & counts | Per-story, per-epic aggregation |
| [learning-recorder.md](./learning-recorder.md) | Failure patterns | Classification, prevention rules |
| [subagent-spawner.md](./subagent-spawner.md) | Bounded subagents | PLANNER, IMPLEMENTER, REVIEWER, etc. |
| [orchestrator-base.md](./orchestrator-base.md) | Base pattern | Phase loop, state cycle, hooks |

---

## Component Interaction

```
┌─────────────────────────────────────────────────────────────────┐
│                     ORCHESTRATOR (domain-specific)               │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │ Phase 01     │───▶│ Phase 02     │───▶│ Phase 03     │──...  │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│         │                   │                   │                │
└─────────┼───────────────────┼───────────────────┼────────────────┘
          │                   │                   │
          ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CORE COMPONENTS                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ state-manager│  │ retry-handler│  │ metrics-     │           │
│  │              │  │              │  │ collector    │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │ learning-    │  │ subagent-    │                              │
│  │ recorder     │  │ spawner      │                              │
│  └──────────────┘  └──────────────┘                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Usage Pattern

Components are invoked via structured interfaces within phase files:

```xml
<step n="1" name="read-state">
  <action>
    state_manager:
      action: read
      state_file: "state/{{workflow_id}}-state.json"
  </action>
</step>

<step n="2" name="spawn-planner">
  <action>
    subagent_spawner:
      action: spawn
      subagent_type: "PLANNER"
      context: {{bounded_context}}
  </action>
</step>

<step n="3" name="run-with-retry">
  <action>
    retry_handler:
      operation: "test"
      max_retries: 3
      on_failure: "learning-recorder"
  </action>
</step>
```

---

## Default Values

| Setting | Default | Notes |
|---------|---------|-------|
| State file location | `state/{workflow_id}-state.json` | Relative to workflow |
| Test retries | 3 | Spawns FIX subagent between |
| Review retries | 2 | Allows iteration on feedback |
| Build retries | 1 | Usually deterministic |
| Subagent context limit | ~4KB | Bounded for efficiency |
| Cascade threshold | 3 failures in 5 items | Triggers pause |

---

## Extension

To create custom components:

1. Follow the interface pattern (YAML input, JSON output)
2. Document in this directory
3. Add to component index
4. Update orchestrator-base if needed

---

## Integration with Lifecycle

Components map to lifecycle phases:

| Lifecycle Phase | Primary Components |
|-----------------|-------------------|
| Design (Phase 1) | state-manager |
| Plan (Phase 2) | state-manager, subagent-spawner (PLANNER) |
| Build (Phase 3) | All components |
| Validate (Phase 4) | metrics-collector, learning-recorder |
