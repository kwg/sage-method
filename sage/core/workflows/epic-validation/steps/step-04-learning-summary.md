# Step 04: Learning Summary

```xml
<step id="04-learning-summary" name="Generate Learning Summary">

  <purpose>
    Aggregate learning records from the epic and generate a persistent summary.
    This captures failure patterns and prevention rules for future reference.
  </purpose>

  <input>
    - epic_id: Epic identifier
    - learning_records: From epic state
    - metrics: From metrics file
  </input>

  <execution>

    <action n="1" name="aggregate-learnings">
      <action>
        learning_recorder:
          action: aggregate
          epic_id: {{epic_id}}
      </action>

      Result:
      {
        "epic_id": "{{epic_id}}",
        "total_failures": {{count}},
        "resolved": {{resolved_count}},
        "unresolved": {{unresolved_count}},
        "by_category": {
          "syntax": {{syntax_count}},
          "logic": {{logic_count}},
          "architecture": {{arch_count}},
          "integration": {{integration_count}},
          "environment": {{env_count}}
        },
        "top_patterns": [...],
        "prevention_rules": [...],
        "recommendations": [...]
      }
    </action>

    <action n="2" name="generate-summary-file">
      Write to: docs/sprint-artifacts/learning/epic-{{epic_id}}-learnings.md

      ---
      # Learning Summary: Epic {{epic_id}}

      **Generated:** {{current_timestamp}}
      **Epic Title:** {{epic_title}}

      ## Overview

      | Metric | Value |
      |--------|-------|
      | Total Failures | {{total_failures}} |
      | Resolved | {{resolved}} |
      | Unresolved | {{unresolved}} |
      | Resolution Rate | {{resolution_rate}}% |

      ## Failures by Category

      | Category | Count | Percentage |
      |----------|-------|------------|
      | Syntax | {{syntax_count}} | {{syntax_pct}}% |
      | Logic | {{logic_count}} | {{logic_pct}}% |
      | Architecture | {{arch_count}} | {{arch_pct}}% |
      | Integration | {{integration_count}} | {{integration_pct}}% |
      | Environment | {{env_count}} | {{env_pct}}% |

      ## Top Patterns

      {{for pattern in top_patterns}}
      ### {{pattern.pattern}}

      - **Occurrences:** {{pattern.occurrences}}
      - **Category:** {{pattern.category}}
      - **Preventable:** {{pattern.preventable ? "Yes" : "No"}}
      - **Prevention Rule:** {{pattern.prevention_rule}}

      {{endfor}}

      ## Prevention Rules

      {{for rule in prevention_rules}}
      - {{rule}}
      {{endfor}}

      ## Recommendations

      {{for rec in recommendations}}
      - {{rec}}
      {{endfor}}

      ## Individual Records

      <details>
      <summary>Click to expand full learning records</summary>

      {{for record in learning_records}}
      ### {{record.record_id}}

      - **Type:** {{record.type}}
      - **Phase:** {{record.context.phase}}
      - **Error:** {{record.context.error}}
      - **Resolution:** {{record.resolution.action or "Unresolved"}}
      - **Category:** {{record.classification.category}}

      {{endfor}}

      </details>
      ---
    </action>

    <action n="3" name="update-patterns-index">
      Update: docs/sprint-artifacts/learning/patterns.json

      Merge new patterns with existing patterns:
      - Increment occurrence counts for known patterns
      - Add new patterns
      - Update prevention rules if improved
    </action>

    <action n="4" name="output-summary">
      <output>
📚 **Learning Summary Generated**

**File:** docs/sprint-artifacts/learning/epic-{{epic_id}}-learnings.md

**Key Insights:**
- Total failures: {{total_failures}} ({{resolved}} resolved)
- Top category: {{top_category}} ({{top_category_count}} failures)
- New patterns identified: {{new_patterns_count}}

**Top Prevention Rules:**
{{for rule in prevention_rules | limit(3)}}
- {{rule}}
{{endfor}}
      </output>
    </action>

  </execution>

  <next-step>
    Load: steps/step-05-cleanup.md
  </next-step>

</step>
```
