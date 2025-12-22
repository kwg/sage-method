# Create Epic - Workflow Instructions

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>You MUST have already loaded and processed: {project-root}/sage/workflows/game/production/create-epic/workflow.yaml</critical>
<critical>Communicate all responses in {communication_language}</critical>

<critical>
PURPOSE: Automate complete epic setup with retrospective learning integration.

KEY PRINCIPLE: "TELL DON'T ASK"
- Subagents receive ALL context upfront
- No back-and-forth for missing information
- Epic Briefing contains everything needed
- Each story gets targeted context injection

WORKFLOW PHASES:
1. Retrospective Review & Epic Validation
2. Dependency Analysis (subagent)
3. Story Draft Creation (batched subagents)
4. Story Context Generation (batched subagents)
5. Epic Kickoff Summary
</critical>

<workflow>

<step n="1" goal="Initialize and Validate Epic Target">

<action>Greet {user_name} and explain the create-epic workflow</action>

<output>
**Create Epic Workflow**

This workflow will:
1. Review ALL previous retrospectives and extract learnings
2. Analyze story dependencies to determine execution order
3. Create story drafts with full context injection
4. Generate story contexts for each story
5. Produce epic kickoff summary

Let me identify the target epic.
</output>

<action>Check if {{epic_identifier}} was provided</action>

<check if="{{epic_identifier}} is empty">
  <action>Load {sprint_status_file} to find available epics</action>
  <action>List epics with status = 'backlog' or 'in-progress'</action>

  <output>
**Available Epics:**
{{list_available_epics}}

Which epic would you like to set up?
  </output>

  <action>WAIT for {user_name} to specify epic</action>
  <action>Set {{epic_identifier}} from user input</action>
</check>

<action>Normalize {{epic_identifier}} to {{epic_key}} and {{epic_number}}</action>
<action>Examples: "8" → epic_key="epic-8", epic_number=8</action>
<action>Examples: "mini-sprint-uiux" → epic_key="mini-sprint-uiux", epic_number=null</action>

<action>Validate epic exists in {sprint_status_file} or {gdd_file}</action>

<check if="epic not found">
  <output>
**Error:** Epic "{{epic_identifier}}" not found in sprint-status or GDD.

Please verify the epic identifier and try again.
  </output>
  <action>HALT</action>
</check>

<action>Load epic definition from {gdd_file} or {epics_file}</action>
<action>Extract story list for {{epic_key}}</action>
<action>Set {{epic_title}} and {{story_count}}</action>

<output>
**Target Epic:** {{epic_key}}
**Title:** {{epic_title}}
**Stories:** {{story_count}}

{{list_stories_brief}}

Proceeding with epic setup...
</output>

</step>

<step n="2" goal="Phase 1: Retrospective Review & Epic Validation">

<output>
═══════════════════════════════════════════════════════════
**PHASE 1: Retrospective Review & Epic Validation**
═══════════════════════════════════════════════════════════
</output>

<action>Find all retrospective files matching {retrospectives_pattern}</action>
<action>Sort by epic number (ascending) to get chronological order</action>

<check if="no retrospectives found">
  <output>
**Note:** No previous retrospectives found. This appears to be the first epic or retros are not yet created.

Proceeding without historical context - recommend running retrospectives after each epic.
  </output>
  <action>Set {{retro_count}} = 0</action>
  <action>Set {{retro_learnings}} = empty</action>
</check>

<check if="retrospectives found">
  <output>
Found {{retro_count}} retrospective(s). Extracting learnings...
  </output>

  <action>For each retrospective file, extract:</action>

  **Action Items:**
  - Parse "## Action Items" section
  - Extract: ID, action, owner, status (✅/⏳/❌)
  - Flag items with status ⏳ (in progress) or ❌ (not addressed)

  **Key Takeaways/Lessons:**
  - Parse "## Key Takeaways" or "## What Went Well" sections
  - Extract numbered insights

  **Patterns Identified:**
  - Parse "## Patterns" or "## Technical Patterns" sections
  - Extract pattern IDs and descriptions (P1, P2, P4, P5, P6, etc.)

  **Technical Debt:**
  - Parse "## Technical Debt" or "## What Didn't Go Well" sections
  - Extract debt items that may affect current epic

  **Process Improvements:**
  - Parse "## Decisions Made" or "## Process Improvements" sections
  - Extract workflow or process changes

  <action>Aggregate learnings across all retros</action>
  <action>Identify patterns that apply to {{epic_key}} based on story types</action>

  <output>
