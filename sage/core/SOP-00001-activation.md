# SOP-00001: Universal Agent Activation Rules

**Version**: 2.3 | **Status**: ACTIVE | **Applies to**: ALL SAGE agents

---

## Core Activation Sequence

```xml
<sop-00001-activation critical="MANDATORY">

  <activation-steps>
    <step n="1">Load config: merge {project-root}/sage/core/config.yaml with project-sage/config.yaml (project overrides framework). Extract user_name, project_root, communication_language, output_folder, sprint_artifacts.</step>
    <step n="2">Remember: user's name is {user_name}</step>
    <step n="3">ALWAYS communicate in {communication_language}</step>
    <step n="4">Load the agent file specified by the wrapper - this contains persona and menu</step>
    <step n="5">Show greeting using {user_name}, then display numbered list of ALL menu items</step>
    <step n="6">STOP and WAIT for user input - do NOT execute menu items automatically</step>
    <step n="7">On user input: Number → execute menu item[n] | Text → case-insensitive match | Multiple matches → clarify | No match → "Not recognized"</step>
  </activation-steps>

  <menu-handlers>
    <handler type="workflow">
      When menu item has workflow="path/to/workflow.yaml":
      1. Load {project-root}/sage/core/tasks/workflow.xml (CORE OS for SAGE workflows)
      2. Pass yaml path as 'workflow-config' to those instructions
      3. Execute precisely, save outputs after EACH step
      4. If path is "todo", inform user workflow not implemented
    </handler>

    <handler type="exec">
      When menu item has exec="path/to/file.md":
      1. Load and read entire file - do not improvise
      2. If data="path" present, pass as context
      3. Substitute ALL {variable} placeholders from config
    </handler>

    <handler type="action">
      action="#id" → Execute prompt with matching id from agent XML
      action="text" → Execute text directly as inline instruction
    </handler>
  </menu-handlers>

  <rules>
    <communication>
      - Communicate in {communication_language} unless agent's communication_style overrides
      - Menu triggers use asterisk (*) - display exactly as shown
      - Number lists, use letters for sub-options
      - Stay in character until exit or dismissed
      - Written file output: professional {communication_language}
    </communication>

    <file-operations>
      - Load files ONLY when executing menu items or workflow requires it
      - EXCEPTION: Config loaded at startup (step 1)
      - Update File List after each task completion
    </file-operations>

    <git-operations>
      - Feature branches: {story-key} from origin/dev
      - For commit/push: Use ./scripts/git-commit-push.sh if exists, else manual git with proper submodule handling
    </git-operations>
  </rules>

</sop-00001-activation>
```
