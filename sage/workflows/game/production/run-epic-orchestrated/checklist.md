# Run Epic (Orchestrated) v2.0 - Checklist

## Version Info

**Workflow Version:** 2.0 (Chunked Execution)
**Updated:** 2025-12-15
**Key Changes:** PLANNER subagent, micro-commits, automatic task tracking, metrics logging

---

## Pre-Flight Checks

- [ ] Epic file exists and is properly formatted
- [ ] All stories in epic have status "ready-for-dev" or "drafted"
- [ ] sprint-status.yaml is up to date
- [ ] No uncommitted changes in working directory
- [ ] On dev branch before starting
- [ ] SAGE submodule at correct commit (check after pulling to new machine)

---

## Per-Story Checklist

### PLANNER Subagent (NEW)
- [ ] Story file read completely
- [ ] Tasks grouped into logical chunks (1-3 files each)
- [ ] Chunk dependencies identified
- [ ] Shared patterns extracted for consistency
- [ ] Execution order determined
- [ ] Planner duration logged

### Per-Chunk Execution (NEW)
- [ ] Chunk scope is minimal (1-5 tasks, 1-3 files)
- [ ] Dependencies from prior chunks read from disk
- [ ] Shared patterns applied consistently
- [ ] Defensive programming applied
- [ ] Files written immediately after subagent returns
- [ ] Micro-commit created with chunk name
- [ ] Task checkboxes updated in story file
- [ ] Chunk metrics logged (duration, files, success)

### Test Execution
- [ ] Tests run after all chunks complete
- [ ] Fix subagent spawned if tests fail
- [ ] Max 3 retry attempts
- [ ] Test results logged

### REVIEWER Subagent
- [ ] Fresh context (no implementation bias)
- [ ] Integration checks passed
- [ ] Scope checks passed
- [ ] Edge case checks passed
- [ ] Defensive programming checks passed
- [ ] All ACs verified with code references
- [ ] Review iterations logged

### Story Completion
- [ ] Story status updated to "review"
- [ ] All task checkboxes marked [x]
- [ ] sprint-status.yaml updated
- [ ] Story branch merged to epic branch
- [ ] Story metrics finalized

---

## Post-Epic Checks

- [ ] All completed stories merged to epic branch
- [ ] Failed stories documented with reasons
- [ ] Metrics JSON file saved to docs/sprint-artifacts/
- [ ] PR created from epic branch to dev
- [ ] Metrics summary included in PR description

---

## Metrics to Track (For Retrospective)

### Per-Chunk Metrics
| Metric | Description | Why It Matters |
|--------|-------------|----------------|
| chunk_id | Unique identifier | Traceability |
| tasks_count | Number of tasks in chunk | Chunk sizing analysis |
| files_created | New files created | Scope verification |
| files_modified | Existing files changed | Impact assessment |
| subagent_duration_ms | Time to implement chunk | Performance baseline |
| context_size_estimate | small/medium/large | Context window risk |
| success | Did chunk complete? | Failure rate tracking |
| retry_count | Retries needed | Stability assessment |

### Per-Story Metrics
| Metric | Description | Why It Matters |
|--------|-------------|----------------|
| chunks_planned | Chunks identified by PLANNER | Planning accuracy |
| chunks_completed | Successfully implemented | Completion rate |
| chunks_failed | Failed to implement | Problem areas |
| planner_duration_ms | Time in PLANNER subagent | Overhead assessment |
| review_iterations | Review rounds needed | Code quality signal |
| issues_found | By severity | Quality metrics |
| tests_passed | Test suite result | Verification |

### Epic Summary Metrics
| Metric | Description | Why It Matters |
|--------|-------------|----------------|
| total_chunks | Sum across all stories | Workload measure |
| avg_chunk_duration_ms | Average implementation time | Efficiency baseline |
| context_compaction_events | Times context was compacted | v1.0 comparison |
| completed_stories | Successfully finished | Delivery rate |
| failed_stories | Could not complete | Blocker analysis |

---

## Retrospective Questions (Epic 4)

After running Epic 4 with v2.0 workflow, answer:

1. **Context Safety:** Did chunked execution reduce/eliminate context compaction events compared to v1.0?

2. **Planner Value:** Was the PLANNER subagent overhead worth the improved chunk coordination?

3. **Task Tracking:** Did automatic task checkbox updates after each chunk work correctly?

4. **Chunk Sizing:** What chunk size (tasks/files) felt optimal? Too small = overhead, too large = context risk.

5. **Micro-commits:** Were per-chunk commits helpful for debugging/rollback, or just noise?

6. **Failure Recovery:** When chunks failed, was retry/skip logic effective?

7. **Metrics Utility:** Which metrics were most useful? Which were unnecessary?

---

## Comparison: v1.0 vs v2.0

| Aspect | v1.0 (Story-level) | v2.0 (Chunked) |
|--------|-------------------|----------------|
| Subagent scope | Entire story | Single chunk (1-3 files) |
| Context risk | High (large stories) | Low (small chunks) |
| Checkpoint granularity | Per story | Per chunk |
| Task tracking | Manual/missed | Automatic per chunk |
| Planner overhead | None | ~1 subagent per story |
| Retry granularity | Whole story | Single chunk |
| Metrics | Basic | Detailed for retrospective |
| Rollback capability | Whole story | Per chunk |

---

## Known Limitations

1. **PLANNER Overhead:** Extra subagent spawn per story adds latency
2. **Chunk Dependencies:** If chunk-1 fails, dependent chunks may also fail
3. **Shared Pattern Drift:** Patterns identified by PLANNER may not cover all edge cases
4. **Metrics Storage:** JSON file grows with epic size

---

## Troubleshooting

### PLANNER returns invalid JSON
- Check story file format
- Fall back to single-chunk mode
- Log error for retrospective

### Chunk implementation fails repeatedly
- Check dependency files exist
- Verify shared patterns are applicable
- Mark chunk failed, try next chunk
- Document in metrics

### Task checkboxes not updating
- Verify story file path is correct
- Check task numbering matches chunk definition
- May need manual cleanup post-epic

### Metrics file not created
- Check docs/sprint-artifacts/ directory exists
- Verify git add/commit succeeds
- Check for disk space issues
