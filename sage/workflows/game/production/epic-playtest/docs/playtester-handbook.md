# Playtester Handbook

**Version**: 1.0
**Based on**: Schultz/Bryant "Game Testing: All in One" (2011)

---

## 1. Testing Types

### Structured Testing
- **Purpose**: Verify acceptance criteria systematically
- **Process**: Follow the epic playtest checklist item by item
- **Documentation**: Mark each item pass/fail with notes
- **When**: First pass on any new epic/feature

### Free Testing (Exploratory)
- **Purpose**: Find edge cases and unexpected behaviors
- **Process**: Set explicit goals before testing, then explore freely
- **Goals Examples**:
  - "What happens if I try to play cards after combat ends?"
  - "Can I crash the game by rapid-clicking?"
  - "What happens with 0 cards in deck?"
- **Documentation**: Record what you tried and what happened

### Gameplay Testing
- **Purpose**: Evaluate balance, difficulty, and fun factor
- **Process**: Play normally, note feelings and observations
- **Focus Areas**:
  - Is it fun? Why or why not?
  - Is it too easy or too hard?
  - Does anything feel unfair?
- **Documentation**: Lead with feeling, follow with reason

---

## 2. Goal Setting

Before each testing session:

1. **State your objective** - What are you testing?
2. **Set a time limit** - 30-60 minutes recommended
3. **Choose your testing type** - Structured, Free, or Gameplay
4. **Prepare recording tools** - Screenshots, video, or notes

Example goals:
- "Verify all Epic 2 acceptance criteria (45 min, structured)"
- "Try to break the card playing system (30 min, free)"
- "Play through combat 3 times, note balance issues (60 min, gameplay)"

---

## 3. Documentation

### The Golden Rule
**"If you're not recording, you're not testing."**

### What to Record
- **Time and date** of testing session
- **Version/commit** being tested
- **Your testing goal**
- **Every bug found** (use Bug Report Template)
- **Every observation** (use Gameplay Feedback Template)

### Recording Methods
1. **Written notes** - Quick and always available
2. **Screenshots** - F12 or Print Screen
3. **Video** - OBS or built-in tools
4. **Audio notes** - Voice memo while playing

---

## 4. Bug Reporting

### Severity Levels (A/B/C)

**A - Critical**
- Game crashes
- Data loss/corruption
- Progression blocked (can't continue)
- Security issues
- Game becomes unplayable

**B - Major**
- Feature doesn't work as intended
- Significant gameplay impact
- Confusing/broken UI
- Wrong calculations affecting balance

**C - Minor**
- Cosmetic issues
- Typos
- Minor visual glitches
- Edge cases with workarounds

### Repro Rate
Always express as "X out of Y attempts":
- "8 of 10" - Very reproducible
- "3 of 10" - Sometimes happens
- "1 of 10" - Rare but confirmed

### Steps to Reproduce
Be specific:
1. Start from a known state (e.g., "New combat with 2 enemies")
2. List exact actions in order
3. Include wait times if relevant
4. Describe expected vs actual result

---

## 5. Gameplay Feedback

### Lead with Feeling, Follow with Reason

**Format**: "I felt [emotion] when [situation] because [reason]"

**Good**: "I felt frustrated when my stack fizzled because I didn't realize wrong answers had consequences."

**Bad**: "Wrong answers are too punishing." (No feeling, no context)

### Factual Observations
Separate facts from opinions:
- **Fact**: "I won combat in 2 turns"
- **Opinion**: "Combat is too short"

### Balance Concerns
Report what you observed, not what you think should change:
- **Do**: "Strike dealt 12 damage which killed the enemy in one hit"
- **Don't**: "Strike should deal less damage"

---

## 6. Balance Testing

### What to Track
- Turns to complete combat
- Cards played per turn
- Damage dealt vs taken
- How often you run out of plays
- Which cards you used most/least

### Recording Format
```
Combat #1:
- Turns: 4
- Cards played: 12
- Damage dealt: 45
- Damage taken: 8
- Notes: Never used Defend cards
```

---

## 7. Fresh Eyes Protocol

### Why Rotate Testers
"Snow blindness" - Familiarity makes you miss issues that new players would catch.

### Rotation Guidelines
- Switch primary tester after 3-4 sessions
- Have someone unfamiliar do the first structured test
- Return after 1+ week for fresh perspective

### Roles
- **Primary Tester**: Does main structured testing
- **Exploratory Tester**: Tries to break things
- **Gameplay Tester**: Evaluates fun and balance
- **Fresh Eyes**: New to feature, catches obvious issues

---

## Quick Reference

| Testing Type | Goal | Output |
|-------------|------|--------|
| Structured | Verify ACs | Checklist + bugs |
| Free | Find edge cases | Bug reports |
| Gameplay | Evaluate fun | Feedback template |

| Severity | Example | Impact |
|----------|---------|--------|
| A | Crash | Blocks all testing |
| B | Feature broken | Blocks feature testing |
| C | Typo | Note and continue |

---

## Templates

- [Bug Report Template](../templates/bug-report-template.md)
- [Gameplay Feedback Template](../templates/gameplay-feedback.md)
- [Playtest Checklist Template](../templates/playtest-checklist.md)
