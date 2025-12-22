# Testarch Common Patterns

**Purpose:** Shared patterns and standards used across testarch workflows
**Reference:** Load this file before workflow-specific instructions

---

## Knowledge Base Loading

All testarch workflows should load fragments from `{project-root}/sage/testarch/tea-index.csv`.

### Core Fragments (Load for All Workflows)

| Fragment | Lines | Description |
|----------|-------|-------------|
| `test-levels-framework.md` | 467 | E2E vs API vs Component vs Unit decision matrix |
| `test-priorities-matrix.md` | 389 | P0-P3 classification with automated scoring |
| `test-quality.md` | 658 | Deterministic, isolated, explicit assertions |
| `selective-testing.md` | 727 | Tag-based, spec filters, avoid duplicate coverage |

### Playwright Utils Fragments (If `config.tea_use_playwright_utils: true`)

| Fragment | Description |
|----------|-------------|
| `overview.md` | Installation, design principles, fixture patterns |
| `api-request.md` | Typed HTTP client with schema validation |
| `network-recorder.md` | HAR record/playback for offline testing |
| `auth-session.md` | Token persistence, multi-user support |
| `intercept-network-call.md` | Network spy/stub with JSON parsing |
| `recurse.md` | Cypress-style polling for async conditions |
| `log.md` | Playwright report-integrated logging |
| `file-utils.md` | CSV/XLSX/PDF/ZIP reading and validation |
| `burn-in.md` | Smart test selection for CI |
| `network-error-monitor.md` | Automatic HTTP error detection |
| `fixtures-composition.md` | mergeTests composition patterns |

### Traditional Patterns (If `config.tea_use_playwright_utils: false`)

| Fragment | Lines | Description |
|----------|-------|-------------|
| `fixture-architecture.md` | 406 | Pure function → fixture → mergeTests |
| `network-first.md` | 489 | Intercept before navigate, HAR capture |

### Healing Fragments (For test healing workflows)

| Fragment | Lines | Description |
|----------|-------|-------------|
| `test-healing-patterns.md` | 648 | Stale selectors, race conditions, dynamic data |
| `selector-resilience.md` | 541 | data-testid > ARIA > text > CSS hierarchy |
| `timing-debugging.md` | 370 | Race condition prevention |

### Risk & Governance (For gate decisions)

| Fragment | Lines | Description |
|----------|-------|-------------|
| `risk-governance.md` | 625 | 6 risk categories, gate decision engine |
| `probability-impact.md` | 604 | Probability × impact matrix |

---

## Test Level Selection Framework

| Level | Use For | Characteristics |
|-------|---------|-----------------|
| **E2E** | Critical user journeys, multi-system integration | High confidence, slow, brittle |
| **API** | Business logic, service contracts, data transforms | Fast feedback, stable, balanced |
| **Component** | UI behavior, interaction, state management | Fast, isolated, granular |
| **Unit** | Pure logic, algorithms, edge cases | Fastest, most granular |

### Selection Rules

1. **Critical happy paths** → E2E (sparingly)
2. **Business logic variations** → API
3. **UI edge cases** → Component
4. **Pure logic edge cases** → Unit

### Avoid Duplicate Coverage

**BAD:** Same behavior at multiple levels
```
E2E: User can login → Dashboard loads
E2E: User can login with different emails → Dashboard loads (duplicate)
```

**GOOD:** Different aspects at appropriate levels
```
E2E: User can login → Dashboard loads (journey)
API: POST /auth/login returns 401 for invalid credentials (contract)
Component: LoginForm disables submit when fields empty (UI state)
Unit: validateEmail() returns false for malformed email (logic)
```

---

## Test Priority Framework

| Priority | Run When | Use For |
|----------|----------|---------|
| **P0** | Every commit | Critical user paths, security, data integrity |
| **P1** | PR to main | Important features, integration points |
| **P2** | Nightly | Edge cases, moderate impact |
| **P3** | On-demand | Nice-to-have, rarely-used features |

### Tagging Convention

```typescript
test('[P0] should login with valid credentials', async ({ page }) => { ... });
test('[P1] should display error for invalid credentials', async ({ page }) => { ... });
test('[P2] should remember login preference', async ({ page }) => { ... });
```

