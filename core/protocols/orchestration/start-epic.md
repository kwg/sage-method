# Protocol: Start Epic

**Purpose**: Initialize a new epic from scratch, guiding through planning phases.

## Prerequisites

- No active checkpoint (or user confirms override)
- Project has `project-sage/config.yaml` configured

## Execution Steps

### Step 1: Epic Discovery

Ask user for epic type:
1. **Full SAGE Flow** - Analysis → Planning → Solutioning → Implementation
2. **Quick Flow** - Tech Spec → Implementation (solo dev)
3. **Custom** - Select specific phases

### Step 2: Initialize Epic Structure

```bash
mkdir -p {sprint_artifacts}/epic-{n}-{slug}/
```

Create `epic-context.yaml`:
```yaml
epic_id: "epic-{n}"
name: "{user_provided_name}"
created: "{date}"
flow_type: "{full|quick|custom}"
phases_enabled:
  - analysis
  - planning
  - solutioning
  - implementation
current_phase: "analysis"
status: "in-progress"
```

### Step 3: Create Git Branch

```bash
git checkout -b epic-{n}-{slug}
```

### Step 4: Write Initial Checkpoint

Save state to `.sage/state/checkpoint.json`

### Step 5: Launch First Phase Agent

Based on flow_type:
- **Full**: Spawn Analyst agent for product-brief
- **Quick**: Spawn Barry for tech-spec
- **Custom**: Show phase selection menu

## Outputs

- Epic directory created
- Git branch created
- Checkpoint saved
- First agent spawned

## TODO

- [ ] Implement GitHub milestone creation
- [ ] Add epic template selection
- [ ] Support resuming from partial epic
