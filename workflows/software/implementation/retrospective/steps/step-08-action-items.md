# Step 8: Synthesize Action Items with Significant Change Detection

**Goal:** Create specific, achievable action items with clear ownership

---

## Action Item Requirements

All action items must have:

| Field | Description |
|-------|-------------|
| Description | Clear description of the action |
| Owner | Specific agent or role |
| Timeline | Deadline |
| Success Criteria | How we'll know it's done |
| Category | process, technical, documentation, team |

---

## SMART Criteria

Ensure action items are:
- **S**pecific: Clear and unambiguous
- **M**easurable: Can verify completion
- **A**chievable: Realistic given constraints
- **R**elevant: Addresses real issues from retro
- **T**ime-bound: Has clear deadline

---

## Action Item Categories

### Process Improvements

```xml
<output>
**Process Improvements:**

1. {{action_item_1}}
   Owner: {{agent_1}}
   Deadline: {{timeline_1}}
   Success criteria: {{criteria_1}}

2. {{action_item_2}}
   Owner: {{agent_2}}
   Deadline: {{timeline_2}}
   Success criteria: {{criteria_2}}
</output>
```

Allow timeline negotiation - bring user in for decisions if needed.

### Technical Debt

```xml
<output>
**Technical Debt:**

1. {{debt_item_1}}
   Owner: {{agent_3}}
   Priority: {{priority_1}}
   Estimated effort: {{effort_1}}

2. {{debt_item_2}}
   Owner: {{agent_4}}
   Priority: {{priority_2}}
   Estimated effort: {{effort_2}}
</output>
```

For priority conflicts:
```xml
<output>
Bob (Scrum Master): "{user_name}, this is a priority call. Testing impact vs. {{reasoning}} -
how do you want to prioritize it?"
</output>
<action>WAIT for {user_name} to help resolve</action>
```

### Documentation

```xml
<output>
**Documentation:**
1. {{doc_need_1}}
   Owner: {{agent_5}}
   Deadline: {{timeline_3}}
</output>
```

### Team Agreements

```xml
<output>
**Team Agreements:**
- {{agreement_1}}
- {{agreement_2}}
- {{agreement_3}}
</output>
```

---

## Epic Preparation Tasks

```xml
<output>
🚀 EPIC {{next_epic_num}} PREPARATION TASKS:

**Technical Setup:**
[ ] {{setup_task_1}} | Owner: {{owner_1}} | Est: {{est_1}}
[ ] {{setup_task_2}} | Owner: {{owner_2}} | Est: {{est_2}}

**Knowledge Development:**
[ ] {{research_task_1}} | Owner: {{owner_3}} | Est: {{est_3}}

**Cleanup/Refactoring:**
[ ] {{refactor_task_1}} | Owner: {{owner_4}} | Est: {{est_4}}

**Total Estimated Effort:** {{total_hours}} hours ({{total_days}} days)
</output>
```

---

## Critical Path

```xml
<output>
⚠️ CRITICAL PATH:

**Blockers to Resolve Before Epic {{next_epic_num}}:**

1. {{critical_item_1}}
   Owner: {{critical_owner_1}}
   Must complete by: {{critical_deadline_1}}

2. {{critical_item_2}}
   Owner: {{critical_owner_2}}
   Must complete by: {{critical_deadline_2}}
</output>
```

---

## Significant Change Detection

**CRITICAL ANALYSIS** - Check if discoveries require epic updates:

| Condition | Impact |
|-----------|--------|
| Architectural assumptions proven wrong | Epic redesign needed |
| Major scope changes occurred | Next epic may be affected |
| Technical approach needs fundamental change | Stories need rewrite |
| Undiscovered dependencies | Blocking risk |
| User needs different than understood | Requirements change |
| Performance/scalability concerns | Design changes |
| Security/compliance issues | Approach change |
| Integration assumptions incorrect | Technical risk |
| Team capacity gaps more severe | Scope adjustment |
| Technical debt unsustainable | Intervention required |

---

## Significant Discovery Alert

```xml
<check if="significant discoveries detected">
  <output>
🚨 SIGNIFICANT DISCOVERY ALERT 🚨

**Significant Changes Identified:**
1. {{significant_change_1}}
   Impact: {{impact_description_1}}

2. {{significant_change_2}}
   Impact: {{impact_description_2}}

**Impact on Epic {{next_epic_num}}:**

Current plan assumes:
- {{wrong_assumption_1}}
- {{wrong_assumption_2}}

But Epic {{epic_number}} revealed:
- {{actual_reality_1}}
- {{actual_reality_2}}

**RECOMMENDED ACTIONS:**
1. Review and update Epic {{next_epic_num}} definition
2. Update affected stories to reflect reality
3. Consider updating architecture/technical specs
4. Hold alignment session with Product Owner
5. Update PRD sections if applicable

**Epic Update Required**: YES - Schedule epic planning review session
  </output>

  <output>
Bob (Scrum Master): "{user_name}, this is significant. We need to address this before
committing to Epic {{next_epic_num}}'s current plan. How do you want to handle it?"
  </output>
  <action>WAIT for {user_name} decision</action>
</check>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{total_action_count}}` | Number of action items |
| `{{prep_task_count}}` | Number of prep tasks |
| `{{critical_count}}` | Number of critical path items |
| `{{epic_update_needed}}` | Boolean if significant changes require epic update |
