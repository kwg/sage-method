# Step 6: Epic Review Discussion - What Went Well, What Didn't

**Goal:** Facilitate team discussion about successes and challenges

---

## Successes Discussion

Start with wins to build psychological safety:

```xml
<output>
Bob (Scrum Master): "Let's start with the good stuff. What went well in Epic {{epic_number}}?"
</output>
```

### Team Sharing Pattern

1. Scrum Master opens with prompt
2. Team members share specific examples
3. Invite user participation:
   ```xml
   <output>
   Bob (Scrum Master): "{user_name}, what stood out to you as going well in this epic?"
   </output>
   <action>WAIT for {user_name} to respond</action>
   ```
4. Have 1-2 team members react to user's input

---

## Challenges Discussion

Transition with care:

```xml
<output>
Bob (Scrum Master): "Okay, we've celebrated some real wins. Now let's talk about challenges -
where did we struggle? What slowed us down?"
</output>
```

### Conflict Resolution

When disagreements arise (expected and healthy):

1. Let tensions surface naturally
2. Scrum Master intervenes calmly
3. Synthesize different perspectives
4. Bring user in as neutral party:
   ```xml
   Bob (Scrum Master): "{user_name}, you have visibility across the whole project.
   What's your take on this situation?"
   <action>WAIT for {user_name} to respond</action>
   ```
5. Guide toward systemic understanding, not blame

---

## Pattern Integration

Weave in patterns from Step 2 story analysis:

```xml
<output>
Bob (Scrum Master): "Speaking of patterns, I noticed something when reviewing all the story records..."
Bob (Scrum Master): "{{pattern_1_description}} - this showed up in {{pattern_1_count}} out of
{{total_stories}} stories."
</output>
```

Ask user about pattern awareness:
```xml
Bob (Scrum Master): "{user_name}, did you notice these patterns during the epic?"
<action>WAIT for {user_name} to share their observations</action>
```

---

## Previous Retro Review (If Applicable)

```xml
<check if="previous retrospective exists">
  <output>
Bob (Scrum Master): "Before we move on, I want to circle back to Epic {{prev_epic_num}}'s retrospective."
Bob (Scrum Master): "We made some commitments in that retro. Let's see how we did."

Bob (Scrum Master): "Action item 1: {{prev_action_1}}. Status: {{prev_action_1_status}}"
  </output>

  <output>
Bob (Scrum Master): "{user_name}, looking at what we committed to last time and what we
actually did - what's your reaction?"
  </output>
  <action>WAIT for {user_name} to respond</action>
</check>
```

---

## Theme Synthesis

Summarize what was discussed:

```xml
<output>
Bob (Scrum Master): "Let me summarize what I'm hearing..."

**Successes:**
{{list_success_themes}}

**Challenges:**
{{list_challenge_themes}}

**Key Insights:**
{{list_insight_themes}}

Bob (Scrum Master): "Does that capture it? Anyone have something important we missed?"
</output>
```

---

## Discussion Dynamics

Throughout the discussion, create moments where:
- Team members ask user questions directly
- User's input shifts discussion direction
- Disagreements arise naturally and get resolved
- Quieter team members are invited to contribute
- Specific stories are referenced with real examples
- Emotions are authentic (frustration, pride, concern, hope)

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{success_themes}}` | List of what went well |
| `{{challenge_themes}}` | List of challenges |
| `{{insight_themes}}` | Key insights from discussion |
