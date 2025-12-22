# Step 11: Save Retrospective and Update Sprint Status

**Goal:** Persist retrospective document and update tracking

---

## Ensure Output Directory

```xml
<action>Ensure retrospectives folder exists: {retrospectives_folder}</action>
<action>Create folder if it doesn't exist</action>
```

---

## Retrospective Document Content

Generate comprehensive summary including:

| Section | Content |
|---------|---------|
| Epic Summary | Title, metrics, completion status |
| Team Participants | Who was in the retrospective |
| Successes | What went well |
| Challenges | Growth areas identified |
| Key Insights | Learnings from discussion |
| Previous Retro Analysis | Action item follow-through (if applicable) |
| Next Epic Preview | Dependencies and preparation |
| Action Items | With owners and timelines |
| Preparation Tasks | For next epic |
| Critical Path | Blocking items |
| Significant Discoveries | Epic update recommendations (if any) |
| Readiness Assessment | Quality, deployment, acceptance status |
| Commitments | Team agreements and next steps |

---

## Document Format

Use the template from `templates/retro-report.md` (if exists) or generate readable markdown with clear sections.

---

## Save Document

```xml
<action>Set filename: {retrospectives_folder}/epic-{{epic_number}}-retro-{date}.md</action>
<action>Save retrospective document</action>

<output>
✅ Retrospective document saved: {retrospectives_folder}/epic-{{epic_number}}-retro-{date}.md
</output>
```

---

## Update Sprint Status

```xml
<action>Set {{story_key}} = "epic-{{epic_number}}-retrospective"</action>
<action>Set {{new_status}} = "done"</action>
<invoke-protocol name="update_story_status" />
```

---

## Output Variables

| Variable | Description |
|----------|-------------|
| `{{retro_file_path}}` | Full path to saved retrospective |
