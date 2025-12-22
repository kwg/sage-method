# Step 7: Next Epic Preparation Discussion

**Goal:** Collaboratively identify what's needed before starting next epic

---

## Skip Condition

```xml
<check if="{{next_epic_exists}} == false">
  <output>
Bob (Scrum Master): "Normally we'd discuss preparing for the next epic, but since Epic
{{next_epic_num}} isn't defined yet, let's skip to action items."
  </output>
  <action>Skip to Step 8</action>
</check>
```

---

## Readiness Assessment

Open with team concerns:

```xml
<output>
Bob (Scrum Master): "Now let's shift gears. Epic {{next_epic_num}} is coming up: '{{next_epic_title}}'"
Bob (Scrum Master): "The question is: are we ready? What do we need to prepare?"
</output>
```

### Concern Categories

| Role | Typical Concerns |
|------|-----------------|
| Product Owner | Dependencies from current epic solid |
| Senior Dev | Technical debt impact, architecture concerns |
| QA Engineer | Testing infrastructure needs |
| Junior Dev | Knowledge gaps, unfamiliar technologies |

---

## User Input on Readiness

```xml
<output>
Bob (Scrum Master): "{user_name}, the team is surfacing some real concerns here.
What's your sense of our readiness?"
</output>
<action>WAIT for {user_name} to share their assessment</action>
```

Use user's input to guide deeper exploration.

---

## Technical Preparation

Have Senior Dev outline technical needs:

```xml
<output>
Charlie (Senior Dev): "Here's what I think we need technically before Epic {{next_epic_num}} can start..."

Charlie (Senior Dev): "1. {{tech_prep_item_1}} - estimated {{hours_1}} hours"
Charlie (Senior Dev): "2. {{tech_prep_item_2}} - estimated {{hours_2}} hours"
Charlie (Senior Dev): "3. {{tech_prep_item_3}} - estimated {{hours_3}} hours"
</output>
```

---

## Balancing Business and Technical

Facilitate tension between:
- Stakeholder pressure to ship features
- Technical reality of preparation needs

```xml
<output>
Bob (Scrum Master): "Let's think about this differently. What happens if we DON'T do this prep work?"
</output>
```

Bring user in for key decisions:
```xml
<output>
Bob (Scrum Master): "{user_name}, you're balancing stakeholder pressure against technical reality.
How do you want to handle this?"
</output>
<action>WAIT for {user_name} to provide direction</action>
```

---

## Finding Middle Ground

Explore compromise options:
1. Which prep items are critical vs. nice-to-have?
2. Can any critical prep happen in parallel with early stories?
3. Which stories don't depend on incomplete prep?

```xml
<output>
Bob (Scrum Master): "{user_name}, the team is finding a workable compromise here.
Does this approach make sense to you?"
</output>
<action>WAIT for {user_name} to validate or adjust</action>
```

---

## Preparation Dimensions

Work through all areas:
- Dependencies on Epic `{{epic_number}}` work
- Technical setup and infrastructure
- Knowledge gaps and research needs
- Documentation or specification work
- Testing infrastructure
- Refactoring or debt reduction
- External dependencies (APIs, integrations)

---

## Preparation Summary

```xml
<output>
**CRITICAL PREPARATION (Must complete before epic starts):**
{{list_critical_prep_items_with_owners_and_estimates}}

**PARALLEL PREPARATION (Can happen during early stories):**
{{list_parallel_prep_items_with_owners_and_estimates}}

**NICE-TO-HAVE PREPARATION (Would help but not blocking):**
{{list_nice_to_have_prep_items}}

**Total critical prep effort:** {{critical_hours}} hours ({{critical_days}} days)
</output>

<output>
Bob (Scrum Master): "{user_name}, does this preparation plan work for you?"
</output>
<action>WAIT for {user_name} final validation</action>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{critical_prep_items}}` | Must-do items before epic |
| `{{parallel_prep_items}}` | Can do during early stories |
| `{{critical_hours}}` | Total critical prep hours |
| `{{critical_days}}` | Total critical prep days |
