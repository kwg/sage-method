# Project-Specific SAGE Extensions

This directory contains project-specific extensions to the core SAGE framework.

**Note:** This is a template for your project's SAGE extensions. Customize as needed.

## Structure

- `agents/` - Custom agents specific to this project
- `workflows/` - Custom workflows specific to this project
- `knowledge/` - Project-specific TEA knowledge base entries
- `config.yaml` - Project configuration (overrides sage/core/config.yaml)

## Configuration Hierarchy

1. `sage/core/config.yaml` - Framework defaults (no project-specific data)
2. `project-sage/config.yaml` - Project overrides (this file's directory)
3. Values in project-sage override values in sage/core

## Usage

Core SAGE agents automatically discover and load extensions from this directory.

### Adding Custom Agents

Create agent files in `agents/` following the same format as core agents in `sage/agents/`.

### Adding Custom Workflows

Create workflow files in `workflows/` following the SAGE workflow format.

## Important

- Do NOT modify core SAGE files in `sage/` directory for project-specific needs
- Use this directory for project-specific additions only
- Changes to SAGE core behavior should be made in the sage/ submodule
