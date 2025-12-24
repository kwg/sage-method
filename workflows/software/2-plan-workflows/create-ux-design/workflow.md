---
name: create-ux-design
version: "2.0-stepped"
description: Work with a peer UX Design expert to plan your applications UX patterns, look and feel.
main_config: '{project-root}/sage/core/config.yaml'
web_bundle: true

# Core Component References (Phase 2 workflows use minimal set)
components:
  state_tracking: "output_file_frontmatter"  # Uses document frontmatter, not JSON state
  retry: "sage/core/components/retry-handler.md"  # For recovery on failures
  # Note: metrics-collector and learning-recorder used only in Phase 3/4
---

# Create UX Design Workflow

**Goal:** Create comprehensive UX design specifications through collaborative visual exploration and informed decision-making where you act as a UX facilitator working with a product stakeholder.

---

## WORKFLOW ARCHITECTURE

This uses **micro-file architecture** for disciplined execution:

- Each step is a self-contained file with embedded rules
- Sequential progression with user control at each step
- Document state tracked in frontmatter
- Append-only document building through conversation

---

## INITIALIZATION

### Configuration Loading

Load config from `{project-root}/sage/core/config.yaml` and resolve:

- `project_name`, `output_folder`, `user_name`
- `communication_language`, `document_output_language`, `user_skill_level`
- `date` as system-generated current datetime

### Paths

- `installed_path` = `{project-root}/sage/workflows/software/2-plan-workflows/create-ux-design`
- `template_path` = `{installed_path}/ux-design-template.md`
- `default_output_file` = `{output_folder}/ux-design-specification.md`

### Output Files

- Color themes: `{output_folder}/ux-color-themes.html`
- Design directions: `{output_folder}/ux-design-directions.html`

### Input Document Discovery

Discover context documents for UX context (Priority: Analysis folder first, then main folder, then sharded):

- PRD: `{output_folder}/analysis/*prd*.md` or `{output_folder}/*prd*.md` or `{output_folder}/*prd*/**/*.md`
- Product brief: `{output_folder}/analysis/*brief*.md` or `{output_folder}/*brief*.md` or `{output_folder}/*brief*/**/*.md`
- Epics: `{output_folder}/analysis/*epic*.md` or `{output_folder}/*epic*.md` or `{output_folder}/*epic*/**/*.md`
- Research: `{output_folder}/analysis/research/*research*.md` or `{output_folder}/*research*.md` or `{output_folder}/*research*/**/*.md`
- Brainstorming: `{output_folder}/analysis/brainstorming/*brainstorming*.md` or `{output_folder}/*brainstorming*.md`

---

## EXECUTION

Load and execute `steps/step-01-init.md` to begin the UX design workflow.