**Retrospective Analysis Complete**

| Source | Action Items | Patterns | Debt Items |
|--------|--------------|----------|------------|
{{retro_summary_table}}

**Unresolved Action Items:** {{unresolved_count}}
**Applicable Patterns:** {{pattern_list}}
  </output>
</check>

<action>Load patterns from {patterns_dir}</action>
<action>Match patterns to stories based on keywords:</action>
- "signal", "async", "await" → P4 (Async Null Guards), P5 (Connection Validation)
- "state", "save", "load" → P6 (Deferred Callbacks)
- "UI", "scene", "node" → Godot scene patterns
- "resource", "data", "tres" → Resource loading patterns

<action>Load {architecture_file} and extract relevant sections</action>
<action>Load tech specs matching {tech_spec_pattern} if they exist</action>

<action>Cross-reference epic stories against retro learnings</action>
<action>For each story, identify:</action>
- Which patterns MUST be applied
- Which action items are relevant
- Which technical debt affects it
- Which architecture sections are relevant

<output>
**Story-Pattern Mapping:**

{{story_pattern_matrix}}

**Validation Result:**
- Stories with pattern requirements: {{stories_with_patterns}}
- Stories with relevant tech debt: {{stories_with_debt}}
- Stories with architecture dependencies: {{stories_with_arch}}
</output>

<action>Generate Epic Briefing document</action>
<action>Save to {{briefing_output}}</action>

<output>
✅ **Epic Briefing Generated:** {{briefing_output}}
</output>

</step>

<step n="3" goal="Phase 2: Dependency Analysis">

<output>
═══════════════════════════════════════════════════════════
**PHASE 2: Dependency Analysis**
═══════════════════════════════════════════════════════════
</output>

<action>Analyze story list for dependencies</action>

**Dependency Types to Check:**

1. **Technical Dependencies**
   - Story A creates component that Story B uses
   - Story A defines resource that Story B references
   - Story A implements system that Story B extends

2. **Data Dependencies**
   - Story A creates data files Story B needs
   - Story A defines schema Story B follows
   - Story A populates content Story B displays

3. **Knowledge Dependencies**
   - Story A's implementation informs Story B's approach
   - Story A discovers patterns Story B should use
   - Story A validates assumptions Story B relies on

4. **Infrastructure Dependencies**
   - Story A sets up tool Story B uses
   - Story A configures environment Story B needs

<action>For each pair of stories, determine if dependency exists</action>
<action>Build dependency graph</action>
<action>Detect cycles (if any - should not exist in well-designed epic)</action>

<check if="dependency cycle detected">
  <output>
**Warning:** Dependency cycle detected:
{{cycle_description}}

This needs to be resolved before proceeding. Options:
1. Break cycle by redefining story scope
2. Merge dependent stories
3. Accept partial ordering with known risk

{user_name}, how would you like to proceed?
  </output>
  <action>WAIT for {user_name} decision</action>
</check>

<action>Group stories into execution batches</action>

**Batching Rules:**
- Stories with no dependencies → Batch 1
- Stories depending only on Batch 1 → Batch 2
- Continue until all stories assigned
- Stories in same batch can run in parallel
- Batches run sequentially

<action>Generate batch structure:</action>

```yaml
batches:
  - batch: 1
    parallel: true
    stories: [{{batch_1_stories}}]
    rationale: "{{batch_1_rationale}}"
  - batch: 2
    parallel: true
    stories: [{{batch_2_stories}}]
    rationale: "{{batch_2_rationale}}"
  # ... continue for all batches
```

<action>Save dependency analysis to {{dependency_output}}</action>

<output>
**Dependency Analysis Complete**

**Execution Batches:**

| Batch | Stories | Can Parallel | Rationale |
|-------|---------|--------------|-----------|
{{batch_table}}

**Dependency Graph:**
```
{{dependency_graph_ascii}}
```

✅ **Dependency Analysis Saved:** {{dependency_output}}
</output>

</step>

<step n="4" goal="Phase 3: Story Draft Creation">

<output>
═══════════════════════════════════════════════════════════
**PHASE 3: Story Draft Creation**
═══════════════════════════════════════════════════════════

