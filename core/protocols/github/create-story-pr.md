# Protocol: Create Story PR

**ID:** github_create_story_pr
**Critical:** STORY_COMPLETION
**Purpose:** Creates PR for completed story

---

## Input/Output

**Input:** story_id, story_branch, epic_branch, story_data
**Output:** pr_number, pr_url

---

## Steps

### Step 1: Build PR Title

Format: `Story {story_id}: {story_title}`

### Step 2: Build PR Body

```markdown
## Summary

{story_objective}

**Story File:** [docs/sprint-artifacts/.../{story_file}](../../../{story_file_path})
**Epic:** [{epic_id}: {epic_title}](../../../{epic_file_path})

---

## Completed Tasks

{list of completed tasks with checkmarks}

---

## Changes

**Files Modified:** {count}
**Lines Added:** +{added}
**Lines Removed:** -{removed}

**Key Files:**
{list of main files changed}

---

## Test Results

{test summary: passed/failed/skipped}

---

## Checklist

- [x] All tasks completed
- [x] Tests passing
- [x] Code reviewed (by REVIEWER agent)
- [x] Documentation updated
- [x] No merge conflicts

---

**Ready for human review and approval.**
```

### Step 3: Create PR

```bash
gh pr create \
  --base {epic_branch} \
  --head {story_branch} \
  --title "{title}" \
  --label "story,{type_label},ready-for-review" \
  --milestone "{milestone_title}" \
  --body "{body}"
```

### Step 4: Update Project Board

Move story card to "Review" column:

```bash
gh project item-edit \
  --id {item_id} \
  --project-id {project_id} \
  --field-id {status_field_id} \
  --single-select-option-id {review_option_id}
```
