# Learning Recorder Component

**Version:** 1.0
**Purpose:** Capture failure context, resolutions, and patterns for continuous improvement

---

## Overview

The Learning Recorder captures structured information about failures encountered during workflow execution. This enables pattern recognition, prevention recommendations, and self-improvement over time.

---

## Interface

### Record Failure

```yaml
learning_recorder:
  action: record_failure
  failure:
    type: "test" | "review" | "build" | "implementation"
    context:
      file: "src/auth/login.py"
      line: 42
      error: "AssertionError: expected 200, got 401"
      phase: "04-test"
      story_id: "7-1"
      chunk_id: "chunk-02"
    retry_count: 2
```

**Output:**
```json
{
  "record_id": "lr-2025-12-19-001",
  "created_at": "2025-12-19T10:30:00Z",
  "failure": { ... recorded failure ... }
}
```

### Record Resolution

```yaml
learning_recorder:
  action: record_resolution
  record_id: "lr-2025-12-19-001"
  resolution:
    action: "Added missing authentication header in request"
    success: true
    files_changed: ["src/auth/login.py", "tests/test_login.py"]
```

### Classify Pattern

```yaml
learning_recorder:
  action: classify
  record_id: "lr-2025-12-19-001"
  classification:
    category: "syntax" | "logic" | "architecture" | "integration" | "environment"
    pattern: "Missing authentication in API calls"
    preventable: true
    prevention_rule: "Always check auth requirements before implementing API endpoints"
```

### Get Patterns

```yaml
learning_recorder:
  action: get_patterns
  scope: "project" | "cross-project"
  category: "logic"  # optional filter
  limit: 10
```

**Output:**
```json
{
  "patterns": [
    {
      "pattern": "Missing authentication in API calls",
      "occurrences": 5,
      "category": "logic",
      "preventable": true,
      "prevention_rule": "Always check auth requirements before implementing API endpoints",
      "last_seen": "2025-12-19T10:30:00Z"
    }
  ]
}
```

---

## Learning Record Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Learning Record",
  "type": "object",
  "required": ["record_id", "failure", "created_at"],
  "properties": {
    "record_id": {
      "type": "string",
      "pattern": "^lr-\\d{4}-\\d{2}-\\d{2}-\\d{3,}$"
    },
    "created_at": {
      "type": "string",
      "format": "date-time"
    },
    "failure": {
      "type": "object",
      "required": ["type", "context"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["test", "review", "build", "implementation"]
        },
        "context": {
          "type": "object",
          "properties": {
            "file": { "type": "string" },
            "line": { "type": "integer" },
            "error": { "type": "string" },
            "phase": { "type": "string" },
            "story_id": { "type": "string" },
            "chunk_id": { "type": "string" },
            "stack_trace": { "type": "string" }
          }
        },
        "retry_count": { "type": "integer" }
      }
    },
    "resolution": {
      "type": "object",
      "properties": {
        "action": { "type": "string" },
        "success": { "type": "boolean" },
        "files_changed": {
          "type": "array",
          "items": { "type": "string" }
        },
        "resolved_at": { "type": "string", "format": "date-time" }
      }
    },
    "classification": {
      "type": "object",
      "properties": {
        "category": {
          "type": "string",
          "enum": ["syntax", "logic", "architecture", "integration", "environment"]
        },
        "pattern": { "type": "string" },
        "preventable": { "type": "boolean" },
        "prevention_rule": { "type": "string" }
      }
    }
  }
}
```

---

## Category Definitions

| Category | Description | Examples |
|----------|-------------|----------|
| `syntax` | Language/framework syntax errors | Missing semicolons, invalid syntax |
| `logic` | Incorrect implementation logic | Wrong condition, missing edge case |
| `architecture` | Design/structure issues | Wrong abstraction, coupling problems |
| `integration` | Component interaction failures | API contract mismatch, timing issues |
| `environment` | Environment/config issues | Missing env vars, wrong versions |

---

## Storage Location

Learning records are stored in:

1. **Per-project**: `docs/sprint-artifacts/learning/` (persisted)
2. **In workflow state**: `state/epic-{id}-state.json` → `learning_records` (runtime)

File structure:
```
docs/sprint-artifacts/learning/
├── records/
│   ├── lr-2025-12-19-001.json
│   └── lr-2025-12-19-002.json
├── patterns.json (aggregated patterns)
└── prevention-rules.md (extracted rules)
```

---

## Usage Example

```xml
<step n="3" name="handle-test-failure">
  <check if="tests_failed AND retry_count >= max_retries">
    <action>
      learning_recorder: record_failure
      failure:
        type: "test"
        context:
          file: "{{failing_test_file}}"
          error: "{{test_error}}"
          phase: "04-test"
          story_id: "{{story_id}}"
        retry_count: {{retry_count}}
    </action>
  </check>
</step>

<step n="4" name="apply-fix">
  <check if="fix_successful">
    <action>
      learning_recorder: record_resolution
      record_id: "{{record_id}}"
      resolution:
        action: "{{fix_description}}"
        success: true
        files_changed: {{changed_files}}
    </action>
  </check>
</step>

<step n="finalize" name="classify-learnings">
  <action>
    For each unclassified learning record:
    - Analyze failure and resolution
    - Determine category
    - Extract pattern if recognizable
    - Determine if preventable
    - Create prevention rule if applicable
  </action>
</step>
```

---

## Aggregation & Pattern Recognition

At epic completion or on request, learning records are aggregated:

```yaml
learning_recorder:
  action: aggregate
  epic_id: "7"
```

**Output:**
```json
{
  "epic_id": "7",
  "total_failures": 12,
  "resolved": 10,
  "unresolved": 2,
  "by_category": {
    "logic": 5,
    "integration": 4,
    "syntax": 2,
    "environment": 1
  },
  "top_patterns": [
    {
      "pattern": "Missing null checks",
      "occurrences": 3,
      "prevention_rule": "Always validate input parameters"
    }
  ],
  "recommendations": [
    "Consider adding input validation middleware",
    "Review API contract documentation before implementation"
  ]
}
```

---

## Integration with Cascade Detection

Learning records feed into cascade detection:

```yaml
cascade_detection:
  check_learning_records: true
  similar_failure_threshold: 3
  on_similar_failures: "pause_and_diagnose"
```

When 3+ similar failures are detected, execution pauses and a diagnosis is generated from the learning records.

---

## Cross-Project Learning

When SAGE is used across multiple projects, learnings can be shared:

1. **Export**: `learning_recorder: export` → generates portable JSON
2. **Import**: `learning_recorder: import` → adds external patterns
3. **Merge**: `learning_recorder: merge` → combines pattern databases

This enables organizational learning across teams and projects.
