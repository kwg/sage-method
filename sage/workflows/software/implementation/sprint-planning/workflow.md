# Sprint Planning Workflow

**Goal:** Generate and manage the sprint status tracking file, extracting all epics and stories from epic files and tracking their status through the development lifecycle.

**Your Role:** You are the Scrum Master (SM) facilitator. This is a standalone workflow that operates independently to generate accurate sprint status tracking.

---

## WORKFLOW ARCHITECTURE

This uses **step-file architecture** for disciplined execution:

### Core Principles

- **Micro-file Design**: Each step is a self-contained instruction file
- **Just-In-Time Loading**: Only the current step file is in memory
- **Sequential Enforcement**: Steps must be completed in order
- **State Tracking**: Document progress in state file
- **Full Load Strategy**: Unlike other Phase 2 workflows, this loads ALL epics at once

### Step Processing Rules

1. **READ COMPLETELY**: Always read the entire step file before taking any action
2. **FOLLOW SEQUENCE**: Execute all numbered sections in order
3. **WAIT FOR INPUT**: Halt at menus and wait for user selection
4. **SAVE STATE**: Update state before loading next step
5. **LOAD NEXT**: When directed, load and execute the next step file

### Critical Rules (NO EXCEPTIONS)

- NEVER load multiple step files simultaneously
- ALWAYS read entire step file before execution
- NEVER skip steps or optimize the sequence
- ALWAYS update state when completing a step
- ALWAYS follow the exact instructions in the step file

---

## INITIALIZATION SEQUENCE

### 1. Configuration Loading

Load config from `{project-root}/sage/core/config.yaml` and resolve:

- `project_name`, `output_folder`, `user_name`
- `communication_language`, `sprint_artifacts`
- `date` as system-generated current datetime

### 2. State Initialization

Initialize workflow state (JSON file or memory):

```json
{
  "workflow": "sprint-planning",
  "started": "{date}",
  "current_step": 1,
  "completed_steps": [],
  "epics_found": 0,
  "stories_found": 0
}
```

### 3. First Step Execution

Load, read the full file and then execute `steps/step-01-discover.md` to begin the workflow.

---

## STEP REFERENCE

| Step | Name | Purpose |
|------|------|---------|
| 01 | Discover | Load all epic files using FULL_LOAD strategy |
| 02 | Parse | Extract epics, stories, retrospectives from content |
| 03 | Detect | Apply intelligent status detection from existing files |
| 04 | Generate | Create/update sprint-status.yaml file |
| 05 | Validate | Verify completeness and report summary |
