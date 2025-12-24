# Protocol: Checkpoint Signal Format

**ID:** checkpoint_signal_format
**Purpose:** Documents the exact signal format for hook detection

---

## Signal Format

The signal format must be EXACT - first line triggers hook:

```
═══ SAGE_SIGNAL:CHECKPOINT ═══
CHECKPOINT_FILE: .sage/state/{epic_id}.json
COMMIT: {40-char-git-hash}
NEXT_ACTION: {continue|retry|hitl|spawn|complete}
═══════════════════════════════
```

Hook regex for detection: `^═{3,}\s*SAGE_SIGNAL:CHECKPOINT\s*═{3,}$`

---

## Hook Response Sequence

1. Hook detects unique signal line pattern
2. Hook writes checkpoint path to `.sage/state/.pending_checkpoint`
3. Hook exits with code 2 (blocking)
4. External orchestrator (`sage/bin/orchestrate.sh`) restarts Claude
5. Orchestrator passes resume command with checkpoint path

---

## Notes

- First line MUST match: `═══ SAGE_SIGNAL:CHECKPOINT ═══`
- This unique pattern prevents false triggers on code that mentions checkpoints
- Field names must be UPPERCASE
- No extra whitespace or formatting
- NEXT_ACTION determines resume behavior
