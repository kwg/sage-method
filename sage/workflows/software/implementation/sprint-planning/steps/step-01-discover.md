# Step 01: Discover Epic Files

**Goal:** Load all epic files using FULL_LOAD strategy.

---

## EMBEDDED RULES

- Sprint planning needs ALL epics to build complete status tracking
- This step uses FULL_LOAD strategy (different from other Phase 2 workflows)
- Priority: Whole document first, then sharded version
- Be flexible with document names (fuzzy matching)

---

## ACTIONS

### 1. Communicate Start

Inform `{user_name}` in `{communication_language}`:

> Starting sprint status discovery. Looking for epic files in `{output_folder}`...

### 2. Epic File Discovery

**Search Priority:**

1. **Whole document first** - Look for `epics.md`, `*epic*.md`, or any file matching the epic pattern
2. **Sharded version** - If whole not found, look for `epics/index.md` or `*epic*/index.md`

**Discovery Locations:**
- Primary: `{output_folder}/*epic*.md`
- Sharded: `{output_folder}/*epic*/*.md`
- Alternative: `{sprint_artifacts}/*epic*.md`

### 3. Handle Sharded Documents

If sharded version found:
- Read `index.md` to understand the document structure
- Read ALL epic section files listed in the index
- Process all epics and their stories from the combined content

### 4. Report Discovery Results

Report to user:

> **Epic Discovery Complete**
> - Files found: {{file_count}}
> - File list: {{file_names}}

### 5. Update State

```json
{
  "current_step": 1,
  "completed_steps": ["01-discover"],
  "files_discovered": ["list of file paths"],
  "discovery_strategy": "whole|sharded"
}
```

---

## NEXT STEP

Load and execute `step-02-parse.md` to parse the discovered files.
