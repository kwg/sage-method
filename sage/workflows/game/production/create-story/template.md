# Story {{epic_num}}.{{story_num}}: {{story_title}}

Status: drafted

## Story

As a {{role}},
I want {{action}},
so that {{benefit}}.

## Acceptance Criteria

1. [Add acceptance criteria from epics/PRD]

## UI/UX

<!--
  UI Status Values:
  - none: Story has no UI component
  - wireframe: Basic layout only, no assets
  - placeholder: Using placeholder/temp assets
  - final: Final art integrated
-->

**Status:** none
**Mockup:** N/A
**Design Spec:** N/A

### Assets

<!-- Populated by Pixel's *export-specs workflow. Format:
| Element | Catalog ID | Godot Path | Status |
|---------|------------|------------|--------|
| Button  | wooden-ui  | res://...  | placeholder |
-->

| Element | Catalog ID | Godot Path | Status |
|---------|------------|------------|--------|
| N/A | - | - | - |

## Tasks / Subtasks

- [ ] Task 1 (AC: #)
  - [ ] Subtask 1.1
- [ ] Task 2 (AC: #)
  - [ ] Subtask 2.1

## Agent Tests

<!-- Visual verification tests for autonomous QA. See docs/workflows/agent-testing-workflow.md for schema. -->

### {{test_name}}
**Description:** {{what_this_test_verifies}}
**Scene:** {{starting_scene}}
**Commands:**
- game goto {{scene}}
- wait 1000
- game state
- screenshot {{test_name}}_verify

**Verify:**
- {{expected_state_output}}
- No SCRIPT ERROR

## Dev Notes

- Relevant architecture patterns and constraints
- Source tree components to touch
- Testing standards summary

### Project Structure Notes

- Alignment with unified project structure (paths, modules, naming)
- Detected conflicts or variances (with rationale)

### References

- Cite all technical details with source paths and sections, e.g. [Source: docs/<file>.md#Section]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### Workflow Documentation

<!--
  EMBEDDED DOCUMENTATION: Each agent documents their own domain as part of task completion.
  No dedicated Tech Writer - the implementer captures context that would be lost in handoff.

  Fill in during implementation:
  - Translation decisions (e.g., Penpot mockup → Godot properties)
  - Patterns discovered or applied
  - Why certain approaches were chosen over alternatives
  - Gotchas, edge cases, or workarounds
  - Anything a future agent/developer would need to know

  This section becomes the spec for future tooling automation.
-->

### File List
