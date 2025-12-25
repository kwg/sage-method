# Merge to Main Workflow

## Purpose

Merge the dev branch to main with verification, ensuring all completed epics are properly integrated into the production branch.

This workflow provides a safe, verified path from dev to main with optional testing and release tagging.

## When to Use

- After completing one or more epics on dev
- After Phase 09 of run-epic-orchestrated completes
- Before a production release
- When ready to promote tested changes to main

## Prerequisites

- Dev branch contains tested, reviewed changes
- All epic PRs have been merged to dev
- CI/CD checks passing on dev
- Git configured and authenticated
- Write access to main branch

## Configuration

Edit `workflow.yaml` to configure:

```yaml
options:
  run_tests: true          # Run test suite before merge
  create_tag: false        # Create release tag after merge
  tag_format: "v{version}" # Tag format
  require_clean_dev: true  # Require dev up-to-date with origin
```

## Execution Steps

### Step 1: Verify Dev State

1. **Checkout and update dev branch:**
   ```bash
   git checkout dev
   git fetch origin
   ```

2. **Check if dev is up-to-date with origin:**
   ```bash
   # Check for local commits not pushed
   git log origin/dev..dev --oneline

   # Check for remote commits not pulled
   git log dev..origin/dev --oneline
   ```

3. **If out of sync:**
   - If local commits exist: `git push origin dev`
   - If remote commits exist: `git pull origin dev`
   - If `require_clean_dev: true`, abort if sync issues exist

### Step 2: Show Pending Changes

1. **List commits that will be merged:**
   ```bash
   git log main..dev --oneline
   ```

2. **Display merge preview:**
   ```
   📊 **Merge Preview: dev → main**

   Commits: {{commit_count}}
   Authors: {{unique_authors}}
   First commit: {{first_commit_date}}
   Last commit: {{last_commit_date}}

   Recent commits (last 10):
   {{last_10_commits}}

   Epics included (from commit messages):
   {{epic_list}}
   ```

3. **Ask for confirmation:**
   ```
   Proceed with merge? [y/n]
   ```

### Step 3: Run Tests (if configured)

**If `run_tests: true`:**

1. **Determine test command:**
   - Check for `package.json`: `npm test`
   - Check for `Makefile`: `make test`
   - Check for `pytest.ini`: `pytest`
   - Check for project.godot: `godot --headless --script test_runner.gd`
   - Custom: Use command from config

2. **Run test suite:**
   ```bash
   {{test_command}}
   ```

3. **If tests fail:**
   ```
   ❌ **Tests Failed**

   Test suite failed with {{error_count}} errors.

   Options:
   1. Fix tests and retry
   2. Skip tests and proceed (not recommended)
   3. Abort merge

   What would you like to do?
   ```

4. **If tests pass:**
   ```
   ✅ All tests passed
   ```

### Step 4: Execute Merge

1. **Checkout main branch:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create merge commit with no-ff:**
   ```bash
   git merge dev --no-ff -m "Merge dev to main: {{epic_summary}}"
   ```

   **Note:** `--no-ff` ensures a merge commit is created even if fast-forward is possible. This preserves the branch history and makes rollbacks easier.

3. **If merge conflict occurs:**
   ```
   ❌ **Merge Conflict**

   Conflicts in:
   {{conflict_files}}

   Manual resolution required:
   1. Resolve conflicts in the listed files
   2. Stage resolved files: git add <file>
   3. Complete merge: git commit
   4. Resume workflow or push manually

   Aborting merge. Run this to reset:
   git merge --abort
   ```

   **Action:** Exit workflow, output manual resolution instructions

4. **If merge succeeds:**
   ```
   ✅ Merge completed successfully
   ```

5. **Push to origin:**
   ```bash
   git push origin main
   ```

6. **Verify push:**
   ```bash
   git log origin/main -n 3 --oneline
   ```

### Step 5: Create Tag (if configured)

**If `create_tag: true`:**

1. **Determine tag name:**
   - Parse version from `package.json`, `pyproject.toml`, or config
   - Apply `tag_format` (e.g., "v{version}" → "v1.2.3")
   - Or use provided tag name

2. **Create annotated tag:**
   ```bash
   git tag -a {{tag_name}} -m "Release {{version}}: {{release_notes}}"
   ```

