# SAGE Enforcement Points

**Version:** 1.0
**Purpose:** Define validation rules enforced at artifact creation time

---

## Overview

SAGE enforces conventions at creation time, not as suggestions. This document defines the validation rules that are checked when creating stories, epics, branches, and other artifacts.

---

## Branch Naming

### Epic Branches

**Pattern:** `epic-{epic_id}`

**Examples:**
- ✅ `epic-001`
- ✅ `epic-authentication`
- ❌ `feature/epic-001` (wrong prefix)
- ❌ `Epic-001` (case sensitive)

**Validation:**
```yaml
branch_validation:
  pattern: "^epic-[a-z0-9-]+$"
  error: "Epic branch must match pattern: epic-{id}"
```

### Story Branches (Software Module)

**Pattern:** `feature/{story_id}`

**Examples:**
- ✅ `feature/001-1`
- ✅ `feature/user-auth`
- ❌ `001-1` (missing prefix)
- ❌ `story/001-1` (wrong prefix)

**Validation:**
```yaml
branch_validation:
  pattern: "^feature/[a-z0-9-]+$"
  error: "Story branch must match pattern: feature/{id}"
```

### Story Branches (Game Module)

**Pattern:** `{story_id}` (no prefix)

**Examples:**
- ✅ `ms-1-1`
- ✅ `combat-system`
- ❌ `feature/ms-1-1` (no prefix needed)

**Validation:**
```yaml
branch_validation:
  pattern: "^[a-z0-9-]+$"
  error: "Story branch must be lowercase alphanumeric with hyphens"
```

---

## File Location

### Epic Files

**Required Location:** `docs/epics/` or `docs/sprint-artifacts/epics/`

**Naming:** `{epic_id}.md` or `epic.md` in epic directory

**Validation:**
```yaml
file_validation:
  epic:
    paths:
      - "docs/epics/*.md"
      - "docs/sprint-artifacts/epics/*/epic.md"
    error: "Epic files must be in docs/epics/ or docs/sprint-artifacts/epics/{id}/"
```

### Story Files

**Required Location:** Same directory as parent epic or `stories/` subdirectory

**Naming:** `{story_id}.md`

**Validation:**
```yaml
file_validation:
  story:
    patterns:
      - "{epic_dir}/{story_id}.md"
      - "{epic_dir}/stories/{story_id}.md"
    error: "Story files must be in epic directory or stories/ subdirectory"
```

### State Files

**Required Location:** `state/` directory (workflow-specific)

**Naming:** `epic-{id}-state.json`

**Validation:**
```yaml
file_validation:
  state:
    path: "state/epic-*-state.json"
    gitignore: recommended
```

### Learning Files

**Required Location:** `docs/sprint-artifacts/learning/`

**Validation:**
```yaml
file_validation:
  learning:
    path: "docs/sprint-artifacts/learning/"
    patterns:
      - "epic-*-learnings.md"
      - "patterns.json"
      - "prevention-rules.md"
```

---

## Story Status

### Valid Statuses

| Status | Description | Allowed Transitions |
|--------|-------------|---------------------|
| `draft` | Initial creation | → `ready-for-review` |
| `ready-for-review` | Awaiting approval | → `ready-for-dev`, `draft` |
| `ready-for-dev` | Approved for implementation | → `in-progress` |
| `in-progress` | Being implemented | → `done`, `blocked` |
| `blocked` | Waiting on dependency | → `in-progress` |
| `done` | Completed | (terminal) |

**Validation:**
```yaml
status_validation:
  allowed: ["draft", "ready-for-review", "ready-for-dev", "in-progress", "blocked", "done"]
  transitions:
    draft: ["ready-for-review"]
    ready-for-review: ["ready-for-dev", "draft"]
    ready-for-dev: ["in-progress"]
    in-progress: ["done", "blocked"]
    blocked: ["in-progress"]
    done: []
```

---

## Commit Message Format

### Pattern

```
type(scope): description

[optional body]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code refactoring |
| `test` | Adding tests |
| `chore` | Maintenance |

**Validation:**
```yaml
commit_validation:
  pattern: "^(feat|fix|docs|refactor|test|chore)(\\([a-z-]+\\))?: .+"
  max_length: 72
```

---

## Enforcement Integration

### In Workflows

```xml
<step n="1" name="validate-branch">
  <action>
    enforcement:
      check: branch_name
      value: {{branch_name}}
      on_failure: error
  </action>
</step>
```

### In Agents

```xml
<agent-rule>
  Before creating any branch, validate against enforcement rules.
  If validation fails, inform user and request correction.
</agent-rule>
```

### Pre-commit Hook (Optional)

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate branch name
branch=$(git symbolic-ref --short HEAD)
if [[ ! $branch =~ ^(epic-|feature/|main|dev) ]]; then
  echo "Error: Invalid branch name: $branch"
  exit 1
fi
```

---

## Compliance Check Workflow

The `agentbuilder/workflow-compliance-check/` workflow validates:

1. Branch naming conventions
2. File location rules
3. Status transitions
4. Commit message format
5. Required fields in artifacts

Run with: `*compliance-check`