### Selective Execution

```bash
npm run test:e2e -- --grep "@P0"      # Critical paths only
npm run test:e2e -- --grep "@P0|@P1"  # Pre-merge
```

---

## Test Quality Standards

### Required for All Tests

| Standard | Description |
|----------|-------------|
| Given-When-Then | Clear structure |
| Explicit assertions | Not hidden in helpers |
| data-testid selectors | Stable identifiers |
| Self-cleaning | Fixtures with auto-cleanup |
| Deterministic | No flaky patterns |
| Fast | Under 90 seconds |
| Lean | Under 300 lines per file |

### Forbidden Patterns

```typescript
// ❌ Hard waits
await page.waitForTimeout(2000);

// ❌ Conditional flow
if (await element.isVisible()) { await element.click(); }

// ❌ Try-catch for test logic
try { await element.click(); } catch (e) { /* swallow */ }

// ❌ Hardcoded test data
const user = { email: 'test@example.com', password: 'password123' };
```

### Required Patterns

```typescript
// ✅ Explicit wait
await expect(page.locator('[data-testid="user-name"]')).toBeVisible();

// ✅ Deterministic assertion
await expect(element).toBeVisible();
await element.click();

// ✅ Factory for test data
const user = createUser(); // Uses faker

// ✅ Fixture with auto-cleanup
const test = base.extend({
  testUser: async ({ page }, use) => {
    const user = await createUser();
    await use(user);
    await deleteUser(user.id); // Auto-cleanup
  },
});
```

---

## Coverage Classification

| Status | Definition |
|--------|------------|
| **FULL** | All scenarios validated at appropriate level(s) |
| **PARTIAL** | Some coverage but missing edge cases or levels |
| **NONE** | No test coverage at any level |
| **UNIT-ONLY** | Only unit tests (missing integration/E2E) |
| **INTEGRATION-ONLY** | Only API/Component (missing unit confidence) |

---

## Gate Decision Thresholds

| Criterion | PASS | CONCERNS | FAIL |
|-----------|------|----------|------|
| P0 Coverage | 100% | N/A | <100% |
| P1 Coverage | ≥90% | 80-89% | <80% |
| Overall Coverage | ≥80% | 70-79% | <70% |
| P0 Pass Rate | 100% | N/A | <100% |
| P1 Pass Rate | ≥95% | 90-94% | <90% |
| Overall Pass Rate | ≥90% | 85-89% | <85% |

---

## Fixture Architecture

### Pattern: Pure Function → Fixture → Test

```typescript
// 1. Pure function (factories/)
export const createUser = (overrides = {}) => ({
  id: faker.number.int(),
  email: faker.internet.email(),
  ...overrides,
});

// 2. Fixture (fixtures/)
export const test = base.extend({
  authenticatedUser: async ({ page }, use) => {
    const user = await createUser();
    await login(page, user);
    await use(user);
    await deleteUser(user.id);
  },
});

// 3. Test (specs/)
test('[P0] should show dashboard', async ({ page, authenticatedUser }) => {
  await expect(page.locator('[data-testid="welcome"]')).toHaveText(
    `Welcome, ${authenticatedUser.email}`
  );
});
```

---

## Network-First Pattern

**Critical:** Intercept routes BEFORE navigation to prevent race conditions.

```typescript
// ✅ CORRECT
await page.route('**/api/user', (route) =>
  route.fulfill({ status: 200, body: JSON.stringify({ id: 1, name: 'Test' }) })
);
await page.goto('/dashboard');

// ❌ WRONG
await page.goto('/dashboard');
await page.route('**/api/user', ...); // Too late - request already fired
```

---

## Test ID Conventions

| Format | Example | Use |
|--------|---------|-----|
| `{STORY_ID}-{LEVEL}-{SEQ}` | `1.3-E2E-001` | Story-linked tests |
| `{FEATURE}-{LEVEL}-{SEQ}` | `AUTH-API-002` | Feature-based tests |

Enables:
- Traceability matrix generation
- Selective test execution
- Gap analysis by story/feature
