# Subagent Spawner Component

**Version:** 1.0
**Purpose:** Spawn bounded-context subagents with standardized interfaces

---

## Overview

The Subagent Spawner provides a standardized way to spawn specialized subagents for specific tasks. Each subagent receives bounded context (~4KB) and returns structured output, enabling modular and efficient workflow execution.

---

## Interface

### Spawn Subagent

```yaml
subagent_spawner:
  action: spawn
  subagent_type: "PLANNER" | "IMPLEMENTER" | "TESTER" | "REVIEWER" | "FIXER" | "custom"
  context:
    # Bounded to ~4KB - only what the subagent needs
    story_summary: "..."
    files_to_modify: [...]
    constraints: [...]
  output_schema:
    # Expected output structure
    type: "object"
    required: ["success", "result"]
```

**Output:**
```json
{
  "subagent_id": "planner-7-1-001",
  "subagent_type": "PLANNER",
  "started_at": "2025-12-19T10:30:00Z",
  "result": { ... subagent output ... },
  "completed_at": "2025-12-19T10:32:00Z",
  "tokens_used": {
    "input": 2500,
    "output": 1200
  }
}
```

---

## Subagent Types

### PLANNER

**Purpose:** Decompose a story into executable chunks.

**Context Receives:**
- Story file content (acceptance criteria, tasks)
- Project context (tech stack, patterns)
- Constraints (time, dependencies)

**Returns:**
```json
{
  "success": true,
  "chunk_plan": {
    "story_summary": "Brief summary",
    "total_tasks": 12,
    "chunks": [
      {
        "id": "chunk-01",
        "name": "Setup data model",
        "description": "Create user authentication data structures",
        "tasks": ["1.1", "1.2", "1.3"],
        "files_to_create": ["src/models/user.py"],
        "files_to_modify": ["src/models/__init__.py"],
        "files_to_read": ["src/config.py"],
        "depends_on": [],
        "estimated_complexity": "medium"
      }
    ],
    "execution_order": ["chunk-01", "chunk-02", "chunk-03"],
    "shared_patterns": ["Repository pattern for data access"],
    "notes": "Chunk-03 can parallelize with chunk-02 if needed"
  }
}
```

### IMPLEMENTER

**Purpose:** Implement a specific chunk of work.

**Context Receives:**
- Chunk definition (tasks, files)
- Relevant existing code (bounded)
- Project patterns/conventions

**Returns:**
```json
{
  "success": true,
  "files": [
    {
      "path": "src/models/user.py",
      "action": "create",
      "content": "# Full file content..."
    }
  ],
  "tests_created": ["tests/test_user.py"],
  "commit_message": "feat(auth): add user data model",
  "notes": "Used existing BaseModel pattern"
}
```

### TESTER

**Purpose:** Run and analyze tests, perform integration testing.

**Context Receives:**
- Test output (stdout, stderr)
- Files under test
- Expected behavior

**Returns:**
```json
{
  "success": true,
  "tests_passed": true,
  "test_summary": {
    "total": 15,
    "passed": 15,
    "failed": 0,
    "skipped": 0
  },
  "coverage": {
    "lines": 85,
    "branches": 72
  },
  "notes": "All tests passing"
}
```

### REVIEWER

**Purpose:** Adversarial code review.

**Context Receives:**
- Changed files (diff or full)
- Story requirements
- Project standards

**Returns:**
```json
{
  "success": true,
  "approved": false,
  "issues": [
    {
      "severity": "high",
      "file": "src/auth/login.py",
      "line": 42,
      "issue": "Missing input validation",
      "suggestion": "Add email format validation before DB query"
    }
  ],
  "suggestions": [
    {
      "file": "src/auth/login.py",
      "suggestion": "Consider extracting auth logic to separate function"
    }
  ],
  "approval_blockers": 1,
  "notes": "One high-severity issue must be addressed"
}
```

### FIXER

**Purpose:** Diagnose and fix failures.

