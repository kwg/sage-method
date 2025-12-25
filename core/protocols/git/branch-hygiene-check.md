# Branch Hygiene Check Protocol

## Purpose

Verify branch alignment before critical workflow phases to prevent:
- Work performed on wrong branch
- Orphaned commits not captured in PRs
- Merge conflicts from branch confusion
- Epic work accidentally committed to story branches
- Story branches created from wrong parent

This protocol is designed to be invoked at key workflow checkpoints to ensure git state matches workflow expectations.

## When to Invoke

### Critical Checkpoints

1. **Phase 01 (story-start)**: Before creating story branch
   - Verify on epic branch
   - Ensure epic branch is up-to-date
   - Prevent story branch from wrong parent

2. **Phase 07 (story-complete)**: Before merging to epic branch
   - Verify on story branch
   - Ensure all changes committed
   - Check epic branch still exists

3. **Phase 08 (finalize)**: Before finalizing epic
   - Verify on epic branch
   - Check all story branches merged
   - Verify no uncommitted changes

4. **Manual invocation**: Before any git operations
   - User can invoke via command
   - Useful for debugging branch state

### Optional Checkpoints

- Before Phase 03 (implement-chunk): Verify still on story branch
- Before Phase 04 (test): Verify on story branch with clean state
- After resuming workflow: Verify expected branch

## Verification Steps

### Step 1: Identify Expected Branch

Determine the expected branch based on workflow phase:

```xml
<action>Determine expected branch:
  if phase == "00-init" or phase == "01-story-start":
    expected_branch = state.epic_branch

  elif phase in ["02-plan", "03-implement-chunk", "04-test", "05-integration", "06-review"]:
    expected_branch = state.story_branch

  elif phase == "07-story-complete":
    # Can be on story branch or epic branch (depends on sub-step)
    expected_branch = state.story_branch OR state.epic_branch

  elif phase in ["08-finalize", "09-merge-to-dev"]:
    expected_branch = state.epic_branch

  else:
    expected_branch = null (no validation needed)
</action>
```

### Step 2: Check Current Branch

```xml
<action>Get current branch:
  current_branch = $(git branch --show-current)
</action>

<check if="current_branch is empty">
  <error>Detached HEAD state detected</error>
  <output>
❌ **Detached HEAD State**

You are not on any branch. This typically happens after checking out a commit directly.

Current commit: {{git rev-parse HEAD}}

Action required:
1. Create a new branch: git checkout -b {{suggested_branch_name}}
2. Or checkout existing branch: git checkout {{expected_branch}}
  </output>
  <action>Exit workflow</action>
</check>
```

### Step 3: Validate Alignment

```xml
<check if="current_branch != expected_branch">
  <warning>Branch mismatch detected</warning>
  <output>
⚠️ **Branch Mismatch**

Current Branch: {{current_branch}}
Expected Branch: {{expected_branch}}
Workflow Phase: {{phase}}

This mismatch may cause:
- Commits on wrong branch
- Merge failures
- Lost work

Options:
1. Switch to expected branch (safe if no uncommitted changes)
2. Continue on current branch (may cause issues)
3. Abort and investigate
  </output>

  <action>Check for uncommitted changes:
    git_status = $(git status --porcelain)
    has_uncommitted = (git_status != "")
  </action>

  <check if="has_uncommitted">
    <error>Cannot auto-switch: uncommitted changes present</error>
    <output>
❌ **Uncommitted Changes Detected**

Files with changes:
{{git status --short}}

You must commit or stash these changes before switching branches.

Options:
1. Commit changes: git add . && git commit -m "WIP: {{description}}"
2. Stash changes: git stash push -m "{{description}}"
3. Abort workflow and investigate

What would you like to do?
    </output>
    <action>Wait for user decision</action>
  </check>

  <check if="not has_uncommitted">
    <action>Offer to auto-switch:
      Should I switch to {{expected_branch}}? [y/n]
    </action>

    <check if="user confirms">
      <action>Switch branch:
        git checkout {{expected_branch}}
      </action>
      <output>✅ Switched to {{expected_branch}}</output>
    </check>

    <check if="user declines">
      <warning>Continuing on {{current_branch}} - this may cause issues</warning>
      <action>Update state.override_branch_check = true</action>
    </check>
  </check>

</check>

<check if="current_branch == expected_branch">
  <output>✅ Branch hygiene OK: on {{current_branch}}</output>
</check>
```

### Step 4: Verify Branch Exists

```xml
<action>Check if expected branch exists locally:
  branch_exists_local = $(git branch --list {{expected_branch}})
</action>

<check if="not branch_exists_local">
  <warning>Expected branch {{expected_branch}} does not exist locally</warning>

  <action>Check if exists on remote:
    branch_exists_remote = $(git ls-remote --heads origin {{expected_branch}})
  </action>

  <check if="branch_exists_remote">
    <action>Offer to checkout from remote:
      Branch {{expected_branch}} exists on origin. Checkout? [y/n]
    </action>

    <check if="user confirms">
      <action>Checkout from remote:
        git fetch origin
        git checkout -b {{expected_branch}} origin/{{expected_branch}}
      </action>
      <output>✅ Checked out {{expected_branch}} from origin</output>
    </check>
  </check>

  <check if="not branch_exists_remote">
    <action>Offer to create new branch:
      Branch {{expected_branch}} does not exist. Create it? [y/n]
    </action>

    <check if="user confirms">
      <action>Determine parent branch:
        if expected_branch is epic_branch:
          parent = "dev"
        elif expected_branch is story_branch:
          parent = state.epic_branch
        else:
          parent = "main"
      </action>

      <action>Create branch:
        git checkout -b {{expected_branch}} {{parent}}
      </action>
      <output>✅ Created {{expected_branch}} from {{parent}}</output>
    </check>

    <check if="user declines">
      <error>Cannot proceed without expected branch</error>
      <action>Exit workflow</action>
    </check>
  </check>

</check>
```

