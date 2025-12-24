# Bug Report Template

---

## Bug Information

**Title**: [Brief description of the bug]

**Severity**: [ ] A (Critical) [ ] B (Major) [ ] C (Minor)

**Repro Rate**: ___ of ___ attempts

**Date Found**: YYYY-MM-DD
**Tester**: [Name]
**Version/Commit**: [Git hash or version]

---

## Environment

**Platform**: [ ] Windows [ ] macOS [ ] Linux
**Resolution**: [e.g., 1920x1080]
**Godot Version**: [e.g., 4.5.1]

---

## Steps to Reproduce

1. [Starting state - be specific]
2. [Action 1]
3. [Action 2]
4. [Continue as needed...]

---

## Expected Result

[What should have happened]

---

## Actual Result

[What actually happened]

---

## Evidence

**Screenshot(s)**: [Attach or link]
**Video**: [Link if available]
**Log Output**: [Paste relevant log lines]

---

## Additional Notes

[Any other context, workarounds found, related issues, etc.]

---

## Severity Definitions

### A - Critical
- Game crashes or freezes
- Data loss or corruption
- Cannot progress in game
- Security vulnerability
- Game is unplayable

### B - Major
- Feature doesn't work as designed
- Significant gameplay impact
- Major UI/UX issues
- Incorrect calculations affecting balance
- Blocking tester from completing structured tests

### C - Minor
- Cosmetic/visual issues
- Typos or text issues
- Minor animation glitches
- Edge cases with easy workarounds
- Polish items

---

## Example Bug Report

**Title**: Cards disappear when dragging to enemy during phase transition

**Severity**: [X] B (Major)

**Repro Rate**: 8 of 10 attempts

**Date Found**: 2025-12-14
**Tester**: [Your Name]
**Version/Commit**: [commit-hash]

**Environment**: Linux, 1920x1080, Godot 4.5.1

**Steps to Reproduce**:
1. Start new combat with any enemies
2. During PLAN phase, select a card from hand
3. Begin dragging card toward enemy
4. While dragging, click "End Turn" or let timer expire
5. Observe the card

**Expected Result**: Card returns to hand when phase changes

**Actual Result**: Card visually disappears. Card is no longer in hand, draw pile, or discard pile.

**Evidence**: [screenshot.png]

**Additional Notes**: Happens more frequently with faster clicks. Card count in deck manager decreases permanently.
