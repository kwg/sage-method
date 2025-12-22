# SOP-00014: Workflow Token Optimization

**Version**: 1.0 | **Type**: Optimization Workflow | **Trigger**: Manual or post-SAGE-update

---

## Purpose

Analyze and optimize workflow files (YAML configs, XML instructions, checklists) to minimize token consumption during execution.

**Token cost layers**:
1. workflow.yaml - Config loaded every execution
2. instructions.xml - Full instruction set parsed
3. checklist.md - Validation content loaded
4. input_file_patterns - Files discovered and loaded
5. Runtime context - Story files, project context, sprint status

---

## Phase 1: Discovery & Baseline

### Inventory Workflows
```bash
find sage/workflows -name "workflow.yaml" -type f
find sage/workflows -name "instructions.*" -type f
find sage/workflows -name "checklist.md" -type f
```

### Measure Token Cost
```bash
estimate_workflow() {
  dir="$1"; total=0
  for f in "$dir"/*.yaml "$dir"/*.xml "$dir"/*.md; do
    [[ -f "$f" ]] || continue
    words=$(wc -w < "$f")
    tokens=$((words * 13 / 10))
    total=$((total + tokens))
    echo "  $(basename "$f"): ~$tokens tokens"
  done
  echo "  TOTAL: ~$total tokens"
}
```

---

## Phase 2: Content Analysis

### Verbose Patterns to Fix

| Pattern | Problem | Solution |
|---------|---------|----------|
| Repeated `<critical>` tags | Same rule 3+ times | Consolidate to one |
| 50+ word `<action>` | Verbose actions | Compress to 15-20 words |
| Embedded examples | Inflate instructions | Move to docs |
| Duplicate logic | Copy-paste across steps | Extract to protocol |

### Input Pattern Optimization

| Strategy | Token Impact | When to Use |
|----------|--------------|-------------|
| FULL_LOAD | High | Only if ALL content needed |
| SELECTIVE_LOAD | Low | When specific shard known |
| INDEX_GUIDED | Medium | When relevance varies |

---

## Phase 3: Optimization Strategies

### 3.1: Compress Instructions
**Before**: `<action>Load comprehensive context from story file's Dev Notes section including architecture requirements, previous learnings, and technical specifications...</action>`

**After**: `<action>Load Dev Notes: architecture, learnings, tech specs</action>`

**Rules**: Actions 10-25 words max, remove qualifiers, focus on "what" not "why"

### 3.2: Consolidate Rules
Move repeated `<critical>` tags to single `<rules>` block at workflow top.

### 3.3: Extract Protocols
If 3+ workflows share logic, extract to reusable protocol:
```xml
<invoke-protocol name="load_sprint_status" />
```

### 3.4: Lazy Loading
Load context on-demand, not all at step 1.

### 3.5: Compress Checklists
Convert verbose prose to terse bullets. Target: <50% original word count.

---

## Phase 4: Validation

### Metrics
| Workflow Type | Target Static Cost |
|---------------|-------------------|
| Simple (status, diagrams) | < 1,000 tokens |
| Medium (create-story) | < 2,500 tokens |
| Complex (dev-story, code-review) | < 4,000 tokens |

### Checks
- [ ] workflow.yaml parses
- [ ] instructions.xml valid XML
- [ ] All step references resolve
- [ ] Protocol invocations work
- [ ] Checklist items actionable

---

## Quick Reference Checklist

```
□ Inventory workflows and measure baseline
□ Find verbose patterns in instructions
□ Analyze input file patterns
□ Find redundant cross-workflow content
□ Apply compression strategies
□ Measure optimized tokens (target: 30-50% reduction)
□ Functional validation
```

---

## Extracted Protocols

| Protocol | Purpose | Used By |
|----------|---------|---------|
| init_sprint_tracking | Initialize sprint tracking | dev-story, code-review, create-story |
| update_story_status | Update story in sprint-status.yaml | dev-story, code-review |
| find_ready_story | Find next ready-for-dev story | dev-story, create-story |

---

## Maintenance

**Frequency**: After SAGE updates or quarterly

**Triggers**: SAGE upgrade, new workflows, execution feels slow, context pressure
