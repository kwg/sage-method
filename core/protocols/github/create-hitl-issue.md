# Protocol: Create HitL Issue

**ID:** github_create_hitl_issue
**Critical:** HITL_CHECKPOINT
**Purpose:** Creates GitHub issue for Human-in-the-Loop review request

---

## Preferred Method: Use Shell Script

For most cases, use the dedicated shell script which handles all edge cases:

```bash
./sage/scripts/gh-create-review-issue.sh <doc_type> <file_path> [options]
```

Options:
- `--branch` - Branch name (default: current branch)
- `--project-id` - Project ID to link issue
- `--milestone` - Milestone number to assign

The script automatically:
- Pushes the branch if not on remote
- Builds absolute GitHub URLs for document links
- Applies appropriate labels
- Emits HITL_REQUIRED signal

---

## Manual Protocol (if script unavailable)

### Input/Output

**Input:** title, document_path, reason, milestone_title, branch (optional)
**Output:** issue_number, issue_url

### Step 0: Ensure Branch is Pushed

```bash
# Get current branch
branch=$(git rev-parse --abbrev-ref HEAD)

# Check if on remote
git ls-remote --exit-code --heads origin "$branch"

# If not on remote, push it
git push -u origin "$branch"
```

IF push fails: Error - cannot create issue without branch on remote

### Step 1: Build Issue Title

Format: `Review: {document_type} - {subject}`
Example: `Review: PRD - Authentication Feature`

### Step 2: Build Absolute Document URL

```bash
# Get owner/repo from remote
remote_url=$(git remote get-url origin)
# Parse to extract owner and repo
```

Build URL: `https://github.com/{owner}/{repo}/blob/{branch}/{document_path}`

### Step 3: Build Issue Body

```markdown
## Review Request

**Document:** [{document_path}]({document_url})

**Context:** {reason}

**What to Review:**
- [Specific review points from document]

---

## How to Respond

**To approve:**
- Comment with: `approved`, `lgtm`, `ship it`, `looks good`, or `go`

**To request changes:**
- Comment with: `needs work`, `changes requested`, or `revise`
- Explain what needs to change

**To start a discussion:**
- Comment with: `let's discuss` or `I have questions`

**To halt/defer:**
- `blocked`, `stop`, `halt` - stops execution
- `skip`, `defer`, `later` - moves to backlog

---

**Created:** {timestamp}
**Checkpoint:** .sage/state/{epic_id}.json
```

### Step 4: Create Issue

```bash
gh issue create \
  --title "{title}" \
  --label "hitl/review,{phase_label},{type_label}" \
  --milestone "{milestone_title}" \
  --body "{body}"
```

### Step 5: Capture Issue Metadata

Parse output for issue number and URL.
Store in checkpoint:
- `hitl.github_issue_id`
- `hitl.github_url`
- `hitl.waiting_since`
- `hitl.type = "issue"`

### Step 6: Signal HitL Required

```
═══════════════════════════════════════════════════════════════════
SIGNAL: HITL_REQUIRED
REASON: {reason}
CONTEXT: {document_path}
OPTIONS: [approve] [reject] [discuss]
GITHUB_ISSUE: #{issue_number}
═══════════════════════════════════════════════════════════════════
```
