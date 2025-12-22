# Learn From This Workflow

## Overview

The **Learn From This** workflow enables all SAGE agents to capture PROBLEM-SOLUTION pairs and automatically modify their agent files and SOPs to prevent repeated errors. This is a self-improvement mechanism focused on **prevention**, not optimization.

## Purpose

- **Stop repeated errors** by capturing learnings and encoding them into agent behavior
- **Self-healing system** that improves based on actual problems encountered
- **Knowledge accumulation** through learning records that persist over time
- **Proactive prevention** by modifying agents before problems recur

## Trigger Word

**`LearnFromThis`** or menu command **`*learn-from-this`**

All agents listen for this trigger and can execute the workflow.

## Usage Modes

### Mode 1: Auto-Detection (No Text Provided)

User simply says: `LearnFromThis`

The agent will:
1. Analyze recent conversation history (last 10-20 exchanges)
2. Look for PROBLEM-SOLUTION patterns (errors → fixes, attempts → success)
3. Present identified problem and solution for confirmation
4. Proceed with learning capture if confirmed

### Mode 2: User Points to Solution (Text Provided)

User says: `LearnFromThis [description pointing to solution]`

The agent will:
1. Treat user input as pointing to the SOLUTION
2. Review recent conversation to identify the PROBLEM
3. Ask for confirmation or clarification
4. Proceed with learning capture

## Workflow Steps

1. **Identify Problem and Solution**: Detect or clarify the problem-solution pair
2. **Analyze Root Cause**: Determine why the problem occurred and what category it falls into
3. **Generate File Modifications**: Create specific edits to agent files or SOPs
4. **Execute File Modifications**: Apply the changes to relevant files
5. **Create Learning Record**: Document the learning for future reference
6. **Verify and Commit**: Optional review and commit of changes

## Root Cause Categories

- **Instruction Gap**: Missing or unclear agent/workflow instructions
- **Validation Missing**: No check to catch the error before it occurred
- **Assumption Error**: Incorrect assumptions due to ambiguous guidance
- **Tool Misuse**: Incorrect tool usage or missing tool guidance
- **Context Loss**: Agent didn't maintain or retrieve critical context
- **Sequencing Error**: Steps executed in wrong order
- **Communication Failure**: Agent didn't ask for clarification when needed
- **Pattern Not Recognized**: Known scenario not recognized by agent

## Files Modified

The workflow may modify:
- **Agent files** (`sage/agents/*.md`): Activation steps, rules, menu handlers
- **Workflow files** (`sage/workflows/**/*.md` or `*.yaml`): Instructions, checklists, steps
- **SOP files** (`sage/workflows/*.md`): Standard operating procedures
- **Core task files** (if issue is systemic)

## Output

### Learning Records
Location: `{output_folder}/learning-records/learning-record-{date}.md`

Each learning record contains:
- Problem and solution summary
- Root cause category
- List of files modified
- Prevention mechanism explanation
- Verification steps
- Related patterns and considerations

### Modified Files
All changes are tracked and can be committed with a descriptive commit message.

## Example Scenarios

### Scenario 1: Agent Forgot to Run Tests
**Problem**: Agent marked task complete without running tests  
**Solution**: Added explicit test execution to task completion checklist  
**Prevention**: Modified agent activation step to ALWAYS run tests before marking complete

### Scenario 2: Missing Config File Load
**Problem**: Agent tried to use config values without loading config file  
**Solution**: Added config load to startup sequence  
**Prevention**: Added mandatory config load step in agent activation with HALT if missing

### Scenario 3: Wrong Tool Used
**Problem**: Agent used grep_search when semantic_search would be better  
**Solution**: Clarified when to use each search tool  
**Prevention**: Added decision tree to tool usage rules in agent file

## Benefits

- **Reduces Token Waste**: Prevent repeated errors that waste context
- **Improves Reliability**: Agents learn from mistakes and don't repeat them
- **Knowledge Base**: Accumulated learning records show patterns
- **Autonomous Improvement**: System gets better without manual intervention
- **Targeted Changes**: Only modifies what's needed to prevent specific issues

## Integration with All Agents

Every agent in the system now has the `*learn-from-this` menu item:
- dev (Amelia)
- pm (John)
- sm (Bob)
- architect (Winston)
- analyst (Mary)
- devops (Nick)
- it (Sarah)
- tea (Murat)
- tech-writer (Paige)
- ux-designer (Sally)
- quick-flow-solo-dev (Barry)

## When NOT to Use

- For optimization or refactoring (use separate optimization workflow)
- For general improvements without specific problem
- When problem is external (tool limitation, API issue)
- When solution is uncertain or speculative

## Quality Gates

The workflow will HALT if:
- Problem cannot be clearly defined or verified
- Solution didn't actually fix the problem
- Root cause is unknown or purely speculative
- Prevention strategy would break existing functionality
- File modifications would create conflicts
- User does not approve the approach

## Future Enhancements

Consider creating a separate optimization workflow to:
- Consolidate multiple related learnings
- Streamline redundant instructions
- Refactor agent files for clarity
- Identify systemic patterns requiring architectural changes
