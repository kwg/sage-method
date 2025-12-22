# Step 9: Critical Readiness Exploration

**Goal:** Verify epic is truly complete before moving forward

---

## Readiness Overview

```xml
<output>
Bob (Scrum Master): "Before we close, I want to do a final readiness check."
Bob (Scrum Master): "Epic {{epic_number}} is marked complete in sprint-status, but is it REALLY done?"
Bob (Scrum Master): "I mean truly production-ready, stakeholders happy, no loose ends."
</output>
```

---

## Testing and Quality

```xml
<output>
Bob (Scrum Master): "{user_name}, tell me about the testing for Epic {{epic_number}}.
What verification has been done?"
</output>
<action>WAIT for {user_name} to describe testing status</action>

<output>
Dana (QA Engineer): [Responds with additional context]
Bob (Scrum Master): "{user_name}, are you confident Epic {{epic_number}} is production-ready
from a quality perspective?"
</output>
<action>WAIT for {user_name} to assess quality readiness</action>
```

If concerns:
```xml
<check if="{user_name} expresses concerns">
  <output>
Bob (Scrum Master): "Okay, let's capture that. What specific testing is still needed?"
Dana (QA Engineer): "I can handle {{testing_work_needed}}, estimated {{testing_hours}} hours."
  </output>
  <action>Add testing completion to critical path</action>
</check>
```

---

## Deployment Status

```xml
<output>
Bob (Scrum Master): "{user_name}, what's the deployment status for Epic {{epic_number}}?
Is it live in production, scheduled for deployment, or still pending?"
</output>
<action>WAIT for {user_name} to provide deployment status</action>
```

If not deployed:
```xml
<check if="not yet deployed">
  <output>
Charlie (Senior Dev): "If it's not deployed yet, we need to factor that into Epic {{next_epic_num}} timing."
Bob (Scrum Master): "{user_name}, when is deployment planned? Does that timing work for
starting Epic {{next_epic_num}}?"
  </output>
  <action>WAIT for {user_name} to clarify timeline</action>
  <action>Add deployment milestone to critical path</action>
</check>
```

---

## Stakeholder Acceptance

```xml
<output>
Bob (Scrum Master): "{user_name}, have stakeholders seen and accepted the Epic {{epic_number}} deliverables?"
Alice (Product Owner): "This is important - I've seen 'done' epics get rejected by stakeholders and force rework."
Bob (Scrum Master): "{user_name}, any feedback from stakeholders still pending?"
</output>
<action>WAIT for {user_name} to describe acceptance status</action>
```

If incomplete:
```xml
<check if="acceptance incomplete or feedback pending">
  <output>
Alice (Product Owner): "We should get formal acceptance before moving on. Otherwise Epic
{{next_epic_num}} might get interrupted by rework."
Bob (Scrum Master): "{user_name}, how do you want to handle stakeholder acceptance?
Should we make it a critical path item?"
  </output>
  <action>WAIT for {user_name} decision</action>
  <action>Add stakeholder acceptance to critical path if agreed</action>
</check>
```

---

## Technical Health

```xml
<output>
Bob (Scrum Master): "{user_name}, this is a gut-check question: How does the codebase feel
after Epic {{epic_number}}?"
Bob (Scrum Master): "Stable and maintainable? Or are there concerns lurking?"
Charlie (Senior Dev): "Be honest, {user_name}. We've all shipped epics that felt... fragile."
</output>
<action>WAIT for {user_name} to assess codebase health</action>
```

If concerns:
```xml
<check if="{user_name} expresses stability concerns">
  <output>
Charlie (Senior Dev): "Okay, let's dig into that. What's causing those concerns?"
Bob (Scrum Master): "What would it take to address these concerns and feel confident about stability?"
Charlie (Senior Dev): "I'd say we need {{stability_work_needed}}, roughly {{stability_hours}} hours."
Bob (Scrum Master): "{user_name}, is addressing this stability work worth doing before
Epic {{next_epic_num}}?"
  </output>
  <action>WAIT for {user_name} decision</action>
  <action>Add stability work to preparation sprint if agreed</action>
</check>
```

---

## Unresolved Blockers

```xml
<output>
Bob (Scrum Master): "{user_name}, are there any unresolved blockers or technical issues from
Epic {{epic_number}} that we're carrying forward?"
Dana (QA Engineer): "Things that might create problems for Epic {{next_epic_num}} if we don't deal with them?"
Bob (Scrum Master): "Nothing is off limits here. If there's a problem, we need to know."
</output>
<action>WAIT for {user_name} to surface blockers</action>
```

If blockers identified:
```xml
<check if="blockers identified">
  <action>Capture each blocker</action>
  <action>Assess impact on next epic</action>
  <action>Assign ownership</action>
  <action>Add to critical path with priority and deadline</action>
</check>
```

---

## Readiness Summary

```xml
<output>
**EPIC {{epic_number}} READINESS ASSESSMENT:**

Testing & Quality: {{quality_status}}
{{#if quality_concerns}}⚠️ Action needed: {{quality_action_needed}}{{/if}}

Deployment: {{deployment_status}}
{{#if deployment_pending}}⚠️ Scheduled for: {{deployment_date}}{{/if}}

Stakeholder Acceptance: {{acceptance_status}}
{{#if acceptance_incomplete}}⚠️ Action needed: {{acceptance_action_needed}}{{/if}}

Technical Health: {{stability_status}}
{{#if stability_concerns}}⚠️ Action needed: {{stability_action_needed}}{{/if}}

Unresolved Blockers: {{blocker_status}}
{{#if blockers_exist}}⚠️ Must resolve: {{blocker_list}}{{/if}}

Bob (Scrum Master): "{user_name}, does this assessment match your understanding?"
</output>
<action>WAIT for {user_name} to confirm or correct</action>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{quality_status}}` | Testing/quality assessment |
| `{{deployment_status}}` | Deployment state |
| `{{acceptance_status}}` | Stakeholder acceptance state |
| `{{stability_status}}` | Technical health assessment |
| `{{blocker_status}}` | Unresolved blockers state |
| `{{critical_work_count}}` | Items to complete before next epic |
