# Protocol: Generate Learning Summary

**ID:** generate_learning_summary
**Critical:** EPIC_COMPLETION
**Purpose:** Generates learning summary at epic completion for continuous improvement

---

## Output

File: `.sage/learning/{epic_id}.json`

---

## Content Structure

```json
{
  "epic_id": "{epic_id}",
  "completed_at": "{timestamp}",
  "duration_minutes": "{total_time}",

  "metrics": {
    "tokens_used": "{total}",
    "tokens_per_task_avg": "{avg}",
    "clears_performed": "{count}",
    "parallel_batches": "{count}",
    "recoveries_performed": "{count}"
  },

  "efficiency": {
    "token_savings_percent": "{(baseline - actual) / baseline * 100}",
    "parallel_time_savings_percent": "{estimated}",
    "context_per_cycle_avg": "{avg_tokens}"
  },

  "successes": [
    {"pattern": "description", "frequency": "count"}
  ],

  "failures": [
    {"task_id": "...", "type": "...", "recovered": "true/false"}
  ],

  "recommendations": [
    "Pattern X worked well, apply to future epics",
    "Pattern Y caused issues, avoid or modify"
  ]
}
```

---

## Steps

1. Collect metrics from checkpoint
2. Calculate efficiency metrics
3. Analyze success/failure patterns
4. Generate recommendations
5. Write to `.sage/learning/`
6. Log: `Learning summary generated for {epic_id}`
