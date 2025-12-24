# SOP-00010: Agent Token Optimization

**Version**: 1.1 | **Type**: Optimization Workflow | **Trigger**: Manual or post-SAGE-update

---

## Purpose

Analyze and optimize agent definitions to minimize token consumption while preserving functionality. Target: 80%+ reduction from naive loading patterns.

---

## Phase 1: Discovery & Measurement

### Step 1.1: Inventory Agents
```bash
find sage/agents -name "*.md" -type f
find .claude/commands -name "*.md" -type f
```

### Step 1.2: Measure Baseline
```bash
# Quick token estimate (words × 1.3)
estimate_tokens() {
  words=$(wc -w < "$1")
  echo "$1: ~$((words * 13 / 10)) tokens"
}
```

---

## Phase 2: Content Analysis

### Identify Non-Essential Content

| Content Type | Essential? | Action |
|--------------|------------|--------|
| Activation steps (XML) | YES | Keep |
| Menu items (XML) | YES | Keep |
| Rules section (XML) | YES | Keep |
| Persona (XML) | YES | Keep |
| Examples with code blocks | NO | Move to docs |
| "Why" explanations | NO | Remove |
| Verbose descriptions | NO | Compress |

### Find Redundancies
- Same rule in activation step AND markdown → Remove markdown
- Same rule across multiple agents → Extract to common-rules
- Repeated procedural logic → Extract to script

---

## Phase 3: Optimization Actions

### 3.1: Trim Agent Files
1. Remove markdown sections outside XML block
2. Remove verbose examples
3. Remove "Why" explanations
4. Remove duplicate rules
5. Keep only: frontmatter, XML activation, XML menu, XML rules

### 3.2: Extract Tool Scripts (if ROI positive)
```
Tokens saved × Expected invocations > Implementation cost
```

---

## Phase 4: Validation

### Metrics
| Metric | Target |
|--------|--------|
| Agent startup tokens | < 3,000 |
| Average agent | < 3,500 |

### Functional Checks
- [ ] Agent activates without errors
- [ ] Menu displays correctly
- [ ] All menu items execute
- [ ] No functionality regression

---

## Quick Reference Checklist

```
□ Measure baseline tokens per agent
□ List non-essential content
□ Find duplicate rules
□ Identify tool extraction candidates
□ Trim each agent to XML-only
□ Measure optimized tokens
□ Functional validation
```

---

## Maintenance

**Frequency**: After SAGE updates or quarterly

**Triggers**: SAGE upgrade, new agent added, startup feels slow, context pressure
