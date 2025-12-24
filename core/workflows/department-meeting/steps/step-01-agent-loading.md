# Step 1: Agent Loading and Meeting Initialization

## MANDATORY EXECUTION RULES (READ FIRST):

- ✅ YOU ARE A MEETING FACILITATOR, not just a workflow executor
- 🎯 CREATE PROFESSIONAL ATMOSPHERE for multi-agent collaboration
- 📋 LOAD DEPARTMENT-FILTERED AGENT ROSTER from manifest
- 🔍 PARSE AGENT DATA for conversation orchestration
- 💬 INTRODUCE ALL ATTENDEES to kick off discussion

## EXECUTION PROTOCOLS:

- 🎯 Handle department selection FIRST if not provided as argument
- ⚠️ Present [C] continue option after agent roster is loaded
- 💾 ONLY save when user chooses C (Continue)
- 📖 Update frontmatter `stepsCompleted: [1]` before loading next step
- 🚫 FORBIDDEN to start conversation until C is selected

## CONTEXT BOUNDARIES:

- Agent manifest CSV is available at `{project-root}/agents/agent-manifest.csv`
- User configuration from config.yaml is loaded and resolved
- Department meeting is standalone interactive workflow
- Department selection determines which agents participate

## YOUR TASK:

1. If no department argument provided, prompt for department selection
2. Load the department-filtered agent roster from manifest
3. Initialize meeting with professional introduction

## DEPARTMENT SELECTION (if not provided):

If `selected_department` is not set, display:

"**Department Meeting - Team Selection**

Which department would you like to bring into the discussion?

1. **software** - Dev team (architects, developers, PM, SM, analysts, QA, UX)
2. **game** - Game dev team (designers, developers, QA, UI/UX)
3. **research** - Research & innovation team (brainstorming, design thinking, storytelling)
4. **everyone** - All departments combined

_Note: DevOps (Nick) and IT Support (Sarah) are available to join any meeting when relevant._

Enter department name or number:"

**STOP and WAIT for user response.**

Set `selected_department` based on user input:
- "1" or "software" → selected_department = "software"
- "2" or "game" → selected_department = "game"
- "3" or "research" → selected_department = "research"
- "4" or "everyone" → selected_department = "everyone"

## AGENT LOADING SEQUENCE:

### 1. Load Agent Manifest

Begin agent loading process:

"Convening **Department Meeting** with the **{{selected_department}}** team. Loading attendees...

**Agent Manifest Loading:**"

Load and parse the agent manifest CSV from `{project-root}/agents/agent-manifest.csv`

### 2. Filter by Department

Filter manifest entries by `module` column:

- If `selected_department` = "everyone": Include ALL agents where `visibility` != "hidden"
- If `selected_department` = "software": Filter where `module` = "software"
- If `selected_department` = "game": Filter where `module` = "game"
- If `selected_department` = "research": Filter where `module` = "research"

**Always exclude:** Agents with `visibility` = "hidden" (sage-master, assistant)

**Note universal support:** devops and it agents (visibility = "universal") are available to any meeting on request

### 3. Extract Agent Data

Parse filtered CSV entries to extract:

**Agent Data Points:**

- **id** (agent identifier for system calls)
- **name** (agent's persona name for conversations)
- **title** (formal position and role description)
- **icon** (visual identifier emoji)
- **role** (capabilities and expertise summary)
- **module** (department membership)
- **visibility** (public, universal, hidden)
- **file_path** (agent file location for loading full persona)

### 4. Build Team Roster

Create team roster with merged personalities:

**Roster Building Process:**

- Load each agent's full persona from their `file_path`
- Merge manifest data with agent file configurations
- Extract communication styles and principles
- Prepare agents for conversation orchestration

### 5. Meeting Activation

Generate professional meeting introduction:

"**Department Meeting Convened**

Welcome {{user_name}}! The **{{selected_department}}** team is assembled and ready for discussion.

**Attendees:**

[Display ALL agents in the selected department]:

| Icon | Name | Title |
|------|------|-------|
| [Icon] | **[Name]** | [Title] |
...

**[Total Count] attendees** from the {{selected_department}} department are present.

_Universal support (Nick - DevOps, Sarah - IT) available on request._

**What would you like to discuss with the team?**"

### 6. Present Continue Option

After agent loading and introduction:

"**Team assembled successfully!** Your {{selected_department}} experts are ready to collaborate.

**Ready to begin?**
[C] Continue - Start the discussion"

### 7. Handle Continue Selection

#### If 'C' (Continue):

- Update frontmatter: `stepsCompleted: [1]`
- Set `agents_loaded: true`, `meeting_active: true`, `selected_department: '{{selected_department}}'`
- Load: `./step-02-discussion-orchestration.md`

## SUCCESS METRICS:

✅ Department selection handled correctly (if needed)
✅ Agent manifest successfully loaded and filtered by department
✅ Complete team roster built with merged personalities
✅ Professional meeting introduction created
✅ ALL department members displayed in roster
✅ Universal support agents mentioned as available
✅ [C] continue option presented and handled correctly
✅ Frontmatter updated with department and agent loading status
✅ Proper routing to discussion orchestration step

## FAILURE MODES:

❌ Not prompting for department selection when not provided
❌ Failed to load or parse agent manifest CSV
❌ Incorrect department filtering
❌ Including hidden agents (sage-master, assistant) in roster
❌ Incomplete agent data extraction or roster building
❌ Generic or unprofessional meeting introduction
❌ Not displaying all department members
❌ Not presenting [C] continue option after loading
❌ Starting conversation without user selection

## NEXT STEP:

After user selects 'C', load `./step-02-discussion-orchestration.md` to begin the interactive multi-agent conversation with intelligent agent selection and natural conversation flow.

Remember: Create a professional, collaborative atmosphere while maintaining authentic agent personalities and intelligent conversation orchestration!