3. **Push tag to origin:**
   ```bash
   git push origin {{tag_name}}
   ```

4. **Output tag info:**
   ```
   🏷️  Tag created: {{tag_name}}
   ```

### Step 6: Cleanup and Summary

1. **Return to dev branch:**
   ```bash
   git checkout dev
   ```

2. **Output success summary:**
   ```
   ✅ **Merge to Main Complete**

   | | |
   |---|---|
   | Merged | {{commit_count}} commits |
   | From | dev |
   | To | main |
   | Tag | {{tag_name}} (if created) |
   | Timestamp | {{current_timestamp}} |

   Main branch updated successfully.

   Next steps:
   - Verify CI/CD pipeline on main
   - Monitor production deployment (if automated)
   - Archive completed epic state files
   - Update project documentation
   ```

## Error Handling

### Test Failures

If tests fail during Step 3:
- Output detailed test results
- Offer to skip tests (with warning)
- Offer to abort
- Log failure for retrospective

### Merge Conflicts

If merge conflicts occur:
- Output conflicting files
- Provide resolution instructions
- Abort merge automatically
- Exit workflow (user must resolve manually)

### Push Failures

If push to main fails:
- Check if main has new commits: `git log main..origin/main`
- Suggest: `git pull origin main --rebase`
- Ask user to resolve and retry

## Rollback Procedure

If issues are discovered after merge:

1. **Identify the merge commit:**
   ```bash
   git log main --oneline --merges -n 5
   ```

2. **Revert the merge:**
   ```bash
   git revert -m 1 {{merge_commit_sha}}
   git push origin main
   ```

3. **Or create a fix-forward:**
   - Create hotfix branch from main
   - Fix issue
   - PR to main directly

## Integration with Epic Workflows

This workflow is typically invoked:

1. **After Phase 09 of run-epic-orchestrated:**
   - Epic merged to dev
   - Optionally auto-run merge-to-main
   - Or user manually invokes

2. **After multiple epics complete:**
   - Several epics merged to dev
   - Batch merge to main
   - Create release tag

3. **Before production deployment:**
   - Ensure main is up-to-date
   - Tag release version
   - Trigger deployment pipeline

## Resume Support

This workflow does not currently support resumption. If it fails mid-execution:
- Manual git operations may be needed
- Use git status to check current state
- Complete merge manually or start fresh

## State File

No state file is created for this workflow. All operations are atomic git commands.

## Metrics

The workflow outputs a merge report:
- Commit count
- Author list
- Epic list (parsed from commits)
- Timestamp
- Tag created (if any)

This report can be saved to: `docs/sprint-artifacts/merge-to-main-{{date}}.md`

## Examples

### Example 1: Simple Merge

```bash
# User invokes workflow
*merge-to-main

# Workflow executes:
# 1. Verify dev is clean
# 2. Show 15 commits to merge
# 3. Run tests (pass)
# 4. Merge dev to main
# 5. Push to origin
# 6. Done
```

### Example 2: Merge with Tag

```yaml
# Configure in workflow.yaml
options:
  create_tag: true
  tag_format: "release-{version}"
```

```bash
# User invokes
*merge-to-main

# Workflow executes merge + creates release-1.2.3 tag
```

### Example 3: Conflict Resolution

```bash
# User invokes
*merge-to-main

# Merge conflict in src/main.gd
# Workflow outputs resolution instructions
# User resolves manually:
git merge --abort
# Fix conflicts in dev
# Retry workflow
```

## Safety Features

1. **No-ff merge:** Always creates merge commit for easy rollback
2. **Pre-merge verification:** Checks branch state before merging
3. **Test execution:** Optional test suite run before merge
4. **Confirmation prompts:** User must confirm before destructive operations
5. **Conflict detection:** Aborts cleanly on merge conflicts

## Troubleshooting

### "dev is not up-to-date with origin"

```bash
git checkout dev
git pull origin dev
# Re-run workflow
```

### "main has diverged"

```bash
git checkout main
git pull origin main
git checkout dev
git rebase main
# Re-run workflow
```

### "Permission denied on push"

- Verify git credentials
- Check branch protection rules
- Ensure you have write access to main

### "Tests fail on dev but pass locally"

- Check for environment differences
- Verify all dependencies pushed
- Review CI logs for details
