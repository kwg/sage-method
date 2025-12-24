# Protocol: Project Board Operations

**Purpose:** GitHub Project V2 integration for tracking items

---

## Add Item to Project

**ID:** github_add_to_project
**Critical:** PROJECT_TRACKING

### Input/Output

**Input:** item_node_id (issue or PR node ID), status ("todo"|"in_progress"|"done")
**Output:** project_item_id

### Steps

#### Step 1: Add Item to Project

```bash
gh api graphql -f query='
  mutation {
    addProjectV2ItemById(input: {
      projectId: "{checkpoint.github.project_id}"
      contentId: "{item_node_id}"
    }) {
      item { id }
    }
  }
'
```

Capture `item.id` as project_item_id.

#### Step 2: Set Status Field

Map status to option ID from `checkpoint.github.status_options`.

```bash
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "{checkpoint.github.project_id}"
      itemId: "{project_item_id}"
      fieldId: "{checkpoint.github.status_field_id}"
      value: { singleSelectOptionId: "{status_option_id}" }
    }) {
      projectV2Item { id }
    }
  }
'
```

#### Step 3: Log Action

Log: `Added {item_type} #{number} to project board with status: {status}`

---

## Update Project Status

**ID:** github_update_project_status
**Critical:** STATUS_UPDATE

### Input/Output

**Input:** project_item_id, new_status ("todo"|"in_progress"|"done")
**Output:** success boolean

### Steps

#### Step 1: Map Status to Option ID

Look up option ID from `checkpoint.github.status_options`.

#### Step 2: Update Status

```bash
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "{checkpoint.github.project_id}"
      itemId: "{project_item_id}"
      fieldId: "{checkpoint.github.status_field_id}"
      value: { singleSelectOptionId: "{status_option_id}" }
    }) {
      projectV2Item { id }
    }
  }
'
```

#### Step 3: Log Update

Log: `Updated project item status to: {new_status}`

---

## Create Milestone

**ID:** github_create_milestone
**Critical:** EPIC_TRACKING

### Input/Output

**Input:** epic_id, epic_title, due_date (optional)
**Output:** milestone_number

### Steps

#### Step 1: Check if Milestone Exists

```bash
gh api repos/{owner}/{repo}/milestones \
  --jq '.[] | select(.title | contains("{epic_id}")) | .number'
```

#### Step 2: Create if Not Exists

```bash
gh api repos/{owner}/{repo}/milestones \
  --method POST \
  --field title="{epic_id}: {epic_title}" \
  --field description="{epic_summary}" \
  --field due_on="{due_date}" \
  --field state="open"
```

#### Step 3: Cache Milestone Number

Store in checkpoint: `epic.milestone_number`
