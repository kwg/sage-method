# Test Automation Expansion

**Workflow ID**: `sage/workflows/software/testarch/automate`
**Version**: 4.1 (SAGE v6 - Optimized)

---

## Overview

Expands test automation coverage by generating comprehensive test suites at appropriate levels (E2E, API, Component, Unit) with supporting infrastructure.

**Dual Mode Operation:**
1. **SAGE-Integrated Mode**: Works WITH SAGE artifacts (story, tech-spec, PRD, test-design)
2. **Standalone Mode**: Works WITHOUT SAGE artifacts - analyzes existing codebase independently

**Core Principle**: Generate prioritized, deterministic tests that avoid duplicate coverage.

---

## Prerequisites

**Load shared patterns first:** `{project-root}/sage/workflows/software/testarch/shared/common-patterns.md`

**Required:**
- ✅ Framework scaffolding configured (run `*framework` workflow if missing)
- ✅ Test framework configuration (playwright.config.ts or cypress.config.ts)

**Optional (SAGE-Integrated):**
- Story markdown with acceptance criteria
- Tech spec, PRD, test-design documents

**Halt Condition:**
- If framework missing: "Run `sage tea *framework` first"

---

## Step 1: Load Context

### Actions

1. **Detect Execution Mode**
   - If `{story_file}` set → SAGE-Integrated Mode
   - If `{target_feature}` or `{target_files}` set → Standalone Mode
   - If neither → Auto-discover mode (scan for untested features)

2. **Load Knowledge Base Fragments**

   From `shared/common-patterns.md` - Core Fragments section:
   - `test-levels-framework.md`
   - `test-priorities-matrix.md`
   - `data-factories.md`
   - `selective-testing.md`
   - `ci-burn-in.md`
   - `test-quality.md`

   If `config.tea_use_playwright_utils: true`:
   - Load all Playwright Utils fragments (see common-patterns.md)

   If `{auto_heal_failures}` enabled:
   - Load Healing fragments

3. **Load Framework Configuration**
   - Read test framework config
   - Identify test directory structure from `{test_dir}`
   - Note test runner capabilities

4. **Analyze Existing Coverage** (if `{analyze_coverage}: true`)
   - Search `{test_dir}` for existing tests
   - Identify coverage gaps
   - Map tests to source files

---

## Step 2: Identify Automation Targets

### Actions

1. **Determine What Needs Testing**

   **SAGE-Integrated:**
   - Map acceptance criteria to test scenarios
   - Expand beyond ATDD with edge cases and negative paths

   **Standalone:**
   - Analyze `{target_feature}` or scan `{source_dir}`
   - Prioritize: No coverage > Complex logic > External integrations > Critical paths

2. **Apply Test Level Selection**

   Reference: `shared/common-patterns.md` - Test Level Selection Framework

   For each feature, determine: E2E, API, Component, or Unit

3. **Avoid Duplicate Coverage**

   Reference: `shared/common-patterns.md` - Avoid Duplicate Coverage

4. **Assign Test Priorities**

   Reference: `shared/common-patterns.md` - Test Priority Framework

   Variables: `{include_p0}`, `{include_p1}`, `{include_p2}`, `{include_p3}`

5. **Create Test Coverage Plan**

   Document what will be tested at each level with priorities.

---

## Step 3: Generate Test Infrastructure

### Actions

1. **Enhance Fixture Architecture**

   Reference: `shared/common-patterns.md` - Fixture Architecture

   Create/enhance in `tests/support/fixtures/`:
   - `authenticatedUser` - User with valid session, auto-cleanup
   - `apiRequest` - Authenticated API client
   - `mockNetwork` - Network mocking
   - `testDatabase` - Database with test data, auto-cleanup

2. **Enhance Data Factories**

   Create/enhance in `tests/support/factories/`:
   - Use `@faker-js/faker` for all random data
   - Support overrides for specific scenarios
   - Include cleanup helpers

3. **Create Helper Utilities** (if `{update_helpers}: true`)

   Create in `tests/support/helpers/`:
   - `waitFor` - Polling helper
   - `retry` - Retry helper
   - `testData` - Data generation
   - `assertions` - Custom assertions

---

## Step 4: Generate Test Files

### Actions

1. **Create Test Structure**

   ```
   tests/
   ├── e2e/{feature}.spec.ts       # E2E (P0-P1)
   ├── api/{feature}.api.spec.ts   # API (P1-P2)
   ├── component/{Component}.test.tsx # Component (P1-P2)
   ├── unit/{module}.test.ts       # Unit (P2-P3)
   └── support/
       ├── fixtures/
       ├── factories/
       └── helpers/
   ```

