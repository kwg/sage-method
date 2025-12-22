# Epic {{epic_number}} Retrospective Report

**Date:** {{date}}
**Epic:** {{epic_number}} - {{epic_title}}
**Status:** {{epic_status}}

---

## Team Participants

{{list_participating_agents}}
- {user_name} (Project Lead)

---

## Epic Summary

### Delivery Metrics

| Metric | Actual | Planned |
|--------|--------|---------|
| Stories Completed | {{completed_stories}}/{{total_stories}} | {{planned_stories}} |
| Story Points | {{actual_points}} | {{planned_points}} |
| Sprints | {{actual_sprints}} | {{planned_sprints}} |
| Velocity | {{points_per_sprint}} pts/sprint | - |

### Quality Metrics

| Metric | Value |
|--------|-------|
| Blockers Encountered | {{blocker_count}} |
| Technical Debt Items | {{debt_count}} |
| Test Coverage | {{coverage_info}} |
| Production Incidents | {{incident_count}} |

### Business Outcomes

| Goal | Status |
|------|--------|
{{#each goals}}
| {{this.name}} | {{this.status}} |
{{/each}}

---

## What Went Well

{{#each success_themes}}
- {{this}}
{{/each}}

---

## Challenges and Growth Areas

{{#each challenge_themes}}
- {{this}}
{{/each}}

---

## Key Insights

{{#each insight_themes}}
1. **{{this.title}}**: {{this.description}}
{{/each}}

---

{{#if prev_retro_exists}}
## Previous Retrospective Follow-Through

**Epic {{prev_epic_num}} Action Items:**

| Action Item | Status | Impact |
|-------------|--------|--------|
{{#each prev_action_items}}
| {{this.description}} | {{this.status}} | {{this.impact}} |
{{/each}}

**Lessons Applied:** {{lessons_applied_count}}/{{lessons_total_count}}
**Process Improvements Effective:** {{improvements_effective_count}}/{{improvements_total_count}}
{{/if}}

---

{{#if next_epic_exists}}
## Next Epic Preview

**Epic {{next_epic_num}}:** {{next_epic_title}}

### Dependencies on This Epic
{{#each dependencies}}
- {{this}}
{{/each}}

### Preparation Required
{{#each preparation_items}}
- [ ] {{this.description}} (Owner: {{this.owner}}, Est: {{this.estimate}})
{{/each}}

### Technical Prerequisites
{{#each technical_prereqs}}
- {{this}}
{{/each}}
{{/if}}

---

## Action Items

### Process Improvements

{{#each process_action_items}}
| # | Action | Owner | Deadline | Success Criteria |
|---|--------|-------|----------|------------------|
| {{@index}} | {{this.description}} | {{this.owner}} | {{this.deadline}} | {{this.criteria}} |
{{/each}}

### Technical Debt

{{#each debt_items}}
| # | Item | Owner | Priority | Effort |
|---|------|-------|----------|--------|
| {{@index}} | {{this.description}} | {{this.owner}} | {{this.priority}} | {{this.effort}} |
{{/each}}

### Documentation

{{#each doc_items}}
- [ ] {{this.description}} (Owner: {{this.owner}}, Due: {{this.deadline}})
{{/each}}

### Team Agreements

{{#each team_agreements}}
- {{this}}
{{/each}}

---

{{#if next_epic_exists}}
## Epic {{next_epic_num}} Preparation Tasks

### Critical (Must Complete Before Epic)
{{#each critical_prep}}
- [ ] {{this.description}} | Owner: {{this.owner}} | Est: {{this.estimate}}
{{/each}}

### Parallel (During Early Stories)
{{#each parallel_prep}}
- [ ] {{this.description}} | Owner: {{this.owner}} | Est: {{this.estimate}}
{{/each}}

### Nice-to-Have
{{#each nice_to_have_prep}}
- [ ] {{this.description}}
{{/each}}

**Total Critical Prep Effort:** {{critical_hours}} hours ({{critical_days}} days)
{{/if}}

---

## Critical Path

{{#each critical_path_items}}
| # | Item | Owner | Must Complete By |
|---|------|-------|------------------|
| {{@index}} | {{this.description}} | {{this.owner}} | {{this.deadline}} |
{{/each}}

---

{{#if significant_discoveries}}
## ⚠️ Significant Discoveries

**Epic Update Required:** YES

### Changes Identified
{{#each significant_discoveries}}
1. **{{this.change}}**
   - Impact: {{this.impact}}
{{/each}}

### Assumptions Invalidated
| We Assumed | Reality Revealed |
|------------|------------------|
{{#each wrong_assumptions}}
| {{this.assumption}} | {{this.reality}} |
{{/each}}

### Recommended Actions
1. Review and update Epic {{next_epic_num}} definition
2. Update affected stories to reflect reality
3. Hold alignment session with Product Owner
4. Update PRD/Architecture if applicable
{{/if}}

---

## Readiness Assessment

| Area | Status | Action Needed |
|------|--------|---------------|
| Testing & Quality | {{quality_status}} | {{quality_action}} |
| Deployment | {{deployment_status}} | {{deployment_action}} |
| Stakeholder Acceptance | {{acceptance_status}} | {{acceptance_action}} |
| Technical Health | {{stability_status}} | {{stability_action}} |
| Unresolved Blockers | {{blocker_status}} | {{blocker_action}} |

---

## Summary

**Commitments Made:**
- Action Items: {{action_count}}
- Preparation Tasks: {{prep_task_count}}
- Critical Path Items: {{critical_count}}

**Next Steps:**
1. Execute Preparation Sprint (Est: {{prep_days}} days)
2. Complete Critical Path items before Epic {{next_epic_num}}
3. Review action items in next standup
{{#if epic_update_needed}}
4. **IMPORTANT:** Hold Epic {{next_epic_num}} planning review session
{{else}}
4. Begin Epic {{next_epic_num}} planning when preparation complete
{{/if}}

---

*Generated by SAGE Retrospective Workflow*
