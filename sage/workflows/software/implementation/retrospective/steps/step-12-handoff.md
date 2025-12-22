# Step 12: Final Summary and Handoff

**Goal:** Provide clear summary and next action guidance to user

---

## Final Summary Output

```xml
<output>
**✅ Retrospective Complete, {user_name}!**

**Epic Review:**
- Epic {{epic_number}}: {{epic_title}} reviewed
- Retrospective Status: completed
- Retrospective saved: {retrospectives_folder}/epic-{{epic_number}}-retro-{date}.md

**Commitments Made:**
- Action Items: {{action_count}}
- Preparation Tasks: {{prep_task_count}}
- Critical Path Items: {{critical_count}}
</output>
```

---

## Next Steps Guidance

```xml
<output>
**Next Steps:**

1. **Review retrospective summary**: {retrospectives_folder}/epic-{{epic_number}}-retro-{date}.md

2. **Execute preparation sprint** (Est: {{prep_days}} days)
   - Complete {{critical_count}} critical path items
   - Execute {{prep_task_count}} preparation tasks
   - Verify all action items are in progress

3. **Review action items in next standup**
   - Ensure ownership is clear
   - Track progress on commitments
   - Adjust timelines if needed

{{#if epic_update_needed}}
4. **IMPORTANT: Schedule Epic {{next_epic_num}} planning review session**
   - Significant discoveries from Epic {{epic_number}} require epic updates
   - Review and update affected stories
   - Align team on revised approach
   - Do NOT start Epic {{next_epic_num}} until review is complete
{{else}}
4. **Begin Epic {{next_epic_num}} when ready**
   - Start drafting stories with SM agent's `create-story`
   - Epic will be marked as `in-progress` automatically when first story is created
   - Ensure all critical path items are done first
{{/if}}
</output>
```

---

## Team Performance Summary

```xml
<output>
**Team Performance:**
Epic {{epic_number}} delivered {{completed_stories}} stories with {{velocity_summary}}.
The retrospective surfaced {{insight_count}} key insights and {{significant_discovery_count}} significant discoveries.
The team is well-positioned for Epic {{next_epic_num}} success.

{{#if significant_discovery_count > 0}}
⚠️ **REMINDER**: Epic update required before starting Epic {{next_epic_num}}
{{/if}}

---

Bob (Scrum Master): "Great session today, {user_name}. The team did excellent work."
Alice (Product Owner): "See you at epic planning!"
Charlie (Senior Dev): "Time to knock out that prep work."
</output>
```

---

## Workflow Complete

The retrospective workflow is now complete. User has:
- Full retrospective document saved
- Sprint status updated
- Clear next steps
- Team commitments documented
