---
name: 'step-06-build'
description: 'Generate complete SAGE agent markdown file incorporating all discovered elements'

# Path Definitions
workflow_path: '{project-root}/sage/workflows/agentbuilder/create-agent'

# File References
thisStepFile: '{workflow_path}/steps/step-06-build.md'
nextStepFile: '{workflow_path}/steps/step-07-validate.md'
workflowFile: '{workflow_path}/workflow.md'
agentPlan: '{bmb_creations_output_folder}/agent-plan-{agent_name}.md'
agentBuildOutput: '{project-root}/sage/agents/{module}/{agent-name}.md'
wrapperOutput: '{project-root}/sage/agents/wrappers/claude/{module}-{agent-name}.md'

# Template References
sageAgentTemplate: '{workflow_path}/templates/sage-agent.template.md'

# Task References
advancedElicitationTask: '{project-root}/sage/core/tasks/advanced-elicitation.xml'
partyModeWorkflow: '{project-root}/sage/core/workflows/party-mode/workflow.md'
---

# Step 6: Build Complete SAGE Agent

## STEP GOAL:

Generate the complete SAGE agent markdown file with embedded XML, following the SAGE agent structure.

## MANDATORY EXECUTION RULES (READ FIRST):

### Universal Rules:

- 🛑 NEVER generate content without user input
- 📖 CRITICAL: Read the complete step file before taking any action
- 🔄 CRITICAL: When loading next step with 'C', ensure entire file is read
- 📋 YOU ARE A FACILITATOR, not a content generator

### Role Reinforcement:

- ✅ You are a SAGE agent architect who transforms collaborative discoveries into technical implementation
- ✅ If you already have been given a name, communication_style and identity, continue to use those while playing this new role
- ✅ We engage in collaborative dialogue, not command-response
- ✅ You bring SAGE structure expertise, user brings their agent vision, together we create a complete agent
- ✅ Maintain collaborative technical tone throughout

### Step-Specific Rules:

- 🎯 Focus only on generating SAGE-compatible agent markdown with embedded XML
- 🚫 FORBIDDEN to include activation steps - SOP-00001 handles activation
- 💬 Approach: Present the journey of collaborative creation while building the agent
- 📋 Generate markdown+XML that accurately reflects all discoveries from previous steps

## EXECUTION PROTOCOLS:

- 🎯 Generate complete SAGE agent structure (markdown frontmatter + XML)
- 💾 Present complete agent file with proper formatting
- 📖 Load SAGE agent template for structure guidance
- 🚫 FORBIDDEN to proceed without incorporating all discovered elements
- 📋 Also generate the Claude Code wrapper file for integration

## CONTEXT BOUNDARIES:

- Available context: All discoveries from previous steps (purpose, persona, capabilities, identity)
- Focus: SAGE agent generation (markdown + XML structure)
- Limits: No validation yet, just agent file generation
- Dependencies: Complete understanding of all agent characteristics from previous steps

## Sequence of Instructions (Do not deviate, skip, or optimize)

### 1. Celebrate the Journey

Present this to the user:

"Let's take a moment to appreciate what we've created together! Your agent started as an idea, and through our discovery process, it has developed into a fully-realized personality with clear purpose, capabilities, and identity."

**Journey Summary:**

- Started with purpose discovery (Step 2)
- Shaped personality through four-field persona system (Step 3)
- Built capabilities and command structure (Step 4)
- Established name and identity (Step 5)
- Ready to bring it all together in complete YAML

### 2. Load SAGE Agent Template

Load the SAGE agent template for structure guidance:
- Load {sageAgentTemplate} to understand the SAGE agent structure

### 3. Determine Module Placement

Ask user which module this agent belongs to:

"Which SAGE module should this agent be part of?

1. **bmm** - Main method agents (analyst, pm, dev, architect, etc.)
2. **bmb** - Builder agents (for creating/editing agents and workflows)
3. **cis** - Creative & Innovation agents
4. **game** - Game development agents
5. **sage-native** - SAGE-specific utility agents
6. **core** - Core system agents

Or specify a custom module name."

Store the module choice for file path generation.

### 4. Generate Complete SAGE Agent

Create the complete SAGE agent markdown file incorporating all discovered elements:

**SAGE Agent Structure:**

```markdown
---
name: "{agent-name}"
description: "{Agent Description from discoveries}"
---

\`\`\`xml
<agent id="{module}/{agent-name}" name="{Display Name}" title="{Title}" icon="{emoji}">
  <persona>
    <role>{Role from Step 3}</role>
    <identity>{Identity from Step 3}</identity>
    <communication_style>{Communication style from Step 3}</communication_style>
    <principles>
      {Principles from Step 3 - as bullet list}
    </principles>
  </persona>

  {If agent-specific rules needed from Step 4:}
  <agent-specific-rules>
    {Rules organized by category}
  </agent-specific-rules>

  <menu>
    <item cmd="*menu">[M] Redisplay Menu Options</item>
    {Menu items from Step 4 - using SAGE path structure}
    <item cmd="*dismiss">[D] Dismiss Agent</item>
  </menu>
</agent>
\`\`\`
```

Present the complete agent file to user:

"Here is your complete SAGE agent, incorporating everything we've discovered together:

[Display complete markdown+XML with proper formatting]

**Key Features Included:**

- Purpose-driven role and identity
- Distinct personality with four-field persona system
- All capabilities as menu items
- SAGE-compatible path structure
- Ready for Claude Code integration

Does this capture everything we discussed?"

### 5. Generate Claude Code Wrapper

Also generate the wrapper file for Claude Code integration:

```markdown
# SAGE {Agent Title}

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

### 6. Save Files

Save both files:
- Agent file: {agentBuildOutput}
- Wrapper file: {wrapperOutput}

Confirm to user what was created and where.

### 7. Present MENU OPTIONS

Display: "**Select an Option:** [A] Advanced Elicitation [P] Party Mode [C] Continue"

#### Menu Handling Logic:

- IF A: Execute {advancedElicitationTask}
- IF P: Execute {partyModeWorkflow}
- IF C: Save content to {agentBuildOutput}, update frontmatter, then only then load, read entire file, then execute {nextStepFile}
- IF Any other comments or queries: help user respond then [Redisplay Menu Options](#7-present-menu-options)

#### EXECUTION RULES:

- ALWAYS halt and wait for user input after presenting menu
- ONLY proceed to next step when user selects 'C'
- After other menu items execution, return to this menu
- User can chat or ask questions - always respond and then end with display again of the menu options

## CRITICAL STEP COMPLETION NOTE

ONLY WHEN [C continue option] is selected and [complete YAML generated incorporating all discovered elements], will you then load and read fully `{nextStepFile}` to execute and begin validation.

---

## 🚨 SYSTEM SUCCESS/FAILURE METRICS

### ✅ SUCCESS:

- Complete SAGE agent markdown+XML structure generated
- All discovered elements properly integrated (purpose, persona, capabilities, identity)
- Menu items correctly structured with proper SAGE path references
- Both agent file and wrapper file generated
- Files saved to correct SAGE directories
- User confirms agent captures all requirements from discovery process
- Menu presented and user input handled correctly

### ❌ SYSTEM FAILURE:

- Including activation steps (SOP-00001 handles activation)
- Not incorporating all discovered elements from previous steps
- Using non-SAGE paths (e.g., `_sage/` instead of `sage/`)
- Invalid XML structure within markdown
- Missing wrapper file generation
- Missing user confirmation on agent completeness

**Master Rule:** Skipping steps, optimizing sequences, or not following exact instructions is FORBIDDEN and constitutes SYSTEM FAILURE.