**Context Receives:**
- Failure output (test, build, etc.)
- Relevant code
- Previous fix attempts

**Returns:**
```json
{
  "success": true,
  "diagnosis": "Missing return statement in auth handler",
  "files": [
    {
      "path": "src/auth/login.py",
      "action": "modify",
      "content": "# Full file with fix..."
    }
  ],
  "root_cause": "logic",
  "preventable": true,
  "prevention_hint": "Always trace return paths in handlers"
}
```

---

## Bounded Context Guidelines

Each subagent should receive **only what it needs** (~4KB target):

### DO Include:
- Task definition (what to do)
- Directly relevant code (files to modify)
- Patterns/conventions (brief)
- Constraints (explicit limits)

### DO NOT Include:
- Full project context
- Unrelated files
- Historical data (unless needed)
- Verbose documentation

### Context Sizing Example:

```
PLANNER Context (~4KB):
├── Story content: ~1.5KB
├── Epic context: ~0.5KB
├── Tech stack summary: ~0.3KB
├── Constraints: ~0.2KB
├── Available patterns: ~0.5KB
└── Examples (if needed): ~1KB
```

---

## Spawn Protocol

```xml
<spawn-subagent type="{{subagent_type}}">

  <step n="1" name="prepare-context">
    <action>Gather required context for subagent type</action>
    <action>Trim to bounded size (~4KB)</action>
    <action>Validate required fields present</action>
  </step>

  <step n="2" name="construct-prompt">
    <action>Load subagent prompt template</action>
    <action>Inject context into template</action>
    <action>Specify output format</action>
  </step>

  <step n="3" name="spawn">
    <action>
      Use Task tool with:
      - subagent_type: "general-purpose"
      - prompt: {{constructed_prompt}}
    </action>
  </step>

  <step n="4" name="parse-output">
    <action>Parse subagent response as JSON</action>
    <action>Validate against output_schema</action>

    <check if="parse fails">
      <action>Log raw output</action>
      <action>Attempt recovery or request retry</action>
    </check>
  </step>

  <step n="5" name="record-metrics">
    <action>
      metrics_collector: record_tokens
      subagent: "{{subagent_type}}"
      input_tokens: {{input_tokens}}
      output_tokens: {{output_tokens}}
    </action>
  </step>

  <return>
    {
      "subagent_id": "{{id}}",
      "subagent_type": "{{type}}",
      "result": {{parsed_output}},
      "tokens_used": { ... }
    }
  </return>

</spawn-subagent>
```

---

## Usage Example

```xml
<step n="2" name="plan-chunks">
  <output>📋 Spawning PLANNER subagent...</output>

  <action>
    subagent_spawner: spawn
    subagent_type: "PLANNER"
    context:
      story: {{story_content}}
      project_patterns: {{brief_patterns}}
      constraints:
        - "Maximum 5 chunks"
        - "Each chunk < 30 minutes work"
  </action>

  <check if="spawn_result.success == true">
    <action>Store chunk_plan in state</action>
    <action>Set chunk_queue from execution_order</action>
  </check>

  <check if="spawn_result.success == false">
    <action>Log planning failure</action>
    <action>Set error state</action>
  </check>
</step>
```

---

## Error Handling

### Subagent Timeout
- Default timeout: 5 minutes
- On timeout: Log context, return error, allow retry

### Invalid Output
- Attempt JSON repair (common issues: trailing commas, unquoted keys)
- If unrepairable: Return raw output, flag for human review

### Subagent Failure
- Record in learning system
- Allow orchestrator to decide: retry, skip, or abort

---

## Custom Subagents

For domain-specific needs, custom subagents can be defined:

```yaml
subagent_spawner:
  action: spawn
  subagent_type: "custom"
  custom_definition:
    name: "SECURITY_REVIEWER"
    prompt_template: |
      You are a security-focused code reviewer...
    context_requirements:
      - changed_files
      - security_policies
    output_schema:
      type: object
      required: ["vulnerabilities", "recommendations"]
```
