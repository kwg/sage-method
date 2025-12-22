# Step 5: Initialize Retrospective with Rich Context

**Goal:** Set up the retrospective session with team, metrics, and context

---

## Team Assembly

```xml
<action>Load agent configurations from {agent_manifest}</action>
<action>Identify which agents participated in Epic {{epic_number}} based on story records</action>
<action>Ensure key roles present: Product Owner, Scrum Master (facilitating), Devs, Testing/QA, Architect</action>
```

---

## Epic Metrics Summary

Present comprehensive metrics:

### Delivery Metrics
- Completed: `{{completed_stories}}`/`{{total_stories}}` stories (`{{completion_percentage}}`%)
- Velocity: `{{actual_points}}` story points (planned: `{{planned_points}}`)
- Duration: `{{actual_sprints}}` sprints (planned: `{{planned_sprints}}`)
- Average velocity: `{{points_per_sprint}}` points/sprint

### Quality and Technical
- Blockers encountered: `{{blocker_count}}`
- Technical debt items: `{{debt_count}}`
- Test coverage: `{{coverage_info}}`
- Production incidents: `{{incident_count}}`

### Business Outcomes
- Goals achieved: `{{goals_met}}`/`{{total_goals}}`
- Success criteria: `{{criteria_status}}`
- Stakeholder feedback: `{{feedback_summary}}`

---

## Next Epic Preview (If Exists)

```xml
<check if="{{next_epic_exists}}">
  <output>
**NEXT EPIC PREVIEW:** Epic {{next_epic_num}}: {{next_epic_title}}

Dependencies on Epic {{epic_number}}:
{{list_dependencies}}

Preparation Needed:
{{list_preparation_gaps}}

Technical Prerequisites:
{{list_technical_prereqs}}
  </output>
</check>
```

---

## Ground Rules

Establish psychological safety:

1. No blame, no judgment
2. Focus on systems and processes, not individuals
3. Everyone's voice matters
4. Specific examples are better than generalizations
5. Everything shared stays in the room unless agreed to escalate

---

## Session Structure

Announce focus areas:

1. Learning from Epic `{{epic_number}}` execution
2. Preparing for Epic `{{next_epic_num}}` success (if exists)

---

## Party Mode Format

All agent dialogue uses: `Name (Role): "dialogue"`

Example:
```
Bob (Scrum Master): "Welcome to the retrospective, {user_name}."
Alice (Product Owner): "Those numbers tell a good story."
Charlie (Senior Dev): "I'm more interested in that technical debt number."
```

---

## User Engagement

```xml
<output>
Bob (Scrum Master): "{user_name}, any questions before we dive in?"
</output>
<action>WAIT for {user_name} to respond or indicate readiness</action>
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{participating_agents}}` | List of agents in session |
| `{{completion_percentage}}` | Story completion rate |
| `{{velocity_description}}` | Narrative about velocity |
