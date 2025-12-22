# Protocol: Check Issue Response

**ID:** github_check_issue_response
**Critical:** HITL_POLLING
**Purpose:** Checks GitHub issue for human response and parses keywords

---

## Input/Output

**Input:** issue_number
**Output:** response object `{status, details}`

---

## Steps

### Step 1: Query Issue Comments

```bash
gh api repos/{owner}/{repo}/issues/{issue_number}/comments \
  --jq '.[] | select(.user.type != "Bot") | {body, created_at, user: .user.login}' \
  | tail -n 1
```

### Step 2: Parse Latest Human Comment

Get comment body (lowercase for matching).

### Step 3: Check Keywords (in priority order)

#### 3a. Discussion Request (highest priority)

IF body contains: `let's discuss`, `questions`, `need to think`, `hmm`, `I wonder`
- Return `{status: "DISCUSS", topic: extract_question(body)}`

#### 3b. Halt/Block

IF body contains: `blocked`, `stop`, `halt`, `pause`, `wait`
- Return `{status: "HALT", reason: body}`

#### 3c. Defer

IF body contains: `skip`, `defer`, `later`, `backlog`, `postpone`
- Return `{status: "DEFER"}`

#### 3d. Approval (check for conditionals)

IF body contains: `approved`, `lgtm`, `ship it`, `looks good`, `go`, `yes`
- IF body also contains: `but`, `however`, `although`, `except`
  - Return `{status: "DISCUSS", topic: "conditional approval"}`
- ELSE
  - Return `{status: "APPROVED"}`

#### 3e. Revision Request

IF body contains: `needs work`, `changes requested`, `revise`, `not yet`, `no`, `fix`
- Return `{status: "REVISE", changes: body}`

#### 3f. Unclear

Return `{status: "UNCLEAR", comment: body}`

### Step 4: Update Checkpoint Based on Response

| Response | Checkpoint Update |
|----------|-------------------|
| APPROVED | Clear hitl section, set next_action = "continue" |
| REVISE | Store revision notes, set next_action = "revise" |
| DISCUSS | Trigger create_discussion protocol |
| HALT/DEFER | Set epic.status = "paused" or "deferred" |
