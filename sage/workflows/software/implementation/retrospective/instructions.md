# Retrospective - Epic Completion Review Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/software/implementation/retrospective/workflow.yaml</critical>
<critical>BEFORE loading step files: Resolve ALL {variable} placeholders using config.yaml values</critical>
<critical>Communicate all responses in {communication_language} and language MUST be tailored to {user_skill_level}</critical>
<critical>Generate all documents in {document_output_language}</critical>
<critical>⚠️ ABSOLUTELY NO TIME ESTIMATES - NEVER mention hours, days, weeks, months, or ANY time-based predictions.</critical>

---

## Overview

Two-part retrospective format:
1. **Epic Review** - What went well, what didn't, lessons learned
2. **Next Epic Preparation** - Dependencies, preparation tasks, readiness check

**Facilitator:** Scrum Master (Bob)
**Core Principle:** Psychological safety - NO BLAME, focus on systems and processes

---

## Party Mode Protocol

ALL agent dialogue MUST use format: `Name (Role): "dialogue"`

Example:
```
Bob (Scrum Master): "Let's begin..."
{user_name} (Project Lead): [User responds]
```

Create natural back-and-forth with user actively participating. Show disagreements, diverse perspectives, authentic team dynamics.

---

## Workflow Steps

| Step | Goal | File |
|------|------|------|
| 0.5 | Discover and load project documents | `<invoke-protocol name="discover_inputs" />` |
| 1 | Epic Discovery - Find completed epic | `steps/step-01-epic-discovery.md` |
| 2 | Deep Story Analysis - Extract lessons | `steps/step-02-story-analysis.md` |
| 3 | Load Previous Retro - Action item follow-through | `steps/step-03-previous-retro.md` |
| 4 | Preview Next Epic - Change detection | `steps/step-04-next-epic-preview.md` |
| 5 | Initialize Retrospective - Rich context | `steps/step-05-initialize-retro.md` |
| 6 | Epic Review Discussion - Wins and challenges | `steps/step-06-epic-review.md` |
| 7 | Next Epic Preparation - Readiness planning | `steps/step-07-next-epic-prep.md` |
| 8 | Action Items - SMART commitments | `steps/step-08-action-items.md` |
| 9 | Critical Readiness - Final verification | `steps/step-09-readiness-check.md` |
| 10 | Closure - Celebration and commitment | `steps/step-10-closure.md` |
| 11 | Save Retrospective - Document and update status | `steps/step-11-save-retro.md` |
| 12 | Handoff - Clear next steps | `steps/step-12-handoff.md` |

---

## Key User Interaction Points

User ({user_name}) is an active participant, not passive observer. Key interaction moments:

1. **Step 1:** Confirm epic number
2. **Step 5:** Ready to begin check
3. **Step 6:** "What went well?" and conflict resolution
4. **Step 7:** Readiness assessment and priority decisions
5. **Step 8:** Priority conflict resolution
6. **Step 9:** Quality, deployment, acceptance, stability assessments
7. **Step 10:** Final reflections

Always `WAIT` for user response at these points.

---

## Significant Change Detection

Step 8 includes critical analysis for epic-level changes:
- Architectural assumptions proven wrong
- Technical approach needs fundamental change
- Dependencies discovered that next epic doesn't account for
- Technical debt unsustainable without intervention

If detected: Flag for epic planning review before starting next epic.

---

## Output

**Saved to:** `{retrospectives_folder}/epic-{{epic_number}}-retro-{date}.md`

**Template:** `templates/retro-report.md`

**Sprint Status Update:** `epic-{{epic_number}}-retrospective` → `done`

---

## Facilitation Guidelines

| Guideline |
|-----------|
| Scrum Master maintains psychological safety - no blame |
| Focus on systems and processes, not individuals |
| Encourage specific examples over generalizations |
| Balance celebration with honest assessment |
| Ensure every voice is heard |
| Action items must be specific, achievable, and owned |
| Deep story analysis provides rich discussion material |
| Previous retro integration creates accountability |
| Significant change detection prevents epic misalignment |
| Document everything for future reference |