### Step 5: Check Branch Sync Status

```xml
<action>Check if branch is up-to-date with origin:
  git fetch origin {{expected_branch}} --dry-run 2>&1

  commits_ahead = $(git rev-list origin/{{expected_branch}}..{{expected_branch}} --count)
  commits_behind = $(git rev-list {{expected_branch}}..origin/{{expected_branch}} --count)
</action>

<check if="commits_behind > 0">
  <warning>Branch is {{commits_behind}} commits behind origin</warning>
  <output>
⚠️ **Branch Behind Origin**

Local: {{expected_branch}}
Origin: origin/{{expected_branch}}
Behind by: {{commits_behind}} commits

Options:
1. Pull changes: git pull origin {{expected_branch}}
2. Continue without sync (may cause conflicts)
3. Abort and investigate

What would you like to do?
  </output>
  <action>Wait for user decision</action>
</check>

<check if="commits_ahead > 0">
  <output>
ℹ️  Branch is {{commits_ahead}} commits ahead of origin

These commits will be pushed when the workflow completes.
  </output>
</check>

<check if="commits_ahead == 0 and commits_behind == 0">
  <output>✅ Branch is in sync with origin</output>
</check>
```

## Integration with run-epic-orchestrated

### Phase 01 Integration

Add to Phase 01 (story-start) as precondition:

```xml
<step n="0" name="branch-hygiene-check">
  <action>Load protocol: sage/core/protocols/git/branch-hygiene-check.md</action>
  <action>Execute protocol with:
    - expected_branch = state.epic_branch
    - phase = "01-story-start"
    - workflow_context = state
  </action>

  <check if="protocol reports mismatch">
    <action>Handle mismatch per protocol instructions</action>
  </check>
</step>
```

### Phase 07 Integration

Add to Phase 07 (story-complete) before merge:

```xml
<step n="4" name="merge-to-epic">
  <action>Run branch hygiene check:
    - expected_branch = state.story_branch
    - phase = "07-story-complete"
  </action>

  <action>git checkout {{epic_branch}}</action>
  <action>Run branch hygiene check again:
    - expected_branch = state.epic_branch
  </action>

  <action>git merge {{story_branch}} --no-edit</action>
  <!-- ... rest of merge logic ... -->
</step>
```

### Phase 08 Integration

Already has branch verification in Step 0, but can use this protocol for consistency:

```xml
<step n="0" name="verify-branch-state">
  <action>Run branch hygiene check:
    - expected_branch = state.epic_branch
    - phase = "08-finalize"
  </action>

  <!-- ... rest of verification logic ... -->
</step>
```

## Standalone Invocation

Users can invoke this protocol manually:

```bash
# Command (to be implemented)
*check-branch

# Or with specific branch
*check-branch epic-7

# Or with verbose output
*check-branch --verbose
```

The protocol should output:
- Current branch
- Expected branch (if in workflow context)
- Sync status with origin
- Uncommitted changes
- Recommendations

## State Updates

The protocol may update state with:

```json
{
  "branch_hygiene_last_check": "2025-12-24T10:30:00Z",
  "branch_hygiene_status": "ok" | "warning" | "error",
  "branch_hygiene_override": false,
  "current_branch_verified": "epic-7"
}
```

## Error Codes

| Code | Meaning | Severity |
|------|---------|----------|
| BH-001 | Branch mismatch | Warning |
| BH-002 | Detached HEAD | Error |
| BH-003 | Uncommitted changes | Warning |
| BH-004 | Branch does not exist | Error |
| BH-005 | Branch behind origin | Warning |
| BH-006 | Merge conflict detected | Error |

## Learning Records

Branch hygiene failures should be recorded as learning records:

```json
{
  "record_id": "lr-{{timestamp}}",
  "type": "implementation",
  "context": {
    "error_code": "BH-001",
    "current_branch": "7-3-class-management",
    "expected_branch": "epic-7",
    "phase": "08-finalize",
    "uncommitted_changes": false
  },
  "resolution": {
    "action": "user switched to epic-7",
    "successful": true
  },
  "classification": {
    "category": "process",
    "subcategory": "branch-management",
    "lesson": "Always verify branch before finalize phase"
  }
}
```

## Testing

To test this protocol:

1. **Test branch mismatch:**
   - Start epic workflow
   - Manually checkout wrong branch
   - Trigger protocol
   - Verify warning and recovery

2. **Test uncommitted changes:**
   - Make file changes
   - Don't commit
   - Trigger protocol
   - Verify prevents auto-switch

3. **Test missing branch:**
   - Delete expected branch
   - Trigger protocol
   - Verify creates or fetches branch

4. **Test sync issues:**
   - Have remote ahead of local
   - Trigger protocol
   - Verify warning and pull option

## Future Enhancements

1. **Auto-recovery:** Automatically fix common issues without user input
2. **Branch naming validation:** Verify branch names match conventions
3. **Stash integration:** Auto-stash uncommitted changes if safe
4. **Metrics:** Track branch hygiene issues for retrospectives
5. **Pre-commit hook:** Run check before every commit
6. **CI integration:** Fail PR if branch hygiene issues detected

## References

- Git branch management best practices
- SAGE workflow phase documentation
- Learning recorder component (EPIC-002)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-24 | Initial protocol from Epic 7 retrospective |
