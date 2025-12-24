# Context Budget Protocol

**Protocol ID:** orchestration/context-budget
**Category:** Orchestration
**Purpose:** Define token limits and context clearing triggers

---

## Token Budgets

### Base Load (~2,000 tokens)

Always loaded when assistant starts:
- Agent definition (persona, capabilities)
- Config and state
- Checkpoint summary (if exists)

### Per-Protocol Load (~500-1,500 tokens)

Protocols are loaded on-demand, not all at once:
- Small protocols: ~500 tokens
- Medium protocols: ~1,000 tokens
- Large protocols (complex workflows): ~1,500 tokens

### Total Context Limit

- Soft limit: 40,000 tokens
- Hard limit: Model context window

---

## Context Clear Triggers

### Automatic Triggers

Clear context when ANY of these conditions are met:

| Trigger | Threshold | Action |
|---------|-----------|--------|
| Context size | >40K tokens | Checkpoint + clear |
| Story complete | N/A | Checkpoint + clear |
| Parallel batch | 5+ subagents complete | Checkpoint + clear |
| Phase transition | N/A | Checkpoint + clear |

### Manual Triggers

- User command: `*checkpoint` or `*clear`
- Orchestrator signal: `CHECKPOINT:WRITE`

---

## Clear Sequence

When context clear is triggered:

1. **Write checkpoint**
   ```bash
   checkpoint-write.sh create $EPIC_ID $STORY_ID $PHASE $TASK | \
   checkpoint-write.sh write
   ```

2. **Emit signal**
   ```
   SAGE_SIGNAL:CHECKPOINT:WRITE:$EPIC_ID:$STORY_ID:$PHASE:$TASK
   ```

3. **Output summary**
   ```
   ---
   CHECKPOINT SAVED
   Epic: {{epic_id}} | Story: {{story_id}}
   Phase: {{phase}} | Task: {{task_index}}
   Commit: {{commit_hash}}

   Context cleared. Resuming from checkpoint.
   ---
   ```

4. **Exit cleanly** (orchestrator will restart)

---

## Budget Tracking

### Estimation Rules

| Content Type | Tokens per Unit |
|--------------|-----------------|
| Markdown text | ~4 tokens per line |
| Code | ~5 tokens per line |
| XML/JSON | ~6 tokens per line |
| Images | N/A (not processed) |

### Running Total

Track approximate context size:
- Start: 2,000 (base load)
- Add: Loaded protocols
- Add: User messages
- Add: Tool outputs
- Add: Generated text

When total > 35K, prepare for clear.

---

## Protocol Loading Strategy

### JIT Loading

Load protocols only when needed:

```xml
<!-- BAD: Load everything upfront -->
<load>all protocols</load>

<!-- GOOD: Load on demand -->
<when action="write-checkpoint">
  <load>sage/core/protocols/checkpoint/write-checkpoint.md</load>
</when>
```

### Unloading

After protocol execution:
- Keep reference for potential reuse
- Drop actual content from context
- Reload if needed later

---

## Subagent Context

Subagents get their own context:
- Do NOT pass full conversation history
- Pass only: Current task context, relevant files
- Expect: Structured JSON output only

```xml
<spawn agent="IMPLEMENTER">
  <context>
    - Story requirements: {{story.md}}
    - Current chunk: {{chunk}}
    - Test file: {{test_file}}
  </context>
  <expect>JSON with: files_changed, tests_passed, notes</expect>
</spawn>
```

---

## Recovery from Context Exhaustion

If context exhausted before checkpoint:

1. **Immediate checkpoint** (best effort)
2. **Log warning** with current state
3. **Exit with recoverable error**
4. **Orchestrator restarts** from last valid checkpoint
