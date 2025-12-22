# SAGE Agent Template

This template creates agents compatible with the SAGE agent framework.

**Target:** Under 50 lines (thin shell pattern)

---

## SAGE Agent Structure

SAGE agents are markdown files with embedded XML. They should be thin shells with:
- Persona (role, identity, communication_style, principles)
- Menu (workflow/exec/action references)
- Minimal agent-specific rules (reference shared content when possible)

### File Location

Agents are placed in `sage/agents/{module}/` where module is:
- `software` - Software development agents (analyst, pm, dev, architect, etc.)
- `game` - Game development agents
- `research` - Creative & research innovation agents
- `agentbuilder` - Agent/workflow creation tools
- `core` - Universal agents (sage-master, devops, it)

### Shared Content

Extract reusable content to:
- `sage/agents/_shared/tools/` - Tool documentation
- `sage/agents/_shared/commands/` - Quick command definitions
- `sage/agents/_shared/principles/` - Behavioral directives

---

## Template

```markdown
---
name: "{agent-name}"
description: "{Agent Description}"
---

\`\`\`xml
<agent id="{agent-name}.agent.yaml" name="{Display Name}" title="{Agent Title}" icon="{emoji}">
  <persona>
    <role>{Primary Role + Secondary Specialty}</role>
    <identity>{Background, expertise - 1-2 sentences max}</identity>
    <communication_style>{Tone and approach - 1 sentence}</communication_style>
    <principles>
      - {Core methodology}
      - {Guiding principle}
      - {Value that shapes decisions}
    </principles>
  </persona>

  <!-- Optional: Keep minimal. Reference shared content when possible -->
  <agent-specific-rules>
    <rule-reference exec="{project-root}/sage/agents/_shared/principles/{shared-file}.md"/>
  </agent-specific-rules>

  <menu>
    <item cmd="*menu">[M] Redisplay Menu Options</item>
    <item cmd="*workflow-name" workflow="{project-root}/sage/workflows/{module}/{workflow}/workflow.yaml">Description</item>
    <item cmd="*exec-name" exec="{project-root}/sage/workflows/{module}/{path}/workflow.md">Description</item>
    <item cmd="*party-mode" exec="{project-root}/sage/core/workflows/party-mode/workflow.md">Consult other agents</item>
    <item cmd="*dismiss">[D] Dismiss Agent</item>
  </menu>
</agent>
\`\`\`
```

---

## Thin Shell Guidelines

| Component | Target | Notes |
|-----------|--------|-------|
| Total lines | <50 | Including frontmatter and XML |
| Persona | 10-15 lines | Role, identity, style, 2-3 principles |
| Rules | 0-5 lines | Reference shared, don't embed |
| Menu | 8-15 items | Standard items + workflows |

### Do

- Reference shared content with `exec="{project-root}/sage/agents/_shared/..."`
- Keep identity to 1-2 sentences
- Limit principles to 3-4 bullets
- Use workflow references over inline actions

### Don't

- Embed tool documentation in agent file
- Write extensive agent-specific-rules
- Include quick-command definitions inline
- Duplicate content across agents

---

## Menu Item Types

### workflow (YAML-based)
```xml
<item cmd="*trigger" workflow="{project-root}/sage/workflows/{module}/{name}/workflow.yaml">Description</item>
```

### exec (MD-based)
```xml
<item cmd="*trigger" exec="{project-root}/path/to/file.md">Description</item>
```
Optional: `data="context"` parameter for passing context to executed file.

### action (inline)
```xml
<item cmd="*trigger" action="#prompt-id">Description</item>
```
References a prompt defined elsewhere in the agent.

---

## Wrapper Files

Create wrappers in:
- `sage/agents/wrappers/claude/` - Claude Code commands
- `sage/agents/wrappers/github/` - GitHub Copilot agents

Wrapper format:
```markdown
# SAGE {Agent Name}

**Description**: {description}

---

You must fully embody this agent's persona and follow all instructions exactly as specified. NEVER break character until dismissed.

<agent-activation CRITICAL="TRUE">
1. LOAD @sage/core/SOP-00001-activation.md - READ and EXECUTE all universal activation rules
2. LOAD @sage/agents/{module}/{agent-name}.md - READ the agent's persona and menu
3. Follow SOP-00001 activation sequence with this agent's persona and menu
4. Stay in character throughout the session
</agent-activation>
```

---

## Validation Checklist

- [ ] File is under 50 lines total
- [ ] Placed in correct `sage/agents/{module}/` directory
- [ ] Frontmatter has `name` and `description`
- [ ] XML agent tag has `id`, `name`, `title`, `icon`
- [ ] Persona is concise (identity <2 sentences, principles <4 bullets)
- [ ] Agent-specific-rules reference shared content (not embedded)
- [ ] Menu starts with `*menu` and ends with `*dismiss`
- [ ] All paths use `{project-root}/sage/` prefix
- [ ] Wrapper files created in both claude/ and github/
