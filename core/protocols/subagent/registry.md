# Subagent Registry Protocol

**Protocol ID:** subagent/registry
**Category:** Subagent Management
**Purpose:** Define available subagents and their roles

---

## Registry

| ID | Phase | Parallel | Role |
|----|-------|----------|------|
| ANALYST | 1 (DESIGN) | No | Research, product brief creation |
| PM | 2 (PLAN) | No | PRD creation, requirements |
| ARCHITECT | 2 (PLAN) | No | Architecture design, tech decisions |
| UX_DESIGNER | 2 (PLAN) | Yes | UX/UI design, wireframes |
| SM | 2 (PLAN) | No | Sprint planning, story creation |
| PLANNER | 3 (BUILD) | Yes | Story/task decomposition |
| IMPLEMENTER | 3 (BUILD) | Conditional | TDD implementation |
| TESTER | 3 (BUILD) | Yes | Test execution |
| FIXER | 3 (BUILD) | No | Fix failing tests |
| REVIEWER | 3 (BUILD) | No | Code review |
| VALIDATOR | 4 (VALIDATE) | No | Epic validation |

---

## Lifecycle Phases

### Phase 1: DESIGN
- **Goal**: Understand requirements
- **Subagents**: ANALYST
- **Output**: Product brief, research docs

### Phase 2: PLAN
- **Goal**: Design solution
- **Subagents**: PM, ARCHITECT, UX_DESIGNER, SM
- **Output**: PRD, architecture, stories

### Phase 3: BUILD
- **Goal**: Implement stories
- **Subagents**: PLANNER, IMPLEMENTER, TESTER, FIXER, REVIEWER
- **Output**: Working code, tests

### Phase 4: VALIDATE
- **Goal**: Verify epic complete
- **Subagents**: VALIDATOR
- **Output**: Validation report

---

## Parallel Execution Rules

### Always Sequential
- ANALYST → PM → ARCHITECT (dependency chain)
- FIXER (requires specific failure context)
- REVIEWER (requires complete implementation)

### Always Parallel
- PLANNER (multiple stories can plan simultaneously)
- TESTER (multiple test suites)
- UX_DESIGNER (independent of backend)

### Conditional Parallel
- IMPLEMENTER: Parallel within same story if chunks are independent

---

## Subagent Invocation

### Using Task Tool

```python
# Sequential
Task(
    subagent_type="software-dev",
    prompt="Implement feature X per story requirements..."
)

# Parallel (single message with multiple)
Task(subagent_type="software-dev", prompt="...chunk 1...")
Task(subagent_type="software-dev", prompt="...chunk 2...")
```

### Expected Output Format

All subagents return JSON:

```json
{
  "status": "success|partial|failed",
  "result": { ... subagent-specific ... },
  "files_changed": ["path/to/file.ts"],
  "notes": "Human-readable summary"
}
```

---

## Subagent Context Requirements

### Minimum Context

Every subagent invocation must include:
- Current epic/story ID
- Relevant acceptance criteria
- Files to focus on

### Maximum Context

Do not include:
- Full conversation history
- Unrelated files
- Other stories' details

---

## Error Handling

### Subagent Failures

| Failure Type | Action |
|--------------|--------|
| JSON parse error | Log, retry once with explicit JSON instruction |
| Task incomplete | Mark partial, continue or fail based on criticality |
| Timeout | Kill task, mark failed |
| Context overflow | Reduce context, retry |

### Retry Policy

- Max retries: 2
- Backoff: None (immediate retry with adjusted prompt)
- Escalation: After max retries, mark failed and continue or halt

---

## Agent File Locations

All subagent definitions in: `sage/agents/`

| ID | File |
|----|------|
| ANALYST | software/analyst.md |
| PM | software/pm.md |
| ARCHITECT | software/architect.md |
| UX_DESIGNER | software/ux-designer.md |
| SM | software/sm.md |
| DEV (IMPLEMENTER) | software/dev.md |
| TESTER | software/tea.md |
| REVIEWER | software/dev.md (review mode) |
