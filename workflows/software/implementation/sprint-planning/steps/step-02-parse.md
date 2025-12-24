# Step 02: Parse Epic Content

**Goal:** Extract epics, stories, and retrospectives from discovered files.

---

## EMBEDDED RULES

- Parse each epic file completely before moving to next
- Extract in order: epic header, then stories, then create retrospective entry
- Convert story IDs to kebab-case format for keys

---

## ACTIONS

### 1. Parse Each Epic File

For each file in `{files_discovered}`, extract:

**Epic Detection:**
- Headers like `## Epic 1:` or `## Epic 2:`
- Extract epic number and title

**Story Detection:**
- Patterns like `### Story 1.1: User Authentication`
- Extract story number (e.g., 1.1) and title

### 2. Story ID Conversion

Convert story format from `Epic.Story: Title` to kebab-case key:

| Original | Converted |
|----------|-----------|
| `### Story 1.1: User Authentication` | `1-1-user-authentication` |
| `### Story 2.3: Data Export` | `2-3-data-export` |

**Rules:**
- Replace period with dash: `1.1` → `1-1`
- Convert title to kebab-case: `User Authentication` → `user-authentication`
- Final key: `{epic}-{story}-{title}`

### 3. Build Inventory Structure

For each epic found, create entries:

```yaml
epic-{num}:
  title: "Epic title"
  status: backlog

{epic}-{story}-{title}:
  title: "Story title"
  epic: epic-{num}
  status: backlog

epic-{num}-retrospective:
  status: optional
```

### 4. Report Parsing Results

Report to user:

> **Parsing Complete**
> - Epics found: {{epic_count}}
> - Stories found: {{story_count}}
> - Retrospectives: {{retro_count}}

### 5. Update State

```json
{
  "current_step": 2,
  "completed_steps": ["01-discover", "02-parse"],
  "epics_found": {{epic_count}},
  "stories_found": {{story_count}},
  "inventory": { ... }
}
```

---

## NEXT STEP

Load and execute `step-03-detect.md` to apply intelligent status detection.
