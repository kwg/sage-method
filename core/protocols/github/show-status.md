# Protocol: GitHub Status

**Purpose**: Display GitHub integration status for current project.

## Prerequisites

- `gh` CLI installed and authenticated
- Git remote configured

## Execution Steps

### Step 1: Check Authentication

```bash
gh auth status
```

### Step 2: Get Repository Info

```bash
gh repo view --json name,owner,url
```

### Step 3: List Open Issues

```bash
gh issue list --state open --limit 10
```

Filter for SAGE-related labels:
- `sage:hitl` - Human-in-the-Loop decisions pending
- `sage:blocked` - Blocked stories
- `sage:review` - Awaiting review

### Step 4: List Open PRs

```bash
gh pr list --state open --limit 10
```

### Step 5: Check Project Board (if configured)

```bash
gh project list
gh project item-list {project_number}
```

### Step 6: Display Status

```
GitHub Status
═══════════════════════════════════════
Repository: {owner}/{name}
URL: {url}

Open Issues: {count}
  HitL Pending: {hitl_count}
  Blocked: {blocked_count}
  Review: {review_count}

Open PRs: {count}
  Ready for Review: {ready_count}
  Changes Requested: {changes_count}
  Approved: {approved_count}

Project Board: {configured/not configured}
  Backlog: {count}
  In Progress: {count}
  Done: {count}
═══════════════════════════════════════
```

## TODO

- [ ] Implement milestone tracking
- [ ] Add webhook status check
- [ ] Support multiple remotes
