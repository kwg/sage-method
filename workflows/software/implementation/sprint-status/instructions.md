# Sprint Status - Multi-Mode Service

<critical>The workflow execution engine is governed by: {project-root}/sage/core/tasks/workflow.xml</critical>
<critical>Modes: interactive (default), validate, data</critical>
<critical>⚠️ NO TIME ESTIMATES - do NOT mention hours, days, weeks</critical>

<workflow>

<step n="0" goal="Determine execution mode">
  <!-- Initialize sprint tracking -->
  <action>Set {{sprint_status}} = {sprint_status_file}</action>
  <invoke-protocol name="init_sprint_tracking" />
  
  <action>Set mode = {{mode}} if provided; otherwise mode = "interactive"</action>

  <check if="mode == data">
    <action>Jump to Step 20</action>
  </check>

  <check if="mode == validate">
    <action>Jump to Step 30</action>
  </check>

  <check if="mode == interactive">
    <action>Continue to Step 1</action>
  </check>
</step>

<step n="1" goal="Locate sprint status file">
  <check if="{{sprint_tracking}} == 'disabled'">
    <output>❌ sprint-status.yaml not found.
Run sprint-planning workflow to generate it.</output>
    <action>Exit workflow</action>
  </check>
  <action>Continue to Step 2</action>
</step>

<step n="2" goal="Read and parse sprint-status.yaml">
  <action>Load FULL file: {sprint_status_file}</action>
  <action>Parse: generated, project, project_key, tracking_system, story_location</action>
  <action>Parse development_status. Classify keys:</action>
  - Epics: keys starting with "epic-" (not ending with "-retrospective")
  - Retrospectives: keys ending with "-retrospective"
  - Stories: everything else (e.g., 1-2-login-form)
  <action>Count statuses: backlog, drafted, ready-for-dev, in-progress, review, done</action>
  <action>Detect risks: review without reviewer, in-progress with nothing behind, no stories drafted</action>
</step>

<step n="3" goal="Select next action recommendation">
  <action>Pick the next recommended workflow using priority:</action>
  1. If any story status == in-progress → recommend `dev-story` for the first in-progress story
  2. Else if any story status == review → recommend `code-review` for the first review story
  3. Else if any story status == ready-for-dev → recommend `dev-story`
  4. Else if any story status == drafted → recommend `story-ready`
  5. Else if any story status == backlog → recommend `create-story`
  6. Else if any epic status == backlog → recommend `epic-tech-context`
  7. Else if retrospectives are optional → recommend `retrospective`
  8. Else → All implementation items done; suggest `workflow-status` to plan next phase
  <action>Store selected recommendation as: next_story_id, next_workflow_id, next_agent (SM/DEV as appropriate)</action>
</step>

<step n="4" goal="Display summary">
  <output>
## 📊 Sprint Status

- Project: {{project}} ({{project_key}})
- Tracking: {{tracking_system}}
- Status file: {sprint_status_file}

**Stories:** backlog {{count_backlog}}, drafted {{count_drafted}}, ready-for-dev {{count_ready}}, in-progress {{count_in_progress}}, review {{count_review}}, done {{count_done}}

**Epics:** backlog {{epic_backlog}}, contexted {{epic_contexted}}

**Next Recommendation:** /sage:bmm:workflows:{{next_workflow_id}} ({{next_story_id}})

{{#if risks}}
**Risks:**
{{#each risks}}

- {{this}}
  {{/each}}
  {{/if}}

{{#if by_epic}}
**Per Epic:**
{{#each by_epic}}

- {{epic_id}}: context={{context_status}}, stories → backlog {{backlog}}, drafted {{drafted}}, ready {{ready_for_dev}}, in-progress {{in_progress}}, review {{review}}, done {{done}}
  {{/each}}
  {{/if}}
  </output>
  </step>

<step n="5" goal="Offer actions">
  <ask>Pick an option:
1) Run recommended workflow now
2) Show all stories grouped by status
3) Show raw sprint-status.yaml
4) Exit
Choice:</ask>

  <check if="choice == 1">
    <output>Run `/sage:bmm:workflows:{{next_workflow_id}}`.
If the command targets a story, set `story_key={{next_story_id}}` when prompted.</output>
  </check>

  <check if="choice == 2">
    <output>
### Stories by Status
- In Progress: {{stories_in_progress}}
- Review: {{stories_in_review}}
- Ready for Dev: {{stories_ready_for_dev}}
- Drafted: {{stories_drafted}}
- Backlog: {{stories_backlog}}
- Done: {{stories_done}}
    </output>
  </check>

  <check if="choice == 3">
    <action>Display the full contents of {sprint_status_file}</action>
  </check>

  <check if="choice == 4">
    <action>Exit workflow</action>
  </check>
</step>

<!-- ========================= -->
<!-- Data mode for other flows -->
<!-- ========================= -->

<step n="20" goal="Data mode output">
  <action>Load and parse {sprint_status_file} same as Step 2</action>
  <action>Compute recommendation same as Step 3</action>
  <template-output>next_workflow_id = {{next_workflow_id}}</template-output>
  <template-output>next_story_id = {{next_story_id}}</template-output>
  <template-output>count_backlog = {{count_backlog}}</template-output>
  <template-output>count_drafted = {{count_drafted}}</template-output>
  <template-output>count_ready = {{count_ready}}</template-output>
  <template-output>count_in_progress = {{count_in_progress}}</template-output>
  <template-output>count_review = {{count_review}}</template-output>
  <template-output>count_done = {{count_done}}</template-output>
  <template-output>epic_backlog = {{epic_backlog}}</template-output>
  <template-output>epic_contexted = {{epic_contexted}}</template-output>
  <template-output>warnings = {{risks}}</template-output>
  <action>Return to caller</action>
</step>

<!-- ========================= -->
<!-- Validate mode -->
<!-- ========================= -->

<step n="30" goal="Validate sprint-status file">
  <action>Check that {sprint_status_file} exists</action>
  <check if="missing">
    <template-output>is_valid = false</template-output>
    <template-output>error = "sprint-status.yaml missing"</template-output>
    <template-output>suggestion = "Run sprint-planning to create it"</template-output>
    <action>Return</action>
  </check>
  <action>Read file and verify it has a development_status section with at least one entry</action>
  <check if="validation fails">
    <template-output>is_valid = false</template-output>
    <template-output>error = "development_status missing or empty"</template-output>
    <template-output>suggestion = "Re-run sprint-planning or repair the file manually"</template-output>
    <action>Return</action>
  </check>
  <template-output>is_valid = true</template-output>
  <template-output>message = "sprint-status.yaml present and parsable"</template-output>
</step>

</workflow>
