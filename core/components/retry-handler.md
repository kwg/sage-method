# Retry Handler Component

**Version:** 1.0
**Purpose:** Configurable retry logic with escalation and learning integration

---

## Overview

The Retry Handler provides standardized retry behavior for operations that may fail transiently. It tracks attempts, applies configurable limits, and integrates with the Learning Recorder for failure analysis.

---

## Interface

### Execute with Retry

```yaml
retry_handler:
  operation: "test" | "review" | "build" | "custom"
  max_retries: 3  # Default based on operation type
  on_failure: "learning-recorder"  # Component to call on final failure
  action: "execute"

  # Operation-specific configuration
  command: "nix develop --command pytest"  # for test/build
  # OR
  subagent_prompt: "..."  # for review/custom
```

**Output (Success):**
```json
{
  "success": true,
  "attempts": 1,
  "result": { ... operation output ... }
}
```

**Output (Failure after retries):**
```json
{
  "success": false,
  "attempts": 3,
  "final_error": "All tests failed: 5 assertions failed in test_auth.py",
  "learning_record_id": "lr-2025-12-19-001",
  "escalation_required": true
}
```

---

## Default Retry Limits by Operation

| Operation | Max Retries | Notes |
|-----------|-------------|-------|
| `test` | 3 | Spawns FIX subagent between attempts |
| `review` | 2 | Allows iteration on feedback |
| `build` | 1 | Usually deterministic - 1 retry for transient issues |
| `custom` | Configurable | Must specify max_retries |

---

## Retry Logic

```xml
<retry-loop operation="{{operation}}" max="{{max_retries}}">

  <attempt n="current">
    <action>Execute operation</action>
    <action>Capture result, stdout, stderr, exit_code</action>
  </attempt>

  <on-success>
    <return>
      {
        "success": true,
        "attempts": {{current_attempt}},
        "result": {{operation_result}}
      }
    </return>
  </on-success>

  <on-failure if="current_attempt < max_retries">
    <output>⚠️ {{operation}} failed (attempt {{current_attempt}}/{{max_retries}})</output>

    <check if="operation == 'test'">
      <action>Spawn FIX subagent with failure context</action>
      <action>Apply fix if successful</action>
    </check>

    <check if="operation == 'review'">
      <action>Apply review feedback</action>
    </check>

    <action>Increment attempt counter</action>
    <action>Continue to next attempt</action>
  </on-failure>

  <on-final-failure>
    <output>❌ {{operation}} failed after {{max_retries}} attempts</output>

    <action>Create learning record via learning-recorder:
      {
        "failure_type": "{{operation}}",
        "context": {
          "error": "{{final_error}}",
          "attempts": {{max_retries}},
          "files_involved": [...]
        }
      }
    </action>

    <return>
      {
        "success": false,
        "attempts": {{max_retries}},
        "final_error": "{{error_summary}}",
        "learning_record_id": "{{record_id}}",
        "escalation_required": true
      }
    </return>
  </on-final-failure>

</retry-loop>
```

---

## Cascade Detection

When integrated with an orchestrator, the retry handler can trigger cascade detection:

```yaml
retry_handler:
  cascade_detection:
    enabled: true
    threshold: 3  # failures within window
    window_size: 5  # items (stories, chunks, etc.)
    on_cascade: "pause_and_alert"
```

**Cascade Response:**
```json
{
  "cascade_detected": true,
  "failures_in_window": 4,
  "threshold": 3,
  "action": "pause_and_alert",
  "diagnosis": "Multiple test failures detected. Possible root cause: ...",
  "recommendation": "Review architecture or dependencies before continuing"
}
```

---

## Fix Subagent Integration

For `test` operations, the retry handler spawns a FIX subagent:

```xml
<fix-subagent>
  <prompt>
You are a TEST FIX SPECIALIST. Analyze failing tests and fix the implementation.

## Test Output
```
{{test_stdout}}
{{test_stderr}}
```

## Files Modified
{{modified_files}}

## Instructions
1. Analyze the test failure output carefully
2. Identify the root cause - usually in implementation, not tests
3. Read the relevant implementation files
4. Apply minimal fixes to make tests pass
5. Do NOT refactor unrelated code

## Output Format
Return JSON:
```json
{
  "success": true,
  "diagnosis": "Brief explanation of what went wrong and the fix",
  "files": [
    {
      "path": "relative/path/to/file",
      "action": "modify",
      "content": "FULL file content with fix applied"
    }
  ]
}
```
  </prompt>
</fix-subagent>
```

---

## Usage Example

```xml
<step n="3" name="run-tests-with-retry">
  <action>
    Use retry-handler with:
    - operation: "test"
    - command: "nix develop --command pytest"
    - max_retries: 3
  </action>

  <check if="retry_result.success == true">
    <output>✅ Tests passed on attempt {{retry_result.attempts}}</output>
    <action>Update metrics: tests_passed = true</action>
    <action>Continue to next phase</action>
  </check>

  <check if="retry_result.success == false">
    <output>❌ Tests failed after {{retry_result.attempts}} attempts</output>
    <action>Update metrics: tests_passed = false</action>
    <action>Record learning: {{retry_result.learning_record_id}}</action>

    <check if="retry_result.cascade_detected">
      <action>Pause execution and alert user</action>
    </check>
  </check>
</step>
```

---

## State Integration

Retry state is tracked in the workflow state for resumability:

```json
{
  "current_operation": "test",
  "retry_attempt": 2,
  "retry_history": [
    {
      "attempt": 1,
      "error": "AssertionError in test_login",
      "fix_applied": "Fixed missing return statement"
    }
  ]
}
```
