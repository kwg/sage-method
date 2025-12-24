# Project Workflow Customizations

**Purpose**: Track customizations made to SAGE workflows so they can be re-applied after SAGE updates.
**Last Updated**: 2025-12-09

---

## Why This File Exists

When SAGE is updated, the workflows in `sage/workflows/software/` may need to be re-synced from upstream. This file documents project-specific customizations that must be preserved or re-applied.

**After SAGE update**: Run `*workflow-sync` then manually check each customization below.

---

## Customizations by Workflow

### `implementation/code-review/checklist.md`

**Source**: Merged from `sage/reference/code-review-checklist.md` (deleted 2025-12-09)

| Addition | Description |
|----------|-------------|
| Pre-Review Checks section | Organized existing checks with headers |
| Code Quality Checks | No debug code, no TODOs, naming conventions, error handling |
| Test & Coverage Checks | Coverage ≥80%, no skipped tests |
| PR Format | `[STORY-ID] Short description` pattern |
| Review Feedback Format | `[MUST]`, `[SHOULD]`, `[COULD]`, `[QUESTION]` severity tags |

---

### `implementation/dev-story/checklist.md`

**Source**: Merged from `sage/reference/testing-requirements.md` (deleted 2025-12-09)

| Addition | Description |
|----------|-------------|
| Coverage Threshold | ≥80% line, ≥75% branch, ≥90% for critical code |
| Test Naming Convention | `test_<function>_should_<behavior>_when_<condition>` |
| AAA Pattern | Arrange/Act/Assert test structure with example |

---

### `implementation/create-story/checklist.md`

**Source**: Originally from `sage/reference/story-validation-guide.md` (deleted 2025-12-09)

| NOT Added (already covered) | Where Covered |
|----------------------------|---------------|
| Story format validation | Already comprehensive in checklist.md |
| Sizing rules (5-13 pts) | In archived SOP-06001 (not critical for LLM dev) |
| Status flow | In sprint-planning workflow |

---

## Overlays (Not Workflows)

These are in `sage/agents/overlays/` and regenerated via merge script, not synced from SAGE:

### `dev-overlay.md`

**Source**: Merged from `sage/reference/story-execution-guide.md` (deleted 2025-12-09)

| Baked Rule | Location |
|------------|----------|
| Git branch pattern | Activation step 16: `{story-key} from origin/dev` |
| NixOS command prefix | Activation step 15: `nix develop --command {cmd}` |

---

## Re-Application Procedure

After SAGE update:

1. **Run**: `*workflow-sync` to see upstream changes
2. **Compare**: Each workflow against this file's customizations
3. **Re-apply**: Any customizations that were overwritten
4. **Update**: This file if new customizations are added

---

## Files Merged Into Workflows (Historical Reference)

| Deleted Reference File | Merged Into | Date |
|------------------------|-------------|------|
| `story-validation-guide.md` | `create-story/checklist.md` | 2025-12-09 |
| `code-review-checklist.md` | `code-review/checklist.md` | 2025-12-09 |
| `testing-requirements.md` | `dev-story/checklist.md` | 2025-12-09 |
| `story-execution-guide.md` | `dev-overlay.md` (already baked) | 2025-12-09 |

---

## Human Guides (Moved to `docs/`)

These are human-readable guides, not agent rules:

| File | Location | Purpose |
|------|----------|----------|
| `sage-update-guide.md` | `docs/` | SAGE update procedure |
| `workflow-migration-guide.md` | `docs/` | Workflow sync procedure |
| `documentation-standards.md` | `docs/` | Doc quality guidelines |

> `sage/reference/` directory removed - all content merged into workflows or moved to `docs/`.
