# SOP-00009: Git Branch Workflow for Story Development

**Type**: Workflow SOP | **Status**: Active | **Applies To**: Developer, Scrum Master, Code Review

---

## Purpose

Defines the **branch-first development workflow** ensuring all story development happens on the correct feature branch.

---

## Branch Naming Conventions

### Drafting Branch (Story Creation)
Pattern: `{epic}-0-story-creation`

Used by `create-story` workflow for drafting all stories in an epic.

### Implementation Branch (Development)
Pattern: `{epic}-{story}-{slug}`

Used by `dev-story` workflow for implementing a specific story.

**Examples**: `3-3-state-recovery-via-log-replay`, `1-5-test-runner-integration`

---

## Folder Structure

```
sprint-artifacts/
├── epic-{m}/
│   └── sprint-{x}/
│       └── {epic}-{story}-{slug}.md
```

---

## Workflow Integration

### Create-Story (Step 1.5)
1. Calls `ensure_drafting_branch` protocol
2. Calls `determine_story_output_path` protocol
3. Commits story draft via `commit_story_draft` protocol

### Dev-Story (Step 0)
1. Calls `ensure_implementation_branch` protocol
2. Creates branch from `origin/dev` if needed

### Code-Review (Step 1)
1. Extract story ID from file
2. Verify current branch matches story ID pattern
3. If mismatch: HALT and present options

---

## Protected Branches

- `main` - Production (no direct push)
- `dev` - Integration (no direct push)

All work via feature branches + Pull Request.

---

## Error Recovery

| Error | Resolution |
|-------|------------|
| Branch not found | Run create-story or: `git checkout -b {story_key} origin/dev` |
| Uncommitted changes | `git stash`, switch branch, `git stash pop` |
| Branch mismatch | Switch to correct branch or review matching story |

---

## Protocol Files

- `sage/workflows/protocols/git-branch-protocol.xml` - Branch management
- `sage/workflows/protocols/sprint-status-protocol.xml` - Story path resolution
