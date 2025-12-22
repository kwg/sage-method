# Step 10: Retrospective Closure with Celebration and Commitment

**Goal:** Close the retrospective with acknowledgment and clear next steps

---

## Key Takeaways

```xml
<output>
═══════════════════════════════════════════════════════════
✅ RETROSPECTIVE COMPLETE
═══════════════════════════════════════════════════════════

Bob (Scrum Master): "Epic {{epic_number}}: {{epic_title}} - REVIEWED"

**Key Takeaways:**

1. {{key_lesson_1}}
2. {{key_lesson_2}}
3. {{key_lesson_3}}
{{#if key_lesson_4}}4. {{key_lesson_4}}{{/if}}
</output>
```

---

## Commitment Summary

```xml
<output>
Bob (Scrum Master): "Commitments made today:"

- Action Items: {{action_count}}
- Preparation Tasks: {{prep_task_count}}
- Critical Path Items: {{critical_count}}

Dana (QA Engineer): "That's a lot of commitments. We need to actually follow through this time."
Bob (Scrum Master): "Agreed. Which is why we'll review these action items in our next standup."
</output>
```

---

## Next Steps

```xml
<output>
═══════════════════════════════════════════════════════════
🎯 NEXT STEPS:
═══════════════════════════════════════════════════════════

1. Execute Preparation Sprint (Est: {{prep_days}} days)
2. Complete Critical Path items before Epic {{next_epic_num}}
3. Review action items in next standup
{{#if epic_update_needed}}
4. Hold Epic {{next_epic_num}} planning review session
{{else}}
4. Begin Epic {{next_epic_num}} planning when preparation complete
{{/if}}
</output>
```

---

## Team Acknowledgment

```xml
<output>
Bob (Scrum Master): "Before we wrap, I want to take a moment to acknowledge the team."

Bob (Scrum Master): "Epic {{epic_number}} delivered {{completed_stories}} stories with
{{velocity_description}} velocity. We overcame {{blocker_count}} blockers. We learned a lot.
That's real work by real people."

Charlie (Senior Dev): "Hear, hear."
Alice (Product Owner): "I'm proud of what we shipped."
Dana (QA Engineer): "And I'm excited about Epic {{next_epic_num}} - especially now that we're prepared for it."
</output>
```

---

## User Final Input

```xml
<output>
Bob (Scrum Master): "{user_name}, any final thoughts before we close?"
</output>
<action>WAIT for {user_name} to share final reflections</action>

<output>
Bob (Scrum Master): [Acknowledges what {user_name} shared] "Thank you for that, {user_name}."

Bob (Scrum Master): "Alright team - great work today. We learned a lot from Epic {{epic_number}}.
Let's use these insights to make Epic {{next_epic_num}} even better."

Bob (Scrum Master): "See you all when prep work is done. Meeting adjourned!"

═══════════════════════════════════════════════════════════
</output>
```

---

## Prepare for Save

```xml
<action>Prepare to save retrospective summary document</action>
```

Proceed to Step 11 for document generation and saving.
