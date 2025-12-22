# Step 01: Review Summary

```xml
<step id="01-review-summary" name="Generate Epic Summary">

  <purpose>
    Generate and present a comprehensive summary of the completed epic.
    This gives the human reviewer context before making approval decision.
  </purpose>

  <input>
    - epic_id: Epic identifier
    - epic_state: State from state/epic-{{epic_id}}-state.json
  </input>

  <execution>

    <action n="1" name="read-state">
      state_manager:
        action: read
        state_file: "state/epic-{{epic_id}}-state.json"

      <check if="state not found">
        <error>Epic state not found. Cannot validate.</error>
        <action>Ask user for epic_id or state file location</action>
      </check>
    </action>

    <action n="2" name="read-metrics">
      Read metrics file: docs/sprint-artifacts/epic-{{epic_id}}-metrics.json

      <check if="metrics not found">
        <warning>Metrics file not found. Summary will be limited.</warning>
      </check>
    </action>

    <action n="3" name="read-pr">
      Check for existing PR:
        gh pr list --head {{epic_branch}} --json number,url,state

      <check if="PR exists">
        Store pr_url, pr_number, pr_state
      </check>
      <check if="no PR">
        <warning>No PR found. Will create during merge step.</warning>
      </check>
    </action>

    <action n="4" name="generate-summary">
      Generate summary from state and metrics:

      ## Epic Summary: {{epic_id}}

      ### Overview
      - **Title:** {{epic_title}}
      - **Branch:** {{epic_branch}}
      - **Duration:** {{duration}}
      - **PR:** {{pr_url or "Not created"}}

      ### Story Results
      | Story | Status | Chunks | Test Attempts | Review Iterations |
      |-------|--------|--------|---------------|-------------------|
      {{for story in metrics.stories}}
      | {{story.story_id}} | {{story.final_status}} | {{story.chunks_completed}}/{{story.chunks_planned}} | {{story.test_attempts}} | {{story.review_iterations}} |
      {{endfor}}

      ### Summary Statistics
      - **Stories Completed:** {{completed_stories.length}}/{{story_queue.length}}
      - **Stories Failed:** {{failed_stories.length}}
      - **Total Chunks:** {{metrics.summary.total_chunks}}
      - **Avg Chunk Duration:** {{metrics.summary.avg_chunk_duration_ms}}ms

      ### Quality Metrics
      - **TDD Compliance:** {{tdd_compliance_rate}}%
      - **Test Pass Rate:** {{test_pass_rate}}%
      - **Review Pass Rate:** {{review_pass_rate}}%

      ### Failed Stories (if any)
      {{for story in failed_stories}}
      - **{{story.story_id}}:** {{story.reason}}
      {{endfor}}

      ### Learning Patterns Identified
      {{for pattern in learning_patterns}}
      - {{pattern.pattern}} ({{pattern.occurrences}}x)
      {{endfor}}
    </action>

    <action n="5" name="output-summary">
      <output>
📊 **EPIC VALIDATION: {{epic_id}}**

{{generated_summary}}

---

**Next Step:** Human checkpoint (approval required)
      </output>
    </action>

  </execution>

  <next-step>
    Load: steps/step-02-human-checkpoint.md
  </next-step>

</step>
```
