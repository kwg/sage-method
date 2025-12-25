# Epic Complete - Workflow Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/core/epic/epic-complete/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language}</critical>

<workflow>

<step n="1" goal="Validate Epic State">

<output>
**Epic Complete Workflow**

Epic: {{epic_id}}
Validating epic completion...
</output>

<action>Check if epic state file exists at {epic_state_file}</action>

<check if="state file missing">
  <output>
**Warning:** Epic state file not found: {epic_state_file}

This epic may have been run with create-epic v1.0 or without run-epic-orchestrated.
State file is recommended for learning extraction in future epics.

Would you like to:
1. Continue without state file (learning records from retro markdown only)
2. Generate state file from git history (manual process)

Choose option (1/2):
  </output>
  <action>WAIT for user choice</action>
</check>

<check if="state file exists">
  <action>Load and validate state file</action>
  <action>Check for learning_records array</action>
  <action>Check for retro_notes object</action>

  <output>
✅ **State File Valid**

Learning Records: {{learning_record_count}}
Retro Notes: {{retro_notes_count}} categories
Stories Completed: {{completed_story_count}}
  </output>
</check>

</step>

<step n="2" goal="Generate Final Metrics">

<output>
═══════════════════════════════════════════════════════════
**Phase 2: Generate Final Metrics**
═══════════════════════════════════════════════════════════
</output>

<action>Aggregate metrics from epic state file (if available)</action>
<action>Calculate:</action>
- Total stories planned vs completed
- Average story completion time
- Retry counts (test, review, build)
- Pattern compliance rate
- Learning records generated

<output>
**Epic Metrics Summary**

| Metric | Value |
|--------|-------|
| Stories Planned | {{planned_count}} |
| Stories Completed | {{completed_count}} |
| Success Rate | {{success_rate}}% |
| Avg Completion Time | {{avg_time}} |
| Test Retries | {{test_retries}} |
| Review Iterations | {{review_iterations}} |
| Patterns Applied | {{patterns_applied}} |
| Learning Records | {{learning_records}} |
</output>

<action>Save metrics summary to {metrics_summary}</action>

</step>

<step n="3" goal="Structure Alignment Check">

<output>
═══════════════════════════════════════════════════════════
**Phase 3: Structure Alignment Check**
═══════════════════════════════════════════════════════════
</output>

<action>Check project structure against SAGE patterns:</action>

**SAGE Standard Structure:**
```
.sage/
  state/
    epic-*-state.json           ✓ Check if exists
docs/
  stories/                      ✓ Check if used
  sprint-artifacts/
    epic-*-briefing.md          ✓ Check if exists
    epic-*-retro.md             ✓ Check if exists
    sprint-status.yaml          ✓ Check if exists
project-sage/
  config.yaml                   ✓ Check if exists
```

<action>For each expected location, check:</action>
- Does directory/file exist?
- Is it in the expected location?
- Does it follow naming conventions?

<action>Generate alignment report:</action>

<output>
**Structure Alignment Report**

| Component | Expected | Actual | Status |
|-----------|----------|--------|--------|
{{alignment_table}}

**Overall Alignment:** {{alignment_percentage}}%

