# Documentation Standards for SAGE

This document defines documentation standards for the SAGE agent system.

## Principles

1. **Clarity**: All documentation should be clear and unambiguous
2. **Completeness**: Cover all essential aspects of the system
3. **Maintainability**: Keep documentation up-to-date with code changes
4. **Accessibility**: Make docs easily discoverable and readable

## File Organization

- **Agent definitions**: `sage/agents/*.md`
- **Agent overlays**: `sage/agents/overlays/*-overlay.md`
- **Workflows**: `sage/workflows/software/{category}/{workflow-name}/`
- **SOPs**: `sage/` (top level)
- **Reference docs**: `docs/reference/`
- **Project docs**: `docs/`

## Markdown Conventions

- Use ATX-style headers (`#` not `===`)
- Include frontmatter for metadata
- Use code blocks with language tags
- Link to related documents with relative paths

## Agent Documentation

Agent files should include:
- YAML frontmatter with name, description
- Persona definition
- Activation instructions
- Menu items with clear descriptions
- Rules and constraints

## Workflow Documentation

Workflows should include:
- workflow.yaml with configuration
- instructions.xml with execution steps
- checklist.md for validation (optional)
- README.md with overview (optional)

## Status Indicators

Use these status indicators consistently:
- **Status**: Not Implemented
- **Status**: Draft
- **Status**: Active
- **Status**: Deprecated
- **Status**: Archived

## Version Control

- Document changes in commit messages
- Update modification dates in frontmatter
- Note breaking changes prominently
