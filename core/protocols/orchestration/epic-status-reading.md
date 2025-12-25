# Epic Status Reading Protocol

## Purpose
Read and display current epic execution state from .sage/state/ files.

## State File Location

```
.sage/state/epic-{epic_id}-state.json
```

## Reading Logic

### Step 1: Identify Active Epic

```
Option A: User provides epic_id
  → Read .sage/state/epic-{epic_id}-state.json

Option B: Auto-detect from sprint-status.yaml
  → Find epic with status = "in-progress"
  → Read corresponding state file

Option C: List all state files
  → Show all epic-*-state.json files
  → Let user choose
```

### Step 2: Parse State File

Extract:
- `current_phase` - Where execution is currently
- `stories[]` - List of stories with status
- `learning_records[]` - Learnings captured
- `metrics` - Execution metrics
- `retro_notes` - Aggregated notes

### Step 3: Display Status

```
**Epic Status: {epic_id}**

Current Phase: {current_phase}
Started: {start_time}

**Stories:**
| Story | Status | Patterns Applied |
|-------|--------|------------------|
{story_status_table}

**Progress:**
- Stories Completed: {completed}/{total}
- Learning Records: {learning_record_count}
- Test Retries: {test_retries}

**Next Action:**
{next_action_recommendation}
```

## Next Action Recommendations

Based on `current_phase`:

```
init → "Run *run-epic to start execution"
story_start → "Story {current_story} is starting"
implement → "Story {current_story} is being implemented"
test → "Story {current_story} is in testing"
review → "Story {current_story} is in review"
complete → "Epic is complete. Run *epic-complete"
```

## Error Handling

**No state file:**
```
No epic state file found.

This can happen if:
- Epic was run with create-epic v1.0
- Epic hasn't started yet
- State file was deleted

To create an epic: *create-epic
To start execution: *run-epic
```

**Multiple active epics:**
```
Multiple epics in progress:
1. epic-7 (Phase: test)
2. epic-8 (Phase: implement)

Which epic's status? (1/2)
```

## Usage

```xml
<action cmd="*epic-status">
  <action>Run epic-status-reading protocol</action>
  <action>Display formatted status</action>
</action>
```