{{#if not_fully_aligned}}
**Recommendations:**
{{conversion_recommendations}}
{{/if}}
</output>

<action>Save structure report to {conversion_report}</action>

</step>

<step n="4" goal="Brownfield Conversion Prompt">

<output>
═══════════════════════════════════════════════════════════
**Phase 4: Brownfield Conversion Prompt**
═══════════════════════════════════════════════════════════
</output>

<check if="project not fully SAGE-aligned">
  <output>
✅ **Epic Complete: {{epic_id}}**

Your project structure could be upgraded to align with SAGE patterns.

**Current Structure:**
{{current_structure_summary}}

**SAGE Standard Structure:**
{{sage_standard_summary}}

**Benefits of Upgrading:**
- Future epics automatically use state files
- Learning records persist across epics
- Standardized locations for artifacts
- Better integration with create-epic v2.0

**Upgrade Process:**
The upgrade is non-destructive and includes:
1. Create missing directories (.sage/state/, docs/stories/)
2. Move/copy files to standard locations (optional)
3. Generate state file from git history (if missing)
4. Update sprint-status.yaml format

**Would you like to upgrade project structure?** (Y/n)
  </output>

  <action>WAIT for user confirmation</action>

  <check if="user confirms">
    <output>
**Starting Structure Upgrade...**

This is currently a manual process. Follow these steps:

1. **Create .sage/state/ directory:**
   ```bash
   mkdir -p .sage/state
   ```

2. **Move sprint artifacts (optional):**
   ```bash
   # If you want to standardize locations
   mkdir -p docs/stories
   # Review and move story files as needed
   ```

3. **Generate state file (if missing):**
   Create `.sage/state/{{epic_id}}-state.json` with:
   - learning_records from retrospective
   - retro_notes aggregated from retro markdown
   - Story completion metrics

4. **Update sprint-status.yaml:**
   Ensure it follows current SAGE format

Would you like me to generate a template state file? (Y/n)
    </output>

    <action>WAIT for user decision</action>

    <check if="user wants template">
      <output>
**Template State File:**

```json
{
  "workflow_name": "run-epic-orchestrated",
  "workflow_version": "3.1",
  "epic_id": "{{epic_id}}",
  "start_time": "{{epic_start_time}}",
  "end_time": "{{date}}",
  "current_phase": "complete",
  "stories": [
    {{#each completed_stories}}
    {
      "story_key": "{{story_key}}",
      "status": "completed",
      "patterns_applied": {{patterns_applied}}
    }{{#unless @last}},{{/unless}}
    {{/each}}
  ],
  "learning_records": [
    {{#each retro_learnings}}
    {
      "source": "{{epic_id}}-retro",
      "type": "{{type}}",
      "description": "{{description}}",
      "applied_to_stories": []
    }{{#unless @last}},{{/unless}}
    {{/each}}
  ],
  "retro_notes": {
    "retrospectives_reviewed": [],
    "unresolved_action_items": [],
    "applicable_patterns": {{pattern_list}},
    "technical_debt": []
  },
  "metrics": {
    "total_stories": {{story_count}},
    "stories_completed": {{completed_count}},
    "patterns_injected": {{pattern_count}}
  }
}
```

Save this to: `.sage/state/{{epic_id}}-state.json`
      </output>
    </check>
  </check>

  <check if="user declines">
    <output>
Structure upgrade skipped. You can run this workflow again anytime with:
`/epic-complete epic_id={{epic_id}}`
    </output>
  </check>
</check>

<check if="project fully SAGE-aligned">
  <output>
✅ **Epic Complete: {{epic_id}}**

Project structure is fully aligned with SAGE patterns.
State file exists with learning records.

No conversion needed.
  </output>
</check>

<output>
═══════════════════════════════════════════════════════════
**EPIC COMPLETION SUMMARY**
═══════════════════════════════════════════════════════════

Epic: {{epic_id}}
Status: ✅ Complete
Structure Alignment: {{alignment_percentage}}%

**Files Generated:**
- Metrics Summary: {metrics_summary}
- Structure Report: {conversion_report}

**Next Steps:**
1. Review retrospective findings
2. Use learning records in next epic (create-epic will auto-load them)
3. Continue with next epic or project milestone

{user_name}, congratulations on completing {{epic_id}}!
</output>

</step>

</workflow>

<error-handling>
  <on-missing-state-file>
    - Warn user but continue
    - Offer to generate from git history
    - Note that future epics benefit from state files
  </on-missing-state-file>

  <on-structure-misalignment>
    - Report specific gaps
    - Provide conversion recommendations
    - Make upgrade opt-in but actively prompted
  </on-structure-misalignment>
</error-handling>
