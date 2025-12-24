# Requirements Traceability & Quality Gate Decision

**Workflow ID**: `testarch-trace`
**Version**: 4.1 (SAGE v6 - Optimized)

---

## Overview

Two-phase workflow for test coverage validation and deployment readiness:

**Phase 1 - Requirements Traceability:**
- Map acceptance criteria to implemented tests
- Classify coverage (FULL/PARTIAL/NONE/UNIT-ONLY/INTEGRATION-ONLY)
- Identify and prioritize gaps

**Phase 2 - Quality Gate Decision:**
- Apply deterministic decision rules
- Generate gate decision (PASS/CONCERNS/FAIL/WAIVED)
- Document with evidence

---

## Prerequisites

**Load shared patterns first:** `{project-root}/sage/workflows/software/testarch/shared/common-patterns.md`

**Required (Phase 1):**
- Acceptance criteria (from story or inline)
- Implemented test suite

**Required (Phase 2 - if `enable_gate_decision: true`):**
- Test execution results (CI/CD reports)
- Test design with priorities

**Recommended:**
- `test-design.md`, `nfr-assessment.md`, `tech-spec.md`

**Halt Conditions:**
- No tests AND no acknowledged gaps → Run `*atdd` first
- No acceptance criteria → Request them
- Phase 2 + no test results → Skip gate decision with warning

---

## PHASE 1: REQUIREMENTS TRACEABILITY

### Step 1: Load Context

1. **Load Knowledge Base Fragments**

   From `shared/common-patterns.md`:
   - `test-priorities-matrix.md`
   - `risk-governance.md`
   - `probability-impact.md`
   - `test-quality.md`
   - `selective-testing.md`

2. **Read SAGE Artifacts**
   - Story file → Extract acceptance criteria, story ID
   - `test-design.md` → Risk assessment, priorities
   - `tech-spec.md` → Technical context

---

### Step 2: Discover and Catalog Tests

1. **Auto-discover tests for story**
   - Search for test IDs (e.g., `1.3-E2E-001`)
   - Search describe blocks mentioning feature
   - Use glob on `{test_dir}`

2. **Categorize by level**: E2E, API, Component, Unit

3. **Extract metadata**
   - Test ID, describe/it blocks
   - Given-When-Then structure
   - Priority markers (P0-P3)

---

### Step 3: Map Criteria to Tests

1. **For each criterion**
   - Search for explicit references
   - Map to test files and it blocks
   - Document test level

2. **Build traceability matrix**

   | Criterion ID | Description | Test ID | Test File | Level | Coverage |
   |--------------|-------------|---------|-----------|-------|----------|
   | AC-1 | User can... | 1.3-E2E-001 | e2e/auth.spec.ts | E2E | FULL |

3. **Classify coverage**

   Reference: `shared/common-patterns.md` - Coverage Classification

4. **Check duplicate coverage**
   - Same behavior at multiple levels?
   - Flag violations of selective testing

---

### Step 4: Analyze Gaps and Prioritize

1. **Identify gaps**
   - List criteria with NONE/PARTIAL/UNIT-ONLY/INTEGRATION-ONLY
   - Assign severity:
     - **CRITICAL (P0)**: Blocks release
     - **HIGH (P1)**: PR blocker
     - **MEDIUM (P2)**: Nightly gap
     - **LOW (P3)**: Acceptable

2. **Recommend tests**
   - Test level, description (Given-When-Then)
   - Test ID, justification

3. **Calculate metrics**
   - Overall coverage %
   - P0/P1 coverage %
   - Coverage by level

4. **Check gates**
   - P0 ≥ 100% (required)
   - P1 ≥ 90% (recommended)
   - Overall ≥ 80% (recommended)

---

### Step 5: Verify Test Quality

1. **For each mapped test, verify**

   Reference: `shared/common-patterns.md` - Test Quality Standards

   - Explicit assertions
   - Given-When-Then structure
   - No hard waits
   - Self-cleaning
   - File < 300 lines
   - Duration < 90 seconds

2. **Flag issues**
   - BLOCKER: Missing assertions, hard waits
   - WARNING: Large files, slow tests
   - INFO: Style inconsistencies

---

### Step 6: Generate Phase 1 Deliverables

1. **Create traceability matrix**
   - Use `trace-template.md`
   - Save to `{output_folder}/traceability-matrix.md`

2. **Generate gate YAML snippet**

   ```yaml
   traceability:
     story_id: '1.3'
     coverage:
       overall: 85%
       p0: 100%
       p1: 90%
     gaps:
       critical: 0
       high: 1
     status: 'PASS'
   ```

3. **Update story file** (if enabled)
   - Add Traceability section
   - Link to matrix

**If `enable_gate_decision: true`:** Proceed to Phase 2

---

## PHASE 2: QUALITY GATE DECISION

### Step 7: Gather Quality Evidence

