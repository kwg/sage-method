# JIT Loading Standard

**Version:** 1.0
**Status:** ACTIVE
**Applies to:** All workflow.yaml files

---

## Purpose

Defines the Just-In-Time (JIT) loading strategies for SAGE workflows to optimize context usage and reduce token consumption.

---

## Load Strategies

### FULL_LOAD

Load the entire document when the workflow starts.

**Use when:**
- Document is small (<500 lines)
- All content is relevant to the workflow
- Example: Architecture decisions, style guides

```yaml
architecture:
  whole: "{output_folder}/*architecture*.md"
  load_strategy: "FULL_LOAD"
```

### SELECTIVE_LOAD

Load only the specific section/file needed for the current step.

**Use when:**
- Large documents with multiple sections
- Only one epic/story relevant to current task
- Example: Epic files, story files

```yaml
epics:
  whole: "{output_folder}/*epic*.md"
  sharded_single: "{output_folder}/*epic*/epic-{{epic_num}}.md"
  load_strategy: "SELECTIVE_LOAD"
```

### INDEX_GUIDED

Load index first, then selectively load sections as needed.

**Use when:**
- Brownfield project documentation
- Very large document sets
- Unknown structure requiring exploration

```yaml
document_project:
  sharded: "{output_folder}/index.md"
  load_strategy: "INDEX_GUIDED"
```

---

## Workflow-Level Declaration

Add to workflow.yaml after `standalone`:

```yaml
standalone: true

# JIT Loading Strategy
load_strategy: SELECTIVE_LOAD  # Description of what gets loaded when
```

---

## Patterns by Workflow Type

| Workflow Type | Default Strategy | Reason |
|---------------|------------------|--------|
| Research | FULL_LOAD | Need complete context for analysis |
| Dev Story | SELECTIVE_LOAD | Only load current story + deps |
| Code Review | SELECTIVE_LOAD | Load only reviewed code |
| Sprint Planning | INDEX_GUIDED | Scan all stories, load details as needed |
| Architecture | FULL_LOAD | Design decisions needed upfront |

---

## Validation

Workflows should declare load_strategy at both:
1. Workflow level (default for workflow)
2. Input file pattern level (specific overrides)

Example:
```yaml
load_strategy: SELECTIVE_LOAD  # Workflow default

input_file_patterns:
  architecture:
    load_strategy: "FULL_LOAD"  # Override: always need full arch
  epics:
    load_strategy: "SELECTIVE_LOAD"  # Follow default
```