Creating {{story_count}} stories in {{batch_count}} batches...
</output>

<action>For each batch in order:</action>

<action>**Batch {{batch_num}} of {{batch_count}}**</action>

<output>
**Processing Batch {{batch_num}}:** {{batch_stories}}
Mode: {{parallel_or_sequential}}
</output>

<action>For each story in batch (parallel if batch.parallel=true):</action>

<action>Prepare story context injection:</action>

```
STORY CONTEXT FOR: {{story_key}}
================================

## Epic Briefing (Summary)
{{epic_briefing_summary}}

## Story Definition
{{story_definition_from_gdd}}

## Required Patterns
{{patterns_for_this_story}}

## Architecture Context
{{relevant_architecture_sections}}

## Technical Notes
{{relevant_tech_spec_sections}}

## Predecessor Learnings
{{learnings_from_earlier_batch_stories}}

## Action Items to Address
{{relevant_action_items}}
```

<action>Spawn subagent to run create-story-draft workflow</action>

**Subagent Prompt:**
```
You are a Scrum Master subagent creating a story draft.

CONTEXT (Tell Don't Ask - everything you need is here):
{{story_context_injection}}

TASK:
Run the create-story-draft workflow for story {{story_key}}.
- Use the context above to inform all sections
- Inject applicable patterns into Dev Notes
- Reference architecture where relevant
- Include learnings from predecessor stories

OUTPUT:
Confirm story file created at: {{expected_story_path}}
Report any issues or blockers encountered.
```

<action>Wait for batch completion</action>

<check if="any story in batch failed">
  <output>
**Warning:** Story creation failed for: {{failed_stories}}
Errors: {{error_messages}}

Continuing with remaining stories. Failed stories will need manual attention.
  </output>
  <action>Log failures for summary</action>
</check>

<output>
✅ **Batch {{batch_num}} Complete:** {{success_count}}/{{batch_size}} stories created
</output>

<action>Continue to next batch</action>

<output>
**Phase 3 Complete**

