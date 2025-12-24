# Protocol: Epic Lifecycle Orchestration

**ID:** orchestrate_epic
**Critical:** FULL_LIFECYCLE
**Purpose:** Master orchestration flow for complete epic execution

---

## Input/Output

**Input:** epic_file path
**Output:** EPIC_COMPLETE signal or HITL_REQUIRED

---

## Phase 1: DESIGN

1.1. Load epic file
1.2. Create/get milestone (`github_create_milestone`)
1.3. Spawn ANALYST for research
1.4. Collect product brief output
1.5. Checkpoint: phase=1, status=design_complete
1.6. HitL: Create issue for brief approval
1.7. Wait for approval (`github_check_issue_response`)

---

## Phase 2: PLAN

2.1. Spawn PM for PRD creation
2.2. Spawn ARCHITECT for design (if needed)
2.3. Spawn SM for story decomposition
2.4. Checkpoint: phase=2, status=planning_complete
2.5. HitL: Create issue for PRD approval
2.6. Wait for approval
2.7. Clear and resume

---

## Phase 3: BUILD (per story)

3.1. Load stories from epic

3.2. For each story:
  - 3.2.1. Spawn PLANNER for task decomposition
  - 3.2.2. Analyze parallel_plan from PLANNER output
  - 3.2.3. For each task/batch:
    - IF parallel_plan.approved_parallel: `spawn_parallel(batch_tasks)`
    - ELSE: `spawn_sequential(task)`
    - Parse output
    - IF failure: `detect_failure` -> `recovery_execute`
  - 3.2.4. Checkpoint after story complete
  - 3.2.5. Create story PR (`github_create_story_pr`)

3.3. Clear cycle after each story

---

## Phase 4: VALIDATE

4.1. Spawn TESTER for full test suite
4.2. Generate QA report
4.3. Checkpoint: phase=4, status=qa_complete
4.4. HitL: Create issue for merge approval
4.5. Wait for approval
4.6. Create epic PR (epic branch -> dev)
4.7. Generate learning summary
4.8. Close milestone
4.9. Signal EPIC_COMPLETE
