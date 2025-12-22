# Metrics Collector Component

**Version:** 1.0
**Purpose:** Capture timing, token usage, and counts for workflow analysis

---

## Overview

The Metrics Collector provides standardized metrics capture for workflow execution. Metrics are stored with the workflow state and aggregated for retrospectives and optimization.

---

## Interface

### Start Timer

```yaml
metrics_collector:
  action: start_timer
  timer_id: "story-7-1"
  category: "story" | "chunk" | "phase" | "subagent"
```

**Output:**
```json
{
  "timer_id": "story-7-1",
  "started_at": "2025-12-19T10:30:00.000Z"
}
```

### Stop Timer

```yaml
metrics_collector:
  action: stop_timer
  timer_id: "story-7-1"
```

**Output:**
```json
{
  "timer_id": "story-7-1",
  "started_at": "2025-12-19T10:30:00.000Z",
  "stopped_at": "2025-12-19T10:45:30.000Z",
  "duration_ms": 930000
}
```

### Record Count

```yaml
metrics_collector:
  action: record_count
  metric: "files_modified" | "tests_written" | "tests_failed" | "review_iterations" | "bugs_found" | "bugs_fixed"
  value: 5
  context:
    story_id: "7-1"
    chunk_id: "chunk-01"
```

### Record Tokens

```yaml
metrics_collector:
  action: record_tokens
  subagent: "PLANNER" | "IMPLEMENTER" | "TESTER" | "REVIEWER" | "FIXER"
  input_tokens: 2500
  output_tokens: 1200
  context:
    story_id: "7-1"
    phase: "02-plan"
```

### Get Summary

```yaml
metrics_collector:
  action: get_summary
  scope: "story" | "epic" | "sprint"
  id: "7-1"
```

**Output:**
```json
{
  "scope": "story",
  "id": "7-1",
  "summary": {
    "timing": {
      "total_duration_ms": 3600000,
      "planning_duration_ms": 120000,
      "implementation_duration_ms": 2400000,
      "testing_duration_ms": 600000,
      "review_duration_ms": 480000
    },
    "tokens": {
      "total": 45000,
      "by_subagent": {
        "PLANNER": 5000,
        "IMPLEMENTER": 30000,
        "TESTER": 3000,
        "REVIEWER": 5000,
        "FIXER": 2000
      }
    },
    "counts": {
      "chunks_planned": 4,
      "chunks_completed": 4,
      "files_modified": 12,
      "tests_written": 8,
      "tests_failed": 2,
      "test_attempts": 2,
      "review_iterations": 1,
      "bugs_found": 3,
      "bugs_fixed": 3
    }
  }
}
```

---

## Metrics Schema

### Per-Story Metrics

```json
{
  "story_id": "7-1",
  "timing": {
    "start_time": "ISO timestamp",
    "end_time": "ISO timestamp",
    "total_duration_ms": 3600000,
    "by_phase": {
      "planning": 120000,
      "implementation": 2400000,
      "testing": 600000,
      "review": 480000
    },
    "by_chunk": [
      { "chunk_id": "chunk-01", "duration_ms": 600000 },
      { "chunk_id": "chunk-02", "duration_ms": 800000 }
    ]
  },
  "tokens": {
    "total": 45000,
    "by_subagent": {
      "PLANNER": 5000,
      "IMPLEMENTER": 30000,
      "TESTER": 3000,
      "REVIEWER": 5000,
      "FIXER": 2000
    }
  },
  "counts": {
    "chunks_planned": 4,
    "chunks_completed": 4,
    "chunks_failed": 0,
    "files_created": 5,
    "files_modified": 12,
    "tests_written": 8,
    "tests_failed": 2,
    "test_attempts": 2,
    "review_iterations": 1,
    "bugs_found": 3,
    "bugs_fixed": 3
  },
  "final_status": "completed" | "failed" | "skipped"
}
```

### Per-Epic Metrics

```json
{
  "epic_id": "7",
  "workflow_version": "3.0-phased",
  "timing": {
    "start_time": "ISO timestamp",
    "end_time": "ISO timestamp",
    "total_duration_ms": 14400000
  },
  "stories": [
    { ... per-story metrics ... }
  ],
  "summary": {
    "total_stories": 5,
    "completed_stories": 4,
    "failed_stories": 1,
    "skipped_stories": 0,
    "total_chunks": 20,
    "total_tokens": 180000,
    "avg_story_duration_ms": 2880000,
    "avg_chunk_duration_ms": 720000
  }
}
```

---

## Storage Location

Metrics are stored in two locations:

1. **In workflow state** (runtime): `state/epic-{id}-state.json` → `metrics` field
2. **In sprint artifacts** (persisted): `docs/sprint-artifacts/epic-{id}-metrics.json`

---

## Usage Example

```xml
<step n="1" name="start-story">
  <action>
    metrics_collector: start_timer
    timer_id: "story-{{story_id}}"
    category: "story"
  </action>
</step>

<step n="3" name="implement-chunk">
  <action>
    metrics_collector: start_timer
    timer_id: "chunk-{{chunk_id}}"
    category: "chunk"
  </action>

  <!-- Implementation happens here -->

  <action>
    metrics_collector: stop_timer
    timer_id: "chunk-{{chunk_id}}"
  </action>

  <action>
    metrics_collector: record_count
    metric: "files_modified"
    value: {{files_changed.length}}
  </action>
</step>

<step n="8" name="finalize">
  <action>
    metrics_collector: stop_timer
    timer_id: "story-{{story_id}}"
  </action>

  <action>
    metrics_collector: get_summary
    scope: "story"
    id: "{{story_id}}"
  </action>

  <action>Write metrics to docs/sprint-artifacts/</action>
</step>
```

---

## Aggregation

Metrics are aggregated at:

1. **Story completion**: Per-story summary calculated
2. **Epic completion**: Per-epic summary with all stories
3. **On request**: User can request aggregation via `*metrics` command

### Cross-Project Aggregation

When SAGE is used as a submodule across projects, metrics can be aggregated:

```yaml
metrics_collector:
  action: aggregate
  scope: "cross-project"
  projects: ["project-a", "project-b"]
  time_range: "last-30-days"
```

This enables pattern recognition across projects for the learning system.