Stories Created: {{total_created}}/{{story_count}}
{{#if failures}}
Failed: {{failure_list}}
{{/if}}
</output>

</step>

<step n="5" goal="Phase 4: Story Context Generation">

<output>
═══════════════════════════════════════════════════════════
**PHASE 4: Story Context Generation**
═══════════════════════════════════════════════════════════

Generating story contexts for {{total_created}} stories...
</output>

<action>For each batch in order (same batching as Phase 3):</action>

<action>**Batch {{batch_num}} of {{batch_count}}**</action>

<output>
**Processing Batch {{batch_num}}:** {{batch_stories}}
</output>

<action>For each successfully created story in batch (parallel):</action>

<action>Spawn subagent to run story-context workflow</action>

**Subagent Prompt:**
```
You are a Scrum Master subagent generating story context.

STORY: {{story_key}}
STORY FILE: {{story_file_path}}

TASK:
Run the story-context workflow for this story.
- Generate dynamic Story Context XML from latest docs and code
- Mark story as ready-for-dev in sprint-status

OUTPUT:
Confirm context file created.
Report final story status.
```

<action>Wait for batch completion</action>

<output>
✅ **Batch {{batch_num}} Context Complete**
</output>

<action>Continue to next batch</action>

<output>
**Phase 4 Complete**

Story Contexts Generated: {{context_count}}/{{total_created}}
Stories Ready for Dev: {{ready_count}}
</output>

</step>

<step n="5.5" goal="Phase 4.5: Verify All Stories Ready for Dev">

<output>
═══════════════════════════════════════════════════════════
**PHASE 4.5: Verify All Stories Ready for Dev**
═══════════════════════════════════════════════════════════
</output>

<action>Scan all created story files and check their Status field</action>
<action>Compare against sprint-status.yaml entries</action>

<action>For each story that is still "drafted" or "backlog":</action>

<check if="story has no context file AND status != ready-for-dev">
  <output>
**Warning:** Story {{story_key}} is still "{{current_status}}" - not ready for dev.

This can happen when:
- Story context was skipped (infra/non-code stories)
- Context generation failed silently
- Manual intervention interrupted the workflow
  </output>

  <action>Ask user: "Mark {{story_key}} as ready-for-dev without context? (Y/n)"</action>

  <check if="user confirms OR story is infrastructure/non-code type">
    <action>Update story file Status: → ready-for-dev</action>
    <action>Update sprint-status.yaml: {{story_key}} → ready-for-dev</action>
    <output>✅ {{story_key}} marked ready-for-dev (no context required)</output>
  </check>
</check>

<action>Final verification: Count stories by status</action>

<output>
**Ready-for-Dev Verification:**

| Status | Count | Stories |
|--------|-------|---------|
| ready-for-dev | {{ready_count}} | {{ready_stories}} |
| drafted | {{drafted_count}} | {{drafted_stories}} |
| other | {{other_count}} | {{other_stories}} |

{{#if drafted_count > 0}}
**⚠️ Warning:** {{drafted_count}} stories still not ready for dev.
Dev agent will skip these until they are marked ready.
{{/if}}

{{#if all_ready}}
✅ **All stories ready for dev!**
{{/if}}
</output>

</step>

<step n="6" goal="Phase 5: Epic Kickoff Summary">

<output>
═══════════════════════════════════════════════════════════
**PHASE 5: Epic Kickoff Summary**
═══════════════════════════════════════════════════════════
</output>

<action>Update {sprint_status_file}:</action>
- Set {{epic_key}} status to "in-progress"
- Set all created stories to "ready-for-dev"

<action>Generate kickoff summary document</action>

<output>
# {{epic_key}} Kickoff Summary

**Generated:** {{date}}
**Epic:** {{epic_title}}

## Stories Created

| Story | Status | Batch | Key Patterns |
|-------|--------|-------|--------------|
{{story_status_table}}

## Execution Order (Recommended)

Based on dependency analysis, execute stories in this order:

{{#each batch}}
### Batch {{batch_num}}: {{rationale}}
{{#if parallel}}
*These stories can be worked in parallel:*
{{/if}}
{{#each stories}}
- [ ] {{story_key}}: {{story_title}}
{{/each}}

{{/each}}

## Patterns Injected

| Pattern | Stories Applied |
|---------|-----------------|
{{pattern_injection_summary}}

## Retro Learnings Applied

{{retro_learnings_applied}}

## Next Steps

1. Review Epic Briefing: {{briefing_output}}
2. Start with Batch 1 stories (no dependencies)
3. Dev agent uses story context files for implementation
4. Run code-review after each story completion
5. Update sprint-status as stories complete

## Files Generated

- Epic Briefing: {{briefing_output}}
- Dependency Analysis: {{dependency_output}}
- Story Files: {{story_file_list}}
- Context Files: {{context_file_list}}
</output>

<action>Save kickoff summary to {{kickoff_output}}</action>

<output>
═══════════════════════════════════════════════════════════
✅ **EPIC SETUP COMPLETE**
═══════════════════════════════════════════════════════════

**{{epic_key}}: {{epic_title}}**

- Stories Created: {{total_created}}/{{story_count}}
- Stories Ready for Dev: {{ready_count}}
- Execution Batches: {{batch_count}}

**Generated Documents:**
- Epic Briefing: {{briefing_output}}
- Kickoff Summary: {{kickoff_output}}
- Dependency Analysis: {{dependency_output}}

**Sprint Status Updated:** {{epic_key}} → in-progress

{user_name}, the epic is ready for development. Start with Batch 1 stories which have no dependencies.
</output>

</step>

</workflow>

<error-handling>
  <on-subagent-failure>
    - Log the failure with story key and error message
    - Continue with remaining stories in batch
    - Skip failed stories in subsequent phases
    - Report all failures in kickoff summary
    - Do NOT halt entire workflow for single story failure
  </on-subagent-failure>

  <on-missing-retros>
    - Warn user that historical context is limited
    - Continue with available information
    - Note in briefing that patterns may be incomplete
  </on-missing-retros>

  <on-missing-gdd>
    - Error: Cannot proceed without epic definition
    - HALT and ask user to provide epic source
  </on-missing-gdd>

  <on-dependency-cycle>
    - Report cycle to user
    - Offer resolution options
    - WAIT for user decision before proceeding
  </on-dependency-cycle>
</error-handling>

<output-formats>
  <epic-briefing>Markdown document with structured sections</epic-briefing>
  <dependency-analysis>YAML file with batch structure</dependency-analysis>
  <kickoff-summary>Markdown document with tables and checklists</kickoff-summary>
</output-formats>
