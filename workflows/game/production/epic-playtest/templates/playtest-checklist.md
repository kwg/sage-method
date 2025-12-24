# Epic Playtest Checklist Template

**Epic**: [Epic Number and Title]
**Date**: YYYY-MM-DD
**Tester**: [Name]
**Version/Commit**: [Git hash]

---

## Section 1: Structured Testing (AC Verification)

### Story X.X: [Story Title]

| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | [Copy from story] | [ ] | [ ] | |
| AC2 | [Copy from story] | [ ] | [ ] | |
| AC3 | [Copy from story] | [ ] | [ ] | |

### Story X.X: [Story Title]

| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | [Copy from story] | [ ] | [ ] | |
| AC2 | [Copy from story] | [ ] | [ ] | |

[Repeat for all stories in epic]

---

## Section 2: Free Testing (Exploratory)

### Testing Goals

Before testing, define 3-5 specific goals:

1. **Goal**: [What you'll try to break]
   - **Result**: [ ] Found issues [ ] No issues
   - **Bugs filed**: [Bug IDs or "None"]

2. **Goal**:
   - **Result**: [ ] Found issues [ ] No issues
   - **Bugs filed**:

3. **Goal**:
   - **Result**: [ ] Found issues [ ] No issues
   - **Bugs filed**:

### Edge Cases Tested

| Scenario | Expected | Actual | Bug? |
|----------|----------|--------|------|
| [e.g., "0 cards in deck"] | [Expected behavior] | [What happened] | [ ] |
| [e.g., "Rapid clicking"] | | | [ ] |
| [e.g., "Alt-tab during animation"] | | | [ ] |

---

## Section 3: Gameplay Testing

### Session Log

| Combat # | Turns | Cards Played | Damage Dealt | Damage Taken | Outcome |
|----------|-------|--------------|--------------|--------------|---------|
| 1 | | | | | [ ] Win [ ] Loss |
| 2 | | | | | [ ] Win [ ] Loss |
| 3 | | | | | [ ] Win [ ] Loss |

### Balance Observations

**What felt too strong?**
-

**What felt too weak?**
-

**What felt unfair?**
-

### Fun Assessment

| Aspect | Rating (1-5) | Notes |
|--------|--------------|-------|
| Overall | | |
| Core mechanic | | |
| Difficulty | | |
| Pacing | | |

---

## Section 4: Sign-Off Criteria

All must be checked to mark epic playtest complete:

- [ ] All structured tests passed (or bugs filed)
- [ ] At least 3 exploratory goals tested
- [ ] At least 3 gameplay sessions logged
- [ ] All A/B severity bugs filed
- [ ] Gameplay feedback template completed
- [ ] Tester signature: ________________

---

## Summary

**Structured Testing**: ___ / ___ ACs passed

**Bugs Found**:
- Severity A: ___
- Severity B: ___
- Severity C: ___

**Blocking Issues**: [ ] Yes [ ] No

If blocking issues exist:
- [ ] Epic CANNOT be marked complete
- [ ] Bug IDs: _______________

**Recommendation**:
[ ] Ready for release
[ ] Needs fixes (list bug IDs)
[ ] Needs redesign (explain why)

---

## Epic 2 Specific Checklist

### Story 2-1: Card Data Structure and Loading
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | CardData resource with all properties | [ ] | [ ] | |
| AC2 | CardLoader validates and loads cards | [ ] | [ ] | |
| AC3 | Starter deck loads correctly | [ ] | [ ] | |

### Story 2-2: Hand Management
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | CardHand displays cards | [ ] | [ ] | |
| AC2 | Cards can be selected | [ ] | [ ] | |
| AC3 | Visual feedback on selection | [ ] | [ ] | |

### Story 2-3: Stack Creation and Target Assignment
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | Stacks created on enemies | [ ] | [ ] | |
| AC2 | Cards added to existing stacks | [ ] | [ ] | |
| AC3 | StackVisual shows cards | [ ] | [ ] | |

### Story 2-4: LIFO Stack Resolution
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | Top card resolves first | [ ] | [ ] | |
| AC2 | Flash card prompt appears | [ ] | [ ] | |
| AC3 | Effect applies on correct answer | [ ] | [ ] | |

### Story 2-5: Plays Resource System
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | 3 plays per turn | [ ] | [ ] | |
| AC2 | New stack costs 1 play | [ ] | [ ] | |
| AC3 | Adding to stack is free | [ ] | [ ] | |
| AC4 | PlaysDisplay shows count | [ ] | [ ] | |

### Story 2-6: Card Effects Framework
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | Attack cards deal damage | [ ] | [ ] | |
| AC2 | Defend cards grant block | [ ] | [ ] | |
| AC3 | Keywords modify effects | [ ] | [ ] | |

### Story 2-7: Card Upgrade System
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | Cards can be upgraded | [ ] | [ ] | |
| AC2 | Upgraded cards show visual | [ ] | [ ] | |
| AC3 | Values increase on upgrade | [ ] | [ ] | |

### Story 2-8: Integration
| AC | Description | Pass | Fail | Notes |
|----|-------------|------|------|-------|
| AC1 | Full combat loop works | [ ] | [ ] | |
| AC2 | All systems connected | [ ] | [ ] | |
| AC3 | No integration errors | [ ] | [ ] | |
