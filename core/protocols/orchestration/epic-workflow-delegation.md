# Epic Workflow Delegation Protocol

## Purpose
Delegate epic workflows (*create-epic, *run-epic) to the appropriate module based on project type.

## Prerequisites
- Project type must be detected (use project-type-detection.md first)

## Delegation Rules

### create-epic Delegation

```
project_type == "game":
  → sage/workflows/game/production/create-epic/workflow.yaml

project_type == "software":
  → sage/workflows/software/implementation/create-epic/workflow.yaml

project_type == "brownfield":
  → sage/workflows/core/epic/create-epic/workflow.yaml

project_type == null:
  → Run project-type-detection first
```

### run-epic Delegation

```
project_type == "game":
  → sage/workflows/game/production/run-epic-orchestrated/workflow.yaml

project_type == "software":
  → sage/workflows/software/implementation/run-epic/workflow.yaml

project_type == "brownfield":
  → Use software workflow with brownfield adaptations
```

## Execution Pattern

```xml
<step goal="Delegate to Module Workflow">
  <action>Detect project type</action>
  <action>Set {{workflow_path}} based on delegation rules</action>

  <output>
Project Type: {{project_type}}
Delegating to: {{workflow_path}}
  </output>

  <action>Execute workflow at {{workflow_path}}</action>
  <action>Pass through all user parameters</action>
</step>
```

## Error Handling

If module workflow doesn't exist:
1. Fall back to core/epic/ workflow
2. Log warning about missing module
3. Suggest creating module-specific workflow

## Module Extension Support

Module workflows can extend core workflows:

```yaml
# game/production/create-epic/workflow.yaml
extends: "core/epic/create-epic/workflow.yaml"

# Game-specific overrides
epic_definition_source: "{output_folder}/GDD.md"
story_workflow: "game/production/create-story/workflow.yaml"
```
