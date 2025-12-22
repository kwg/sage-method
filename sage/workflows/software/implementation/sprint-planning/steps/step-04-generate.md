# Step 04: Generate Sprint Status File

**Goal:** Create or update the sprint-status.yaml file.

---

## EMBEDDED RULES

- Metadata appears TWICE: once as comments for documentation, once as YAML fields
- Items ordered: epic, its stories, its retrospective, next epic
- Valid YAML syntax required

---

## ACTIONS

### 1. Prepare File Content

Create the sprint status file with this structure:

```yaml
# generated: {date}
# project: {project_name}
# project_key: {project_key}
# tracking_system: {tracking_system}
# story_location: {story_location}

# STATUS DEFINITIONS:
# ==================
# Epic Status:
#   - backlog: Epic not yet started
#   - in-progress: Epic actively being worked on
#   - done: All stories in epic completed
#
# Story Status:
#   - backlog: Story only exists in epic file
#   - drafted: Story file created in stories folder
#   - ready-for-dev: Draft approved and story context created
#   - in-progress: Developer actively working on implementation
#   - review: Ready for code review
#   - done: Story completed
#
# Retrospective Status:
#   - optional: Can be completed but not required
#   - completed: Retrospective has been done

generated: {date}
project: {project_name}
project_key: {project_key}
tracking_system: {tracking_system}
story_location: {story_location}

development_status:
  # Epic 1
  epic-1: {status}
  1-1-story-title: {status}
  1-2-story-title: {status}
  epic-1-retrospective: optional

  # Epic 2
  epic-2: {status}
  # ... stories ...
  epic-2-retrospective: optional
```

### 2. Write File

Write the complete sprint status YAML to `{sprint_artifacts}/sprint-status.yaml`

### 3. Confirm Write

Verify file was written successfully by checking file exists and is valid YAML.

### 4. Update State

```json
{
  "current_step": 4,
  "completed_steps": ["01-discover", "02-parse", "03-detect", "04-generate"],
  "output_file": "{sprint_artifacts}/sprint-status.yaml",
  "file_written": true
}
```

---

## NEXT STEP

Load and execute `step-05-validate.md` to validate and report.