2. **Write Tests**

   Reference: `shared/common-patterns.md` - Test Quality Standards

   For each test:
   - Follow Given-When-Then format
   - Tag with priority: `[P0]`, `[P1]`, etc.
   - Use data-testid selectors
   - One assertion per test (atomic)
   - No hard waits

3. **Apply Network-First Pattern** (E2E)

   Reference: `shared/common-patterns.md` - Network-First Pattern

4. **Enforce Quality Standards**

   Reference: `shared/common-patterns.md` - Required for All Tests, Forbidden Patterns

---

## Step 5: Validate & Heal Tests

### Actions

1. **Run Generated Tests**

   ```bash
   npx playwright test {generated_test_files}
   ```

2. **Evaluate Results**
   - All pass → Proceed to Step 6
   - Failures + `config.tea_use_mcp_enhancements: true` → Healing loop
   - Failures + healing disabled → Document for manual review

3. **Healing Loop** (max 3 iterations per test)

   For each failure, classify and apply fix:

   | Failure Type | Detection | Fix |
   |--------------|-----------|-----|
   | Stale selector | "locator resolved to 0 elements" | CSS → data-testid |
   | Race condition | "timeout waiting for" | Add network-first |
   | Dynamic data | "Expected 'User 123'" | Hardcoded → regex |
   | Network error | "API call failed" | Add route mock |
   | Hard wait | `waitForTimeout()` in code | Event-based wait |

4. **Mark Unfixable Tests**

   After 3 failed attempts:
   ```typescript
   test.fixme('[P1] should handle complex interaction', async ({ page }) => {
     // FIXME: Test healing failed after 3 attempts
     // Failure: [details]
     // Attempted: [fixes tried]
     // Manual investigation needed
   });
   ```

5. **Generate Healing Report**

---

## Step 6: Documentation & Scripts

### Actions

1. **Update Test README** (if `{update_readme}: true`)
   - Test suite structure
   - Execution instructions
   - Priority convention

2. **Update package.json Scripts** (if `{update_package_scripts}: true`)

   ```json
   {
     "scripts": {
       "test:e2e": "playwright test",
       "test:e2e:p0": "playwright test --grep '@P0'",
       "test:e2e:p1": "playwright test --grep '@P0|@P1'"
     }
   }
   ```

3. **Run Test Suite** (if `{run_tests_after_generation}: true`)

---

## Step 7: Generate Summary

### Actions

1. **Create Automation Summary**

   Save to `{output_summary}`:
   - Mode (SAGE-Integrated/Standalone)
   - Tests created by level and priority
   - Infrastructure created (fixtures, factories)
   - Coverage status
   - Healing outcomes (if applicable)
   - Definition of Done checklist
   - Next steps

2. **Output Concise Summary**

   ```markdown
   ## Automation Complete

   **Coverage:** {total_tests} tests across {levels} levels
   **Priority:** P0: {p0}, P1: {p1}, P2: {p2}
   **Infrastructure:** {fixtures} fixtures, {factories} factories

   **Run:** `npm run test:e2e`
   **Next:** Review tests, run in CI, integrate with quality gate
   ```

---

## Validation Checklist

Phase 1 - Context:
- [ ] Execution mode determined
- [ ] Knowledge base fragments loaded
- [ ] Framework configuration loaded
- [ ] Existing coverage analyzed

Phase 2 - Targets:
- [ ] Automation targets identified
- [ ] Test levels selected appropriately
- [ ] Duplicate coverage avoided
- [ ] Priorities assigned

Phase 3 - Infrastructure:
- [ ] Fixtures created/enhanced (with auto-cleanup)
- [ ] Factories created/enhanced (using faker)
- [ ] Helpers created/enhanced

Phase 4 - Tests:
- [ ] Tests written (Given-When-Then, priority tags, data-testid)
- [ ] Network-first pattern applied
- [ ] Quality standards enforced

Phase 5 - Validation:
- [ ] Tests validated
- [ ] Failures healed (if enabled)
- [ ] Unfixable tests marked with test.fixme()

Phase 6 - Documentation:
- [ ] README updated
- [ ] package.json scripts updated
- [ ] Summary created

---

## Notes

- **No Page Objects** - Keep tests simple and direct
- **Deterministic Only** - No flaky patterns
- **Self-Cleaning** - All fixtures auto-cleanup
- **Prioritized Execution** - Run P0 on every commit, P1 on PR

Reference `shared/common-patterns.md` for detailed patterns and examples.
