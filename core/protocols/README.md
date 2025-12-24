# SAGE Protocols

Externalized protocol definitions for the SAGE orchestration system. Protocols define repeatable procedures that agents execute during workflows.

## Directory Structure

```
protocols/
├── checkpoint/           # State management
│   ├── write-checkpoint.md
│   ├── read-checkpoint.md
│   └── signal-format.md
├── github/              # GitHub integration
│   ├── create-hitl-issue.md
│   ├── check-issue-response.md
│   ├── create-story-pr.md
│   └── project-board.md
├── subagent/            # Subagent spawning
│   ├── registry.md           # Subagent definitions and roles
│   ├── generate-context.md
│   ├── spawn-sequential.md
│   ├── spawn-parallel.md
│   └── parse-output.md
├── recovery/            # Failure handling
│   ├── detect-failure.md
│   ├── execute-recovery.md
│   ├── log-failure.md
│   └── resume-after-recovery.md
└── orchestration/       # Epic lifecycle
    ├── on-load-sequence.md   # Assistant initialization
    ├── signal-definitions.md # SAGE signal format
    ├── context-budget.md     # Token limits and clearing
    ├── epic-lifecycle.md
    └── learning-summary.md
```

## Usage

Protocols are loaded on-demand by agents using the exec handler:

```xml
<handler type="exec">
  When protocol needed: exec="sage/core/protocols/{category}/{protocol}.md"
</handler>
```

## Protocol Format

Each protocol file contains:

1. **Header** - ID, critical flag, purpose
2. **Input/Output** - What goes in, what comes out
3. **Steps** - Numbered implementation steps
4. **Error Handling** - How to handle failures

## Shell Script Alternatives

Some protocols have shell script implementations in `sage/scripts/` that are preferred for:

- Testability
- Reusability across projects
- Reduced token consumption

| Protocol | Shell Script |
|----------|--------------|
| checkpoint/write-checkpoint | checkpoint-write.sh |
| checkpoint/read-checkpoint | checkpoint-write.sh read |
| github/create-hitl-issue | gh-create-review-issue.sh |
| github/check-issue-response | gh-poll-response.sh |
| github/create-story-pr | gh-create-pr.sh |
| github/project-board | gh-milestone.sh |
| orchestration/on-load-sequence | Uses checkpoint-write.sh read |
| recovery/execute-recovery | git-recover.sh |

### Git Operations

All git operations should use dedicated scripts:

| Operation | Script |
|-----------|--------|
| Branch creation/switching | git-branch.sh |
| State verification | git-state-check.sh |
| Checkpoint commit | git-checkpoint.sh |
| Recovery/revert | git-recover.sh |

### GitHub Operations

| Operation | Script |
|-----------|--------|
| HitL review issue | gh-create-review-issue.sh |
| Poll for response | gh-poll-response.sh |
| Wait for approval | gh-wait-approval.sh |
| Create PR | gh-create-pr.sh |
| Milestone management | gh-milestone.sh |

### Metrics & Testing

| Operation | Script |
|-----------|--------|
| Collect metrics | metrics-collect.sh |
| Run tests | test-run.sh |
| Update sprint status | sprint-update.sh |

## Adding New Protocols

1. Create new `.md` file in appropriate category folder
2. Follow the standard protocol format
3. Add entry to this README
4. Reference from agents using exec handler
