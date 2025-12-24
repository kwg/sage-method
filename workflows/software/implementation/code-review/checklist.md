# Senior Developer Review - Validation Checklist

## Pre-Review Checks

- [ ] Story file loaded from `{{story_path}}`
- [ ] Story Status verified as reviewable (review)
- [ ] Epic and Story IDs resolved ({{epic_num}}.{{story_num}})
- [ ] Story Context located or warning recorded
- [ ] Epic Tech Spec located or warning recorded
- [ ] Architecture/standards docs loaded (as available)
- [ ] Tech stack detected and documented

## Code Quality Checks

- [ ] No debug code (`console.log`, `print`, `debugger` statements)
- [ ] No TODOs without issue/story reference
- [ ] Clear naming conventions followed
- [ ] Error handling for async operations
- [ ] MCP doc search performed (or web fallback) and references captured

## Test & Coverage Checks

- [ ] All ACs have corresponding tests
- [ ] Tests pass locally (verified or reported by dev)
- [ ] Coverage ≥80% for new code
- [ ] No skipped tests without justification
- [ ] Tests identified and mapped to ACs; gaps noted

## Implementation Review

- [ ] Acceptance Criteria cross-checked against implementation
- [ ] File List reviewed and validated for completeness
- [ ] Code quality review performed on changed files
- [ ] Security review performed on changed files and dependencies

## Review Completion

- [ ] Outcome decided (Approve/Changes Requested/Blocked)
- [ ] Review notes appended under "Senior Developer Review (AI)"
- [ ] Change Log updated with review entry
- [ ] Status updated according to settings (if enabled)
- [ ] Sprint status synced (if sprint tracking enabled)
- [ ] Story saved successfully

---

## PR Format (for human PRs)

**Title**: `[STORY-ID] Short description`
**Example**: `[M-2] Restructure SOP directory`

## Review Feedback Format

Use severity tags for clarity:
- **[MUST]** — Critical issue, blocks merge
- **[SHOULD]** — Important but not blocking
- **[COULD]** — Suggestion for improvement
- **[QUESTION]** — Need clarification

---

_Reviewer: {{user_name}} on {{date}}_
