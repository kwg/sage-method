# Protocol: Generate Context

**ID:** generate_context
**Critical:** CONTEXT_INJECTION
**Purpose:** Generates bounded context XML for subagent spawning

---

## Input/Output

**Input:** task_id, subagent_type, task_data
**Output:** context_file path (`.sage/context/{task-id}.xml`)

---

## Steps

### Step 1: Load Context Limits

Read `.sage/config/context-limits.yaml`
Get limits for subagent_type (use overrides if defined)
Set: max_total, max_file_content, max_prior_output

### Step 2: Build Context XML Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<subagent-context version="1.0">

  <task>
    <id>{task_id}</id>
    <type>{implement|test|fix|review|plan}</type>
    <description>{task description from story}</description>
    <story-ref>{story file path}</story-ref>
  </task>

  <instructions>
    <!-- Task-specific directives based on subagent type -->
    <instruction>Follow TDD: write failing test first</instruction>
    <instruction>Stay within scope - only modify listed files</instruction>
  </instructions>

  <scope>
    <files-to-modify>
      <file>{file paths from task}</file>
    </files-to-modify>
    <files-to-read>
      <file>{dependency file paths}</file>
    </files-to-read>
    <files-forbidden>
      <pattern>{patterns that must not be touched}</pattern>
    </files-forbidden>
  </scope>

  <context>
    <item type="story-excerpt">{relevant story text}</item>
    <item type="code-standards">{coding standards excerpt}</item>
    <item type="prior-output">{summary of previous task output}</item>
  </context>

  <output-format>
    <required-fields>
      <field name="status">success | failure | blocked</field>
      <field name="summary">Brief description of result</field>
      <field name="files-modified">List of files changed</field>
    </required-fields>
    <optional-fields>
      <field name="notes">Additional context</field>
      <field name="recommended-action">Next step suggestion</field>
    </optional-fields>
  </output-format>

</subagent-context>
```

### Step 3: Apply Context Limits

Count tokens in each section.

IF section exceeds limit:
- Summarize content
- Replace file content with path reference
- Truncate if still over

IF total exceeds max_total:
- Apply summarization strategies in priority order
- If still over limit: Error - task too large for subagent

### Step 4: Write Context File

Write XML to: `.sage/context/{task_id}.xml`
Validate XML is well-formed
Log: `Context generated for {task_id}: {token_count} tokens`

### Step 5: Return File Path

Return: `.sage/context/{task_id}.xml`
