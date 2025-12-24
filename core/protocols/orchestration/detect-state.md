# Protocol: Detect State

**Purpose**: Determine project state on assistant load to enable dynamic menu selection.

**JIT Loading**: Called by on-load-sequence.md before displaying menu.

---

## State Hierarchy

States are evaluated in order. First match wins.

```
┌─────────────────────────────────────────────────────────────┐
│ State Detection Flow                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. .sage/state/checkpoint.json exists AND valid?           │
│     YES → STATE: ACTIVE_CHECKPOINT                          │
│     NO  ↓                                                   │
│                                                             │
│  2. {sprint_artifacts}/epic-*/epic-context.yaml exists?     │
│     (any epic with SAGE context file)                       │
│     YES → STATE: HAS_SAGE_EPICS                             │
│     NO  ↓                                                   │
│                                                             │
│  3. {sprint_artifacts}/epic-* dirs exist (no context)?      │
│     OR docs with story-like patterns detected?              │
│     OR GitHub issues detected?                              │
│     YES → STATE: BROWNFIELD_DETECTED                        │
│     NO  ↓                                                   │
│                                                             │
│  4. project-sage/config.yaml exists?                        │
│     YES → STATE: SAGE_CONFIGURED                            │
│     NO  → STATE: UNCONFIGURED                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Execution Steps

### Step 1: Run Quick Scan

Load and execute `scan-project.md` with depth: `structure`

### Step 2: Evaluate Checkpoint State

```
IF scan_results.sage_state.has_checkpoint == true:
    Read .sage/state/checkpoint.json
    IF valid JSON with required fields (epic_id, status):
        RETURN state: ACTIVE_CHECKPOINT
        WITH checkpoint_summary: {
            epic_id: ...,
            story_id: ...,
            phase: ...,
            last_commit: ...
        }
```

### Step 3: Evaluate SAGE Epics

```
IF scan_results.epics.sage_epics.length > 0:
    RETURN state: HAS_SAGE_EPICS
    WITH epic_summary: {
        count: ...,
        epics: [{id, status, current_phase}],
        most_recent: ...
    }
```

### Step 4: Evaluate Brownfield Indicators

```
brownfield_indicators = []

IF scan_results.epics.orphan_epics.length > 0:
    brownfield_indicators.push("orphan_epic_dirs")

IF scan_results.work_tracking.method == "github_issues" AND issue_count > 0:
    brownfield_indicators.push("github_issues")

IF scan_results.documentation.notable_files contains PRD/spec patterns:
    brownfield_indicators.push("existing_docs")

IF scan_results.git.recent_branches contains feature/* or story/* patterns:
    brownfield_indicators.push("feature_branches")

IF brownfield_indicators.length > 0:
    RETURN state: BROWNFIELD_DETECTED
    WITH indicators: brownfield_indicators
    WITH details: {
        orphan_epics: [...],
        issue_count: ...,
        notable_docs: [...],
        feature_branches: [...]
    }
```

### Step 5: Evaluate Configuration

```
IF scan_results.sage_state.configured == true:
    RETURN state: SAGE_CONFIGURED
    WITH config: {
        project_name: ...,
        sprint_artifacts: ...
    }
ELSE:
    RETURN state: UNCONFIGURED
    WITH project_guess: {
        name: scan_results.project.name,
        name_source: scan_results.project.name_source
    }
```

---

## State Definitions

### ACTIVE_CHECKPOINT

**Meaning**: There is saved work that can be resumed.

**Context Provided**:
- Checkpoint details (epic, story, phase, task)
- Last commit hash
- Time since checkpoint

**Primary Action**: Continue from checkpoint

---

### HAS_SAGE_EPICS

**Meaning**: Project has SAGE-managed epics but no active checkpoint.

**Context Provided**:
- List of epics with status
- Most recently modified epic
- Overall progress

**Primary Action**: Select an epic to run

---

### BROWNFIELD_DETECTED

**Meaning**: Project has work artifacts not managed by SAGE.

**Context Provided**:
- What was detected (epic dirs, issues, docs, branches)
- Counts and locations
- No assumptions about what they mean

**Primary Action**: Import/adopt the project

---

### SAGE_CONFIGURED

**Meaning**: SAGE is set up but no work has been tracked yet.

**Context Provided**:
- Project configuration
- Ready for first epic

**Primary Action**: Start new epic

---

### UNCONFIGURED

**Meaning**: No SAGE configuration found.

**Context Provided**:
- Inferred project name (from package file or directory)
- What would need to be configured

**Primary Action**: Initialize SAGE

---

## Output Format

```yaml
detected_state:
  state: "ACTIVE_CHECKPOINT|HAS_SAGE_EPICS|BROWNFIELD_DETECTED|SAGE_CONFIGURED|UNCONFIGURED"
  timestamp: "{ISO8601}"

  # State-specific context (varies by state)
  context:
    # For ACTIVE_CHECKPOINT:
    checkpoint:
      epic_id: "..."
      story_id: "..."
      phase: "..."
      task_index: n
      last_commit: "..."
      age_minutes: n

    # For HAS_SAGE_EPICS:
    epics:
      count: n
      list: [{id, status, phase}]
      most_recent: "..."

    # For BROWNFIELD_DETECTED:
    indicators: ["orphan_epic_dirs", "github_issues", ...]
    details:
      orphan_epics: [...]
      issue_count: n
      notable_docs: [...]
      feature_branches: [...]

    # For SAGE_CONFIGURED:
    config:
      project_name: "..."
      sprint_artifacts: "..."

    # For UNCONFIGURED:
    project_guess:
      name: "..."
      source: "..."

  # Always included
  scan_summary:
    git_repo: true|false
    remote: "..." | null
    uncommitted_changes: n
```

---

## Menu Mapping

State detection feeds directly into dynamic menu selection:

| State | Menu Template |
|-------|--------------|
| ACTIVE_CHECKPOINT | menu-checkpoint.xml |
| HAS_SAGE_EPICS | menu-epics.xml |
| BROWNFIELD_DETECTED | menu-brownfield.xml |
| SAGE_CONFIGURED | menu-ready.xml |
| UNCONFIGURED | menu-init.xml |

See `assistant.md` for menu definitions.
