# Shared Persona Fragments

**Version:** 1.0
**Purpose:** Reusable persona fragments for agent composition

---

## Overview

Persona fragments are modular traits that can be composed to build agent personas. Instead of defining complete personas for each agent, fragments allow mixing and matching specific qualities.

---

## Available Fragments

| Fragment | Purpose | Use Case |
|----------|---------|----------|
| [tdd-practitioner.md](./tdd-practitioner.md) | Test-driven development mindset | Implementation agents |
| [data-driven.md](./data-driven.md) | Evidence-based decision making | Analysis agents |
| [user-focused.md](./user-focused.md) | User experience priority | Design agents |
| [precision-communicator.md](./precision-communicator.md) | Clear, concise communication | All agents |
| [creative-storyteller.md](./creative-storyteller.md) | Narrative and creative expression | Game/content agents |
| [systematic-thinker.md](./systematic-thinker.md) | Structured problem solving | Architecture agents |

---

## Usage Pattern

### In Agent Definition

```xml
<agent id="software/dev">
  <persona>
    <!-- Compose from fragments -->
    <compose-from>
      <fragment>_shared/personas/tdd-practitioner.md</fragment>
      <fragment>_shared/personas/precision-communicator.md</fragment>
    </compose-from>

    <!-- Override or extend as needed -->
    <role>Software Developer</role>
    <additional-traits>
      - Specific domain expertise
      - Project-specific conventions
    </additional-traits>
  </persona>
</agent>
```

### In Workflow Context

```xml
<subagent-spawn>
  <persona-fragments>
    - tdd-practitioner
    - systematic-thinker
  </persona-fragments>
  <context>{{bounded_context}}</context>
</subagent-spawn>
```

---

## Fragment Structure

Each fragment follows this structure:

```markdown
# Fragment Name

## Core Trait
Brief description of the core trait.

## Behaviors
- Specific behaviors this trait exhibits
- Observable patterns in work

## Communication Style
How this trait affects communication.

## Decision Making
How this trait influences decisions.

## Anti-patterns
What this trait explicitly avoids.
```

---

## Composition Guidelines

1. **Complementary Fragments**: Choose fragments that complement each other
2. **Avoid Conflicts**: Don't combine conflicting traits (e.g., "move-fast" with "thorough-review")
3. **Role Alignment**: Match fragments to the agent's primary role
4. **Context Override**: Agent-specific traits can override fragment defaults

---

## Creating New Fragments

1. Identify a reusable trait pattern
2. Extract core behaviors and communication style
3. Document anti-patterns (what the trait avoids)
4. Add to this directory with clear naming
5. Update this README

---

## Fragment Combinations by Role

| Role | Recommended Fragments |
|------|----------------------|
| Developer | tdd-practitioner, precision-communicator |
| Architect | systematic-thinker, data-driven |
| Designer | user-focused, creative-storyteller |
| Analyst | data-driven, systematic-thinker |
| PM | user-focused, precision-communicator |
| Reviewer | systematic-thinker, precision-communicator |