1. **Load Phase 1 results** (inherited)

2. **Load test execution results**
   - Parse CI/CD reports (JUnit XML, TAP, JSON)
   - Calculate pass rates (P0, P1, overall)

3. **Load NFR assessment** (if provided)

4. **Validate evidence freshness** (if enabled)
   - Warn if artifacts > 7 days old

---

### Step 8: Apply Decision Rules

**Decision Mode: Deterministic** (rule-based)

Reference: `shared/common-patterns.md` - Gate Decision Thresholds

| Decision | Condition |
|----------|-----------|
| **PASS** | P0 cov ≥100%, P1 cov ≥90%, overall ≥80%, P0 pass =100%, P1 pass ≥95%, overall pass ≥90%, NFRs pass |
| **CONCERNS** | P1 cov 80-89%, P1 pass 90-94%, overall pass 85-89%, minor NFR issues |
| **FAIL** | P0 cov <100%, P0 pass <100%, P1 cov <80%, P1 pass <90%, overall <80%, critical NFR fail |
| **WAIVED** | FAIL conditions + business approval + mitigation plan |

**Risk tolerance adjustments:**
- `allow_p2_failures: true` → P2 failures don't affect decision
- `allow_p3_failures: true` → P3 failures don't affect decision

---

### Step 9: Document Decision

1. **Create gate decision document**

   Save to `{output_folder}/gate-decision-{gate_type}-{story_id}.md`

   Structure:
   ```markdown
   # Quality Gate Decision: {gate_type} {story_id}

   **Decision**: [PASS / CONCERNS / FAIL / WAIVED]
   **Date**: {date}
   **Decider**: deterministic | manual

   ## Summary
   [1-2 sentences]

   ## Decision Criteria
   | Criterion | Threshold | Actual | Status |
   |-----------|-----------|--------|--------|
   ...

   ## Evidence Summary
   - Test Coverage
   - Test Execution Results
   - NFRs

   ## Decision Rationale
   [Why this decision]

   ## Next Steps
   [Action items]
   ```

2. **Waiver documentation** (if WAIVED)
   - Approver name and role
   - Date and method
   - Justification
   - Mitigation plan
   - Evidence link

---

### Step 10: Update Status and Notify

1. **Update workflow status** (if `append_to_history: true`)

2. **Generate stakeholder notification** (if enabled)

   ```
   🚦 Quality Gate Decision: Story 1.3

   Decision: ⚠️ CONCERNS
   - P0 Coverage: ✅ 100%
   - P1 Coverage: ⚠️ 88%
   - Test Pass Rate: ✅ 96%

   Action: Create follow-up story for gap
   ```

3. **Request sign-off** (if `require_sign_off: true`)

---

## Decision Matrix (Quick Reference)

| P0 Cov | P1 Cov | Overall | P0 Pass | P1 Pass | NFRs | Decision |
|--------|--------|---------|---------|---------|------|----------|
| 100% | ≥90% | ≥80% | 100% | ≥95% | Pass | **PASS** |
| 100% | 80-89% | ≥80% | 100% | 90-94% | Pass | **CONCERNS** |
| <100% | - | - | - | - | - | **FAIL** |
| 100% | <80% | - | 100% | - | - | **FAIL** |
| 100% | - | - | <100% | - | - | **FAIL** |
| - | - | - | - | - | Fail | **FAIL** |

---

## Waiver Management

**When to use:**
- Time-boxed MVP (known gaps, follow-up planned)
- Low-risk P1 gaps with mitigation
- External dependencies blocking automation

**Required:**
- Approver name
- Justification
- Mitigation plan
- Evidence link
- Follow-up stories

**Never waive:**
- P0 gaps
- Critical security issues
- Critical NFR failures

---

## Validation Checklist

**Phase 1:**
- [ ] All criteria mapped or gaps documented
- [ ] Coverage classified
- [ ] Gaps prioritized by risk
- [ ] P0 coverage 100% or blockers documented
- [ ] Duplicate coverage flagged
- [ ] Test quality assessed
- [ ] Traceability matrix generated

**Phase 2:**
- [ ] Test execution results loaded
- [ ] Decision rules applied consistently
- [ ] Gate document created with evidence
- [ ] Waiver documented (if applicable)
- [ ] Status updated
- [ ] Stakeholders notified

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No tests found | Run `*atdd` workflow first |
| Cannot determine coverage | Add test IDs and Given-When-Then |
| P0 coverage <100% | BLOCKER - add missing tests |
| Duplicate coverage | Consolidate at appropriate level |
| Test results missing | Phase 2 skipped with warning |
| Gate FAIL but urgent | Request waiver with mitigation |

---

## Notes

Reference `shared/common-patterns.md` for:
- Coverage Classification details
- Gate Decision Thresholds
- Test Quality Standards
- Fixture Architecture
